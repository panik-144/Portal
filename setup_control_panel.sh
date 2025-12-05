#!/bin/bash

# Setup Control Panel Service
# Installs the web interface as a systemd service

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing Rogue Control Panel..."

# Install Flask if not present (system-wide)
# Note: On Pi, we might need --break-system-packages or use apt
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Installing Flask..."
    apt-get update
    apt-get install -y python3-flask
fi

# Create Service File
cat <<EOF > /etc/systemd/system/rogue-control.service
[Unit]
Description=Rogue AP Control Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=/usr/bin/python3 $SCRIPT_DIR/control_panel.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and Start
systemctl daemon-reload
systemctl enable rogue-control.service
systemctl restart rogue-control.service

echo ""
echo "Control Panel Installed!"
echo "Access at:"
echo "  - Management Mode: http://10.42.0.1:5000"
echo "  - Attack Mode:     http://192.168.10.1:5000"
