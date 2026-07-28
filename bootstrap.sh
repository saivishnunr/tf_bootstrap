#!/bin/bash

set -e

echo "=== BOOTSTRAP START ==="

sudo dnf install -y python3 firewalld nginx

sudo mkdir -p /home/adminuser/myapp
sudo chown adminuser:adminuser /home/adminuser/myapp

cat << 'EOF' | sudo tee /home/adminuser/myapp/index.html
<h1>Hello from Python App on RHEL!</h1>
<p>This page is served by SimpleHTTPRequestHandler.</p>
EOF

sudo chown adminuser:adminuser /home/adminuser/myapp/index.html

cat << 'EOF' | sudo tee /home/adminuser/myapp/app.py
from http.server import SimpleHTTPRequestHandler, HTTPServer
import os

# Ensure correct directory is served
os.chdir("/home/adminuser/myapp")

HTTPServer(("0.0.0.0", 8080), SimpleHTTPRequestHandler).serve_forever()
EOF

sudo chown adminuser:adminuser /home/adminuser/myapp/app.py

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
sudo systemctl enable myapp
sudo systemctl restart myapp

echo "<h1>Azure VM Connectivity Test - RHEL 8.7 (VM Extension)</h1>" | sudo tee /usr/share/nginx/html/index.html

sudo systemctl enable nginx
sudo systemctl start nginx

sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

echo "=== BOOTSTRAP COMPLETE ==="
