# Troubleshooting Guide - Common Issues

## Issues You Encountered and How They're Fixed

### Issue 1: Virtual Environment Path Mismatch
**Error**: `/home/pani/Rogue_Captive_Portal/.venv/bin/pip: exec: /Users/pani/Developer/Rogue Captive Portal/.venv/bin/python3.14: not found`

**Cause**: The virtual environment was created with hardcoded paths from a different system

**Fix Applied**:
- All scripts now use `SCRIPT_DIR` variable to dynamically determine the current directory
- Scripts detect the actual Python binary name (python3, python, python3.x)
- No more hardcoded paths

**How to Fix Your Existing Setup**:
```bash
# Delete the old venv with wrong paths
rm -rf /home/pani/Rogue_Captive_Portal/.venv

# Run the install script again
cd /home/pani/Rogue_Captive_Portal
sudo ./1_install_dependencies.sh
```

---

### Issue 2: Missing sysctl.conf
**Error**: `sed: can't read /etc/sysctl.conf: No such file or directory`

**Cause**: Some minimal Linux installations don't have `/etc/sysctl.conf` by default

**Fix Applied**:
- Script now checks if `/etc/sysctl.conf` exists before trying to modify it
- If it doesn't exist, the script creates it
- IP forwarding is still enabled via `/proc/sys/net/ipv4/ip_forward`

**Manual Fix** (if needed):
```bash
# Create sysctl.conf manually
sudo bash -c 'echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf'
```

---

### Issue 3: Flask Not Installed
**Error**: `Flask is NOT installed in venv`

**Cause**: Virtual environment was created on a different system with different paths

**Fix Applied**:
- Script 1 now verifies Flask installation even if venv exists
- Script 3 provides detailed diagnostics about which Python binary it's checking
- Better error messages showing exact paths

**Manual Fix**:
```bash
# Reinstall Flask in your venv
cd /home/pani/Rogue_Captive_Portal
.venv/bin/pip install --upgrade flask

# Or recreate the entire venv
rm -rf .venv
python3 -m venv .venv
.venv/bin/pip install flask
```

---

## General Troubleshooting Steps

### Step 1: Clean Slate
If you're moving the project to a new system, always start fresh:

```bash
# Navigate to your project directory
cd /home/pani/Rogue_Captive_Portal  # or wherever it is

# Remove old virtual environment
rm -rf .venv

# Run installation from scratch
sudo ./1_install_dependencies.sh
```

### Step 2: Verify Your Location
Make sure you're running scripts from the correct directory:

```bash
# Check where you are
pwd

# Should output something like: /home/pani/Rogue_Captive_Portal

# List files to confirm
ls -la
# Should see: app.py, index.html, 1_install_dependencies.sh, etc.
```

### Step 3: Check Python Installation
```bash
# Verify Python 3 is installed
python3 --version

# Should output: Python 3.x.x
```

### Step 4: Run Status Check
After installation and configuration, always run:

```bash
sudo ./3_check_status.sh
```

This will tell you exactly what's wrong.

---

## System-Specific Issues

### Different Directory Structure
**Problem**: Project is in `/home/pani/Rogue_Captive_Portal` instead of `/Users/pani/Developer/Rogue captive portal`

**Solution**: ✅ Already handled! All scripts now use `SCRIPT_DIR` to auto-detect location

### Different Python Version
**Problem**: System has `python3.11` but venv was created with `python3.14`

**Solution**: ✅ Already handled! Scripts now search for any Python binary in venv

### Missing System Packages
**Problem**: `hostapd` or `dnsmasq` not installed

**Solution**:
```bash
sudo apt-get update
sudo apt-get install -y hostapd dnsmasq iptables python3 python3-pip python3-venv
```

---

## Quick Fixes for Common Errors

### "Interface wlan0 does not exist"
```bash
# List available interfaces
ip link show

# Update the INTERFACE variable in scripts 2 and 4
# Change wlan0 to your actual wireless interface (e.g., wlan1, wlp2s0)
```

### "Permission denied"
```bash
# Make sure you're running with sudo
sudo ./script_name.sh

# Make sure scripts are executable
chmod +x *.sh
```

### "Flask application failed to start"
```bash
# Check the Flask log
cat flask.log

# Common issues:
# 1. Port 8080 already in use
sudo lsof -i :8080
sudo kill -9 <PID>

# 2. app.py has syntax errors
python3 -m py_compile app.py
```

### "hostapd failed to start"
```bash
# Check if your wireless adapter supports AP mode
iw list | grep "Supported interface modes" -A 8

# Should show "AP" in the list

# Check hostapd logs
sudo journalctl -u hostapd -n 50

# Try a different channel in /etc/hostapd/hostapd.conf
# Change: channel=6 to channel=1 or channel=11
```

---

## Captive Portal Issues

### Popup Doesn't Appear
**Problem**: Connected to Wi-Fi but no login page appears automatically.

**Solutions**:
1.  **Forget Network**: The device might remember a previous state. "Forget" the network and reconnect.
2.  **Check Flask Logs**: Run `tail -f flask.log`. You should see requests for `generate_204` (Android) or `hotspot-detect.html` (iOS).
3.  **Manual Trigger**: Open a browser and visit `http://neverssl.com` or `http://1.1.1.1`.
4.  **DNS Check**: Ensure `dnsmasq` is running (`systemctl status dnsmasq`).

### Browser Shows SSL Warning
**Problem**: "Your connection is not private" when visiting https://google.com.

**Cause**: This is expected behavior. We are intercepting HTTPS traffic but don't have the real certificate for Google/Apple/etc.
**Fix**: Users must proceed through the warning or use an HTTP site (like the auto-popup does) to trigger the login page.

---

## Verification Checklist

Before running script 4, verify:

- [ ] You're in the correct directory (`pwd` shows your project path)
- [ ] Virtual environment exists (`.venv` folder is present)
- [ ] Flask is installed (run script 3 to check)
- [ ] Configuration files exist (`/etc/hostapd/hostapd.conf` and `/etc/dnsmasq.conf`)
- [ ] Wireless interface exists and is correct (check with `ip link show`)
- [ ] You're running as root (`sudo`)

---

## Still Having Issues?

Run this diagnostic command:

```bash
# Create a diagnostic report
echo "=== System Info ===" > diagnostic.txt
uname -a >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== Python Info ===" >> diagnostic.txt
python3 --version >> diagnostic.txt
which python3 >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== Current Directory ===" >> diagnostic.txt
pwd >> diagnostic.txt
ls -la >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== Virtual Environment ===" >> diagnostic.txt
ls -la .venv/bin/ 2>&1 >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== Network Interfaces ===" >> diagnostic.txt
ip link show >> diagnostic.txt
echo "" >> diagnostic.txt

echo "=== Installed Packages ===" >> diagnostic.txt
dpkg -l | grep -E "hostapd|dnsmasq|python3" >> diagnostic.txt

cat diagnostic.txt
```

This will show all relevant information for debugging.
