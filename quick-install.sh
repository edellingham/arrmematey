#!/bin/bash

# Arrmematey - Simple Container Installation
# One-command setup for container environments

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🏴‍☠️ Arrmematey - Arr... Me Matey!          ║"
    echo "║                Simple Container Installation                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

check_docker() {
    print_step "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is required but not installed${NC}"
        echo "Install Docker first:"
        echo "  Ubuntu/Debian: sudo apt install docker.io docker-compose"
        echo "  CentOS/RHEL: sudo dnf install docker docker-compose"
        echo "  Or follow: https://docs.docker.com/get-docker/"
        exit 1
    fi

    echo -e "${GREEN}✅ Docker found${NC}"

    # Check if docker is running
    if ! docker ps &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker daemon not running${NC}"
        echo "Start Docker service:"
        echo "  sudo systemctl start docker"
        exit 1
    fi
}

get_mullvad_id() {
    echo ""
    echo -e "${BLUE}🔐 Mullvad VPN Configuration${NC}"
    echo "Mullvad account ID is required for privacy protection."
    echo "Get your ID from: https://mullvad.net/en/account/"
    echo ""

    read -p "Enter Mullvad Account ID: " MULLVAD_ID
    while [[ -z "$MULLVAD_ID" ]]; do
        echo -e "${RED}Account ID is required${NC}"
        read -p "Enter Mullvad Account ID: " MULLVAD_ID
    done

    echo -e "${GREEN}✅ Mullvad ID configured${NC}"
}

create_simple_env() {
    print_step "Creating simple configuration..."

    cat > .env << EOF
# Arrmematey - Simple Container Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC

# VPN Configuration
MULLVAD_ACCOUNT_ID=$MULLVAD_ID
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# Docker volume paths (inside container)
MEDIA_PATH=/data/media
DOWNLOADS_PATH=/data/downloads
CONFIG_PATH=/data/config

# Management UI
MANAGEMENT_UI_PORT=8787

# Default service ports
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055
EMBY_PORT=8096

# Service passwords (auto-generated)
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

# Cloudflare tunnel (optional)
# CLOUDFLARE_TOKEN=
# CLOUDFLARE_TUNNEL_NAME=arrstack
# CLOUDFLARE_DOMAIN=
EOF

    echo -e "${GREEN}✅ Configuration created${NC}"
}

start_services() {
    print_step "Starting Arrmematey services..."

    # Create necessary directories
    mkdir -p ./data/{media/{tv,movies,music},downloads/{complete,incomplete},config}

    # Start services with Docker Compose
    echo -e "${BLUE}🚀 Starting containers...${NC}"
    docker-compose --profile full up -d

    echo -e "${GREEN}✅ Services started${NC}"
    echo ""
    echo -e "${BLUE}📊 Service Status:${NC}"
    docker-compose ps
}

show_completion() {
    echo ""
    echo -e "${GREEN}🎉 Arrmematey is ready!${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}🌐 Access Points:${NC}"
    echo "  Management UI: http://localhost:8080"
    echo "  Prowlarr:      http://localhost:9696"
    echo "  Sonarr:        http://localhost:8989"
    echo "  Radarr:        http://localhost:7878"
    echo "  Lidarr:        http://localhost:8686"
    echo "  SABnzbd:       http://localhost:8080"
    echo "  qBittorrent:   http://localhost:8081"
    echo "  Jellyseerr:    http://localhost:5055"
    echo ""
    echo -e "${BLUE}📁 Data Locations:${NC}"
    echo "  Media:         ./data/media"
    echo "  Downloads:     ./data/downloads"
    echo "  Config:        ./data/config"
    echo ""
    echo -e "${BLUE}🔧 Management Commands:${NC}"
    echo "  View status:   docker-compose ps"
    echo "  View logs:     docker-compose logs -f [service]"
    echo "  Stop all:      docker-compose down"
    echo "  Restart:       docker-compose restart"
    echo ""
    echo -e "${YELLOW}⚠️  Next Steps:${NC}"
    echo "1. Configure your media paths in ./data/media"
    echo "2. Set up indexers in Prowlarr (localhost:9696)"
    echo "3. Configure downloaders (SABnzbd/qBittorrent)"
    echo "4. Add your media libraries in Sonarr/Radarr/Lidarr"
    echo ""
    echo -e "${GREEN}🏴‍☠️ Happy treasure hunting!${NC}"
}

main() {
    print_banner

    check_docker
    get_mullvad_id
    create_simple_env
    start_services
    show_completion
}

main "$@"