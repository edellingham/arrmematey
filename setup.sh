#!/bin/bash

# Arr Stack Setup Script
# Sets up Docker, Sonarr, Radarr, Lidarr, SABnzbd, qBittorrent, Gluetun, Jellyseerr, Cloudflare Tunnel, and management UI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
MANAGEMENT_UI_PORT=8080

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons."
        exit 1
    fi
}

# Install Docker and Docker Compose
install_docker() {
    print_status "Installing Docker and Docker Compose..."
    
    if ! command -v docker &> /dev/null; then
        print_status "Docker not found. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_warning "You may need to log out and log back in to use Docker without sudo."
    else
        print_status "Docker is already installed."
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_status "Docker Compose not found. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        print_status "Docker Compose is already installed."
    fi
}

# Interactive configuration function
request_configuration() {
    print_status "Configuration Setup"
    print_status "==================="
    
    # Get user ID info
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    # Location preferences
    echo ""
    read -p "Enter your timezone [America/New_York]: " TZONE
    TZONE=${TZONE:-America/New_York}
    
    read -p "Enter Mullvad account ID: " MULLVAD_ID
    while [[ -z "$MULLVAD_ID" ]]; do
        print_warning "Mullvad account ID is required for VPN protection"
        read -p "Enter Mullvad account ID: " MULLVAD_ID
    done
    
    echo ""
    print_status "Available Mullvad countries:"
    echo "us, ca, uk, de, nl, se, no, dk, fi, ch, fr, it, es, at, be, pl, cz, hu, ro, bg, gr, pt, ie"
    read -p "Enter Mullvad country [us]: " MULLVAD_COUNTRY
    MULLVAD_COUNTRY=${MULLVAD_COUNTRY:-us}
    
    if [[ "$MULLVAD_COUNTRY" == "us" ]]; then
        echo "Available US cities: ny, la, chicago, dallas, seattle, miami, atlanta, denver"
        read -p "Enter Mullvad city [ny]: " MULLVAD_CITY
        MULLVAD_CITY=${MULLVAD_CITY:-ny}
    else
        MULLVAD_CITY=""
    fi
    
    echo ""
    read -p "Enter Cloudflare tunnel token (press Enter to skip): " CF_TOKEN
    read -p "Enter your domain for Cloudflare tunnel (press Enter to skip): " CF_DOMAIN
    
    # Path configuration
    echo ""
    print_status "Directory Configuration"
    print_status "======================"
    read -p "Media directory path [$HOME/Media]: " MEDIA_DIR
    MEDIA_DIR=${MEDIA_DIR:-$HOME/Media}
    
    read -p "Downloads directory path [$HOME/Downloads]: " DOWNLOADS_DIR
    DOWNLOADS_DIR=${DOWNLOADS_DIR:-$HOME/Downloads}
    
    read -p "Config directory path [$HOME/Config]: " CONFIG_DIR
    CONFIG_DIR=${CONFIG_DIR:-$HOME/Config}
    
    # Service passwords
    echo ""
    print_status "Security Configuration"
    print_status "======================"
    
    # Generate secure passwords if not provided
    SABNZBD_PW=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    JELLYSEERR_PW=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    
    read -p "SABnzbd password [auto-generated]: " SABNZBD_PASS
    SABNZBD_PASS=${SABNZBD_PASS:-$SABNZBD_PW}
    
    read -p "Jellyseerr password [auto-generated]: " JELLYSEERR_PASS
    JELLYSEERR_PASS=${JELLYSEERR_PASS:-$JELLYSEERR_PW}
    
    # Port configuration
    echo ""
    read -p "Management UI port [8080]: " UI_PORT
    UI_PORT=${UI_PORT:-8080}
    
    # NZB provider setup
    echo ""
    print_status "NZB Provider Configuration"
    print_status "=========================="
    
    NZB_PROVIDERS=("drunkenslug" "dognzb" "nzb.su" "omgwtfnzbs" "nzbid" "alt.hub")
    echo "Popular NZB providers: ${NZB_PROVIDERS[*]}"
    read -p "Enter your NZB provider name: " NZB_PROVIDER
    
    if [[ -n "$NZB_PROVIDER" ]]; then
        read -p "Enter NZB provider API key: " NZB_APIKEY
        read -p "Enter NZB provider URL (if custom): " NZB_URL
    fi
    
    # Usenet indexer configuration
    echo ""
    read -p "Enter Usenet server hostname [news.usenetserver.com]: " USENET_SERVER
    USENET_SERVER=${USENET_SERVER:-news.usenetserver.com}
    read -p "Enter Usenet port [563]: " USENET_PORT
    USENET_PORT=${USENET_PORT:-563}
    read -p "Enter Usenet username: " USENET_USER
    read -p "Enter Usenet password: " USENET_PASS
    read -p "Use SSL? [y/N]: " USENET_SSL
    USENET_SSL=${USENET_SSL:-n}
    
    # Torrent indexer setup
    echo ""
    print_status "Torrent Indexer Configuration"
    print_status "=============================="
    
    echo "Popular torrent trackers:"
    echo "- IPTorrents"
    echo "- TorrentDay"
    echo "- TorrentLeech"
    echo "- MoreThanTV"
    echo "- FileList"
    echo "- BroadcasTheNet"
    echo "- PassThePopcorn"
    echo "- GazelleGames"
    
    read -p "Enter torrent tracker name (or press Enter to skip): " TORRENT_TRACKER
    if [[ -n "$TORRENT_TRACKER" ]]; then
        read -p "Enter tracker RSS key or username: " TORRENT_USER
        read -p "Enter tracker password/key: " TORRENT_PASS
        read -p "Enter tracker URL (if custom): " TORRENT_URL
    fi
    
    # Media server configuration
    echo ""
    print_status "Media Server Configuration"
    print_status "==========================="
    
    echo "Choose your media server:"
    echo "1. Emby"
    echo "2. Jellyfin"
    echo "3. Plex"
    echo "4. No media server"
    
    read -p "Select media server [1-4]: " MEDIA_SERVER_CHOICE
    MEDIA_SERVER_CHOICE=${MEDIA_SERVER_CHOICE:-1}
    
    case $MEDIA_SERVER_CHOICE in
        1) 
            MEDIA_SERVER="emby"
            read -p "Enter Emby server URL [http://localhost:8096]: " EMBY_URL
            EMBY_URL=${EMBY_URL:-http://localhost:8096}
            read -p "Enter Emby API key: " EMBY_API_KEY
            while [[ -z "$EMBY_API_KEY" ]]; do
                print_warning "Emby API key is required for Jellyseerr integration"
                echo "Get your API key from Emby Settings > Advanced > API Keys"
                read -p "Enter Emby API key: " EMBY_API_KEY
            done
            ;;
        2) 
            MEDIA_SERVER="jellyfin"
            read -p "Enter Jellyfin server URL [http://localhost:8096]: " JELLYFIN_URL
            JELLYFIN_URL=${JELLYFIN_URL:-http://localhost:8096}
            read -p "Enter Jellyfin API key: " JELLYFIN_API_KEY
            while [[ -z "$JELLYFIN_API_KEY" ]]; do
                print_warning "Jellyfin API key is required for Jellyseerr integration"
                echo "Get your API key from Jellyfin Settings > API Keys"
                read -p "Enter Jellyfin API key: " JELLYFIN_API_KEY
            done
            ;;
        3) 
            MEDIA_SERVER="plex"
            read -p "Enter Plex server URL: " PLEX_URL
            read -p "Enter Plex token: " PLEX_TOKEN
            while [[ -z "$PLEX_TOKEN" ]]; do
                print_warning "Plex token is required for Jellyseerr integration"
                echo "Get your token from https://plex.tv/api/v2/users.xml?X-Plex-Token=YOUR_TOKEN"
                read -p "Enter Plex token: " PLEX_TOKEN
            done
            ;;
        4) 
            MEDIA_SERVER="none"
            ;;
    esac
    
    # Quality profiles
    echo ""
    print_status "Quality Profile Selection"
    print_status "=========================="
    echo "1. Standard (720p/1080p) - Good for most users"
    echo "2. Quality (1080p/4K) - For quality enthusiasts"
    echo "3. Archive (4K only) - Maximum quality storage"
    echo "4. Custom - Configure manually later"
    
    read -p "Select quality profile [1-4]: " QUALITY_CHOICE
    QUALITY_CHOICE=${QUALITY_CHOICE:-1}
    
    case $QUALITY_CHOICE in
        1) QUALITY_PROFILE="standard" ;;
        2) QUALITY_PROFILE="quality" ;;
        3) QUALITY_PROFILE="archive" ;;
        4) QUALITY_PROFILE="custom" ;;
        *) QUALITY_PROFILE="standard" ;;
    esac
}

