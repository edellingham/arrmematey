#!/bin/bash

# Quick Install Script - One command setup
# For users who want a quick installation with sensible defaults

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Arrmematey - Arr... Me Matey!          ║"
    echo "║                🎬 🎥 🎵 📥 ⬇️ 🍿 🏴‍☠️                       ║"
    echo "║                                                              ║"
    echo "║     🏴‍☠️ Arrmematey: Arr... me matey!                   ║"
    echo "║     Your trusty pirate crew for media treasure!         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_warning "This script should not be run as root for security reasons."
        exit 1
    fi
    
    # Check for required commands
    local missing_commands=()
    
    for cmd in curl docker; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_warning "Missing commands: ${missing_commands[*]}"
        print_info "Installing missing dependencies..."
        
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y curl docker.io docker-compose
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y curl docker docker-compose
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl docker docker-compose
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm curl docker docker-compose
        else
            print_warning "Please install curl and docker manually, then run this script again."
            exit 1
        fi
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        print_warning "You may need to log out and log back in to use Docker without sudo."
    fi
}

quick_config() {
    print_step "Quick configuration with sensible defaults..."
    
    # Get basic info
    echo ""
    print_info "Let's configure the basics. Press Enter to use defaults."
    
    # Mullvad is required for privacy
    echo ""
    read -p "🔐 Mullvad Account ID (required for VPN): " MULLVAD_ID
    while [[ -z "$MULLVAD_ID" ]]; do
        print_warning "Mullvad account ID is required for privacy protection"
        echo "Get your account ID from: https://mullvad.net/en/account/"
        read -p "Mullvad Account ID: " MULLVAD_ID
    done
    
    # Media server choice
    echo ""
    print_info "Choose your media server:"
    echo "1) Jellyfin (Free & Open Source)"
    echo "2) Emby (Free with premium features)"
    echo "3) Plex (Free with premium features)"
    echo "4) No media server"
    
    read -p "Media server [1-4]: " MEDIA_CHOICE
    MEDIA_CHOICE=${MEDIA_CHOICE:-1}
    
    case $MEDIA_CHOICE in
        1) MEDIA_SERVER="jellyfin" ;;
        2) MEDIA_SERVER="emby" ;;
        3) MEDIA_SERVER="plex" ;;
        4) MEDIA_SERVER="none" ;;
        *) MEDIA_SERVER="jellyfin" ;;
    esac
    
    # Quality profile
    echo ""
    print_info "Choose quality profile:"
    echo "1) Standard (720p/1080p) - Good for most users"
    echo "2) Quality (1080p/4K) - Better quality"
    echo "3) Archive (4K only) - Maximum quality"
    
    read -p "Quality profile [1-3]: " QUALITY_CHOICE
    QUALITY_CHOICE=${QUALITY_CHOICE:-1}
    
    case $QUALITY_CHOICE in
        1) QUALITY_PROFILE="standard" ;;
        2) QUALITY_PROFILE="quality" ;;
        3) QUALITY_PROFILE="archive" ;;
        *) QUALITY_PROFILE="standard" ;;
    esac
    
    # Optional configuration
    echo ""
    read -p "🌐 Cloudflare tunnel token (optional, for remote access): " CF_TOKEN
    if [[ -n "$CF_TOKEN" ]]; then
        read -p "🌐 Domain for Cloudflare tunnel: " CF_DOMAIN
    fi
    
    print_info "Configuration complete!"
}

create_quick_env() {
    print_step "Creating environment configuration..."
    
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    cat > .env << EOF
# Arr Stack Quick Configuration
# Generated on $(date)

# User Configuration
PUID=$USER_ID
PGID=$GROUP_ID
TZ=America/New_York

# VPN Configuration (Required)
MULLVAD_ACCOUNT_ID=$MULLVAD_ID
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# Cloudflare Tunnel (Optional)
CLOUDFLARE_TOKEN=$CF_TOKEN
CLOUDFLARE_TUNNEL_NAME=arrstack
CLOUDFLARE_DOMAIN=$CF_DOMAIN

# Port Configuration
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055
MANAGEMENT_UI_PORT=8080

# Directory Configuration
MEDIA_PATH=\$HOME/Media
DOWNLOADS_PATH=\$HOME/Downloads
CONFIG_PATH=\$HOME/Config

# Security Configuration
SABNZBD_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
JELLYSEERR_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)

# Media Server Configuration
MEDIA_SERVER=$MEDIA_SERVER

# Quality Profile
QUALITY_PROFILE=$QUALITY_PROFILE

# API Keys (auto-populated)
SONARR_API_KEY=
RADARR_API_KEY=
LIDARR_API_KEY=

