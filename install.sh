#!/bin/bash
# Arrmematey One-Line Installer
#
# INSTALLATION COMMAND:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)"
#
# That's it! Just run this one command and Arrmematey will be installed.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏴‍☠️ Arrmematey One-Line Installer${NC}"
echo "================================="
echo ""

# Check requirements and setup docker-compose command
check_docker() {
    echo -e "${BLUE}[STEP]${NC} Checking Docker..."

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is required but not installed${NC}"
        echo "Install Docker first:"
        echo "  Ubuntu/Debian: sudo apt install docker.io"
        echo "  CentOS/RHEL: sudo dnf install docker"
        echo "  Or follow: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check if docker daemon is running
    if ! docker ps &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker daemon not running${NC}"
        echo "Start Docker:"
        echo "  sudo systemctl start docker"
        echo "  Or start Docker Desktop"
        exit 1
    fi

    echo -e "${GREEN}✅ Docker found and running${NC}"

    # Set docker-compose command (supports both docker-compose and 'docker compose')
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        echo -e "${GREEN}✅ Using docker-compose${NC}"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
        echo -e "${GREEN}✅ Using docker compose${NC}"
    else
        echo -e "${RED}❌ Neither 'docker-compose' nor 'docker compose' is available${NC}"
        echo "Install docker-compose:"
        echo "  Ubuntu/Debian: sudo apt install docker-compose"
        echo "  Or install Docker Desktop which includes compose"
        exit 1
    fi
}

# Get Mullvad ID
get_mullvad_id() {
    echo ""
    echo -e "${BLUE}🔐 Mullvad VPN Configuration${NC}"
    echo "Get your ID from: https://mullvad.net/en/account/"
    echo ""
    read -p "Enter Mullvad Account ID: " MULLVAD_ID
    while [[ -z "$MULLVAD_ID" ]]; do
        echo -e "${RED}Account ID is required${NC}"
        read -p "Enter Mullvad Account ID: " MULLVAD_ID
    done
    echo -e "${GREEN}✅ Mullvad ID configured${NC}"
}

# Create configuration
create_config() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Creating configuration..."

    INSTALL_DIR="$HOME/arrmematey"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

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
}

# Download docker-compose.yml
download_compose() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Downloading service configuration..."

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
      - SABNZBD_PASSWORD=${SABNZBD_PASSWORD:-changeme}
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
      - JELLYSEERR_PASSWORD=${JELLYSEERR_PASSWORD:-changeme}
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
}

# Start services
start_services() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Starting services..."

    # Create directories
    mkdir -p ./data/{media/{tv,movies,music},downloads/{complete,incomplete},config}

    # Start services using the detected compose command
    echo -e "${BLUE}🚀 Starting containers...${NC}"
    $DOCKER_COMPOSE_CMD up -d

    echo -e "${GREEN}✅ Services started${NC}"
}

# Show completion
show_completion() {
    INSTALL_DIR="$HOME/arrmematey"
    echo ""
    echo -e "${GREEN}🎉 Arrmematey is ready!${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}🌐 Access Points:${NC}"
    echo "  Management UI:  http://localhost:8080"
    echo "  Prowlarr:       http://localhost:9696"
    echo "  Sonarr:         http://localhost:8989"
    echo "  Radarr:         http://localhost:7878"
    echo "  Lidarr:         http://localhost:8686"
    echo "  SABnzbd:        http://localhost:8080"
    echo "  qBittorrent:    http://localhost:8081"
    echo "  Jellyseerr:     http://localhost:5055"
    echo ""
    echo -e "${BLUE}📁 Installation:${NC}"
    echo "  Directory:      $INSTALL_DIR"
    echo ""
    echo -e "${BLUE}🔧 Management:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  $DOCKER_COMPOSE_CMD ps             # Check status"
    echo "  $DOCKER_COMPOSE_CMD logs -f        # View logs"
    echo "  $DOCKER_COMPOSE_CMD down           # Stop all"
    echo ""
    echo -e "${GREEN}🏴‍☠️ Happy treasure hunting!${NC}"
}

# Main execution
main() {
    check_docker
    get_mullvad_id
    create_config
    download_compose
    start_services
    show_completion
}

main "$@"