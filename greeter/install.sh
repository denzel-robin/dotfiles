#!/usr/bin/env bash
# Install / update the rice login screen (greetd + Quickshell greeter).
#   sudo ~/dotfiles/greeter/install.sh
# Undo: sudo systemctl disable greetd   (back to the text console login)
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Run with sudo: sudo $0"; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
user=${SUDO_USER:-ibexe}
home=$(getent passwd "$user" | cut -d: -f6)

pacman -Q greetd >/dev/null 2>&1 || pacman -S --needed greetd

echo "→ greeter files"
install -d /etc/greetd/rice-greeter
install -m 644 "$here/rice-greeter/shell.qml" /etc/greetd/rice-greeter/shell.qml
install -m 644 "$here/hyprland.lua" /etc/greetd/hyprland.lua
[ -f /etc/greetd/config.toml ] && [ ! -f /etc/greetd/config.toml.orig ] && cp /etc/greetd/config.toml /etc/greetd/config.toml.orig
install -m 644 "$here/config.toml" /etc/greetd/config.toml

echo "→ wallpaper sync"
install -m 755 "$here/rice-greeter-sync" /usr/local/bin/rice-greeter-sync
for u in rice-greeter-sync.path rice-greeter-sync.service; do
    sed "s|@HOME@|$home|g; s|@USER@|$user|g" "$here/$u" > "/etc/systemd/system/$u"
done
systemctl daemon-reload
systemctl enable --now rice-greeter-sync.path
RICE_USER=$user /usr/local/bin/rice-greeter-sync

echo "→ checking the greeter's Hyprland config"
Hyprland --verify-config --config /etc/greetd/hyprland.lua

echo "→ login screen on at boot"
systemctl enable greetd

echo
echo "Done. Reboot to see the new login screen."
echo "Fallback: Ctrl+Alt+F2 gives a text login (then run start-hyprland)."