# Create environment file with user input
create_env_file() {
    print_status "Creating environment configuration..."
    
    cat > "$ENV_FILE" << EOF
# Arr Stack Environment Configuration
# Generated by setup.sh on $(date)

# User Configuration
PUID=$USER_ID
PGID=$GROUP_ID
TZ=$TZONE

# Mullvad VPN Configuration
MULLVAD_ACCOUNT_ID=$MULLVAD_ID
MULLVAD_COUNTRY=$MULLVAD_COUNTRY
MULLVAD_CITY=$MULLVAD_CITY

# Cloudflare Tunnel Configuration (Optional)
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
MANAGEMENT_UI_PORT=$UI_PORT

# Directory Configuration
MEDIA_PATH=$MEDIA_DIR
DOWNLOADS_PATH=$DOWNLOADS_DIR
CONFIG_PATH=$CONFIG_DIR

# Service Passwords
SABNZBD_PASSWORD=$SABNZBD_PASS
JELLYSEERR_PASSWORD=$JELLYSEERR_PASS

# NZB Provider Configuration
NZB_PROVIDER=$NZB_PROVIDER
NZB_APIKEY=$NZB_APIKEY
NZB_URL=$NZB_URL

# Usenet Configuration
USENET_SERVER=$USENET_SERVER
USENET_PORT=$USENET_PORT
USENET_USERNAME=$USENET_USER
USENET_PASSWORD=$USENET_PASS
USENET_SSL=${USENET_SSL,,}

# Torrent Indexer Configuration
TORRENT_TRACKER=$TORRENT_TRACKER
TORRENT_USER=$TORRENT_USER
TORRENT_PASSWORD=$TORRENT_PASS
TORRENT_URL=$TORRENT_URL

# Media Server Configuration
MEDIA_SERVER=$MEDIA_SERVER
EMBY_URL=$EMBY_URL
EMBY_API_KEY=$EMBY_API_KEY
JELLYFIN_URL=$JELLYFIN_URL
JELLYFIN_API_KEY=$JELLYFIN_API_KEY
PLEX_URL=$PLEX_URL
PLEX_TOKEN=$PLEX_TOKEN

# Quality Profile
QUALITY_PROFILE=$QUALITY_PROFILE

# API Keys (will be auto-populated after first run)
SONARR_API_KEY=
RADARR_API_KEY=
LIDARR_API_KEY=

# Advanced Configuration
MAX_CONCURRENT_DOWNLOADS=3
MIN_DISK_SPACE=10
MAX_DISK_USAGE=90
ENABLE_NOTIFICATIONS=true
EOF
}

