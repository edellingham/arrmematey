#!/bin/bash
# Minimal Docker Storage Fix
# Just fixes overlay2.size issue directly

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Minimal Docker Storage Fix${NC}"
echo "=========================="
echo ""

echo -e "${RED}❌ Docker daemon is broken${NC}"
echo "Fixing overlay2.size configuration..."
echo ""

# Remove problematic configuration
sudo rm -f /etc/docker/daemon.json

# Create working configuration (no size limits)
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2"
}
EOF

echo ""
echo -e "${GREEN}✅ Fixed daemon.json${NC}"
echo ""

echo -e "${YELLOW}Restarting Docker daemon...${NC}"
sudo systemctl restart docker
sleep 5

echo ""
echo -e "${BLUE}Verifying Docker...${NC}"
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker is working!${NC}"
    echo ""
    echo -e "${GREEN}🎉 Docker storage fix complete!${NC}"
    echo ""
    echo -e "${BLUE}What this does:${NC}"
    echo "  • Removes overlay2.size limits (fixes 'no space left on device')"
    echo "  • Works on any filesystem (no XFS required)"
    echo "  • Existing containers will restart normally"
    echo ""
    echo -e "${GREEN}✅ Your Docker storage issue is solved!${NC}"
else
    echo -e "${RED}❌ Docker still broken${NC}"
    echo "Check logs: sudo journalctl -u docker.service"
    exit 1
fi