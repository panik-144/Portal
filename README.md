# Rogue Captive Portal - UNI-MAINZ Login Clone

This project clones the University of Mainz login page and captures credentials. It includes both a standalone Flask application and a complete rogue access point setup for Kali Linux.

## Features

- **Realistic Login Clone**: Pixel-perfect clone of the UNI-MAINZ login page
- **Dual Authentication Methods**: 
  - Username/Password capture
  - Passkey (WebAuthn) attempt logging
- **Admin Panel**: Real-time view of captured credentials
- **Rogue AP Setup**: Automated script for Kali Linux to create a fake Wi-Fi network
- **Error Handling**: Displays realistic error messages after login attempts

## Quick Start (Standalone)

### 1. Install Dependencies

The project uses a virtual environment:
```bash
python3 -m venv .venv
.venv/bin/pip install flask
```

### 2. Run the Server

```bash
.venv/bin/python3 app.py
```

The server will start on port 8080 (http://localhost:8080).

## Rogue Access Point Setup (Kali Linux)

### Prerequisites

- Kali Linux (or any Debian-based Linux)
- Wireless adapter that supports AP mode
- Root access

### Modular Setup (Recommended)

The setup has been broken into 4 separate scripts for better control and debugging:

#### 1. Install Dependencies
```bash
sudo ./1_install_dependencies.sh
```
This script:
- Updates package lists
- Installs system packages (hostapd, dnsmasq, iptables, python3, etc.)
- Creates Python virtual environment
- Installs Flask

#### 2. Configure Services
```bash
sudo ./2_configure_services.sh
```
This script:
- Configures hostapd (Wi-Fi access point)
- Configures dnsmasq (DHCP and DNS server)
- Sets up network interface
- Configures iptables rules
- Enables services for systemd

#### 3. Check Status (Optional but Recommended)
```bash
sudo ./3_check_status.sh
```
This script verifies:
- All dependencies are installed
- Configuration files exist and are correct
- Network interface is available
- Services are properly configured
- Provides detailed status report with errors and warnings

#### 4. Run Rogue Access Point
```bash
sudo ./4_run_rogue_ap.sh
```
This script:
- Configures network interface with static IP
- Applies iptables rules
- Starts hostapd and dnsmasq services
- Starts Flask captive portal
- Displays status dashboard
- Runs until you press Ctrl+C

### Legacy Setup (All-in-One)

Alternatively, you can use the original monolithic script:

```bash
chmod +x setup_rogue_ap.sh
sudo ./setup_rogue_ap.sh
```

### Configuration

Edit the variables at the top of `2_configure_services.sh` and `4_run_rogue_ap.sh`:

```bash
SSID="UNI-MAINZ"              # Wi-Fi network name
INTERFACE="wlan0"              # Your wireless interface
GATEWAY_IP="192.168.10.1"      # AP gateway IP
FLASK_PORT=8080                # Flask server port
```

### What Happens

1. **Victim connects** to the "UNI-MAINZ" Wi-Fi network
2. **All DNS queries** are redirected to the rogue AP
3. **All HTTP/HTTPS traffic** is redirected to the captive portal
4. **Victim sees** the fake UNI-MAINZ login page
5. **Credentials are captured** when they attempt to log in
6. **Admin can view** captured credentials at `http://192.168.10.1:8080/admin`

## 🎮 Management Mode (PI-ZERO)

Since the Pi Zero often lacks a screen/keyboard, we set up a persistent Management AP called **"PI-ZERO"**.

### Initial Setup
Run this once to configure the management hotspot:
```bash
sudo ./setup_management_ap.sh
```

### How it Works
1.  **Boot**: The Pi creates a Wi-Fi network `PI-ZERO` (OPEN / No Password).
2.  **Connect**: Join this network from your laptop.
3.  **SSH**: `ssh pani@10.42.0.1`
4.  **Start Attack**: Run `sudo ./4_run_rogue_ap.sh`.
    *   This **stops** PI-ZERO and **starts** UNI-MAINZ.
    *   You will lose SSH connection (this is normal).
5.  **Stop Attack**: Press `Ctrl+C`.
    *   UNI-MAINZ stops.
    *   PI-ZERO restarts automatically.
    *   You can reconnect via SSH.

### Switching to Internet Mode
If you need to update the Pi or install packages:
```bash
sudo ./switch_mode.sh client
```
This stops the AP and lets you connect to a normal Wi-Fi network using `sudo nmtui`.

To go back to AP mode:
```bash
sudo ./switch_mode.sh ap
```

## 🚀 Usage

### Victim Page
- Access `http://localhost:8080/` (or `http://192.168.10.1:8080/` on rogue AP)
- This is the cloned login page with two options:
  - **Benutzername / Passwort**: Traditional login form
  - **Passkey**: WebAuthn authentication attempt

### Admin Page
- Access `http://localhost:8080/admin` (or `http://192.168.10.1:8080/admin` on rogue AP)
- This page lists all captured login attempts with:
  - Timestamp
  - IP address
  - Credentials or authentication data
  - Type (password login, passkey success, passkey failed)

## 📂 Files

### Core Scripts
*   `1_install_dependencies.sh`: Installs system packages and Python venv.
*   `2_configure_services.sh`: Configures hostapd, dnsmasq, and firewall.
*   `3_check_status.sh`: Verifies that everything is ready to run.
*   `4_run_rogue_ap.sh`: Starts the attack (stops management AP, starts rogue AP).

### Management Scripts
*   `setup_management_ap.sh`: Creates the "PI-ZERO" persistent Hotspot (Run once).
*   `switch_mode.sh`: Toggles between "PI-ZERO" (AP) and Internet (Client) modes.

### Web Application
*   `app.py`: Flask application that serves the portal.
*   `index.html`: The cloned login page.
*   `css/` & `images/`: Local assets for the website.
*   `download_resources.sh`: Utility to re-download website assets.

### Documentation
*   `TROUBLESHOOTING.md`: Detailed solutions for common errors.
*   `README.md`: This file

## Security Notice

⚠️ **This tool is for educational and authorized security testing purposes only.**

- Only use on networks you own or have explicit permission to test
- Unauthorized access to computer systems is illegal
- This is a demonstration of social engineering and phishing techniques
- Always follow responsible disclosure practices

## Stopping the Rogue AP

Press `Ctrl+C` in the terminal where the script is running. The script will automatically:
- Stop hostapd and dnsmasq
- Stop the Flask application
- Restore network settings
- Re-enable NetworkManager

## Troubleshooting

### Rogue AP Issues

1. **hostapd fails to start**:
   - Check if your wireless adapter supports AP mode: `iw list | grep "Supported interface modes" -A 8`
   - Try a different channel in the config

2. **No internet access for victims**:
   - This is intentional. Uncomment the NAT line in `configure_iptables()` if you want to provide internet

3. **DNS not redirecting**:
   - Check dnsmasq logs: `journalctl -u dnsmasq -f`
   - Verify iptables rules: `iptables -t nat -L -n -v`

### Flask Issues

1. **Port already in use**:
   - Change `FLASK_PORT` in the script or `app.py`
   - Kill existing process: `pkill -f app.py`

2. **Credentials not showing**:
   - Check Flask logs: `cat flask.log`
   - Verify the admin page is accessible

## Advanced Configuration

### Custom SSID

Edit `SSID` variable in `setup_rogue_ap.sh` to match your target network name.

### SSL/HTTPS

For a more convincing attack, you can:
1. Generate a self-signed certificate
2. Modify Flask to use HTTPS
3. Update iptables rules to redirect port 443

### Persistence

To save captured credentials to a file:
- Modify `app.py` to write to a JSON file
- Or export from the admin panel

## License

This project is for educational purposes only. Use responsibly and legally.
