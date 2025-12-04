#!/bin/bash

# Setup Management AP (PI-ZERO)
# Creates a persistent Hotspot for SSH and file transfer

echo "Configuring Management AP 'PI-ZERO'..."

# 1. Disable conflicting services on boot
# We only want hostapd to run when we explicitly start the rogue script
systemctl disable hostapd 2>/dev/null
systemctl stop hostapd 2>/dev/null
systemctl disable dnsmasq 2>/dev/null
systemctl stop dnsmasq 2>/dev/null

# 2. Configure NetworkManager Hotspot
# Delete existing connection if it exists
nmcli con delete PI-ZERO 2>/dev/null

# Create new Hotspot
# SSID: PI-ZERO
# Password: raspberrypi
# IP: 10.42.0.1 (Default for NM Shared)
nmcli con add type wifi ifname wlan0 con-name PI-ZERO autoconnect yes ssid PI-ZERO
nmcli con modify PI-ZERO 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify PI-ZERO wifi-sec.key-mgmt wpa-psk wifi-sec.psk "raspberrypi"

# 3. Set priority
# Make sure this connection has high priority so it starts on boot if no other known network is found
nmcli con modify PI-ZERO connection.autoconnect-priority 100

echo ""
echo "Management AP 'PI-ZERO' configured!"
echo "Password: raspberrypi"
echo "IP Address: 10.42.0.1"
echo ""
echo "It will start automatically on boot."
echo "To switch to Client mode (Internet), use: sudo nmcli con down PI-ZERO"
