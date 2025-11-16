#!/bin/bash
###############################################################################
# Arrmematey Simple Installer
# One-command installation for Debian and Ubuntu
#
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Spinner variables
SPINNER_PID=""
SPINNER_MESSAGE=""
SPINNER_DONE=""

# Spinner animation frames
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

show_spinner() {
    local message="$1"
    local frame=0

    while [[ -z "$SPINNER_DONE" ]]; do
        printf "\r${CYAN}${SPINNER_FRAMES[$frame]}${NC} ${message}"
        frame=$(((frame + 1) % ${#SPINNER_FRAMES[@]}))
        sleep 0.15
    done
    printf "\r${GREEN}✓${NC} ${message}                \n"
}

start_spinner() {
    SPINNER_MESSAGE="$1"
    SPINNER_DONE=""
    show_spinner "$SPINNER_MESSAGE" &
    SPINNER_PID=$!
}

stop_spinner() {
    SPINNER_DONE="done"
    if [[ -n "$SPINNER_PID" ]]; then
        wait $SPINNER_PID 2>/dev/null || true
    fi
}

do_with_progress() {
    local message="$1"
    shift

    start_spinner "$message"

    # Execute command and capture output
    local output
    output=$("$@" 2>&1)
    local exit_code=$?

    stop_spinner

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}✗${NC} Failed: $message"
        echo "$output"
        exit $exit_code
    fi

    return 0
}

print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  🏴‍☠️  ARRMEMATEY INSTALLER  🏴‍☠️                         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  One-Command Media Automation Stack Installation           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Version: ${GREEN}2.0.0${PURPLE}  |  Date: ${GREEN}2025-11-16${PURPLE}                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

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

###############################################################################
# System Checks
###############################################################################

check_os() {
    print_step "Checking operating system compatibility..."

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"

        if [[ "$OS_ID" == "debian" ]] || [[ "$OS_ID" == "ubuntu" ]]; then
            print_success "Detected $PRETTY_NAME"
            return 0
        else
            error_exit "This installer only supports Debian and Ubuntu. Detected: $PRETTY_NAME"
        fi
    else
        error_exit "Cannot determine operating system. /etc/os-release not found."
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

check_system_resources() {
    print_step "Checking system resources..."

    # Check RAM
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))

    # Check CPU
    local cpu_cores
    cpu_cores=$(nproc)

    # Check disk space (total vs available)
    local root_total_gb
    root_total_gb=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')
    local root_avail_gb
    root_avail_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    local root_used_gb
    root_used_gb=$(df -BG / | awk 'NR==2 {print $3}' | sed 's/G//')

    echo ""
    print_info "System Resources:"
    echo "  • CPU: $cpu_cores cores"
    echo "  • RAM: ${total_mem_gb} GB (total system memory)"
    echo "  • Total Storage: ${root_total_gb}GB"
    echo "  • Used Storage: ${root_used_gb}GB"
    echo "  • Available Storage: ${root_avail_gb}GB"
    echo ""

    # Warn if low resources
    if [[ $total_mem_gb -lt 2 ]]; then
        print_warning "Low RAM detected (${total_mem_gb}GB). Recommended: 4GB+"
    fi

    if [[ $root_avail_gb -lt 20 ]]; then
        print_warning "Low disk space (${root_avail_gb}GB available). Recommended: 40GB+"
        print_info "Your disk has ${root_total_gb}GB total, but only ${root_avail_gb}GB free"
    fi

    return 0
}

###############################################################################
# Docker Installation
###############################################################################

check_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        if ! systemctl is-active --quiet docker; then
            print_info "Starting Docker service..."
            systemctl start docker
            systemctl enable docker
        fi
    else
        print_warning "Docker not found"
        return 1
    fi

    # Check npm
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found - will install"
        return 2
    fi

    local npm_version
    npm_version=$(npm --version 2>/dev/null || echo "unknown")
    print_success "npm found (version $npm_version)"
    return 0
}

install_npm() {
    print_step "Installing npm..."

    print_info "Updating package lists..."
    apt-get update -qq

    print_info "Installing npm..."
    apt-get install -y npm

    local npm_version
    npm_version=$(npm --version)
    print_success "npm installed (version $npm_version)"
}

