#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_DIR="${TAILSCALE_INSTALL_DIR:-$HOME/tailscale}"
readonly SERVICE_FILE="/etc/systemd/system/tailscaled.service"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null || die "curl is required"
command -v tar >/dev/null || die "tar is required"
command -v sudo >/dev/null || die "sudo is required"
command -v systemctl >/dev/null || die "systemctl is required"

case "$(uname -m)" in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    ;;
  *)
    die "Unsupported architecture: $(uname -m). Supported architectures are x86_64 and arm64."
    ;;
esac

PACKAGE_INDEX="https://pkgs.tailscale.com/stable/"
VERSION="$(
  curl --fail --silent --show-error --location "$PACKAGE_INDEX" |
    grep --only-matching --extended-regexp "tailscale_[0-9]+\.[0-9]+\.[0-9]+_${ARCH}\.tgz" |
    sed -E 's/^tailscale_([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/' |
    sort --version-sort |
    tail --lines=1
)"

[[ -n "$VERSION" ]] || die "Could not determine the latest Tailscale version for $ARCH"

ARCHIVE="tailscale_${VERSION}_${ARCH}.tgz"
DOWNLOAD_URL="${PACKAGE_INDEX}${ARCHIVE}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

printf 'Installing Tailscale %s for %s...\n' "$VERSION" "$ARCH"
curl --fail --location --output "$TEMP_DIR/$ARCHIVE" "$DOWNLOAD_URL"

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar --extract --gzip --file "$TEMP_DIR/$ARCHIVE" \
  --strip-components=1 \
  --directory "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR/tailscale" "$INSTALL_DIR/tailscaled"

sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Tailscale node agent
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$INSTALL_DIR/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock
RuntimeDirectory=tailscale
StateDirectory=tailscale
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tailscaled

printf '\nTailscale is installed and tailscaled is running.\n'
printf 'Log in with:\n  sudo %q up --qr --ssh --operator=%q\n' \
  "$INSTALL_DIR/tailscale" "$USER"
