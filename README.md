# Tailscale installer for SteamOS

This script installs the latest stable Tailscale release on SteamOS and configures
`tailscaled` to start automatically with systemd. It supports:

- Steam Deck and other x86-64 SteamOS systems
- ARM64 SteamOS systems

## Install

Run this from Desktop Mode or an SSH session:

```sh
curl -fsSL https://raw.githubusercontent.com/dylanjphelps/steamos-tailscale-installer/main/install-tailscale.sh | bash
```

The script detects the CPU architecture, downloads the matching package, installs
it under `~/tailscale`, and enables `tailscaled`.

## Log in

After installation, run the command printed by the script. It opens a QR code
and enables Tailscale SSH:

```sh
sudo ~/tailscale/tailscale up --qr --ssh --operator="$USER"
```

## Updating

Run the installer again. It downloads the latest stable release and replaces the
existing binaries while preserving Tailscale state.

## Uninstall

Remove the Tailscale binaries and systemd service with:

```sh
curl -fsSL https://raw.githubusercontent.com/dylanjphelps/steamos-tailscale-installer/main/uninstall-tailscale.sh | bash
```

By default, the script preserves Tailscale state in `/var/lib/tailscale`. To
remove the state too, download the script and run it with `--purge`:

```sh
curl -fsSLO https://raw.githubusercontent.com/dylanjphelps/steamos-tailscale-installer/main/uninstall-tailscale.sh
bash uninstall-tailscale.sh --purge
rm uninstall-tailscale.sh
```

## Requirements

The system must provide `curl`, `tar`, `sudo`, and `systemctl`. The installer
supports `x86_64` and `aarch64`/`arm64`.
