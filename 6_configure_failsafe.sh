#!/bin/bash

# Failsafe Configuration
# Sets up the most basic, compatible hostapd config possible

INTERFACE="wlan0"
SSID="UNI-MAINZ"

echo "Configuring FAILSAFE hostapd..."

# 1. Unblock everything
rfkill unblock all

# 2. Create minimal config
cat <<EOF > /etc/hostapd/hostapd.conf
interface=$INTERFACE
# Generic driver
driver=nl80211
# The SSID
ssid=$SSID
# Mode g = 2.4GHz
hw_mode=g
# Channel 1 is often safest
channel=1
# Disable all advanced features
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
# No encryption
wpa=0
EOF

echo "Failsafe config created at /etc/hostapd/hostapd.conf"
echo "Try running ./5_debug_hostapd.sh now to see if it works."
