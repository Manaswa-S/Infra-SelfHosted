#!/usr/bin/env bash

# =========================
# ROOT ESCALATION (ONCE)
# =========================
if [[ $EUID -ne 0 ]]; then
  echo "[safe-boot] Re-executing as root..."
  exec sudo -E bash "$0" "$@"
fi

# =========================
# STRICT MODE (SECURITY)
# =========================
set -Eeuo pipefail
IFS=$'\n\t'

# =========================
# CONFIG
# =========================
BOOT_WAIT_SECONDS=5
STABILIZE_CHECKS=6
STABILIZE_INTERVAL=10
MAX_MEM_PERCENT=85
MAX_CPU_LOAD=5.0   # load average (1m) threshold

LOG_FILE="./safe-boot.log"

# =========================
# LOGGING
# =========================
log() {
  echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"
}

fail() {
  log "FATAL: $*"
  exit 1
}

# =========================
# CLEAN ERROR HANDLING
# =========================
trap 'fail "Script failed at line $LINENO"' ERR

# =========================
# RESOURCE CHECKS
# =========================
check_resources() {
  local mem_used cpu_load

  mem_used=$(free | awk '/Mem:/ { printf("%.0f", $3/$2 * 100) }')
  cpu_load=$(awk '{print $1}' /proc/loadavg)

  log "Resource check → MEM=${mem_used}% LOAD=${cpu_load}"

  (( mem_used < MAX_MEM_PERCENT )) || return 1
  awk "BEGIN {exit !($cpu_load < $MAX_CPU_LOAD)}"
}

wait_for_stability() {
  log "Checking system stability..."

  local failures=0

  while true; do
    if check_resources; then
      log "System within limits ✔"
      return 0
    else
      ((++failures))
      log "Resources over limit (${failures}/${STABILIZE_CHECKS})"

      if (( failures > STABILIZE_CHECKS )); then
        fail "System failed stability checks more than ${STABILIZE_CHECKS} times"
      fi
    fi

    sleep "$STABILIZE_INTERVAL"
  done
}



# =========================
# DOCKER
# =========================
start_docker() {
  log "Starting Docker..."
  systemctl start docker
  sleep 5

  docker info >/dev/null 2>&1 || fail "Docker failed to start"
}

run_service_group() {
  local group="$1"
  local dir="./$group"

  log "Starting service: $group"

  [[ -d "$dir" ]] || fail "Missing directory: $dir"

  pushd "$dir" >/dev/null

  if [[ -f "./prepare.sh" ]]; then
    log "Running prepare.sh for $group"
    bash ./prepare.sh
  fi

  log "Running docker compose for $group"
  docker compose up -d || fail "docker-compose failed for $group"

  popd >/dev/null

  wait_for_stability
}

# =========================
# MAIN FLOW
# =========================
log "==== SAFE BOOT START ===="

log "Initial boot wait (${BOOT_WAIT_SECONDS}s)"
sleep "$BOOT_WAIT_SECONDS"

log "==== WAIT FOR STABILITY ===="
wait_for_stability

start_docker
wait_for_stability

if [[ -x "./docker-networks.sh" ]]; then
  log "Running docker-networks.sh"
  bash ./docker-networks.sh
fi

SERVICES=(caddy database monitoring gitea n8n)

for svc in "${SERVICES[@]}"; do
  run_service_group "$svc"
done


log "==== SAFE BOOT COMPLETE ===="
