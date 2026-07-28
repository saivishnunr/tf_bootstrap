#!/bin/bash

set -e

echo "=== BOOTSTRAP START ==="

sudo dnf install -y python3 firewalld nginx

sudo mkdir -p /home/adminuser/myapp
sudo chown adminuser:adminuser /home/adminuser/myapp

# Stop and disable service BEFORE writing new files
echo "Stopping and disabling old service..."
sudo systemctl stop myapp || true
sudo systemctl disable myapp || true

# Remove old files
echo "Removing old app.py and index.html..."
sudo rm -f /home/adminuser/myapp/app.py
sudo rm -f /home/adminuser/myapp/index.html

echo "Creating index.html..."
cat << 'EOF' | sudo tee /home/adminuser/myapp/index.html
<h1>Hello from Python App on RHEL!</h1>
<p>This page is served by SimpleHTTPRequestHandler.</p>
EOF

sudo chown adminuser:adminuser /home/adminuser/myapp/index.html

echo "Creating NEW app.py..."
cat << 'EOF' | sudo tee /home/adminuser/myapp/app.py
from http.server import SimpleHTTPRequestHandler, HTTPServer
import os

# Ensure correct directory is served
os.chdir("/home/adminuser/myapp")

HTTPServer(("0.0.0.0", 8080), SimpleHTTPRequestHandler).serve_forever()
EOF

sudo chown adminuser:adminuser /home/adminuser/myapp/app.py

echo "Creating systemd service..."
cat << 'EOF' | sudo tee /etc/systemd/system/myapp.service
[Unit]
Description=Simple Python Web App
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/adminuser/myapp/app.py
Restart=always
User=adminuser

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Re-enable and start service AFTER writing new app.py
echo "Re-enabling and starting service..."
sudo systemctl enable myapp
sudo systemctl start myapp

echo "<h1>Azure VM Connectivity Test - RHEL 8.7 (VM Extension)</h1>" | sudo tee /usr/share/nginx/html/index.html

sudo systemctl enable nginx
sudo systemctl start nginx

sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

echo "=== BOOTSTRAP COMPLETE ==="
