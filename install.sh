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

# Configure x11auto.udev.sh
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|g" "$SCRIPT_DIR/x11auto.udev.sh.in" > "$SCRIPT_DIR/x11auto.udev.sh"

# Configure 99-monitor-hotplug.rules
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|g" "$SCRIPT_DIR/99-monitor-hotplug.rules.in" > "$SCRIPT_DIR/99-monitor-hotplug.rules"

# Configure x11auto-lid.service
sed "s|@SCRIPT_DIR@|$SCRIPT_DIR|g" "$SCRIPT_DIR/x11auto-lid.service.in" > "$SCRIPT_DIR/x11auto-lid.service"

# Make scripts executable
chmod +x "$SCRIPT_DIR/x11auto.sh"
chmod +x "$SCRIPT_DIR/x11auto.udev.sh"
chmod +x "$SCRIPT_DIR/x11auto-lid.sh"
chmod +x "$SCRIPT_DIR/x11auto-lid-wrapper.sh"

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

# Install systemd service for lid monitoring
if [ -d /etc/systemd/system/ ]; then
    echo "Installing systemd service for lid monitoring..."
    cp "$SCRIPT_DIR/x11auto-lid.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable --now x11auto-lid.service
else
    echo "Warning: systemd directory not found. Skipping service installation."
fi

echo "Installation complete!"
echo
echo "Scripts installed from: $SCRIPT_DIR"
echo "Logs: /var/log/x11auto.log"
echo "Lid monitoring logs: /var/log/x11auto-lid.log"

