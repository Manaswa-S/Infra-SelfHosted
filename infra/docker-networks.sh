#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  echo "[safe-boot] Re-executing as root..."
  exec sudo -E bash "$0" "$@"
fi

set -e

NETWORKS=(
  edge_net
  apps_net
  db_net
  metrics_net
)

echo "Checking Docker availability..."
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running or not accessible"
  exit 1
fi

for net in "${NETWORKS[@]}"; do
  if ! docker network inspect "$net" >/dev/null 2>&1; then
    echo "Creating network: $net"
    docker network create "$net"
  else
    echo "Network already exists: $net"
  fi
done

echo "All required Docker networks are ready."
