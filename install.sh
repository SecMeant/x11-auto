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

# Configure template files by replacing @SCRIPT_DIR@ with actual path
echo "Configuring scripts with installation directory: $SCRIPT_DIR"

# Configure x11-auto.udev.sh
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|g" "$SCRIPT_DIR/x11-auto.udev.sh.in" > "$SCRIPT_DIR/x11-auto.udev.sh"

# Configure 99-monitor-hotplug.rules
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|g" "$SCRIPT_DIR/99-monitor-hotplug.rules.in" > "$SCRIPT_DIR/99-monitor-hotplug.rules"

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
echo "Scripts installed from: $SCRIPT_DIR"
echo "Logs: /var/log/x11-auto.log"