install_docker() {
    print_step "Installing Docker..."

    print_info "Downloading Docker installation script..."
    start_spinner "Downloading Docker installer"
    if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
        stop_spinner
        error_exit "Failed to download Docker installation script"
    fi
    stop_spinner

    print_info "Running Docker installation (this may take a few minutes)..."
    start_spinner "Installing Docker engine"
    sh /tmp/get-docker.sh
    stop_spinner

    rm /tmp/get-docker.sh

    # Install docker-compose plugin
    print_info "Installing Docker Compose plugin..."
    apt-get install -y docker-compose-plugin

    print_success "Docker installation complete"

    # Start and enable Docker
    print_info "Starting Docker service..."
    systemctl start docker
    systemctl enable docker

    # Verify installation
    print_info "Verifying Docker installation..."
    if docker run --rm hello-world &> /dev/null; then
        print_success "Docker is working correctly"
    else
        print_warning "Docker installation may have issues. You may need to log out and back in."
    fi

    # Verify docker-compose
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is working"
    else
        error_exit "Docker Compose installation failed"
    fi
}

###############################################################################
# Arrmematey Installation
###############################################################################

install_arrmematey() {
    print_step "Installing Arrmematey..."

    local install_dir="/opt/arrmematey"
    local repo_url="https://github.com/edellingham/arrmematey.git"

    # Clone repository
    if [[ -d "$install_dir" ]]; then
        print_warning "Arrmematey directory already exists at $install_dir"
        read -p "Remove and reinstall? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$install_dir"
        else
            error_exit "Installation cancelled. Remove $install_dir or choose a different location."
        fi
    fi

    print_info "Cloning repository to $install_dir..."
    start_spinner "Cloning Arrmematey repository"
    if ! git clone "$repo_url" "$install_dir"; then
        stop_spinner
        error_exit "Failed to clone Arrmematey repository"
    fi
    stop_spinner

    print_success "Arrmematey downloaded successfully"
    cd "$install_dir"
}

###############################################################################
# Configuration
###############################################################################

setup_environment() {
    print_step "Setting up environment configuration..."

    local home_dir
    home_dir=$(eval echo ~)
    local data_dir="/data/arrmematey"

    local env_file="$home_dir/.env"

    # Get current user info
    local current_user
    current_user=$(whoami)
    local current_uid
    current_uid=$(id -u)
    local current_gid
    current_gid=$(id -g)

    # Create .env with defaults using /data/arrmematey structure
    cat > "$env_file" <<EOF
# Arrmematey Configuration
# Generated by Arrmematey Installer

# User Configuration
PUID=$current_uid
PGID=$current_gid
TZ=UTC

# Mullvad VPN Configuration
MULLVAD_ACCOUNT_ID=
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# Port Configuration
MANAGEMENT_UI_PORT=8080
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055

# Directory Configuration (using /data for storage)
CONFIG_PATH=$data_dir/Config
MEDIA_PATH=$data_dir/Media
DOWNLOADS_PATH=$data_dir/Downloads

# Media Paths
MOVIES_PATH=$data_dir/Media/Movies
TV_PATH=$data_dir/Media/TV
MUSIC_PATH=$data_dir/Media/Music

# Download Paths
USENET_PATH=$data_dir/Downloads/usenet
TORRENTS_PATH=$data_dir/Downloads/torrents

# Service Passwords (change these!)
SABNZBD_PASSWORD=arrmematey_secure
JELLYSEERR_PASSWORD=arrmematey_secure

# Optional: Fanart.tv API Key (for movie backdrops)
FANART_API_KEY=

# Optional: Cloudflare Tunnel
CLOUDFLARE_TOKEN=
EOF

    print_success "Environment file created: $env_file"
    print_info "Using /data/arrmematey for data storage"
}

detect_existing_media() {
    # Check for common media directory patterns
    local storage_paths=(
        "/storage/shared-media"
        "/mnt/media"
        "/media"
        "/srv/media"
    )

    local detected_path=""
    local path_type=""

    for path in "${storage_paths[@]}"; do
        if [[ -d "$path" ]]; then
            print_info "Found existing media directory: $path"
            detected_path="$path"
            path_type="$path"
            break
        fi
    done

    # If no standard path found, check for Downloads or Media in common locations
    if [[ -z "$detected_path" ]]; then
        local common_paths=(
            "$HOME/Downloads"
            "$HOME/Media"
            "/data/arrmematey"
        )

        for path in "${common_paths[@]}"; do
            if [[ -d "$path" ]]; then
                detected_path=$(dirname "$path")
                path_type="common"
                break
            fi
        done
    fi

    echo "$detected_path"
}

