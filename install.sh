#!/bin/bash
# Arrmematey One-Line Installer with Cleanup Options
#
# MAIN COMMAND:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)"
#
# This script includes a menu with:
# 1. Install - Normal Arrmematey installation
# 2. Clean Up - Remove Docker containers and unused images
# 3. Nuclear Clean Up - Aggressive Docker/containerd cleanup

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==========================================
# INSTALLATION FUNCTIONS (Moved to top)
# ==========================================

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

# ==========================================
# CLEANUP FUNCTIONS
# ==========================================

# Regular cleanup function
cleanup_docker() {
    echo -e "${BLUE}🧹 Docker Cleanup${NC}"
    echo "=================="
    echo ""

    # Stop and remove containers
    echo "🛑 Stopping containers..."
    docker ps -aq 2>/dev/null | xargs -r docker stop 2>/dev/null || echo "No containers to stop"
    docker ps -aq 2>/dev/null | xargs -r docker rm -f 2>/dev/null || echo "No containers to remove"

    # Clean system
    echo "🧽 Cleaning Docker system..."
    docker system prune -f 2>/dev/null || echo "System prune failed"
    docker image prune -f 2>/dev/null || echo "Image prune failed"
    docker volume prune -f 2>/dev/null || echo "Volume prune failed"
    docker network prune -f 2>/dev/null || echo "Network prune failed"

    # Clean specific directories
    echo "🧽 Cleaning Docker directories..."
    sudo rm -rf /var/lib/docker-tmp 2>/dev/null || true
    sudo rm -rf /tmp/docker-* 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✅ Docker cleanup complete!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Nuclear cleanup function
nuclear_cleanup() {
    echo -e "${RED}💥 Nuclear Docker Cleanup${NC}"
    echo "=========================="
    echo ""
    echo -e "${RED}WARNING: This will remove ALL Docker data!${NC}"
    read -p "Are you sure? Type 'yes' to continue: " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    echo ""
    echo "🛑 Stopping services..."
    sudo systemctl stop docker containerd 2>/dev/null || true

    echo "🔥 Killing processes..."
    sudo pkill -9 -f docker 2>/dev/null || true
    sudo pkill -9 -f containerd 2>/dev/null || true

    echo "🗑️ Removing ALL Docker data..."
    sudo rm -rf /var/lib/docker* 2>/dev/null || true
    sudo rm -rf /var/lib/containerd* 2>/dev/null || true
    sudo rm -rf /run/docker* 2>/dev/null || true
    sudo rm -rf /run/containerd* 2>/dev/null || true
    sudo rm -f /var/run/docker.sock /run/docker.sock 2>/dev/null || true

    echo "🧽 Cleaning configuration..."
    sudo rm -rf ~/.docker 2>/dev/null || true

    echo "🚀 Restarting services..."
    sudo systemctl start containerd 2>/dev/null || true
    sudo systemctl start docker 2>/dev/null || true

    sleep 5

    echo "🔍 Testing Docker..."
    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker restarted successfully!${NC}"
    else
        echo -e "${RED}❌ Docker restart failed. You may need to reinstall Docker.${NC}"
    fi

    echo ""
    echo -e "${GREEN}✅ Nuclear cleanup complete!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# ==========================================
# MENU SYSTEM
# ==========================================

# Main menu
show_menu() {
    echo -e "${BLUE}🏴‍☠️ Arrmematey - Choose Your Action${NC}"
    echo "===================================="
    echo ""
    echo -e "${CYAN}1) 🚀 Install Arrmematey${NC}"
    echo "   Complete media automation stack installation"
    echo ""
    echo -e "${YELLOW}2) 🧹 Clean Up Docker${NC}"
    echo "   Remove containers, unused images, and volumes"
    echo ""
    echo -e "${RED}3) 💥 Nuclear Clean Up${NC}"
    echo "   Aggressive cleanup - fixes severe Docker issues"
    echo ""
    echo -e "${GREEN}4) ℹ️  Help${NC}"
    echo "   Show detailed information about each option"
    echo ""
    read -p "Select an option (1-4): " choice
}

# Help function
show_help() {
    echo ""
    echo -e "${BLUE}📖 Detailed Help${NC}"
    echo "================="
    echo ""
    echo -e "${CYAN}🚀 Option 1 - Install Arrmematey${NC}"
    echo "  • Installs complete media automation stack"
    echo "  • Includes Prowlarr, Sonarr, Radarr, Lidarr, SABnzbd, qBittorrent, Jellyseerr"
    echo "  • Sets up Mullvad VPN protection"
    echo "  • Creates management UI"
    echo "  • Requires: Docker, curl, Mullvad account"
    echo ""
    echo -e "${YELLOW}🧹 Option 2 - Clean Up Docker${NC}"
    echo "  • Removes all Docker containers"
    echo "  • Prunes unused images and volumes"
    echo "  • Cleans system cache"
    echo "  • Use when: Installation fails or Docker is cluttered"
    echo ""
    echo -e "${RED}💥 Option 3 - Nuclear Clean Up${NC}"
    echo "  • Complete Docker/containerd rebuild"
    echo "  • Removes ALL Docker data and configuration"
    echo "  • Kills hanging processes"
    echo "  • Use when: Severe Docker issues or containerd errors"
    echo ""
    echo -e "${GREEN}ℹ️  Option 4 - Help (this page)${NC}"
    echo "  • Shows detailed information"
    echo ""
    echo "Press Enter to return to menu..."
    read
}

# ==========================================
# MAIN EXECUTION
# ==========================================

echo -e "${BLUE}🏴‍☠️ Arrmematey One-Line Installer${NC}"
echo "================================="
echo ""

# Main menu loop
while true; do
    show_menu

    case $choice in
        1)
            echo ""
            echo -e "${GREEN}🚀 Starting Arrmematey Installation...${NC}"
            echo ""
            # Run the original installation process
            check_docker
            get_mullvad_id
            create_config
            download_compose
            start_services
            show_completion
            break
            ;;
        2)
            cleanup_docker
            ;;
        3)
            nuclear_cleanup
            ;;
        4)
            show_help
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-4.${NC}"
            sleep 2
            ;;
    esac
    echo ""
done