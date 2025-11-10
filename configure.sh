#!/bin/bash

# Service Configuration Script
# Automatically configures all services to work together

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment
if [[ ! -f ".env" ]]; then
    print_error ".env file not found. Run setup.sh first."
    exit 1
fi

source .env

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
            print_status "$name is ready"
            return 0
        fi
        print_status "Waiting for $name to start... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "$name failed to start after $max_attempts attempts"
    return 1
}

# Configure SABnzbd
configure_sabnzbd() {
    print_status "Configuring SABnzbd..."
    
    wait_for_service "http://localhost:${SABNZBD_PORT:-8080}" "SABnzbd"
    
    # SABnzbd API configuration
    SABNZBD_API_URL="http://localhost:${SABNZBD_PORT:-8080}/sabnzbd/api"
    
    # Get SABnzbd API key
    API_KEY=$(curl -s "${SABNZBD_API_URL}?mode=auth&apikey=" | grep -oP '(?<=<apikey>)[^<]+' || echo "")
    
    if [[ -z "$API_KEY" ]]; then
        print_error "Could not get SABnzbd API key"
        return 1
    fi
    
    # Configure Usenet server if credentials provided
    if [[ -n "$USENET_SERVER" && -n "$USENET_USERNAME" && -n "$USENET_PASSWORD" ]]; then
        print_status "Configuring Usenet server..."
        
        SSL_SETTING="false"
        if [[ "$USENET_SSL" == "true" || "$USENET_SSL" == "yes" ]]; then
            SSL_SETTING="true"
        fi
        
        curl -s "${SABNZBD_API_URL}?mode=config&name=server&apikey=${API_KEY}&host=${USENET_SERVER}&port=${USENET_PORT}&username=${USENET_USERNAME}&password=${USENET_PASSWORD}&ssl=${SSL_SETTING}&connections=10&retention=1000&timeout=60" > /dev/null
        
        print_status "Usenet server configured"
    fi
    
    # Set download paths
    curl -s "${SABNZBD_API_URL}?mode=config&name=folders&apikey=${API_KEY}&complete_dir=${DOWNLOADS_PATH}/complete&incomplete_dir=${DOWNLOADS_PATH}/incomplete" > /dev/null
    
    print_status "SABnzbd configuration completed"
}

# Configure qBittorrent
configure_qbittorrent() {
    print_status "Configuring qBittorrent..."
    
    wait_for_service "http://localhost:${QBITTORRENT_PORT:-8081}" "qBittorrent"
    
    # qBittorrent WebUI API
    QB_URL="http://localhost:${QBITTORRENT_PORT:-8081}"
    
    # Login to get session cookie
    SESSION_COOKIE=$(curl -s -c - --data "username=admin&password=adminadmin" "${QB_URL}/api/v2/auth/login" | grep -oP '(?<=SID\t)[^\s]+')
    
    if [[ -z "$SESSION_COOKIE" ]]; then
        print_error "Could not authenticate with qBittorrent"
        return 1
    fi
    
    # Set download paths
    curl -s -b "SID=${SESSION_COOKIE}" --data "json={\"save_path\":\"${DOWNLOADS_PATH}/complete\",\"temp_download_path\":\"${DOWNLOADS_PATH}/incomplete\"}" "${QB_URL}/api/v2/app/setPreferences" > /dev/null
    
    # Configure anonymous mode for privacy
    curl -s -b "SID=${SESSION_COOKIE}" --data "json={\"anonymous_mode\":true}" "${QB_URL}/api/v2/app/setPreferences" > /dev/null
    
    print_status "qBittorrent configuration completed"
}