configure_arrmematey() {
    print_step "Configuring Arrmematey..."

    local home_dir
    home_dir=$(eval echo ~)
    local data_dir="/data/arrmematey"
    local env_file="$home_dir/.env"

    echo ""
    print_info "Please configure your Arrmematey installation:"
    echo ""

    # Mullvad Account ID (required)
    echo -n "Mullvad Account ID (required): "
    read -r MULLVAD_ACCOUNT_ID

    if [[ -z "$MULLVAD_ACCOUNT_ID" ]]; then
        error_exit "Mullvad Account ID is required for VPN functionality"
    fi

    # Country
    echo ""
    echo -n "VPN Country code [us]: "
    read -r MULLVAD_COUNTRY
    [[ -z "$MULLVAD_COUNTRY" ]] && MULLVAD_COUNTRY="us"

    # City
    echo -n "VPN City code [ny]: "
    read -r MULLVAD_CITY
    [[ -z "$MULLVAD_CITY" ]] && MULLVAD_CITY="ny"

    # Media directory detection
    echo ""
    print_info "Checking for existing media directories..."
    local existing_media
    existing_media=$(detect_existing_media)

    if [[ -n "$existing_media" ]] && [[ -d "$existing_media/Downloads" ]] || [[ -d "$existing_media/Media" ]]; then
        print_warning "Found existing media structure at: $existing_media"
        echo ""
        echo "Detected structure:"
        if [[ -d "$existing_media/Downloads" ]]; then
            echo "  • Downloads: $existing_media/Downloads"
            ls -la "$existing_media/Downloads" 2>/dev/null | grep -E "^d" | awk '{print "    - " $9}' | head -5
        fi
        if [[ -d "$existing_media/Media" ]]; then
            echo "  • Media: $existing_media/Media"
            ls -la "$existing_media/Media" 2>/dev/null | grep -E "^d" | awk '{print "    - " $9}' | head -5
        fi
        echo ""
        read -p "Use existing media structure? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            CONFIG_PATH="$data_dir/Config"
            DOWNLOADS_PATH="$existing_media/Downloads"
            MEDIA_PATH="$existing_media/Media"
            print_success "Using existing media structure: $existing_media"
        else
            # Use defaults
            CONFIG_PATH="$data_dir/Config"
            MEDIA_PATH="$data_dir/Media"
            DOWNLOADS_PATH="$data_dir/Downloads"
        fi
    else
        # Directory customization
        echo ""
        print_info "Directory paths (press Enter for /data/arrmematey defaults):"
        echo ""

        echo -n "Config directory [$data_dir/Config]: "
        read -r CONFIG_PATH
        [[ -z "$CONFIG_PATH" ]] && CONFIG_PATH="$data_dir/Config"

        echo -n "Media directory [$data_dir/Media]: "
        read -r MEDIA_PATH
        [[ -z "$MEDIA_PATH" ]] && MEDIA_PATH="$data_dir/Media"

        echo -n "Downloads directory [$data_dir/Downloads]: "
        read -r DOWNLOADS_PATH
        [[ -z "$DOWNLOADS_PATH" ]] && DOWNLOADS_PATH="$data_dir/Downloads"
    fi

    # Update .env file
    print_info "Updating configuration..."

    sed -i "s|MULLVAD_ACCOUNT_ID=.*|MULLVAD_ACCOUNT_ID=$MULLVAD_ACCOUNT_ID|" "$env_file"
    sed -i "s|MULLVAD_COUNTRY=.*|MULLVAD_COUNTRY=$MULLVAD_COUNTRY|" "$env_file"
    sed -i "s|MULLVAD_CITY=.*|MULLVAD_CITY=$MULLVAD_CITY|" "$env_file"

    sed -i "s|CONFIG_PATH=.*|CONFIG_PATH=$CONFIG_PATH|" "$env_file"
    sed -i "s|MEDIA_PATH=.*|MEDIA_PATH=$MEDIA_PATH|" "$env_file"
    sed -i "s|DOWNLOADS_PATH=.*|DOWNLOADS_PATH=$DOWNLOADS_PATH|" "$env_file"

    sed -i "s|MOVIES_PATH=.*|MOVIES_PATH=$MEDIA_PATH/Movies|" "$env_file"
    sed -i "s|TV_PATH=.*|TV_PATH=$MEDIA_PATH/TV|" "$env_file"
    sed -i "s|MUSIC_PATH=.*|MUSIC_PATH=$MEDIA_PATH/Music|" "$env_file"

    sed -i "s|USENET_PATH=.*|USENET_PATH=$DOWNLOADS_PATH/usenet|" "$env_file"
    sed -i "s|TORRENTS_PATH=.*|TORRENTS_PATH=$DOWNLOADS_PATH/torrents|" "$env_file"

    print_success "Configuration saved"
    print_info "Media Path: $MEDIA_PATH"
    print_info "Downloads Path: $DOWNLOADS_PATH"
}