# Advanced Configuration
MAX_CONCURRENT_DOWNLOADS=3
MIN_DISK_SPACE=10
MAX_DISK_USAGE=90
ENABLE_NOTIFICATIONS=true
EOF
    
    print_info "Environment configuration created"
}

setup_directories() {
    print_step "Creating directories..."
    
    # Create directories
    mkdir -p "$HOME/Media"/{tv,movies,music}
    mkdir -p "$HOME/Downloads"/{incomplete,complete}
    mkdir -p "$HOME/Config"/{sonarr,radarr,lidarr,sabnzbd,qbittorrent,jellyseerr,gluetun,recyclarr}
    
    # Set permissions
    chmod 755 "$HOME/Media" "$HOME/Downloads" "$HOME/Config"
    
    print_info "Directories created"
}

create_quick_compose() {
    print_step "Creating Docker Compose configuration..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Gluetun VPN with Mullvad
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=mullvad
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${MULLVAD_ACCOUNT_ID}
      - SERVER_Countries=${MULLVAD_COUNTRY}
      - SERVER_Cities=${MULLVAD_CITY}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/gluetun:/config
    ports:
      - ${SONARR_PORT:-8989}:8989
      - ${RADARR_PORT:-7878}:7878
      - ${LIDARR_PORT:-8686}:8686
      - ${SABNZBD_PORT:-8080}:8080
      - ${QBITTORRENT_PORT:-8081}:8081
    restart: unless-stopped

  # Sonarr
  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/sonarr:/config
      - ${MEDIA_PATH}/tv:/tv
      - ${DOWNLOADS_PATH}/complete:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  # Radarr
  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/radarr:/config
      - ${MEDIA_PATH}/movies:/movies
      - ${DOWNLOADS_PATH}/complete:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  # Lidarr
  lidarr:
    image: linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/lidarr:/config
      - ${MEDIA_PATH}/music:/music
      - ${DOWNLOADS_PATH}/complete:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  # SABnzbd
  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/sabnzbd:/config
      - ${DOWNLOADS_PATH}/incomplete:/incomplete-downloads
      - ${DOWNLOADS_PATH}/complete:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  # qBittorrent
  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=8081
    volumes:
      - ${CONFIG_PATH}/qbittorrent:/config
      - ${DOWNLOADS_PATH}/complete:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  # Jellyseerr
  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - PORT=5055
    volumes:
      - ${CONFIG_PATH}/jellyseerr:/config
    ports:
      - ${JELLYSEERR_PORT:-5055}:5055
    restart: unless-stopped

  # Management UI
  arrstack-ui:
    build:
      context: ./ui
      dockerfile: Dockerfile
    container_name: arrstack-ui
    environment:
      - NODE_ENV=production
      - PORT=3000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./.env:/app/.env:ro
    ports:
      - ${MANAGEMENT_UI_PORT:-8080}:3000
    restart: unless-stopped
EOF

    # Add media server if configured
    case "$MEDIA_SERVER" in
        "jellyfin")
            cat >> docker-compose.yml << 'EOF'

  # Jellyfin Media Server
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/jellyfin:/config
      - ${MEDIA_PATH}:/data
    ports:
      - 8096:8096
    restart: unless-stopped
EOF
            ;;
        "emby")
            cat >> docker-compose.yml << 'EOF'

  # Emby Media Server
  emby:
    image: linuxserver/emby:latest
    container_name: emby
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/emby:/config
      - ${MEDIA_PATH}:/data
    ports:
      - 8096:8096
    restart: unless-stopped
EOF
            ;;
        "plex")
            cat >> docker-compose.yml << 'EOF'

  # Plex Media Server
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - VERSION=docker
    volumes:
      - ${CONFIG_PATH}/plex:/config
      - ${MEDIA_PATH}:/data
    ports:
      - 32400:32400
    restart: unless-stopped
EOF
            ;;
    esac
    
    # Add Cloudflare tunnel if configured
    if [[ -n "$CF_TOKEN" ]]; then
        cat >> docker-compose.yml << EOF

  # Cloudflare Tunnel
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TOKEN}
    restart: unless-stopped
EOF
    fi
    
    print_info "Docker Compose configuration created"
}

create_management_ui() {
    print_step "Creating Management UI..."
    
    # Create UI directory and files
    mkdir -p ui
    
    # UI files would go here (simplified version)
    cat > ui/package.json << 'EOF'
{
  "name": "arrstack-ui",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "dockerode": "^3.3.5",
    "dotenv": "^16.3.1",
    "socket.io": "^4.7.4"
  }
}
EOF
    
    cat > ui/server.js << 'EOF'
const express = require('express');
const Docker = require('dockerode');
const path = require('path');

const app = express();
const docker = new Docker();

app.use(express.static('public'));

