#!/bin/bash

# Restore Wi-Fi Functionality
# Run this if you can't connect to the internet after using the Rogue AP

echo "Restoring Wi-Fi functionality..."

# 1. Remove the "ignore wlan0" rule
if [ -f /etc/NetworkManager/conf.d/99-rogue-ap.conf ]; then
    rm /etc/NetworkManager/conf.d/99-rogue-ap.conf
    echo "Removed NetworkManager ignore rule."
fi

# 2. Unmask and restart wpa_supplicant
systemctl unmask wpa_supplicant
systemctl restart wpa_supplicant
echo "Restored wpa_supplicant."

# 3. Restart NetworkManager
systemctl restart NetworkManager
systemctl restart dhcpcd 2>/dev/null || true
echo "Restarted NetworkManager and dhcpcd."

# 4. Bring interface up
ip link set wlan0 up

echo ""
echo "Done! You should be able to use nmtui now."