# Create Recyclarr configuration
create_recyclarr_config() {
    print_status "Creating Recyclarr configuration..."
    
    mkdir -p "${CONFIG_PATH}/recyclarr"
    
    # Load environment to get quality profile
    source "$ENV_FILE"
    
    cat > "${CONFIG_PATH}/recyclarr/recyclarr.yml" << 'EOF'
instance_definitions:
  sonarr:
    base_url: http://sonarr:8989
    api_key: ${SONARR_API_KEY}
  radarr:
    base_url: http://radarr:7878
    api_key: ${RADARR_API_KEY}

custom_formats:
  # Sonarr TV Quality Profiles
  - trash_ids:
      - 718202e192e65918c4976585c8794979  # HDR Versions
      - 9b8d0e0c6b86be983d5276c82983987a  # x265 HDR
      - 31b2f40b5fc47d52733b435c5fb5ffea  # Remux
    type: sonarr
    quality_profiles:
      - name: Standard
        score: 0
      - name: Quality
        score: 100
      - name: Archive
        score: 200

  - trash_ids:
      - d8354082262407771b4e3fa85a7b7281  # Scene/WEB-DL
    type: sonarr
    quality_profiles:
      - name: Standard
        score: 0
      - name: Quality
        score: -10
      - name: Archive
        score: -50

  - trash_ids:
      - 2f8495484986a8015824b5b062a1d61b  # x264
    type: sonarr
    quality_profiles:
      - name: Standard
        score: 0
      - name: Quality
        score: -20
      - name: Archive
        score: -100

  - trash_ids:
      - dc7804c6185ed8735c29c0ad749937e7  # Low Quality
      type: both
    quality_profiles:
      - name: Standard
        score: -100
      - name: Quality
        score: -200
      - name: Archive
        score: -500

  # Radarr Movie Quality Profiles
  - trash_ids:
      - 9b2745312fe622258bad074b4b2a5adc  # Remux
      - 44ad8c40033a66300a88c5f3b0dff4a2  # IMAX Enhanced
    type: radarr
    quality_profiles:
      - name: Standard
        score: 0
      - name: Quality
        score: 100
      - name: Archive
        score: 200

  - trash_ids:
      - 7b90c03cf744c8352a51b87fe873084c  # HDR/Dolby Vision
    type: radarr
    quality_profiles:
      - name: Standard
        score: 50
      - name: Quality
        score: 100
      - name: Archive
        score: 200

  - trash_ids:
      - eca7788c1b7e045231d87d85d8426726  # Low Quality
      - cdd88c675fad4e3b945594e13cb8ae3c  # Cam/TS
    type: radarr
    quality_profiles:
      - name: Standard
        score: -100
      - name: Quality
        score: -200
      - name: Archive
        score: -500

quality_profiles:
  sonarr:
    - name: Standard
      upgrade_allowed: true
      min_format_score: -100
      upgrade_until_score: 50
      cutoff_format_score: 0
      
    - name: Quality
      upgrade_allowed: true
      min_format_score: -50
      upgrade_until_score: 150
      cutoff_format_score: 100
      
    - name: Archive
      upgrade_allowed: true
      min_format_score: 0
      upgrade_until_score: 300
      cutoff_format_score: 200

  radarr:
    - name: Standard
      upgrade_allowed: true
      min_format_score: -100
      upgrade_until_score: 50
      cutoff_format_score: 0
      
    - name: Quality
      upgrade_allowed: true
      min_format_score: -50
      upgrade_until_score: 150
      cutoff_format_score: 100
      
    - name: Archive
      upgrade_allowed: true
      min_format_score: 0
      upgrade_until_score: 300
      cutoff_format_score: 200
EOF

    # Create profile-specific configurations
    case "$QUALITY_PROFILE" in
        "standard")
            cat > "${CONFIG_PATH}/recyclarr/standard.yml" << EOF