app.get('/api/services', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    res.json(containers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Management UI running on port ${PORT}`);
});
EOF
    
    mkdir -p ui/public
    cat > ui/public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Arr Stack Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .service { border: 1px solid #ccc; margin: 10px; padding: 10px; }
        .healthy { background-color: #d4edda; }
        .unhealthy { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>Arr Stack Management</h1>
    <div id="services"></div>
    
    <script>
        fetch('/api/services')
            .then(response => response.json())
            .then(containers => {
                const servicesDiv = document.getElementById('services');
                containers.forEach(container => {
                    const serviceDiv = document.createElement('div');
                    serviceDiv.className = 'service ' + (container.State === 'running' ? 'healthy' : 'unhealthy');
                    serviceDiv.innerHTML = `
                        <h3>${container.Names[0].replace('/', '')}</h3>
                        <p>Status: ${container.State}</p>
                        <p>Ports: ${container.Ports.map(p => p.PrivatePort).join(', ')}</p>
                    `;
                    servicesDiv.appendChild(serviceDiv);
                });
            });
    </script>
</body>
</html>
EOF
    
    cat > ui/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
    
    print_info "Management UI created"
}

start_services() {
    print_step "Starting services..."
    
    # Build UI first
    docker-compose build arrstack-ui
    
    # Start all services
    docker-compose up -d
    
    print_info "Services are starting up..."
    print_info "This may take a few minutes for the first time."
}

wait_for_services() {
    print_step "Waiting for services to be ready..."
    
    local services=(
        "gluetun:9999"
        "sonarr:8989"
        "radarr:7878"
        "lidarr:8686"
        "sabnzbd:8080"
        "qbittorrent:8081"
        "jellyseerr:5055"
        "arrstack-ui:3000"
    )
    
    for service in "${services[@]}"; do
        local name=${service%:*}
        local port=${service#*:}
        
        echo -n "Waiting for $name..."
        local attempts=0
        local max_attempts=60
        
        while [[ $attempts -lt $max_attempts ]]; do
            if curl -s --connect-timeout 5 "http://localhost:$port" > /dev/null 2>&1; then
                echo " ✅ Ready"
                break
            fi
            
            if [[ $((attempts % 10)) -eq 0 ]]; then
                echo -n "."
            fi
            
            sleep 3
            ((attempts++))
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            echo " ⚠️ Timeout"
        fi
    done
}

show_completion_info() {
    echo ""
    echo -e "${GREEN}🏴‍☠️ Arrmematey Installation Complete!${NC}"
    echo "===================================="
    echo ""
    echo -e "${BLUE}Your pirate crew has found the treasure!${NC}"
    echo ""
    echo "🏴‍☠️ Arrmematey Service Access:"
    echo "• Management UI: http://localhost:8080"
    echo "• Prowlarr (Indexers): http://localhost:9696"
    echo "• Sonarr (TV): http://localhost:8989"
    echo "• Radarr (Movies): http://localhost:7878"
    echo "• Lidarr (Music): http://localhost:8686"
    echo "• SABnzbd (Usenet): http://localhost:8080"
    echo "• qBittorrent (Torrents): http://localhost:8081"
    echo "• Jellyseerr (Requests): http://localhost:5055"
    echo ""
    
    if [[ "$MEDIA_SERVER" != "none" ]]; then
        echo "• Media Server ($MEDIA_SERVER): http://localhost:8096"
        echo ""
    fi
    
    echo "🔐 VPN Status:"
    echo "• All download services are protected by Mullvad VPN"
    echo "• Your real IP is hidden when downloading"
    echo ""
    
    echo "📋 Next Steps:"
    echo "1. Open the Management UI at http://localhost:8080"
    echo "2. Add your media libraries to Sonarr/Radarr/Lidarr"
    echo "3. Configure indexers (NZB providers, torrent trackers)"
    echo "4. Start adding your favorite shows, movies, and music!"
    echo ""
    
    echo "📚 Helpful Commands:"
    echo "• ./manage.sh status - Check service status"
    echo "• ./manage.sh logs <service> - View service logs"
    echo "• ./health.sh check - Run health check"
    echo "• ./vpn-security.sh check - Verify VPN security"
    echo "• ./configure.sh - Reconfigure services"
    echo ""
    
    if [[ -n "$CF_TOKEN" ]]; then
        echo -e "${YELLOW}🌍 Remote Access:${NC}"
        echo "• Cloudflare Tunnel is configured"
        echo "• Your services are accessible via your domain"
        echo ""
    fi
    
    echo -e "${GREEN}Happy Media Hunting with Arrmematey! 🏴‍☠️🍿${NC}"
}

# Main function
main() {
    print_banner
    
    check_prerequisites
    quick_config
    create_quick_env
    setup_directories
    create_quick_compose
    create_management_ui
    start_services
    wait_for_services
    show_completion_info
}

# Run the quick installation
main "$@"