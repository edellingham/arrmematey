#!/bin/bash
# Simple Docker Storage Size Fix
# For users who just installed Docker and need to increase container writable layer size

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Docker Storage Size Fix${NC}"
echo "=========================="
echo ""

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Install Docker first:"
    echo "  sudo apt update"
    echo "  sudo apt install docker.io"
    echo "  sudo systemctl start docker"
    echo "  sudo systemctl enable docker"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    echo "Start Docker:"
    echo "  sudo systemctl start docker"
    exit 1
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
        echo ""
        read -p "Enter new size limit (e.g., 20G) or press Enter to keep current: " new_size
        
        if [[ -n "$new_size" ]]; then
            echo -e "${BLUE}🔧 Updating overlay2.size to ${new_size}${NC}"
            echo ""
            echo -e "${RED}⚠️  This will restart Docker daemon${NC}"
            read -p "Continue? (yes/NO): " confirm
            
            if [[ "$confirm" == "yes" ]]; then
                # Backup current config
                sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d-%H%M%S)
                
                # Update daemon.json with new size
                sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.size=${new_size}"
  ]
}
EOF
                
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✅ Configuration updated successfully${NC}"
                    echo ""
                    echo -e "${YELLOW}Restarting Docker daemon...${NC}"
                    sudo systemctl restart docker
                    sleep 5
                    
                    if docker ps &> /dev/null; then
                        echo -e "${GREEN}✅ Docker restarted successfully!${NC}"
                        echo -e "${GREEN}✅ New container writable layer limit: ${new_size}${NC}"
                        echo ""
                        echo -e "${BLUE}To apply changes to existing containers, restart them:${NC}"
                        echo "  docker restart <container-name>"
                        echo ""
                        echo -e "${GREEN}✅ Docker storage size fix complete!${NC}"
                    else
                        echo -e "${RED}❌ Docker restart failed${NC}"
                        echo "Restoring backup..."
                        sudo cp /etc/docker/daemon.json.backup.$(date +%Y%m%d-%H%M%S) /etc/docker/daemon.json
                        sudo systemctl restart docker
                        echo "🔄 Docker restored to previous configuration"
                    fi
                else
                    echo -e "${RED}❌ Failed to update configuration${NC}"
                fi
        else
            echo -e "${GREEN}✅ Keeping current configuration${NC}"
        fi
    else
        echo -e "${BLUE}No overlay2.size configuration found${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Setting default 20GB limit for containers${NC}"
        echo ""
        echo -e "${RED}⚠️  This will restart Docker daemon${NC}"
        read -p "Continue? (yes/NO): " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            # Create daemon.json with 20GB limit
            sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.size=20G"
  ]
}
EOF
            
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✅ Configuration created successfully${NC}"
                echo ""
                echo -e "${YELLOW}Restarting Docker daemon...${NC}"
                sudo systemctl restart docker
                sleep 5
                
                if docker ps &> /dev/null; then
                    echo -e "${GREEN}✅ Docker restarted successfully!${NC}"
                    echo -e "${GREEN}✅ Container writable layer limit set to 20GB${NC}"
                    echo ""
                    echo -e "${GREEN}✅ Docker storage size fix complete!${NC}"
                else
                    echo -e "${RED}❌ Docker restart failed${NC}"
                    echo "Check logs: sudo journalctl -u docker.service"
                fi
            else
                echo -e "${RED}❌ Failed to create configuration${NC}"
            fi
    fi
else
    echo -e "${RED}❌ Could not read Docker configuration${NC}"
    echo "Docker may not be running properly"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Docker storage size fix complete!${NC}"
echo ""
echo -e "${BLUE}What this does:${NC}"
echo "  • Sets a 20GB writable layer limit for each container"
echo "  • Prevents 'no space left on device' errors during container operations"
echo "  • Works with any filesystem (no XFS required)"
echo "  • Existing containers will need restart to apply new limits"
echo ""
echo -e "${BLUE}To verify the fix:${NC}"
echo "  docker info  # Should show overlay2.size in storage-opts"
echo "  docker run --rm -it ubuntu bash  # Test container creation"
echo ""
echo -e "${GREEN}✅ Your Docker storage is now properly configured!${NC}"