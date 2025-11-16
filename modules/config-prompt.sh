###############################################################################
# Configuration Prompt Module
# Interactively configures Arrmematey settings
#
# Version: 1.0.0
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_error() {
    echo -e "${RED}✗${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

# Get current environment configuration
load_env() {
    local home_dir
    home_dir=$(eval echo ~)

    local env_file="$home_dir/.env"

    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
    fi
}

# Prompt for Mullvad VPN configuration
prompt_mullvad_config() {
    print_step "Mullvad VPN Configuration"
    echo ""
    print_info "Your Mullvad account is required for VPN protection"
    echo ""

    # Mullvad Account ID
    echo -n "Mullvad Account ID: "
    read -r MULLVAD_ACCOUNT_ID

    if [[ -z "$MULLVAD_ACCOUNT_ID" ]]; then
        print_error "Mullvad Account ID is required!"
        return 1
    fi

    if [[ "$MULLVAD_ACCOUNT_ID" == "YOUR_MULLVAD_ACCOUNT_ID_HERE" ]]; then
        print_error "Please enter your actual Mullvad Account ID"
        return 1
    fi

    # Country
    echo ""
    print_info "Choose VPN location (default: us)"
    echo "  Common options: us, uk, de, ca, au, nl, fr, jp"
    echo -n "Country code: "
    read -r MULLVAD_COUNTRY

    if [[ -z "$MULLVAD_COUNTRY" ]]; then
        MULLVAD_COUNTRY="us"
    fi

    # City
    echo ""
    print_info "Choose city (default: ny)"
    echo "  Common options: ny, la, chi, hou, mia, dal, sea (US)"
    echo "  For other countries: london, berlin, toronto, sydney, amsterdam, paris, tokyo"
    echo -n "City code: "
    read -r MULLVAD_CITY

    if [[ -z "$MULLVAD_CITY" ]]; then
        MULLVAD_CITY="ny"
    fi

    print_success "Mullvad configuration saved"
    return 0
}

# Prompt for directory configuration
prompt_directory_config() {
    print_step "Directory Configuration"
    echo ""
    print_info "Configure media and download directories"
    echo ""

    local home_dir
    home_dir=$(eval echo ~)

    # Configuration path
    echo -n "Configuration directory [$home_dir/Config]: "
    read -r CONFIG_PATH
    if [[ -z "$CONFIG_PATH" ]]; then
        CONFIG_PATH="$home_dir/Config"
    fi

    # Media path
    echo -n "Media directory [$home_dir/Media]: "
    read -r MEDIA_PATH
    if [[ -z "$MEDIA_PATH" ]]; then
        MEDIA_PATH="$home_dir/Media"
    fi

    # Downloads path
    echo -n "Downloads directory [$home_dir/Downloads]: "
    read -r DOWNLOADS_PATH
    if [[ -z "$DOWNLOADS_PATH" ]]; then
        DOWNLOADS_PATH="$home_dir/Downloads"
    fi

    # Derived paths
    MOVIES_PATH="$MEDIA_PATH/Movies"
    TV_PATH="$MEDIA_PATH/TV"
    MUSIC_PATH="$MEDIA_PATH/Music"

    USENET_PATH="$DOWNLOADS_PATH/usenet"
    TORRENTS_PATH="$DOWNLOADS_PATH/torrents"

    print_success "Directory configuration saved"
    return 0
}

# Prompt for port configuration
prompt_port_config() {
    print_step "Port Configuration"
    echo ""
    print_info "Configure service ports (use defaults unless you have conflicts)"
    echo ""

    echo "Common conflicts:"
    echo "  - 8080: Often used by web servers"
    echo "  - 8989: Often used by development servers"
    echo "  - 7878: Usually available"
    echo ""

    # Management UI
    echo -n "Management UI port [8080]: "
    read -r MANAGEMENT_UI_PORT
    if [[ -z "$MANAGEMENT_UI_PORT" ]]; then
        MANAGEMENT_UI_PORT=8080
    fi

    # Prowlarr
    echo -n "Prowlarr port [9696]: "
    read -r PROWLARR_PORT
    if [[ -z "$PROWLARR_PORT" ]]; then
        PROWLARR_PORT=9696
    fi

    # Sonarr
    echo -n "Sonarr port [8989]: "
    read -r SONARR_PORT
    if [[ -z "$SONARR_PORT" ]]; then
        SONARR_PORT=8989
    fi

    # Radarr
    echo -n "Radarr port [7878]: "
    read -r RADARR_PORT
    if [[ -z "$RADARR_PORT" ]]; then
        RADARR_PORT=7878
    fi

    # Lidarr
    echo -n "Lidarr port [8686]: "
    read -r LIDARR_PORT
    if [[ -z "$LIDARR_PORT" ]]; then
        LIDARR_PORT=8686
    fi

    # SABnzbd
    echo -n "SABnzbd port [8080]: "
    read -r SABNZBD_PORT
    if [[ -z "$SABNZBD_PORT" ]]; then
        SABNZBD_PORT=8080
    fi

    # qBittorrent
    echo -n "qBittorrent port [8081]: "
    read -r QBITTORRENT_PORT
    if [[ -z "$QBITTORRENT_PORT" ]]; then
        QBITTORRENT_PORT=8081
    fi

    # Jellyseerr
    echo -n "Jellyseerr port [5055]: "
    read -r JELLYSEERR_PORT
    if [[ -z "$JELLYSEERR_PORT" ]]; then
        JELLYSEERR_PORT=5055
    fi

    print_success "Port configuration saved"
    return 0
}

# Prompt for password configuration
prompt_password_config() {
    print_step "Service Password Configuration"
    echo ""
    print_warning "Please change these default passwords after first login!"
    echo ""

    # SABnzbd password
    echo -n "SABnzbd password [arrmematey_secure]: "
    read -r SABNZBD_PASSWORD
    if [[ -z "$SABNZBD_PASSWORD" ]]; then
        SABNZBD_PASSWORD="arrmematey_secure"
    fi

    # Jellyseerr password
    echo -n "Jellyseerr password [arrmematey_secure]: "
    read -r JELLYSEERR_PASSWORD
    if [[ -z "$JELLYSEERR_PASSWORD" ]]; then
        JELLYSEERR_PASSWORD="arrmematey_secure"
    fi

    print_success "Password configuration saved"
    print_warning "Remember to change these passwords after first login!"
    return 0
}

# Prompt for optional API keys
prompt_api_keys() {
    print_step "Optional API Keys"
    echo ""
    print_info "You can configure these later through the web UIs"
    echo ""

    # Fanart.tv API Key
    echo "Fanart.tv API Key (for movie backdrops in UI):"
    echo -n "  Press Enter to skip, or enter key: "
    read -r FANART_API_KEY

    # Cloudflare Tunnel Token
    echo ""
    echo "Cloudflare Tunnel Token (for remote access without port forwarding):"
    echo -n "  Press Enter to skip, or enter token: "
    read -r CLOUDFLARE_TOKEN

    print_success "API key configuration saved"
    return 0
}

# Update environment file
update_env_file() {
    local home_dir
    home_dir=$(eval echo ~)

    local env_file="$home_dir/.env"

    print_step "Updating environment configuration..."

    # Create backup
    cp "$env_file" "${env_file}.backup.$(date +%Y%m%d-%H%M%S)"

    # Update values
    sed -i "s/MULLVAD_ACCOUNT_ID=.*/MULLVAD_ACCOUNT_ID=$MULLVAD_ACCOUNT_ID/" "$env_file"
    sed -i "s/MULLVAD_COUNTRY=.*/MULLVAD_COUNTRY=$MULLVAD_COUNTRY/" "$env_file"
    sed -i "s/MULLVAD_CITY=.*/MULLVAD_CITY=$MULLVAD_CITY/" "$env_file"

    sed -i "s|MANAGEMENT_UI_PORT=.*|MANAGEMENT_UI_PORT=$MANAGEMENT_UI_PORT|" "$env_file"
    sed -i "s/PROWLARR_PORT=.*/PROWLARR_PORT=$PROWLARR_PORT/" "$env_file"
    sed -i "s/SONARR_PORT=.*/SONARR_PORT=$SONARR_PORT/" "$env_file"
    sed -i "s/RADARR_PORT=.*/RADARR_PORT=$RADARR_PORT/" "$env_file"
    sed -i "s/LIDARR_PORT=.*/LIDARR_PORT=$LIDARR_PORT/" "$env_file"
    sed -i "s/SABNZBD_PORT=.*/SABNZBD_PORT=$SABNZBD_PORT/" "$env_file"
    sed -i "s/QBITTORRENT_PORT=.*/QBITTORRENT_PORT=$QBITTORRENT_PORT/" "$env_file"
    sed -i "s/JELLYSEERR_PORT=.*/JELLYSEERR_PORT=$JELLYSEERR_PORT/" "$env_file"

    sed -i "s|CONFIG_PATH=.*|CONFIG_PATH=$CONFIG_PATH|" "$env_file"
    sed -i "s|MEDIA_PATH=.*|MEDIA_PATH=$MEDIA_PATH|" "$env_file"
    sed -i "s|DOWNLOADS_PATH=.*|DOWNLOADS_PATH=$DOWNLOADS_PATH|" "$env_file"

    sed -i "s|MOVIES_PATH=.*|MOVIES_PATH=$MOVIES_PATH|" "$env_file"
    sed -i "s|TV_PATH=.*|TV_PATH=$TV_PATH|" "$env_file"
    sed -i "s|MUSIC_PATH=.*|MUSIC_PATH=$MUSIC_PATH|" "$env_file"

    sed -i "s|USENET_PATH=.*|USENET_PATH=$USENET_PATH|" "$env_file"
    sed -i "s|TORRENTS_PATH=.*|TORRENTS_PATH=$TORRENTS_PATH|" "$env_file"

    sed -i "s/SABNZBD_PASSWORD=.*/SABNZBD_PASSWORD=$SABNZBD_PASSWORD/" "$env_file"
    sed -i "s/JELLYSEERR_PASSWORD=.*/JELLYSEERR_PASSWORD=$JELLYSEERR_PASSWORD/" "$env_file"

    if [[ -n "$FANART_API_KEY" ]]; then
        sed -i "s/FANART_API_KEY=.*/FANART_API_KEY=$FANART_API_KEY/" "$env_file"
    fi

    if [[ -n "$CLOUDFLARE_TOKEN" ]]; then
        sed -i "s/CLOUDFLARE_TOKEN=.*/CLOUDFLARE_TOKEN=$CLOUDFLARE_TOKEN/" "$env_file"
    fi

    print_success "Environment configuration updated"
}

# Restart services with new configuration
restart_services() {
    print_step "Restarting Arrmematey services..."

    cd /opt/arrmematey

    print_info "Stopping services..."
    docker-compose down

    print_info "Starting services with new configuration..."
    docker-compose --profile full up -d

    print_info "Waiting for services to start..."
    sleep 15

    print_success "Services restarted"
}

# Display access information
display_access_info() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  🎉 Configuration Complete! 🎉                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Access your Arrmematey stack at:${NC}"
    echo ""
    echo -e "  🏴‍☠️  Management UI:  ${GREEN}http://localhost:$MANAGEMENT_UI_PORT${NC}"
    echo -e "  🔍 Prowlarr:        ${GREEN}http://localhost:$PROWLARR_PORT${NC}"
    echo -e "  📺 Sonarr:          ${GREEN}http://localhost:$SONARR_PORT${NC}"
    echo -e "  🎬 Radarr:          ${GREEN}http://localhost:$RADARR_PORT${NC}"
    echo -e "  🎵 Lidarr:          ${GREEN}http://localhost:$LIDARR_PORT${NC}"
    echo -e "  📥 SABnzbd:         ${GREEN}http://localhost:$SABNZBD_PORT${NC}"
    echo -e "  ⬇️  qBittorrent:    ${GREEN}http://localhost:$QBITTORRENT_PORT${NC}"
    echo -e "  🍿 Jellyseerr:      ${GREEN}http://localhost:$JELLYSEERR_PORT${NC}"
    echo ""
    echo -e "${CYAN}Default Credentials:${NC}"
    echo -e "  SABnzbd:    username: arrmematey, password: $SABNZBD_PASSWORD"
    echo -e "  Jellyseerr: username: admin,      password: $JELLYSEERR_PASSWORD"
    echo ""
    echo -e "${YELLOW}⚠ Important Next Steps:${NC}"
    echo "  1. Change default passwords after first login"
    echo "  2. Configure indexers in Prowlarr"
    echo "  3. Set up download clients in SABnzbd/qBittorrent"
    echo "  4. Add your media libraries to Sonarr/Radarr/Lidarr"
    echo "  5. Configure Jellyseerr to connect to your services"
    echo ""
    print_success "Arrmematey is ready to use!"
}

