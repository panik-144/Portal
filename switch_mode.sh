#!/bin/bash

# Switch Wi-Fi Mode
# Usage: ./switch_mode.sh [ap|client]

MODE=$1

if [ "$MODE" == "ap" ]; then
    echo "Switching to Management AP (PI-ZERO)..."
    nmcli con up PI-ZERO
    echo "AP started. Connect to SSID 'PI-ZERO' (pass: raspberrypi)"
    
elif [ "$MODE" == "client" ]; then
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
