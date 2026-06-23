#!/bin/bash

# ModelVault Service Installation Script
# Purpose: Install and configure ModelVault as a systemd service
# Author: Javier Alonso

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}ModelVault Service Installer${NC}"
echo "==============================="

# 1. Create modelvault user
echo -n "Creating modelvault user... "
if id "modelvault" &>/dev/null; then
    echo -e "${YELLOW}already exists${NC}"
else
    useradd -r -s /bin/bash -d /opt/modelvault -m modelvault
    echo -e "${GREEN}✓${NC}"
fi

# 2. Copy files to /opt/modelvault
echo -n "Installing ModelVault to /opt/modelvault... "
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create directory structure
mkdir -p /opt/modelvault/{src,utils,docker,data,logs,systemd}

# Copy all files
cp -r "$SCRIPT_DIR"/* /opt/modelvault/
chown -R modelvault:modelvault /opt/modelvault
chmod +x /opt/modelvault/*.sh
chmod +x /opt/modelvault/src/*.sh
chmod +x /opt/modelvault/utils/*.sh
echo -e "${GREEN}✓${NC}"

# 3. Install systemd service
echo -n "Installing systemd service... "
cp /opt/modelvault/systemd/modelvault.service /etc/systemd/system/
systemctl daemon-reload
echo -e "${GREEN}✓${NC}"

# 4. Create log directory with proper permissions
echo -n "Setting up logging... "
mkdir -p /var/log/modelvault
chown modelvault:modelvault /var/log/modelvault
echo -e "${GREEN}✓${NC}"

# 5. Enable service (but don't start)
echo -n "Enabling service... "
systemctl enable modelvault.service
echo -e "${GREEN}✓${NC}"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Service commands:"
echo "  - Start:   sudo systemctl start modelvault"
echo "  - Stop:    sudo systemctl stop modelvault"
echo "  - Status:  sudo systemctl status modelvault"
echo "  - Logs:    sudo journalctl -u modelvault -f"
echo ""
echo "Configuration:"
echo "  - Install path: /opt/modelvault"
echo "  - User: modelvault"
echo "  - Logs: /var/log/modelvault and journald"
echo ""
echo -e "${YELLOW}Note: The service is enabled but not started.${NC}"
echo -e "${YELLOW}Run 'sudo systemctl start modelvault' to start it.${NC}"