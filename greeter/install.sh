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

# The greeter user's home is "/" (not writable): give it its own cache
install -d -o greeter -g greeter -m 750 /var/cache/rice-greeter /var/cache/rice-greeter/state /var/cache/rice-greeter/data

echo "→ wallpaper sync"
install -m 755 "$here/rice-greeter-sync" /usr/local/bin/rice-greeter-sync
for u in rice-greeter-sync.path rice-greeter-sync.service; do
    sed "s|@HOME@|$home|g; s|@USER@|$user|g" "$here/$u" > "/etc/systemd/system/$u"
done
systemctl daemon-reload
systemctl enable --now rice-greeter-sync.path
RICE_USER=$user /usr/local/bin/rice-greeter-sync

echo "→ checking the greeter's Hyprland config"
# (Hyprland won't run as root without a runtime dir, so check it as you)
sudo -u "$user" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" Hyprland --verify-config --config /etc/greetd/hyprland.lua | tail -1

echo "→ login screen on at boot"
systemctl enable greetd

echo
echo "Done. Reboot to see the new login screen."
echo "Fallback: Ctrl+Alt+F2 gives a text login (then run start-hyprland)."
