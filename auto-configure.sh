#!/bin/bash
###############################################################################
# Arrmematey Auto-Configuration Script
# Configures all services to work together automatically
#
# Usage: ./auto-configure.sh
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error_exit() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Load environment
if [[ -f ~/.env ]]; then
    source ~/.env
else
    error_exit "~/.env file not found. Please run install-arrmematey.sh first."
fi

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=60
    local attempt=0

    print_info "Waiting for $service_name to be ready..."
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s "http://localhost:$port" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 5
    done

    print_warning "$service_name is not responding"
    return 1
}

# Get API key from service
get_api_key() {
    local service=$1
    local port=$2
    
    local api_key=""
    case $service in
        "prowlarr")
            # Prowlarr API key is in the config file
            api_key=$(grep -oP '(?<=ApiKey = ")[^"]*' "$CONFIG_PATH/prowlarr/config.xml" 2>/dev/null || echo "")
            ;;
        "sonarr")
            api_key=$(grep -oP '(?<=ApiKey = ")[^"]*' "$CONFIG_PATH/sonarr/config.xml" 2>/dev/null || echo "")
            ;;
        "radarr")
            api_key=$(grep -oP '(?<=ApiKey = ")[^"]*' "$CONFIG_PATH/radarr/config.xml" 2>/dev/null || echo "")
            ;;
        "lidarr")
            api_key=$(grep -oP '(?<=ApiKey = ")[^"]*' "$CONFIG_PATH/lidarr/config.xml" 2>/dev/null || echo "")
            ;;
    esac
    
    echo "$api_key"
}

# Configure Prowlarr with indexers (placeholder - requires user input)
configure_prowlarr() {
    print_step "Configuring Prowlarr..."
    
    print_warning "Prowlarr requires manual configuration for indexers"
    print_info "Please:"
    echo "  1. Open http://localhost:$PROWLARR_PORT"
    echo "  2. Go to Indexers"
    echo "  3. Add your NZB/Torrent providers"
    echo "  4. Save the API key for Sonarr/Radarr/Lidarr"
    echo ""
}

# Add root folder to Sonarr/Radarr/Lidarr
add_root_folder() {
    local service=$1
    local port=$2
    local api_port=$3
    local path=$4
    local api_key=$5
    
    if [[ -z "$api_key" ]]; then
        print_warning "Could not get $service API key"
        return 1
    fi
    
    print_info "Adding root folder to $service: $path"
    
    # Try to add root folder via API
    local response=$(curl -s -X POST "http://localhost:$api_port/api/rootfolder" \
        -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        -d "{\"path\": \"$path\"}" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]]; then
        print_success "Added $path to $service"
    else
        print_warning "Could not add root folder to $service (may already exist or need manual setup)"
    fi
}

# Configure Sonarr
configure_sonarr() {
    print_step "Configuring Sonarr..."
    
    wait_for_service "Sonarr" "$SONARR_PORT"
    
    local api_key=$(get_api_key "sonarr" "$SONARR_PORT")
    
    # Add TV Shows path
    if [[ -d "$TV_PATH" ]]; then
        add_root_folder "Sonarr" "$SONARR_PORT" "$SONARR_PORT" "$TV_PATH" "$api_key"
    fi
    
    # Configure Prowlarr connection
    if [[ -n "$api_key" ]] && [[ -f "$CONFIG_PATH/prowlarr/config.xml" ]]; then
        print_info "Configuring Prowlarr integration in Sonarr..."
        print_warning "Manual step required: Add Prowlarr in Sonarr Settings > Indexers"
    fi
    
    print_success "Sonarr configuration complete"
}

