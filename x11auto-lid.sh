#!/bin/bash

# Script to monitor lid events and control built-in display
# Requires: libinput, xrandr, root privileges for libinput

set -euo pipefail

# Log file location
LOG_FILE="/var/log/x11auto-lid.log"

# Function to log messages with timestamp
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Function to find the lid switch input device
find_lid_device() {
    # Search for lid switch device in /proc/bus/input/devices
    local device_block=""
    local device_path=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^I: ]]; then
            # Start of new device block
            device_block="$line"
        elif [[ "$line" =~ ^N: ]]; then
            device_block="$device_block"$'\n'"$line"
        elif [[ "$line" =~ ^H:.+event([0-9]+) ]]; then
            local event_num="${BASH_REMATCH[1]}"
            # Check if this device block contains "Lid Switch"
            if echo "$device_block" | grep -qi "Lid Switch"; then
                echo "/dev/input/event$event_num"
                return 0
            fi
            device_block=""
        fi
    done < /proc/bus/input/devices
    
    return 1
}

# Function to find the built-in display
find_builtin_display() {
    # Common names for built-in displays
    xrandr --query | grep -E "^(eDP|LVDS|DSI|PANEL)" | awk '{print $1}' | head -n1
}

# Function to enable display
enable_display() {
    local display="$1"
    log_message "Lid opened - enabling display: $display"
    xrandr --output "$display" --auto
}

# Function to disable display
disable_display() {
    local display="$1"
    log_message "Lid closed - disabling display: $display"
    xrandr --output "$display" --off
}

# Check if running as root (needed for libinput)
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root to access libinput events"
    echo "Usage: sudo $0"
    exit 1
fi

# Check if DISPLAY environment variable is set
if [ -z "${DISPLAY:-}" ]; then
    log_message "Error: DISPLAY environment variable not set"
    log_message "If running via sudo, use: sudo -E $0"
    exit 1
fi

# Check if libinput is available
if ! command -v libinput &> /dev/null; then
    log_message "Error: libinput not found. Please install libinput-tools"
    exit 1
fi

# Ensure log file exists and is writable
touch "$LOG_FILE" 2>/dev/null || {
    echo "Error: Cannot create/write to log file: $LOG_FILE"
    exit 1
}

# Find the lid switch device
LID_DEVICE=$(find_lid_device)

if [ -z "$LID_DEVICE" ]; then
    log_message "Error: Could not find lid switch device"
    log_message "Available input devices:"
    cat /proc/bus/input/devices | grep -E "^N:" | while read -r line; do
        log_message "  $line"
    done
    exit 1
fi

log_message "Found lid switch device: $LID_DEVICE"

# Find the built-in display
BUILTIN_DISPLAY=$(find_builtin_display)

if [ -z "$BUILTIN_DISPLAY" ]; then
    log_message "Error: Could not detect built-in display"
    log_message "Available displays:"
    xrandr --query | grep " connected" | while read -r line; do
        log_message "  $line"
    done
    exit 1
fi

log_message "Monitoring lid events for display: $BUILTIN_DISPLAY"
log_message "Press Ctrl+C to stop"
log_message ""

# Track current lid state to avoid redundant operations
LID_STATE=""

# Listen to libinput events from the lid switch device only
# Using --device ensures we only subscribe to this specific device's events
stdbuf -oL libinput debug-events --device "$LID_DEVICE" | while IFS= read -r line; do
    # Look for lid switch events
    # Example: " SWITCH_TOGGLE  +0.000s    switch lid state 1"
    # Example: " SWITCH_TOGGLE  +0.000s    switch lid state 0"
    if echo "$line" | grep -q "switch lid state"; then
        # Extract the lid state (0 = open, 1 = closed)
        STATE=$(echo "$line" | grep -oP 'state \K[0-9]+')
        
        # Only act if state changed
        if [ "$STATE" != "$LID_STATE" ]; then
            LID_STATE="$STATE"
            
            if [ "$STATE" = "1" ]; then
                # Lid closed
                disable_display "$BUILTIN_DISPLAY"
            elif [ "$STATE" = "0" ]; then
                # Lid open
                enable_display "$BUILTIN_DISPLAY"
                udevadm trigger
            fi
        fi
    fi
done
