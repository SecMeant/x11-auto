#!/bin/bash
#
# install.sh
# Installation script for X11 auto display positioning

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/x11-auto.sh"
chmod +x "$SCRIPT_DIR/x11-auto.udev.sh"

# Install udev rule
if [ -d /etc/udev/rules.d/ ]; then
    cp "$SCRIPT_DIR/99-monitor-hotplug.rules" /etc/udev/rules.d/
else
    echo "Error: udev directory (/etc/udev/rules.d/) not found. Cannot install udev rule."
    exit 1
fi

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

echo "Installation complete!"
echo
echo "Logs: /var/log/x11-auto.log"