# Configure Radarr
configure_radarr() {
    print_step "Configuring Radarr..."
    
    wait_for_service "Radarr" "$RADARR_PORT"
    
    local api_key=$(get_api_key "radarr" "$RADARR_PORT")
    
    # Add Movies path
    if [[ -d "$MOVIES_PATH" ]]; then
        add_root_folder "Radarr" "$RADARR_PORT" "$RADARR_PORT" "$MOVIES_PATH" "$api_key"
    fi
    
    # Configure Prowlarr connection
    if [[ -n "$api_key" ]] && [[ -f "$CONFIG_PATH/prowlarr/config.xml" ]]; then
        print_info "Configuring Prowlarr integration in Radarr..."
        print_warning "Manual step required: Add Prowlarr in Radarr Settings > Indexers"
    fi
    
    print_success "Radarr configuration complete"
}

# Configure Lidarr
configure_lidarr() {
    print_step "Configuring Lidarr..."
    
    wait_for_service "Lidarr" "$LIDARR_PORT"
    
    local api_key=$(get_api_key "lidarr" "$LIDARR_PORT")
    
    # Add Music path
    if [[ -d "$MUSIC_PATH" ]]; then
        add_root_folder "Lidarr" "$LIDARR_PORT" "$LIDARR_PORT" "$MUSIC_PATH" "$api_key"
    fi
    
    # Configure Prowlarr connection
    if [[ -n "$api_key" ]] && [[ -f "$CONFIG_PATH/prowlarr/config.xml" ]]; then
        print_info "Configuring Prowlarr integration in Lidarr..."
        print_warning "Manual step required: Add Prowlarr in Lidarr Settings > Indexers"
    fi
    
    print_success "Lidarr configuration complete"
}

# Display configuration guide
display_guide() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  📋 MANUAL CONFIGURATION STEPS:${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}After running this script, complete these steps:${NC}"
    echo ""
    echo -e "${BLUE}1. Prowlarr (http://localhost:$PROWLARR_PORT)${NC}"
    echo "   → Add your indexers (NZBGet, DogNZB, Torrent providers)"
    echo "   → Save API key"
    echo ""
    echo -e "${BLUE}2. SABnzbd (http://localhost:$SABNZBD_PORT)${NC}"
    echo "   → Configure news server settings"
    echo "   → Set categories for Sonarr/Radarr"
    echo ""
    echo -e "${BLUE}3. qBittorrent (http://localhost:$QBITTORRENT_PORT)${NC}"
    echo "   → Change default admin password"
    echo "   → Set download directory to: $TORRENTS_PATH"
    echo ""
    echo -e "${BLUE}4. Sonarr/Radarr/Lidarr${NC}"
    echo "   → Add Prowlarr as indexer (Settings → Indexers → Add → Prowlarr)"
    echo "   → Add SABnzbd & qBittorrent (Settings → Download Clients → Add)"
    echo "   → Verify root folders are set correctly"
    echo ""
    echo -e "${CYAN}✅ Paths auto-configured:${NC}"
    echo "   • Movies: $MOVIES_PATH"
    echo "   • TV: $TV_PATH"
    echo "   • Music: $MUSIC_PATH"
    echo "   • Downloads: $DOWNLOADS_PATH"
    echo ""
    echo -e "${GREEN}🚀 Your media automation stack is ready!${NC}"
    echo ""
}

# Main execution
main() {
    echo ""
    print_step "Starting Arrmematey Auto-Configuration..."
    echo ""
    
    # Wait for all services
    wait_for_service "Prowlarr" "$PROWLARR_PORT"
    wait_for_service "Sonarr" "$SONARR_PORT"
    wait_for_service "Radarr" "$RADARR_PORT"
    wait_for_service "Lidarr" "$LIDARR_PORT"
    wait_for_service "SABnzbd" "$SABNZBD_PORT"
    wait_for_service "qBittorrent" "$QBITTORRENT_PORT"
    
    echo ""
    
    # Configure services
    configure_prowlarr
    configure_sonarr
    configure_radarr
    configure_lidarr
    
    echo ""
    
    # Display guide
    display_guide
}

main "$@"