# Automated configuration (use sensible defaults)
automated_config() {
    print_step "Running automated configuration..."

    local home_dir
    home_dir=$(eval echo ~)

    # Default values
    MULLVAD_ACCOUNT_ID="${MULLVAD_ACCOUNT_ID:-YOUR_MULLVAD_ACCOUNT_ID_HERE}"
    MULLVAD_COUNTRY="${MULLVAD_COUNTRY:-us}"
    MULLVAD_CITY="${MULLVAD_CITY:-ny}"

    MANAGEMENT_UI_PORT="${MANAGEMENT_UI_PORT:-8080}"
    PROWLARR_PORT="${PROWLARR_PORT:-9696}"
    SONARR_PORT="${SONARR_PORT:-8989}"
    RADARR_PORT="${RADARR_PORT:-7878}"
    LIDARR_PORT="${LIDARR_PORT:-8686}"
    SABNZBD_PORT="${SABNZBD_PORT:-8080}"
    QBITTORRENT_PORT="${QBITTORRENT_PORT:-8081}"
    JELLYSEERR_PORT="${JELLYSEERR_PORT:-5055}"

    CONFIG_PATH="${CONFIG_PATH:-$home_dir/Config}"
    MEDIA_PATH="${MEDIA_PATH:-$home_dir/Media}"
    DOWNLOADS_PATH="${DOWNLOADS_PATH:-$home_dir/Downloads}"
    MOVIES_PATH="$MEDIA_PATH/Movies"
    TV_PATH="$MEDIA_PATH/TV"
    MUSIC_PATH="$MEDIA_PATH/Music"
    USENET_PATH="$DOWNLOADS_PATH/usenet"
    TORRENTS_PATH="$DOWNLOADS_PATH/torrents"

    SABNZBD_PASSWORD="${SABNZBD_PASSWORD:-arrmematey_secure}"
    JELLYSEERR_PASSWORD="${JELLYSEERR_PASSWORD:-arrmematey_secure}"

    FANART_API_KEY="${FANART_API_KEY:-}"
    CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

    update_env_file
    restart_services
    display_access_info
}

# Main function
configure_arrmematey() {
    print_step "Starting Arrmematey configuration..."

    # Load current configuration
    load_env

    if [[ "$INSTALL_MODE" == "automated" ]]; then
        automated_config
    else
        # Interactive mode
        print_info "Configuration will be saved to ~/.env"
        echo ""
        echo "You can re-run this configuration later by editing ~/.env directly"
        echo ""

        # Step through configuration
        prompt_mullvad_config || return 1
        echo ""

        prompt_directory_config
        echo ""

        prompt_port_config
        echo ""

        prompt_password_config
        echo ""

        prompt_api_keys
        echo ""

        # Update and restart
        update_env_file
        restart_services
        display_access_info
    fi

    return 0
}
