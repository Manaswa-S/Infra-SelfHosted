#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  echo "[safe-boot] Re-executing as root..."
  exec sudo -E bash "$0" "$@"
fi

set -Eeuo pipefail
IFS=$'\n\t'

log() {
  echo "[docker-install] $*"
}

fail() {
  log "FATAL: $*"
  exit 1
}

trap 'fail "Failed at line $LINENO"' ERR

log "Checking if Docker is already installed..."

if command -v docker >/dev/null 2>&1; then
  log "Docker already installed ✔"
else
  log "Docker not found. Installing..."

  log "Updating apt cache..."
  sudo apt update -y

  log "Installing prerequisites..."
  sudo apt install -y ca-certificates curl

  log "Setting up keyrings directory..."
  sudo install -m 0755 -d /etc/apt/keyrings

  log "Downloading Docker GPG key..."
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

  sudo chmod a+r /etc/apt/keyrings/docker.asc

  log "Adding Docker apt repository..."
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  log "Updating apt cache with Docker repo..."
  sudo apt update -y

  log "Installing Docker packages..."
  sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  log "Docker installation complete ✔"
fi

log "Checking Docker service status..."

if systemctl is-active --quiet docker; then
  log "Docker service already running ✔"
else
  log "Docker service not running. Starting..."
  sudo systemctl start docker
fi

log "Verifying Docker daemon..."
if docker info >/dev/null 2>&1; then
  log "Docker is healthy and responding ✔"
else
  fail "Docker installed but daemon is not responding"
fi

log "Docker setup finished successfully."