create_directories() {
    print_step "Creating directory structure..."

    # Load env
    source ~/.env

    local directories=(
        "$CONFIG_PATH"
        "$MEDIA_PATH/Movies"
        "$MEDIA_PATH/TV"
        "$MEDIA_PATH/Music"
        "$DOWNLOADS_PATH/usenet"
        "$DOWNLOADS_PATH/torrents"
    )

    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
        else
            print_info "Already exists: $dir"
        fi
    done
}

###############################################################################
# Service Startup
###############################################################################

start_services() {
    print_step "Starting Arrmematey services..."

    cd /opt/arrmematey

    # Load environment
    source ~/.env

    # Pull latest images
    print_info "Pulling Docker images (this will take a few minutes)..."
    start_spinner "Pulling Docker images"
    if ! docker-compose pull 2>&1 | grep -q "Pulling from"; then
        stop_spinner
        error_exit "Failed to pull Docker images"
    fi
    stop_spinner
    print_success "Docker images pulled"

    # Build UI
    print_info "Building management UI..."
    start_spinner "Installing Node.js dependencies"
    cd ui
    if ! npm install &>/dev/null; then
        stop_spinner
        error_exit "Failed to install Node.js dependencies"
    fi
    stop_spinner

    start_spinner "Building UI Docker image"
    if ! docker build -t arrstack-ui . &>/dev/null; then
        stop_spinner
        error_exit "Failed to build UI Docker image"
    fi
    stop_spinner
    print_success "UI Docker image built"
    cd /opt/arrmematey

    # Start services
    print_info "Starting Arrmematey stack..."
    start_spinner "Starting all services"
    if ! docker-compose --profile full up -d &>/dev/null; then
        stop_spinner
        error_exit "Failed to start services"
    fi
    stop_spinner
    print_success "Arrmematey services started"

    # Wait for services
    print_info "Waiting for services to initialize..."
    sleep 15

    # Check status
    print_step "Checking service status..."
    docker-compose ps
}

display_completion() {
    print_header
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  🎉 INSTALLATION COMPLETE! 🎉                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_success "Arrmematey is now installed and running!"
    echo ""
    echo -e "${CYAN}Access your services at:${NC}"
    echo ""
    source ~/.env
    echo -e "  🏴‍☠️  Management UI:  ${GREEN}http://localhost:$MANAGEMENT_UI_PORT${NC}"
    echo -e "  🔍 Prowlarr:        ${GREEN}http://localhost:$PROWLARR_PORT${NC}"
    echo -e "  📺 Sonarr:          ${GREEN}http://localhost:$SONARR_PORT${NC}"
    echo -e "  🎬 Radarr:          ${GREEN}http://localhost:$RADARR_PORT${NC}"
    echo -e "  🎵 Lidarr:          ${GREEN}http://localhost:$LIDARR_PORT${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Access the Management UI to configure your services"
    echo "  2. Set up indexers in Prowlarr"
    echo "  3. Configure download clients (SABnzbd/qBittorrent)"
    echo "  4. Add your media libraries to Sonarr/Radarr/Lidarr"
    echo ""
}

###############################################################################
# Main Installation Flow
###############################################################################

main() {
    print_header

    echo -e "${GREEN}Starting Arrmematey installation...${NC}"
    echo ""

    # Pre-flight checks
    check_root
    check_os
    check_system_resources

    echo ""
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    echo ""
    print_step "Beginning installation process..."
    echo ""

    # Install Docker if needed
    if ! check_docker; then
        install_docker
        echo ""
    fi

    # Install npm if needed
    check_result=$?
    if [[ $check_result -eq 2 ]]; then
        install_npm
        echo ""
    fi

    # Install Arrmematey
    install_arrmematey
    echo ""

    # Configure
    setup_environment
    configure_arrmematey
    create_directories
    echo ""

    # Start services
    start_services
    echo ""

    # Success!
    display_completion
}

# Run main function
main "$@"
