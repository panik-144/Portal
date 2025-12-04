#!/bin/bash

# Setup Management AP (PI-ZERO)
# Creates a persistent Hotspot for SSH and file transfer

echo "Configuring Management AP 'PI-ZERO'..."

# 1. CLEANUP: Remove any "Ignore wlan0" rules from previous runs
if [ -f /etc/NetworkManager/conf.d/99-rogue-ap.conf ]; then
    rm /etc/NetworkManager/conf.d/99-rogue-ap.conf
    echo "Removed NetworkManager ignore rule."
fi

# 2. CLEANUP: Ensure services are available for NetworkManager
systemctl unmask wpa_supplicant 2>/dev/null
systemctl enable wpa_supplicant 2>/dev/null
systemctl restart wpa_supplicant 2>/dev/null

# 3. DISABLE conflicting services
# We don't want hostapd running on boot (NM handles the AP)
systemctl disable hostapd 2>/dev/null
systemctl stop hostapd 2>/dev/null
systemctl disable dnsmasq 2>/dev/null
systemctl stop dnsmasq 2>/dev/null

# Disable dhcpcd because we are using NetworkManager
systemctl disable dhcpcd 2>/dev/null
systemctl stop dhcpcd 2>/dev/null

# 4. Restart NetworkManager to see the device again
systemctl restart NetworkManager
sleep 5

# 5. Configure NetworkManager Hotspot
# Delete existing connection if it exists
nmcli con delete PI-ZERO 2>/dev/null

# Create new Hotspot
# SSID: PI-ZERO
# Password: raspberrypi
# IP: 10.42.0.1 (Default for NM Shared)
echo "Creating Hotspot connection..."
nmcli con add type wifi ifname wlan0 con-name PI-ZERO autoconnect yes ssid PI-ZERO
nmcli con modify PI-ZERO 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify PI-ZERO wifi-sec.key-mgmt wpa-psk wifi-sec.psk "raspberrypi"

# 6. Set priority
nmcli con modify PI-ZERO connection.autoconnect-priority 100

# 7. Force Start
echo "Starting PI-ZERO..."
nmcli con up PI-ZERO

echo ""
echo "Management AP 'PI-ZERO' configured!"
echo "Password: raspberrypi"
echo "IP Address: 10.42.0.1"
