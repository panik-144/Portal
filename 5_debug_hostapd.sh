#!/bin/bash

# Debug Hostapd Script
# Runs hostapd in the foreground to see why it's not broadcasting

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Must run as root${NC}" 
   exit 1
fi

echo -e "${YELLOW}Stopping background services...${NC}"
systemctl stop hostapd
systemctl stop dnsmasq
killall wpa_supplicant 2>/dev/null

echo -e "${YELLOW}Unblocking Wi-Fi radio...${NC}"
rfkill unblock wlan
if command -v iw &> /dev/null; then
    iw dev wlan0 set power_save off 2>/dev/null
fi

echo -e "${YELLOW}Checking interface status...${NC}"
ip link set wlan0 down
ip link set wlan0 up
ip link show wlan0

echo -e "${GREEN}Starting hostapd in DEBUG mode...${NC}"
echo -e "Look for errors like 'Failed to initialize driver' or 'Hardware does not support'..."
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Run hostapd directly with debug output
hostapd -d /etc/hostapd/hostapd.conf
