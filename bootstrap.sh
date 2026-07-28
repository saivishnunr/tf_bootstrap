#!/bin/bash

set -e

echo "=== BOOTSTRAP START ==="

############################################
# Install required packages
############################################
echo "Installing packages..."
sudo dnf install -y python3 firewalld nginx

############################################
# Create application directory
############################################
echo "Creating app directory..."
sudo mkdir -p /home/adminuser/myapp
sudo chown adminuser:adminuser /home/adminuser/myapp

############################################
# Create Python web app
############################################
echo "Creating Python app..."
cat << 'EOF' | sudo tee /home/adminuser/myapp/app.py
from http.server import SimpleHTTPRequestHandler, HTTPServer
HTTPServer(("0.0.0.0", 8080), SimpleHTTPRequestHandler).serve_forever()
EOF

sudo chown adminuser:adminuser /home/adminuser/myapp/app.py

############################################
# Create systemd service
############################################
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

############################################
# Enable and start Python app service
############################################
echo "Enabling Python app service..."
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp

############################################
# Configure Nginx
############################################
echo "Configuring Nginx..."
echo "<h1>Azure VM Connectivity Test - RHEL 8.7 (VM Extension)</h1>" | sudo tee /usr/share/nginx/html/index.html

sudo systemctl enable nginx
sudo systemctl start nginx

############################################
# Configure firewall
############################################
echo "Configuring firewall..."
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

echo "=== BOOTSTRAP COMPLETE ==="