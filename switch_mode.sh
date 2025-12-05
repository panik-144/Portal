#!/bin/bash

# Switch Wi-Fi Mode
# Usage: ./switch_mode.sh [ap|client]

MODE=$1

# Helper to ensure NM can manage the device
ensure_managed() {
    if [ -f /etc/NetworkManager/conf.d/99-rogue-ap.conf ]; then
        echo "Removing ignore rule..."
        rm /etc/NetworkManager/conf.d/99-rogue-ap.conf
        systemctl reload NetworkManager
        sleep 2
    fi
}

if [ "$MODE" == "ap" ]; then
    ensure_managed
    echo "Switching to Management AP (PI-ZERO)..."
    nmcli con up PI-ZERO
    echo "AP started. Connect to SSID 'PI-ZERO' (OPEN)"
    
elif [ "$MODE" == "client" ]; then
    ensure_managed
    echo "Switching to Client Mode (Internet)..."
    nmcli con down PI-ZERO
    echo "AP stopped. Searching for known networks..."
    # Force a scan and connect
    nmcli device wifi rescan
    sleep 2
    nmcli device wifi list
    echo "Use 'sudo nmtui' to connect to a network if not connected automatically."
    
else
    echo "Usage: ./switch_mode.sh [ap|client]"
    echo "  ap     - Start PI-ZERO Access Point"
    echo "  client - Connect to Internet (Stop AP)"
fi
