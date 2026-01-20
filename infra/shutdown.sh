#!/usr/bin/env bash

# =========================
# ROOT ESCALATION (ONCE)
# =========================
if [[ $EUID -ne 0 ]]; then
  echo "[safe-shutdown] Re-executing as root..."
  exec sudo -E bash "$0" "$@"
fi

# =========================
# STRICT MODE
# =========================
set -Eeuo pipefail
IFS=$'\n\t'

# =========================
# CONFIG
# =========================
LOG_FILE="./safe-shutdown.log"

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

trap 'fail "Script failed at line $LINENO"' ERR

# =========================
# SHUTDOWN FUNCTION
# =========================
shutdown_service() {
  local group="$1"
  local dir="./$group"

  log "Shutting down service: $group"

  [[ -d "$dir" ]] || { log "Skipping missing directory: $dir"; return; }

  pushd "$dir" >/dev/null

  if [[ -f "docker-compose.yaml" ]]; then
    log "Running docker compose down for $group"
    docker compose down || log "Warning: docker-compose down failed for $group"
  else
    log "No docker-compose.yml found in $group, skipping"
  fi

  popd >/dev/null
}

# =========================
# MAIN FLOW
# =========================
log "==== SAFE SHUTDOWN START ===="

SERVICES=(caddy database monitoring gitea n8n)

for svc in "${SERVICES[@]}"; do
  shutdown_service "$svc"
done

log "==== SAFE SHUTDOWN COMPLETE ===="