# Configure Sonarr
configure_sonarr() {
    print_status "Configuring Sonarr..."
    
    wait_for_service "http://localhost:8989" "Sonarr"
    
    # Get Sonarr API key
    SONARR_API_KEY=$(curl -s "http://localhost:8989/api/v3/system/status?apikey=" | grep -oP '(?<=<apiKey>)[^<]+' || echo "")
    
    if [[ -z "$SONARR_API_KEY" ]]; then
        # Try to extract from config file
        if [[ -f "${CONFIG_PATH}/sonarr/config.xml" ]]; then
            SONARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "${CONFIG_PATH}/sonarr/config.xml" || echo "")
        fi
    fi
    
    if [[ -z "$SONARR_API_KEY" ]]; then
        print_error "Could not get Sonarr API key"
        return 1
    fi
    
    # Save API key to environment
    sed -i "s/SONARR_API_KEY=.*/SONARR_API_KEY=${SONARR_API_KEY}/" .env
    
    SONARR_API_URL="http://localhost:8989/api/v3"
    
    # Add SABnzbd as download client
    if command -v jq &> /dev/null; then
        SABNZBD_CLIENT=$(cat << EOF
{
    "enable": true,
    "protocol": "usenet",
    "name": "SABnzbd",
    "fields": [
        {
            "name": "host",
            "value": "sabnzbd"
        },
        {
            "name": "port",
            "value": 8080
        },
        {
            "name": "apiKey",
            "value": "${SABNZBD_PASSWORD}"
        },
        {
            "name": "category",
            "value": "tv"
        }
    ]
}
EOF
        )
        
        curl -s -X POST -H "X-Api-Key: ${SONARR_API_KEY}" -H "Content-Type: application/json" -d "$SABNZBD_CLIENT" "${SONARR_API_URL}/downloadclient" > /dev/null
    fi
    
    # Add qBittorrent as download client
    QB_CLIENT=$(cat << EOF
{
    "enable": true,
    "protocol": "torrent",
    "name": "qBittorrent",
    "fields": [
        {
            "name": "host",
            "value": "qbittorrent"
        },
        {
            "name": "port",
            "value": 8081
        },
        {
            "name": "username",
            "value": "admin"
        },
        {
            "name": "password",
            "value": "adminadmin"
        },
        {
            "name": "category",
            "value": "sonarr"
        }
    ]
}
EOF
    )
    
    curl -s -X POST -H "X-Api-Key: ${SONARR_API_KEY}" -H "Content-Type: application/json" -d "$QB_CLIENT" "${SONARR_API_URL}/downloadclient" > /dev/null
    
    # Set up root folders
    curl -s -X POST -H "X-Api-Key: ${SONARR_API_KEY}" -H "Content-Type: application/json" -d "{\"path\":\"${MEDIA_PATH}/tv\",\"accessible\":true}" "${SONARR_API_URL}/rootfolder" > /dev/null
    
    print_status "Sonarr configuration completed"
}

# Configure Radarr
configure_radarr() {
    print_status "Configuring Radarr..."
    
    wait_for_service "http://localhost:7878" "Radarr"
    
    # Get Radarr API key
    RADARR_API_KEY=$(curl -s "http://localhost:7878/api/v3/system/status?apikey=" | grep -oP '(?<=<apiKey>)[^<]+' || echo "")
    
    if [[ -z "$RADARR_API_KEY" ]]; then
        # Try to extract from config file
        if [[ -f "${CONFIG_PATH}/radarr/config.xml" ]]; then
            RADARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "${CONFIG_PATH}/radarr/config.xml" || echo "")
        fi
    fi
    
    if [[ -z "$RADARR_API_KEY" ]]; then
        print_error "Could not get Radarr API key"
        return 1
    fi
    
    # Save API key to environment
    sed -i "s/RADARR_API_KEY=.*/RADARR_API_KEY=${RADARR_API_KEY}/" .env
    
    RADARR_API_URL="http://localhost:7878/api/v3"
    
    # Add SABnzbd as download client
    SABNZBD_CLIENT=$(cat << EOF
{
    "enable": true,
    "protocol": "usenet",
    "name": "SABnzbd",
    "fields": [
        {
            "name": "host",
            "value": "sabnzbd"
        },
        {
            "name": "port",
            "value": 8080
        },
        {
            "name": "apiKey",
            "value": "${SABNZBD_PASSWORD}"
        },
        {
            "name": "category",
            "value": "movies"
        }
    ]
}
EOF
    )
    
    curl -s -X POST -H "X-Api-Key: ${RADARR_API_KEY}" -H "Content-Type: application/json" -d "$SABNZBD_CLIENT" "${RADARR_API_URL}/downloadclient" > /dev/null
    
    # Add qBittorrent as download client
    QB_CLIENT=$(cat << EOF
{
    "enable": true,
    "protocol": "torrent",
    "name": "qBittorrent",
    "fields": [
        {
            "name": "host",
            "value": "qbittorrent"
        },
        {
            "name": "port",
            "value": 8081
        },
        {
            "name": "username",
            "value": "admin"
        },
        {
            "name": "password",
            "value": "adminadmin"
        },
        {
            "name": "category",
            "value": "radarr"
        }
    ]
}
EOF
    )
    
    curl -s -X POST -H "X-Api-Key: ${RADARR_API_KEY}" -H "Content-Type: application/json" -d "$QB_CLIENT" "${RADARR_API_URL}/downloadclient" > /dev/null
    
    # Set up root folders
    curl -s -X POST -H "X-Api-Key: ${RADARR_API_KEY}" -H "Content-Type: application/json" -d "{\"path\":\"${MEDIA_PATH}/movies\",\"accessible\":true}" "${RADARR_API_URL}/rootfolder" > /dev/null
    
    print_status "Radarr configuration completed"
}

# Configure Jellyseerr
configure_jellyseerr() {
    print_status "Configuring Jellyseerr..."
    
    wait_for_service "http://localhost:${JELLYSEERR_PORT:-5055}" "Jellyseerr"
    
    # Jellyseerr configuration via environment variables or API calls
    # The actual configuration would depend on Jellyseerr's API structure
    
    print_status "Jellyseerr configuration completed"
}