# Standard Quality Profile - 720p/1080p focus
sonarr:
  - name: Standard
    quality_definition:
      type: hybrid
    qualities:
      - name: HDTV-720p
        enabled: true
      - name: HDTV-1080p
        enabled: true
      - name: WEBDL-1080p
        enabled: true
      - name: WEBRip-1080p
        enabled: true
      - name: Bluray-720p
        enabled: false
      - name: Bluray-1080p
        enabled: true
      - name: Bluray-2160p
        enabled: false

radarr:
  - name: Standard
    quality_definition:
      type: hybrid
    qualities:
      - name: DVD
        enabled: false
      - name: Bluray-720p
        enabled: true
      - name: HDTV-720p
        enabled: true
      - name: WEBDL-720p
        enabled: true
      - name: WEBRip-720p
        enabled: true
      - name: Bluray-1080p
        enabled: true
      - name: HDTV-1080p
        enabled: true
      - name: WEBDL-1080p
        enabled: true
      - name: WEBRip-1080p
        enabled: true
      - name: Bluray-2160p
        enabled: false
      - name: WEBDL-2160p
        enabled: false
EOF
            ;;
        "quality")
            cat > "${CONFIG_PATH}/recyclarr/quality.yml" << EOF
# Quality Profile - 1080p/4K focus
sonarr:
  - name: Quality
    quality_definition:
      type: hybrid
    qualities:
      - name: HDTV-720p
        enabled: false
      - name: HDTV-1080p
        enabled: true
      - name: WEBDL-1080p
        enabled: true
      - name: WEBRip-1080p
        enabled: true
      - name: Bluray-720p
        enabled: false
      - name: Bluray-1080p
        enabled: true
      - name: Bluray-2160p
        enabled: true

radarr:
  - name: Quality
    quality_definition:
      type: hybrid
    qualities:
      - name: DVD
        enabled: false
      - name: Bluray-720p
        enabled: false
      - name: HDTV-720p
        enabled: false
      - name: WEBDL-720p
        enabled: false
      - name: WEBRip-720p
        enabled: false
      - name: Bluray-1080p
        enabled: true
      - name: HDTV-1080p
        enabled: true
      - name: WEBDL-1080p
        enabled: true
      - name: WEBRip-1080p
        enabled: true
      - name: Bluray-2160p
        enabled: true
      - name: WEBDL-2160p
        enabled: true
EOF
            ;;
        "archive")
            cat > "${CONFIG_PATH}/recyclarr/archive.yml" << EOF
# Archive Profile - 4K focus
sonarr:
  - name: Archive
    quality_definition:
      type: hybrid
    qualities:
      - name: HDTV-720p
        enabled: false
      - name: HDTV-1080p
        enabled: false
      - name: WEBDL-1080p
        enabled: false
      - name: WEBRip-1080p
        enabled: false
      - name: Bluray-720p
        enabled: false
      - name: Bluray-1080p
        enabled: false
      - name: Bluray-2160p
        enabled: true

