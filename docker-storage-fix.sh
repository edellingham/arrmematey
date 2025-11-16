#!/bin/bash
# Quick Docker Storage Fix
# For users who just need to increase container writable layer size

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Quick Docker Storage Fix${NC}"
echo "=========================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Install Docker first:"
    echo "  sudo apt update"
    echo "  sudo apt install docker.io"
    echo "  sudo systemctl start docker"
    echo "  sudo systemctl enable docker"
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    echo "Starting Docker daemon..."
    sudo systemctl start docker
    sleep 3
    
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✅ Docker daemon started${NC}"
    else
        echo -e "${RED}❌ Failed to start Docker daemon${NC}"
        echo "Check: sudo systemctl status docker"
        exit 1
    fi
fi

# Show current Docker storage configuration
echo -e "${BLUE}Current Docker Storage Configuration:${NC}"
docker_info=$(docker info 2>/dev/null)
storage_driver=$(echo "$docker_info" | grep "Storage Driver:" | awk '{print $3}')
backing_fs=$(echo "$docker_info" | grep "Backing Filesystem:" | awk '{print $3}')

echo "  Storage Driver: $storage_driver"
echo "  Backing Filesystem: ${backing_fs:-unknown}"
echo ""

# Check if overlay2.size is already configured
if [[ -f "/etc/docker/daemon.json" ]]; then
    current_config=$(cat /etc/docker/daemon.json 2>/dev/null)
    if echo "$current_config" | grep -q "overlay2.size"; then
        current_size=$(echo "$current_config" | grep -o "overlay2.size=" | sed 's/.*overlay2.size="//g' | sed 's/".*//g')
        echo -e "${YELLOW}⚠️  overlay2.size already configured: ${current_size}${NC}"
        echo -e "${BLUE}Current container writable layer limit: ${current_size}${NC}"
    else
        echo -e "${BLUE}No overlay2.size configuration found${NC}"
    fi
else
    echo -e "${BLUE}No daemon.json file found${NC}"
fi

echo ""
echo -e "${YELLOW}Setting 20GB container writable layer limit...${NC}"

# Create or update daemon.json with 20GB limit
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.size=20G"
  ]
}
EOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Configuration updated successfully${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Docker daemon must be restarted for changes to take effect${NC}"
    echo ""
    read -p "Restart Docker daemon now? (yes/NO): " restart_choice
    
    if [[ "$restart_choice" == "yes" ]]; then
        echo -e "${BLUE}🔄 Restarting Docker daemon...${NC}"
        sudo systemctl restart docker
        sleep 5
        
        if docker ps &> /dev/null; then
            echo -e "${GREEN}✅ Docker daemon restarted successfully!${NC}"
            echo -e "${GREEN}✅ Container writable layer limit set to 20GB${NC}"
            echo ""
            echo -e "${BLUE}What this does:${NC}"
            echo "  • Sets 20GB writable layer limit for each container"
            echo "  • Prevents 'no space left on device' errors"
            echo "  • Works on any filesystem (no XFS required)"
            echo "  • Existing containers will need restart to apply new limits"
            echo ""
            echo -e "${GREEN}✅ Docker storage size fix complete!${NC}"
        else
            echo -e "${RED}❌ Docker daemon restart failed${NC}"
            echo "Check: sudo systemctl status docker"
            echo "Check logs: sudo journalctl -u docker.service"
        fi
    else
        echo -e "${RED}❌ Failed to update configuration${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Failed to create daemon.json${NC}"
    exit 1
fi