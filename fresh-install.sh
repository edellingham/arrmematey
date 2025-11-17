#!/bin/bash
# Arrmematey Fresh Install Script
# For fresh Debian 13 systems - installs Docker and Arrmematey stack

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏴‍☠️ Arrmematey Fresh Install${NC}"
echo "================================="
echo ""

echo -e "${BLUE}This script will:${NC}"
echo "  • Install Docker and dependencies"
echo "  • Install complete Arrmematey stack"
echo "  • Configure Docker storage properly"
echo "  • Start all services automatically"
echo ""
echo -e "${YELLOW}Requirements:${NC}"
echo "  • Internet connection"
echo "  • Sudo access (for system packages)"
echo ""
read -p "Continue with fresh installation? (yes/NO): " continue_install

if [[ "$continue_install" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}[STEP 1/4]${NC} Updating system packages..."
if sudo apt update; then
    echo -e "${GREEN}✅ System updated${NC}"
else
    echo -e "${YELLOW}⚠️  System update failed (continuing...)${NC}"
fi

echo ""
echo -e "${BLUE}[STEP 2/4]${NC} Installing Docker and dependencies..."
# Install Docker and essential packages
DEBIAN_FRONTEND=noninteractive sudo apt install -y docker.io docker-compose curl wget gnupg2 ca-certificates

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Docker and dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[STEP 3/4]${NC} Installing XFS tools for Docker storage..."
# Install XFS tools for overlay2.size support
sudo apt install -y xfsprogs

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ XFS tools installed${NC}"
else
    echo -e "${YELLOW}⚠️  XFS tools failed (continuing without overlay2.size limits)${NC}"
fi

echo ""
echo -e "${BLUE}[STEP 4/4]${NC} Creating installation directory..."
INSTALL_DIR="$HOME/arrmematey"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ""
echo -e "${BLUE}[STEP 5/4]${NC} Creating configuration..."
# Create optimal Docker daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Docker daemon configured${NC}"
else
    echo -e "${RED}❌ Failed to configure Docker${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[STEP 6/4]${NC} Creating environment file..."
# Create environment file
cat > .env << EOF
# Arrmematey Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC

# Mullvad VPN Configuration (REQUIRED)
MULLVAD_USER=your_mullvad_id_here
MULLVAD_ACCOUNT_ID=your_mullvad_id_here
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# VPN Type: openvpn (simpler) or wireguard (faster, needs private key)
VPN_TYPE=openvpn

# Docker volume paths
MEDIA_PATH=/data/media
DOWNLOADS_PATH=/data/downloads
CONFIG_PATH=/data/config

# Management UI
MANAGEMENT_UI_PORT=8787

# Service ports
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055
EMBY_PORT=8096

# Service Passwords (change these!)
SABNZBD_PASSWORD=arrmematey_secure
JELLYSEERR_PASSWORD=arrmematey_secure

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

echo ""
echo -e "${BLUE}[STEP 7/4]${NC} Downloading docker-compose.yml..."
# Download docker-compose.yml
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
      - MULLVAD_USER=${MULLVAD_ACCOUNT_ID}
      - SERVER_Countries=${MULLVAD_COUNTRY:-us}
      - SERVER_Cities=${MULLVAD_CITY:-ny}
      - TZ=${TZ:-UTC}
      - FIREWALL=on
      - FIREWALL_VPN_INPUT_PORTS=${SONARR_PORT:-8989},${RADARR_PORT:-7878},${LIDARR_PORT:-8686},${SABNZBD_PORT:-8080},${QBITTORRENT_PORT:-8081}
      - DNS_ADDRESS=1.1.1.1
      - AUTOCONNECT=true
      - KILLSWITCH=true
    volumes:
      - gluetun-config:/config
    ports:
      - ${SONARR_PORT:-8989}:8989
      - ${RADARR_PORT:-7878}:7878
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

  emby:
    image: linuxserver/emby:latest
    container_name: emby
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - emby-config:/config
      - sonarr-media:/data/media/series:ro
      - radarr-media:/data/media/movies:ro
      - lidarr-media:/data/media/music:ro
    ports:
      - ${EMBY_PORT:-8096}:8096
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
  emby-config:
  sonarr-media:
  radarr-media:
  lidarr-media:
  downloads:
EOF

echo -e "${GREEN}✅ Docker Compose configuration downloaded${NC}"

echo ""
echo -e "${BLUE}[STEP 8/4]${NC} Creating data directories..."
mkdir -p ./data/{media/{tv,movies,music},downloads/{complete,incomplete},config}

echo -e "${GREEN}✅ Data directories created${NC}"

echo ""
echo -e "${BLUE}[STEP 9/4]${NC} Starting Arrmematey services..."
docker compose up -d

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