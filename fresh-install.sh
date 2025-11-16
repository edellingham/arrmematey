#!/bin/bash
# Arrmematey Fresh Install Script
# For fresh Debian 13 systems - installs Docker, dependencies, and Arrmematey stack

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🏴‍☠️ Arrmematey Fresh Install${NC}"
echo "================================="
echo ""
echo -e "${BLUE}This script will:${NC}"
echo "  • Install Docker and dependencies"
echo "  • Install Arrmematey media automation stack"
echo "  • Configure Docker storage for optimal performance"
echo "  • Start all services automatically"
echo ""
echo -e "${YELLOW}Requirements:${NC}"
echo "  • Fresh Debian 13 system"
echo "  • Internet connection"
echo "  • Sudo access (for system packages)"
echo ""
echo -e "${RED}⚠️  This will install Docker and configure storage${NC}"
echo ""
read -p "Continue with fresh installation? (yes/NO): " continue_install

if [[ "$continue_install" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Starting Installation...${NC}"

# Step 1: Update system and install dependencies
echo ""
echo -e "${BLUE}[STEP 1/4]${NC} Updating system packages..."
if sudo apt update; then
    echo -e "${GREEN}✅ System updated${NC}"
else
    echo -e "${RED}❌ System update failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[STEP 2/4]${NC} Installing Docker and dependencies..."
if sudo apt install -y docker.io docker-compose curl wget gnupg2 ca-certificates; then
    echo -e "${GREEN}✅ Docker and dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

# Step 2.5: Install XFS tools for overlay2.size support
echo ""
echo -e "${BLUE}[STEP 2.5/4]${NC} Installing XFS tools for Docker storage limits..."
if sudo apt install -y xfsprogs; then
    echo -e "${GREEN}✅ XFS tools installed${NC}"
else
    echo -e "${YELLOW}⚠️  XFS tools failed, but continuing...${NC}"
fi

# Step 3: Configure Docker storage
echo ""
echo -e "${BLUE}[STEP 3/4]${NC} Configuring Docker storage for optimal performance..."

# Check if Docker is already configured with problematic overlay2.size
if [[ -f "/etc/docker/daemon.json" ]]; then
    current_config=$(cat /etc/docker/daemon.json 2>/dev/null)
    if echo "$current_config" | grep -q "overlay2.size"; then
        echo -e "${YELLOW}⚠️  Found problematic overlay2.size configuration${NC}"
        echo -e "${BLUE}Removing overlay2.size limits...${NC}"
        
        # Remove overlay2.size from daemon.json
        sudo sed -i '/overlay2.size/d' /etc/docker/daemon.json
        
        echo -e "${GREEN}✅ Removed overlay2.size limits${NC}"
        echo -e "${BLUE}Docker will use default behavior (no size limits)${NC}"
    else
        echo -e "${GREEN}✅ Docker configuration is clean${NC}"
fi

# Create optimal daemon.json configuration
echo ""
echo -e "${BLUE}Creating optimal Docker daemon configuration...${NC}"
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Docker daemon configured successfully${NC}"
else
    echo -e "${RED}❌ Failed to configure Docker daemon${NC}"
    exit 1
fi

# Step 4: Start Docker
echo ""
echo -e "${BLUE}[STEP 4/4]${NC} Starting Docker daemon..."
if sudo systemctl start docker; then
    echo -e "${GREEN}✅ Docker started successfully${NC}"
else
    echo -e "${RED}❌ Failed to start Docker${NC}"
    exit 1
fi

# Step 5: Verify Docker is working
echo ""
echo -e "${BLUE}[STEP 5/4]${NC} Verifying Docker installation..."
sleep 3

if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker is running properly!${NC}"
else
    echo -e "${RED}❌ Docker failed to start${NC}"
    exit 1
fi

# Step 6: Get Mullvad ID
echo ""
echo -e "${BLUE}[STEP 6/4]${NC} Getting Mullvad VPN configuration..."
echo ""
echo -e "${BLUE}Get your ID from: https://mullvad.net/en/account/${NC}"
echo ""
read -p "Enter Mullvad Account ID: " MULLVAD_ID
while [[ -z "$MULLVAD_ID" ]]; do
    echo -e "${RED}Account ID is required${NC}"
    read -p "Enter Mullvad Account ID: " MULLVAD_ID
done
echo -e "${GREEN}✅ Mullvad ID configured${NC}"

# Step 7: Create Arrmematey installation directory
echo ""
echo -e "${BLUE}[STEP 7/4]${NC} Creating installation directory..."
INSTALL_DIR="$HOME/arrmematey"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Step 8: Create configuration
echo ""
echo -e "${BLUE}[STEP 8/4]${NC} Creating configuration..."
cat > .env << EOF
# Arrmematey Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC

# VPN Configuration
MULLVAD_ACCOUNT_ID=$MULLVAD_ID
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# Docker volume paths
MEDIA_PATH=/data/media
DOWNLOADS_PATH=/data/downloads
CONFIG_PATH=/data/config

# Management UI
MANAGEMENT_UI_PORT=8080

# Service ports
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055

# Service passwords
SABNZBD_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
JELLYSEERR_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

# Quality profile
QUALITY_PROFILE=standard

# Enable services
ENABLE_PROWLARR=true
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_LIDARR=true
ENABLE_SABNZBD=true
ENABLE_QBITTORRENT=true
ENABLE_JELLYSEERR=true
ENABLE_EMBY=true
ENABLE_CLOUDFLARE_TUNNEL=false
EOF

echo -e "${GREEN}✅ Configuration created${NC}"

# Step 9: Download docker-compose.yml
echo ""
echo -e "${BLUE}[STEP 9/4]${NC} Downloading service configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add: [NET_ADMIN]
    environment:
      - VPN_SERVICE_PROVIDER=mullvad
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${MULLVAD_ACCOUNT_ID}
      - SERVER_Countries=${MULLVAD_COUNTRY:-us}
      - SERVER_Cities=${MULLVAD_CITY:-ny}
      - TZ=${TZ:-UTC}
      - FIREWALL=on
      - FIREWALL_VPN_INPUT_PORTS=${SONARR_PORT:-8989},${RADARR_PORT:-7878},${LIDARR_PORT:-8686},${SABNZBD_PORT:-8080},${QBITTORRENT_PORT:-8081}
      - DNS_PLAINTEXT_ADDRESS=1.1.1.1,1.0.0.1
      - AUTOCONNECT=true
      - KILLSWITCH=true
    volumes:
      - gluetun-config:/config
    ports:
      - ${SONARR_PORT:-8989}:8989
      - ${RADARR_PORT:-7878}:7878
      - ${LIDARR_PORT:-8686}:8686
      - ${LIDARR_PORT:-8686}:8686
      - ${SABNZBD_PORT:-8080}:8080
      - ${QBITTORRENT_PORT:-8081}:8081
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://ifconfig.me"]
      interval: 30s
      timeout: 10s
      retries: 3

  prowlarr:
    image: linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - prowlarr-config:/config
    network_mode: "service:gluetun"
    depends_on:
      gluetun:
        condition: service_healthy
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - sonarr-config:/config
      - sonarr-media:/tv
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - radarr-config:/config
      - radarr-media:/movies
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  lidarr:
    image: linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - lidarr-config:/config
      - lidarr-media:/music
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - SABNZBD_USERNAME=arrmematey
      - SABNZBD_PASSWORD=${SABNZBD_PASSWORD}
    volumes:
      - sabnzbd-config:/config
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - WEBUI_PORT=8081
    volumes:
      - qbittorrent-config:/config
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - PORT=5055
      - JELLYSEERR_PASSWORD=${JELLYSEERR_PASSWORD}
    volumes:
      - jellyseerr-config:/app/config
    ports:
      - ${JELLYSEERR_PORT:-5055}:5055
    restart: unless-stopped

volumes:
  gluetun-config:
  prowlarr-config:
  sonarr-config:
  radarr-config:
  lidarr-config:
  sabnzbd-config:
  qbittorrent-config:
  jellyseerr-config:
  sonarr-media:
  radarr-media:
  lidarr-media:
  downloads:
EOF

echo -e "${GREEN}✅ Service configuration downloaded${NC}"

# Step 10: Create data directories
echo ""
echo -e "${BLUE}[STEP 10/4]${NC} Creating data directories..."
mkdir -p ./data/{media/{tv,movies,music},downloads/{complete,incomplete},config}

echo -e "${GREEN}✅ Data directories created${NC}"

# Step 11: Start services
echo ""
echo -e "${BLUE}[STEP 11/4]${NC} Starting Arrmematey services..."
docker-compose up -d

echo ""
echo -e "${GREEN}🎉 Arrmematey Installation Complete!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo "  Management UI:  http://localhost:${MANAGEMENT_UI_PORT:-8080}"
echo "  Prowlarr:       http://localhost:${PROWLARR_PORT:-9696}"
echo "  Sonarr:         http://localhost:${SONARR_PORT:-8989}"
echo "  Radarr:         http://localhost:${RADARR_PORT:-7878}"
echo "  Lidarr:         http://localhost:${LIDARR_PORT:-8686}"
echo "  SABnzbd:        http://localhost:${SABNZBD_PORT:-8080}"
echo "  qBittorrent:    http://localhost:${QBITTORRENT_PORT:-8081}"
echo "  Jellyseerr:     http://localhost:${JELLYSEERR_PORT:-5055}"
echo ""
echo -e "${BLUE}📁 Installation Directory:${NC}"
echo "  $INSTALL_DIR"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo "  cd $INSTALL_DIR"
echo "  docker-compose ps              # Check status"
echo "  docker-compose logs -f         # View logs"
echo "  docker-compose restart         # Restart services"
echo "  docker-compose down           # Stop all"
echo ""
echo -e "${GREEN}🏴‍☠️ Happy treasure hunting!${NC}"