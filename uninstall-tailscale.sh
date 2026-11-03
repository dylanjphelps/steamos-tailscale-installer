#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_DIR="${TAILSCALE_INSTALL_DIR:-$HOME/tailscale}"
readonly SERVICE_FILE="/etc/systemd/system/tailscaled.service"
readonly STATE_DIR="/var/lib/tailscale"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

command -v sudo >/dev/null || die "sudo is required"
command -v systemctl >/dev/null || die "systemctl is required"

PURGE_STATE=false
if [[ "${1:-}" == "--purge" ]]; then
  PURGE_STATE=true
elif [[ $# -gt 0 ]]; then
  die "Usage: $0 [--purge]"
fi

if sudo systemctl cat tailscaled.service >/dev/null 2>&1; then
  sudo systemctl disable --now tailscaled
fi

sudo rm -f "$SERVICE_FILE"
sudo systemctl daemon-reload

rm -rf "$INSTALL_DIR"

if [[ "$PURGE_STATE" == true ]]; then
  sudo rm -rf "$STATE_DIR"
  printf 'Removed Tailscale binaries, service, and state.\n'
else
  printf 'Removed Tailscale binaries and service. State was preserved in %s.\n' "$STATE_DIR"
  printf 'To remove the state as well, run: %s --purge\n' "$0"
fi
