# X11 Auto Display Positioning

Automatically positions newly connected displays: above the primary display if it's the only secondary screen, or to the right of other non-primary screens if multiple displays are already connected.

## Installation

Run the installation script as root:

```bash
sudo ./install.sh
```

The installer will:
1. Automatically detect the installation directory using `BASH_SOURCE`
2. Configure template files (`.in` files) with the correct paths
3. Generate the final scripts (`x11auto.udev.sh` and `99-monitor-hotplug.rules`)
4. Install the udev rule to `/etc/udev/rules.d/`
5. Reload udev rules

## Files

- `x11auto.sh` - Main script that handles display positioning logic
- `x11auto.udev.sh.in` - Template for the udev wrapper script (configured during install)
- `99-monitor-hotplug.rules.in` - Template for the udev rule (configured during install)
- `install.sh` - Installation script that configures and installs everything

Generated files (not in git):
- `x11auto.udev.sh` - Configured udev wrapper script
- `99-monitor-hotplug.rules` - Configured udev rule

## Logs

Monitor activity in `/var/log/x11auto.log`

