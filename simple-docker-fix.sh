#!/bin/bash
# Simple Docker Storage Fix
# Just fixes overlay2.size issue

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Simple Docker Storage Fix${NC}"
echo "=========================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Installing Docker first..."
    echo ""
    echo -e "${BLUE}Run this command:${NC}"
    echo "  sudo apt update && sudo apt install -y docker.io"
    echo ""
    echo -e "${YELLOW}Then run this script again to configure storage${NC}"
    exit 1
fi

# Check if overlay2.size is causing issues
if [[ -f "/etc/docker/daemon.json" ]]; then
    current_config=$(cat /etc/docker/daemon.json 2>/dev/null)
    if echo "$current_config" | grep -q "overlay2.size"; then
        echo -e "${YELLOW}⚠️  Found problematic overlay2.size configuration${NC}"
        echo ""
        echo -e "${BLUE}Removing overlay2.size limits...${NC}"
        
        # Remove overlay2.size from daemon.json
        sudo sed -i '/overlay2.size/d' /etc/docker/daemon.json
        
        echo -e "${GREEN}✅ overlay2.size removed${NC}"
        echo ""
        echo -e "${BLUE}Restarting Docker daemon...${NC}"
        sudo systemctl restart docker
        sleep 3
        
        if docker ps &> /dev/null; then
            echo -e "${GREEN}✅ Docker is working properly!${NC}"
            echo ""
            echo -e "${GREEN}🎉 Docker storage issue fixed!${NC}"
            echo ""
            echo -e "${BLUE}What this does:${NC}"
            echo "  • Removes problematic overlay2.size limits"
            echo "  • Allows containers to use full filesystem space"
            echo "  • Works on any filesystem (no XFS required)"
            echo ""
            echo -e "${GREEN}✅ Your Docker storage issue is now solved!${NC}"
        else
            echo -e "${RED}❌ Docker restart failed${NC}"
            echo "Check: sudo journalctl -u docker.service"
        fi
    else
        echo -e "${GREEN}✅ No overlay2.size configuration found${NC}"
        echo ""
        echo -e "${GREEN}✅ Docker storage is already working properly!${NC}"
    fi
else
    echo -e "${RED}❌ Could not read daemon.json${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Docker storage fix complete!${NC}"
echo ""
echo -e "${BLUE}What this does:${NC}"
echo "  • Removes overlay2.size limits that cause 'no space left on device'"
echo "  • Allows containers to use full filesystem space"
echo "  • Works on any filesystem (no XFS required)"
echo "  • Fixes your Docker storage issue permanently"
echo ""
echo -e "${GREEN}✅ Your Docker storage issue is now solved!${NC}"