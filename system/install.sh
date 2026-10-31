#!/bin/sh
# System-wide bits of the rice that need root. Run: sudo ~/dotfiles/system/install.sh
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
here=$(dirname "$(realpath "$0")")

# Battery charge limit: writable by wheel (now, and on every boot via udev)
install -Dm644 "$here/90-rice-charge-limit.rules" /etc/udev/rules.d/90-rice-charge-limit.rules
udevadm control --reload
for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
    [ -e "$f" ] && chgrp wheel "$f" && chmod g+w "$f" && echo "charge limit: $f is now writable by wheel"
done
echo done