radarr:
  - name: Archive
    quality_definition:
      type: hybrid
    qualities:
      - name: DVD
        enabled: false
      - name: Bluray-720p
        enabled: false
      - name: HDTV-720p
        enabled: false
      - name: WEBDL-720p
        enabled: false
      - name: WEBRip-720p
        enabled: false
      - name: Bluray-1080p
        enabled: false
      - name: HDTV-1080p
        enabled: false
      - name: WEBDL-1080p
        enabled: false
      - name: WEBRip-1080p
        enabled: false
      - name: Bluray-2160p
        enabled: true
      - name: WEBDL-2160p
        enabled: true
EOF
            ;;
    esac
}

# Create service initialization scripts
create_init_scripts() {
    print_status "Creating service initialization scripts..."
    
    # Load environment
    source "$ENV_FILE"
    
    mkdir -p "${CONFIG_PATH}/init-scripts"
    
    # Sonarr initialization script
    cat > "${CONFIG_PATH}/init-scripts/sonarr-init.sh" << 'EOF'
#!/bin/bash
# Sonarr Configuration Script

SONARR_URL="http://localhost:8989/api/v3"
API_KEY_FILE="${CONFIG_PATH}/sonarr/config.xml"

# Wait for Sonarr to be ready
until curl -s "$SONARR_URL/system/status" > /dev/null; do
    echo "Waiting for Sonarr to start..."
    sleep 5
done

# Get API key from config
if [[ -f "$API_KEY_FILE" ]]; then
    API_KEY=$(grep -oP '(?<=ApiKey>)[^<]+' "$API_KEY_FILE")
    echo "Sonarr API Key: $API_KEY"
    
    # Save API key to environment for Recyclarr
    sed -i "s/SONARR_API_KEY=.*/SONARR_API_KEY=$API_KEY/" "/home/ed/.env"
else
    echo "Sonarr config not found"
fi
EOF

    # Radarr initialization script
    cat > "${CONFIG_PATH}/init-scripts/radarr-init.sh" << 'EOF'
#!/bin/bash
# Radarr Configuration Script

RADARR_URL="http://localhost:7878/api/v3"
API_KEY_FILE="${CONFIG_PATH}/radarr/config.xml"

# Wait for Radarr to be ready
until curl -s "$RADARR_URL/system/status" > /dev/null; do
    echo "Waiting for Radarr to start..."
    sleep 5
done

# Get API key from config
if [[ -f "$API_KEY_FILE" ]]; then
    API_KEY=$(grep -oP '(?<=ApiKey>)[^<]+' "$API_KEY_FILE")
    echo "Radarr API Key: $API_KEY"
    
    # Save API key to environment for Recyclarr
    sed -i "s/RADARR_API_KEY=.*/RADARR_API_KEY=$API_KEY/" "/home/ed/.env"
else
    echo "Radarr config not found"
fi
EOF

    chmod +x "${CONFIG_PATH}/init-scripts"/*.sh
}

# Configure service connections
configure_service_connections() {
    print_status "Configuring service connections..."
    
    # Load environment
    source "$ENV_FILE"
    
    # Create Docker Compose with service dependencies
    cat > "$COMPOSE_FILE" << 'EOF'
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
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://ifconfig.me"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      - ${CONFIG_PATH}/init-scripts/sonarr-init.sh:/init-scripts/sonarr-init.sh:ro
    network_mode: "service:gluetun"
    depends_on:
      gluetun:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8989"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      - ${CONFIG_PATH}/init-scripts/radarr-init.sh:/init-scripts/radarr-init.sh:ro
    network_mode: "service:gluetun"
    depends_on:
      gluetun:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7878"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      gluetun:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8686"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      gluetun:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      gluetun:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081"]
      interval: 30s
      timeout: 10s
      retries: 3

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
    depends_on:
      - sonarr
      - radarr

  # Recyclarr for quality profiles
  recyclarr:
    image: ghcr.io/recyclarr/recyclarr:latest
    container_name: recyclarr
    volumes:
      - ${CONFIG_PATH}/recyclarr:/config
      - ./.env:/config/.env:ro
    environment:
      - RECYCLARR_BASE_URL_SONARR=http://sonarr:8989
      - RECYCLARR_BASE_URL_RADARR=http://radarr:7878
    network_mode: "service:gluetun"
    depends_on:
      sonarr:
        condition: service_healthy
      radarr:
        condition: service_healthy
    restart: "no"
    command: sync
EOF

    # Add Cloudflare tunnel if configured
    if [[ -n "$CF_TOKEN" ]]; then
        cat >> "$COMPOSE_FILE" << EOF

  # Cloudflare Tunnel
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TOKEN}
    restart: unless-stopped
EOF
    fi

    # Add Media Server if configured
    case "$MEDIA_SERVER" in
        "emby")
            cat >> "$COMPOSE_FILE" << EOF

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
        "jellyfin")
            cat >> "$COMPOSE_FILE" << EOF

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
        "plex")
            cat >> "$COMPOSE_FILE" << EOF

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

    # Add Management UI
    cat >> "$COMPOSE_FILE" << EOF

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
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    # Read paths from .env file
    source "$ENV_FILE"
    
    mkdir -p "${CONFIG_PATH}"/{gluetun,sonarr,radarr,lidarr,sabnzbd,qbittorrent,jellyseerr}
    mkdir -p "${MEDIA_PATH}"/{tv,movies,music}
    mkdir -p "${DOWNLOADS_PATH}"/{incomplete,complete}
    
    print_status "Directories created successfully."
}

# Create management UI
create_management_ui() {
    print_status "Creating Management UI..."
    
    mkdir -p ui
    
    # Create package.json
    cat > ui/package.json << 'EOF'
{
  "name": "arrstack-ui",
  "version": "1.0.0",
  "description": "Arr Stack Management UI",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "dockerode": "^3.3.5",
    "dotenv": "^16.3.1",
    "axios": "^1.6.0",
    "socket.io": "^4.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    # Create server.js
    cat > ui/server.js << 'EOF'
const express = require('express');
const Docker = require('dockerode');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');
const axios = require('axios');
const path = require('path');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const docker = new Docker();

const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Get service status from environment
const getServiceConfig = () => {
  return {
    sonarr: { port: process.env.SONARR_PORT, name: 'Sonarr', icon: '🎬' },
    radarr: { port: process.env.RADARR_PORT, name: 'Radarr', icon: '🎥' },
    lidarr: { port: process.env.LIDARR_PORT, name: 'Lidarr', icon: '🎵' },
    sabnzbd: { port: process.env.SABNZBD_PORT, name: 'SABnzbd', icon: '📥' },
    qbittorrent: { port: process.env.QBITTORRENT_PORT, name: 'qBittorrent', icon: '⬇️' },
    jellyseerr: { port: process.env.JELLYSEERR_PORT, name: 'Jellyseerr', icon: '🍿' }
  };
};

// API Routes
app.get('/api/services', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const services = [];
    const config = getServiceConfig();
    
    for (const [key, service] of Object.entries(config)) {
      const container = containers.find(c => c.Names.includes(`/${key}`));
      services.push({
        id: key,
        name: service.name,
        icon: service.icon,
        port: service.port,
        url: `http://localhost:${service.port}`,
        status: container ? container.State : 'not_found',
        health: container ? container.Status : 'Container not found'
      });
    }
    
    res.json(services);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/service/:id/:action', async (req, res) => {
  try {
    const { id, action } = req.params;
    const container = docker.getContainer(id);
    
    if (action === 'start') {
      await container.start();
    } else if (action === 'stop') {
      await container.stop();
    } else if (action === 'restart') {
      await container.restart();
    } else {
      return res.status(400).json({ error: 'Invalid action' });
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/service/:id/logs', async (req, res) => {
  try {
    const { id } = req.params;
    const container = docker.getContainer(id);
    const logs = await container.logs({
      stdout: true,
      stderr: true,
      timestamps: true,
      tail: 100
    });
    
    res.json({ logs: logs.toString() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/system/info', async (req, res) => {
  try {
    const info = await docker.info();
    const containers = await docker.listContainers({ all: true });
    const images = await docker.listImages();
    
    res.json({
      docker: {
        version: info.ServerVersion,
        containers: containers.length,
        running: containers.filter(c => c.State === 'running').length,
        images: images.length
      },
      services: containers.filter(c => c.Names.some(name => 
        Object.keys(getServiceConfig()).some(service => name.includes(service))
      ))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Socket.io for real-time updates
setInterval(async () => {
  try {
    const containers = await docker.listContainers({ all: true });
    io.emit('containerUpdate', containers);
  } catch (error) {
    console.error('Error fetching container status:', error);
  }
}, 5000);

// Serve main HTML
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

server.listen(PORT, () => {
  console.log(`Arr Stack Management UI running on port ${PORT}`);
});
EOF

    # Create public directory and HTML
    mkdir -p ui/public
    cat > ui/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Arr Stack Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .system-info {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 30px;
            color: white;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }
        
        .services-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .service-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .service-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
        }
        
        .service-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 15px;
        }
        
        .service-name {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.2rem;
            font-weight: 600;
        }
        
        .service-icon {
            font-size: 1.5rem;
        }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 500;
            text-transform: uppercase;
        }
        
        .status-running {
            background: #10b981;
            color: white;
        }
        
        .status-stopped {
            background: #ef4444;
            color: white;
        }
        
        .status-restarting {
            background: #f59e0b;
            color: white;
        }
        
        .service-info {
            margin-bottom: 15px;
        }
        
        .service-url {
            color: #6b7280;
            font-size: 0.9rem;
            margin-bottom: 5px;
        }
        
        .service-health {
            color: #6b7280;
            font-size: 0.85rem;
        }
        
        .service-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 500;
            transition: all 0.3s ease;
            flex: 1;
            min-width: 80px;
        }
        
        .btn:hover {
            transform: scale(1.05);
        }
        
        .btn-start {
            background: #10b981;
            color: white;
        }
        
        .btn-stop {
            background: #ef4444;
            color: white;
        }
        
        .btn-restart {
            background: #f59e0b;
            color: white;
        }
        
        .btn-open {
            background: #3b82f6;
            color: white;
        }
        
        .btn-logs {
            background: #8b5cf6;
            color: white;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
        }
        
        .modal-content {
            background: white;
            margin: 50px auto;
            padding: 20px;
            border-radius: 15px;
            width: 80%;
            max-width: 800px;
            max-height: 70vh;
            overflow-y: auto;
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .close-modal {
            background: none;
            border: none;
            font-size: 1.5rem;
            cursor: pointer;
            color: #6b7280;
        }
        
        .logs-content {
            background: #1f2937;
            color: #f3f4f6;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 0.85rem;
            white-space: pre-wrap;
            max-height: 400px;
            overflow-y: auto;
        }
        
        .loading {
            text-align: center;
            color: white;
            font-size: 1.2rem;
        }
        
        @media (max-width: 768px) {
            .services-grid {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .system-info {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎬 Arr Stack Management</h1>
            <p>Manage your media services with ease</p>
        </div>

        <div class="system-info" id="systemInfo">
            <div class="loading">Loading system information...</div>
        </div>

        <div class="services-grid" id="servicesGrid">
            <div class="loading">Loading services...</div>
        </div>
    </div>

    <div class="modal" id="logsModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="logsTitle">Service Logs</h3>
                <button class="close-modal" onclick="closeLogsModal()">&times;</button>
            </div>
            <div class="logs-content" id="logsContent">
                Loading logs...
            </div>
        </div>
    </div>

    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        
        async function fetchServices() {
            try {
                const response = await fetch('/api/services');
                const services = await response.json();
                renderServices(services);
            } catch (error) {
                console.error('Error fetching services:', error);
            }
        }
        
        async function fetchSystemInfo() {
            try {
                const response = await fetch('/api/system/info');
                const info = await response.json();
                renderSystemInfo(info);
            } catch (error) {
                console.error('Error fetching system info:', error);
            }
        }
        
        function renderServices(services) {
            const grid = document.getElementById('servicesGrid');
            grid.innerHTML = services.map(service => `
                <div class="service-card">
                    <div class="service-header">
                        <div class="service-name">
                            <span class="service-icon">${service.icon}</span>
                            <span>${service.name}</span>
                        </div>
                        <div class="status-badge status-${service.status}">
                            ${service.status}
                        </div>
                    </div>
                    <div class="service-info">
                        <div class="service-url">
                            <strong>URL:</strong> <a href="${service.url}" target="_blank">${service.url}</a>
                        </div>
                        <div class="service-health">
                            <strong>Status:</strong> ${service.health}
                        </div>
                    </div>
                    <div class="service-actions">
                        <button class="btn btn-start" onclick="controlService('${service.id}', 'start')" 
                                ${service.status === 'running' ? 'disabled' : ''}>
                            Start
                        </button>
                        <button class="btn btn-stop" onclick="controlService('${service.id}', 'stop')"
                                ${service.status !== 'running' ? 'disabled' : ''}>
                            Stop
                        </button>
                        <button class="btn btn-restart" onclick="controlService('${service.id}', 'restart')">
                            Restart
                        </button>
                        <button class="btn btn-open" onclick="window.open('${service.url}', '_blank')">
                            Open
                        </button>
                        <button class="btn btn-logs" onclick="viewLogs('${service.id}', '${service.name}')">
                            Logs
                        </button>
                    </div>
                </div>
            `).join('');
        }
        
        function renderSystemInfo(info) {
            const systemInfoDiv = document.getElementById('systemInfo');
            systemInfoDiv.innerHTML = `
                <div>
                    <h3>🐳 Docker</h3>
                    <p>Version: ${info.docker.version}</p>
                </div>
                <div>
                    <h3>📦 Containers</h3>
                    <p>Total: ${info.docker.containers}</p>
                    <p>Running: ${info.docker.running}</p>
                </div>
                <div>
                    <h3>🖼️ Images</h3>
                    <p>Total: ${info.docker.images}</p>
                </div>
                <div>
                    <h3>🎬 Services</h3>
                    <p>Total: ${info.services.length}</p>
                </div>
            `;
        }
        
        async function controlService(serviceId, action) {
            try {
                const response = await fetch(`/api/service/${serviceId}/${action}`, {
                    method: 'POST'
                });
                
                if (response.ok) {
                    await fetchServices();
                }
            } catch (error) {
                console.error('Error controlling service:', error);
            }
        }
        
        async function viewLogs(serviceId, serviceName) {
            try {
                const response = await fetch(`/api/service/${serviceId}/logs`);
                const data = await response.json();
                
                document.getElementById('logsTitle').textContent = `${serviceName} Logs`;
                document.getElementById('logsContent').textContent = data.logs;
                document.getElementById('logsModal').style.display = 'block';
            } catch (error) {
                console.error('Error fetching logs:', error);
            }
        }
        
        function closeLogsModal() {
            document.getElementById('logsModal').style.display = 'none';
        }
        
        // Socket.io event listeners
        socket.on('containerUpdate', (containers) => {
            fetchServices();
        });
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('logsModal');
            if (event.target === modal) {
                modal.style.display = 'none';
            }
        }
        
        // Initial load
        fetchServices();
        fetchSystemInfo();
        
        // Refresh every 30 seconds
        setInterval(() => {
            fetchServices();
            fetchSystemInfo();
        }, 30000);
    </script>
</body>
</html>
EOF

    # Create Dockerfile for UI
    cat > ui/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF

    print_status "Management UI created successfully."
}

# Setup script complete
setup_complete() {
    print_status "Arrmematey setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Edit .env file with your Mullvad account ID and Cloudflare token"
    print_status "2. Run 'docker-compose up -d' to start all services"
    print_status "3. Access the Management UI at http://localhost:${MANAGEMENT_UI_PORT}"
    print_status "4. Configure each service through their respective web interfaces"
    print_status ""
    print_status "Services will be available at:"
    print_status "- Management UI: http://localhost:${MANAGEMENT_UI_PORT}"
    print_status "- Prowlarr: http://localhost:9696"
    print_status "- Sonarr: http://localhost:${SONARR_PORT:-8989}"
    print_status "- Radarr: http://localhost:${RADARR_PORT:-7878}"
    print_status "- Lidarr: http://localhost:${LIDARR_PORT:-8686}"
    print_status "- SABnzbd: http://localhost:${SABNZBD_PORT:-8080}"
    print_status "- qBittorrent: http://localhost:${QBITTORRENT_PORT:-8081}"
    print_status "- Jellyseerr: http://localhost:${JELLYSEERR_PORT:-5055}"
    print_status ""
    print_status "🎭 Arrmematey: Your media butler has arranged everything!"
}

# Configure services after startup
configure_services() {
    print_status "Configuring services..."
    
    source "$ENV_FILE"
    
    # Wait for services to be ready
    sleep 30
    
    # Configure SABnzbd if credentials provided
    if [[ -n "$USENET_SERVER" && -n "$USENET_USERNAME" && -n "$USENET_PASSWORD" ]]; then
        print_status "Configuring SABnzbd..."
        # SABnzbd auto-configuration would go here
    fi
    
    # Configure Sonarr/Radarr with indexers
    if [[ -n "$NZB_APIKEY" || -n "$TORRENT_USER" ]]; then
        print_status "Configuring media managers..."
        # Indexer configuration would go here
    fi
    
    # Configure Jellyseerr with media server
    if [[ -n "$MEDIA_SERVER" ]]; then
        print_status "Configuring Jellyseerr..."
        # Media server connection would go here
    fi
    
    # Run Recyclarr to apply quality profiles
    if [[ "$QUALITY_PROFILE" != "custom" ]]; then
        print_status "Applying Recyclarr quality profiles..."
        # Recyclarr execution would go here
    fi
}

# Main execution
main() {
    print_status "Starting Arrmematey Setup..."
    
    check_root
    install_docker
    request_configuration
    create_env_file
    configure_service_connections
    create_recyclarr_config
    create_init_scripts
    create_management_ui
    create_directories
    
    print_status "Starting services for initial configuration..."
    docker-compose up -d
    
    configure_services
    
    setup_complete
}

# Run the script
main "$@"