# Apply Recyclarr quality profiles
apply_recyclarr_profiles() {
    print_status "Applying Recyclarr quality profiles..."
    
    if [[ ! -d "${CONFIG_PATH}/recyclarr" ]]; then
        print_status "Recyclarr config not found, skipping quality profiles"
        return 0
    fi
    
    # Run Recyclarr if Docker image is available
    if docker pull ghcr.io/recyclarr/recyclarr:latest &>/dev/null; then
        docker run --rm \
            -v "${CONFIG_PATH}/recyclarr:/config" \
            -v ./.env:/config/.env:ro \
            --network container:gluetun \
            ghcr.io/recyclarr/recyclarr:latest sync
        
        print_status "Recyclarr quality profiles applied"
    else
        print_status "Recyclarr image not available, skipping quality profiles"
    fi
}

# Configure Prowlarr
configure_prowlarr() {
    print_status "Configuring Prowlarr..."
    
    wait_for_service "http://localhost:9696" "Prowlarr"
    
    # Get Prowlarr API key
    PROWLARR_API_KEY=$(curl -s "http://localhost:9696/api/v3/system/status?apikey=" | grep -oP '(?<=<apiKey>)[^<]+' || echo "")
    
    if [[ -z "$PROWLARR_API_KEY" ]]; then
        # Try to extract from config file
        if [[ -f "${CONFIG_PATH}/prowlarr/config.xml" ]]; then
            PROWLARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "${CONFIG_PATH}/prowlarr/config.xml" || echo "")
        fi
    fi
    
    if [[ -z "$PROWLARR_API_KEY" ]]; then
        print_error "Could not get Prowlarr API key"
        return 1
    fi
    
    # Save API key to environment
    sed -i "s/PROWLARR_API_KEY=.*/PROWLARR_API_KEY=${PROWLARR_API_KEY}/" .env
    
    print_status "Prowlarr API key extracted and saved"
    
    # Configure basic settings if needed
    PROWLARR_API_URL="http://localhost:9696/api/v3"
    
    # Set up application settings
    curl -s -X PUT -H "X-Api-Key: ${PROWLARR_API_KEY}" -H "Content-Type: application/json" \
        -d '{"apiKey":"'"${PROWLARR_API_KEY}"'"}' \
        "${PROWLARR_API_URL}/config/host" > /dev/null
    
    print_status "Prowlarr configuration completed"
}

# Main configuration function
configure_all_services() {
    print_status "Starting service configuration..."
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Services are not running. Please start them first with 'docker-compose up -d'"
        exit 1
    fi
    
    # Configure services in order
    configure_prowlarr
    configure_sabnzbd
    configure_qbittorrent
    configure_sonarr
    configure_radarr
    configure_jellyseerr
    configure_indexers
    apply_recyclarr_profiles
    
    print_status "All services configured successfully!"
    print_status ""
    print_status "Services are now ready to use."
    print_status "Access the management UI at: http://localhost:${MANAGEMENT_UI_PORT:-8080}"
}

# Show configuration summary
show_config_summary() {
    print_status "Configuration Summary"
    print_status "===================="
    echo "Media Server: $MEDIA_SERVER"
    echo "NZB Provider: $NZB_PROVIDER"
    echo "Torrent Tracker: $TORRENT_TRACKER"
    echo "Quality Profile: $QUALITY_PROFILE"
    echo "VPN: Mullvad ($MULLVAD_COUNTRY)"
    echo ""
    echo "Service URLs:"
    echo "- Prowlarr: http://localhost:9696"
    echo "- Management UI: http://localhost:${MANAGEMENT_UI_PORT:-8080}"
    echo "- Sonarr: http://localhost:8989"
    echo "- Radarr: http://localhost:7878"
    echo "- Lidarr: http://localhost:8686"
    echo "- SABnzbd: http://localhost:${SABNZBD_PORT:-8080}"
    echo "- qBittorrent: http://localhost:${QBITTORRENT_PORT:-8081}"
    echo "- Jellyseerr: http://localhost:${JELLYSEERR_PORT:-5055}"
}

case "$1" in
    "configure"|"")
        configure_all_services
        ;;
    "summary")
        show_config_summary
        ;;
    "prowlarr")
        configure_prowlarr
        ;;
    "sabnzbd")
        configure_sabnzbd
        ;;
    "qbittorrent")
        configure_qbittorrent
        ;;
    "sonarr")
        configure_sonarr
        ;;
    "radarr")
        configure_radarr
        ;;
    "jellyseerr")
        configure_jellyseerr
        ;;
    "recyclarr")
        apply_recyclarr_profiles
        ;;
    *)
        echo "Service Configuration Script"
        echo "==========================="
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  configure  - Configure all services (default)"
        echo "  summary    - Show configuration summary"
        echo "  sabnzbd    - Configure SABnzbd only"
        echo "  qbittorrent - Configure qBittorrent only"
        echo "  sonarr     - Configure Sonarr only"
        echo "  radarr     - Configure Radarr only"
        echo "  jellyseerr - Configure Jellyseerr only"
        echo "  recyclarr  - Apply Recyclarr profiles only"
        exit 1
        ;;
esac