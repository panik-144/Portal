# Rogue Captive Portal - Quick Reference

## Modular Setup Workflow

### First Time Setup

```bash
# Step 1: Install all dependencies
sudo ./1_install_dependencies.sh

# Step 2: Configure all services
sudo ./2_configure_services.sh

# Step 3: Verify everything is ready (optional but recommended)
sudo ./3_check_status.sh

# Step 4: Run the rogue access point
sudo ./4_run_rogue_ap.sh
```

### Subsequent Runs

If you've already installed and configured everything:

```bash
# Just run the access point
sudo ./4_run_rogue_ap.sh
```

### Checking Status Anytime

```bash
# Run the status checker to verify configuration
sudo ./3_check_status.sh
```

## Script Breakdown

### 1_install_dependencies.sh
**Purpose**: Install system packages and Python dependencies  
**Run When**: 
- First time setup
- After system reinstall
- When dependencies are missing

**What it does**:
- Updates apt package lists
- Installs: hostapd, dnsmasq, iptables, python3, python3-pip, python3-venv
- Creates Python virtual environment (.venv)
- Installs Flask in the virtual environment
- Stops services for configuration

**Safe to re-run**: Yes (will skip if venv exists)

---

### 2_configure_services.sh
**Purpose**: Configure all services and system settings  
**Run When**:
- First time setup
- After changing configuration (SSID, IP, etc.)
- When configuration files are corrupted

**What it does**:
- Configures hostapd (Wi-Fi access point settings)
- Configures dnsmasq (DHCP and DNS settings)
- Sets up network interface configuration
- Configures iptables rules for traffic redirection
- Enables services for systemd

**Safe to re-run**: Yes (will overwrite existing configs)

**Configuration Variables** (edit at top of script):
- `SSID`: Wi-Fi network name
- `INTERFACE`: Wireless interface (e.g., wlan0)
- `GATEWAY_IP`: Access point IP address
- `DHCP_RANGE_START/END`: DHCP IP range
- `FLASK_PORT`: Port for Flask application

---

### 3_check_status.sh
**Purpose**: Verify system configuration and readiness  
**Run When**:
- Before running the access point
- When troubleshooting issues
- To verify configuration changes

**What it checks**:
- ✓ System packages installed
- ✓ Python virtual environment exists
- ✓ Flask is installed
- ✓ Configuration files exist and are correct
- ✓ Network interface exists
- ✓ iptables is available
- ✓ Services are enabled

**Output**:
- Green ✓ : Everything OK
- Yellow ⚠ : Warnings (may still work)
- Red ✗ : Errors (must fix before running)

**Safe to re-run**: Yes (read-only, no changes)

---

### 4_run_rogue_ap.sh
**Purpose**: Start and run the rogue access point  
**Run When**:
- After installation and configuration
- Every time you want to run the attack

**What it does**:
- Configures network interface with static IP
- Applies iptables rules for traffic redirection
- Starts hostapd (Wi-Fi access point)
- Starts dnsmasq (DHCP/DNS server)
- Starts Flask captive portal
- Displays status dashboard
- Runs continuously until Ctrl+C

**Cleanup on Exit**:
- Stops all services
- Restores network settings
- Flushes iptables rules
- Restarts NetworkManager

**Safe to re-run**: Yes (will clean up previous instance)

---

## Troubleshooting

### Script 1 Fails
**Problem**: Package installation fails  
**Solution**: 
```bash
sudo apt-get update
sudo apt-get upgrade
```

### Script 2 Fails
**Problem**: Configuration files can't be written  
**Solution**: Make sure you're running as root with `sudo`

### Script 3 Shows Errors
**Problem**: Dependencies or configs missing  
**Solution**: 
- If packages missing: Run script 1
- If configs missing: Run script 2

### Script 4 Fails to Start
**Common Issues**:

1. **Interface doesn't exist**
   - Check available interfaces: `ip link show`
   - Update `INTERFACE` variable in script

2. **hostapd fails**
   - Check if interface supports AP mode: `iw list | grep "Supported interface modes" -A 8`
   - Try different channel in hostapd.conf

3. **Flask fails**
   - Check if app.py exists
   - Check flask.log for errors
   - Verify port 8080 is available

## Admin Access

Once running, access the admin panel:
```
http://192.168.10.1:8080/admin
```

View captured credentials in real-time.

## Stopping the Attack

Press `Ctrl+C` in the terminal running script 4. The cleanup function will automatically restore everything.

## Security Warning

⚠️ **Use only for authorized testing and educational purposes!**
