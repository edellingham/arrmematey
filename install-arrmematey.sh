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
    echo -e "${PURPLE}║${NC}  Version: ${GREEN}2.8.0${PURPLE}  |  Date: ${GREEN}2025-11-16${PURPLE}                    ${PURPLE}║${NC}"
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
        return 0
    else
        print_warning "Docker not found"
        return 1
    fi
}

check_npm() {
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found - will install"
        return 1
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

    print_info "Running Docker installation (this may take 5-10 minutes)..."
    print_info "⏳ Please be patient - Docker installation can take several minutes..."
    print_info "You will see package installation progress below..."
    echo ""

    # Show Docker installation output - shows packages being installed
    sh /tmp/get-docker.sh

    echo ""
    print_success "Docker installed successfully"

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
    print_info "⏳ This may take 30-60 seconds..."
    echo ""

    # Clone with progress indication
    if ! git clone --progress "$repo_url" "$install_dir"; then
        error_exit "Failed to clone Arrmematey repository"
    fi

    echo ""
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

# Function to check if a directory contains media by looking for common subdirectory patterns
check_media_patterns() {
    local base_dir="$1"
    local has_media=0
    local has_downloads=0
    local pattern_matches=()

    # Check for Downloads/Usenet/Torrents patterns (case insensitive)
    if ls -1 "$base_dir" 2>/dev/null | grep -iE "^(downloads?|usenet|torrents?)$" > /dev/null; then
        has_downloads=1
        pattern_matches+=("Downloads")
    fi

    # Check for Movies/Films patterns
    if ls -1 "$base_dir" 2>/dev/null | grep -iE "^(movies?|films?)$" > /dev/null; then
        has_media=1
        pattern_matches+=("Movies")
    fi

    # Check for TV patterns
    if ls -1 "$base_dir" 2>/dev/null | grep -iE "^(tv( shows?)?|tvshows?|series)$" > /dev/null; then
        has_media=1
        pattern_matches+=("TV Shows")
    fi

    # Check for Music/Audio patterns
    if ls -1 "$base_dir" 2>/dev/null | grep -iE "^(music|audio|songs?)$" > /dev/null; then
        has_media=1
        pattern_matches+=("Music")
    fi

    # Return result
    if [[ $has_media -eq 1 ]] || [[ $has_downloads -eq 1 ]]; then
        echo "1"
    else
        echo "0"
    fi
}

# Enhanced function to find media directories with pattern matching
find_media_directories() {
    local base_dir="$1"
    local media_subdir=""
    local downloads_subdir=""

    # Find Downloads/Usenet/Torrents directory
    for dir in Downloads downloads Usenet usenet Torrents torrents; do
        if [[ -d "$base_dir/$dir" ]]; then
            downloads_subdir="$base_dir/$dir"
            break
        fi
    done

    # Find Media directory (various naming patterns)
    for dir in Media media Movies movies TV\ Shows TV\ Shows tv\ shows tvshows TV TV series Series; do
        if [[ -d "$base_dir/$dir" ]]; then
            media_subdir="$base_dir/$dir"
            break
        fi
    done

    # If no standard "Media" dir, check if base dir itself contains media patterns
    if [[ -z "$media_subdir" ]] && check_media_patterns "$base_dir" | grep -q "1"; then
        media_subdir="$base_dir"
    fi

    # Return both paths
    echo "$downloads_subdir|$media_subdir"
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

    if [[ -n "$existing_media" ]]; then
        # Use enhanced pattern matching
        IFS='|' read -r downloads_path media_path < <(find_media_directories "$existing_media")

        # Validate that we found either downloads or media
        if [[ -n "$downloads_path" ]] || [[ -n "$media_path" ]]; then
            print_warning "Found existing media structure at: $existing_media"
            echo ""
            echo "Detected structure:"

            # Show downloads directory if found
            if [[ -n "$downloads_path" ]]; then
                echo "  • Downloads: $downloads_path"
                ls -la "$downloads_path" 2>/dev/null | grep -E "^d" | awk '{print "    - " $9}' | head -5
            fi

            # Show media directory if found
            if [[ -n "$media_path" ]] && [[ "$media_path" != "$existing_media" ]]; then
                echo "  • Media: $media_path"
                ls -la "$media_path" 2>/dev/null | grep -E "^d" | awk '{print "    - " $9}' | head -5
            elif [[ -n "$media_path" ]] && [[ "$media_path" == "$existing_media" ]]; then
                # If media_path is the base dir, show its contents
                echo "  • Media Structure: $existing_media"
                echo "    (Multiple media types detected)"
                ls -la "$existing_media" 2>/dev/null | grep -E "^d" | grep -v "^\." | awk '{print "    - " $9}' | head -8
            fi
            echo ""
            read -p "Use existing media structure? (Y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                CONFIG_PATH="$data_dir/Config"

                # Always use /data structure for consistency
                # Will create symlinks later to preserve existing structure
                if [[ -n "$downloads_path" ]]; then
                    DOWNLOADS_PATH="$data_dir/Downloads"
                    USE_EXISTING_DOWNLOADS=1
                    EXISTING_DOWNLOADS_PATH="$downloads_path"
                else
                    DOWNLOADS_PATH="$data_dir/Downloads"
                fi

                if [[ -n "$media_path" ]]; then
                    MEDIA_PATH="$data_dir/Media"
                    USE_EXISTING_MEDIA=1
                    EXISTING_MEDIA_PATH="$media_path"
                else
                    MEDIA_PATH="$data_dir/Media"
                fi

                print_success "Using existing media structure via symlinks: $existing_media"
            else
                # Use defaults
                CONFIG_PATH="$data_dir/Config"
                MEDIA_PATH="$data_dir/Media"
                DOWNLOADS_PATH="$data_dir/Downloads"
            fi
        else
            # No recognized media patterns, use manual configuration
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

    # Always create base directories in /data/arrmematey
    local base_directories=(
        "$CONFIG_PATH"
        "$MEDIA_PATH"
        "$DOWNLOADS_PATH"
    )

    for dir in "${base_directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
        else
            print_info "Already exists: $dir"
        fi
    done

    # Handle existing media directories with symlinks
    print_info "Setting up media directories..."

    # Check if we should use existing media
    if [[ -n "${USE_EXISTING_MEDIA:-}" ]] && [[ "$USE_EXISTING_MEDIA" == "1" ]]; then
        print_info "Creating symlinks to existing media structure..."

        # Map existing media to standard structure
        local media_mappings=(
            "$EXISTING_MEDIA_PATH/Movies:$MEDIA_PATH/Movies"
            "$EXISTING_MEDIA_PATH/TVShows:$MEDIA_PATH/TV"
            "$EXISTING_MEDIA_PATH/TV:$MEDIA_PATH/TV"
            "$EXISTING_MEDIA_PATH/series:$MEDIA_PATH/TV"
            "$EXISTING_MEDIA_PATH/Movies:$MEDIA_PATH/Movies"
            "$EXISTING_MEDIA_PATH/Music:$MEDIA_PATH/Music"
        )

        for mapping in "${media_mappings[@]}"; do
            IFS=':' read -r source_dir target_dir <<< "$mapping"

            if [[ -d "$source_dir" ]]; then
                # Create target parent directory
                mkdir -p "$(dirname "$target_dir")"

                # Remove target if it exists (but not if it's a symlink to our source)
                if [[ -L "$target_dir" ]] || [[ -d "$target_dir" ]]; then
                    if [[ ! "$target_dir" -ef "$source_dir" ]]; then
                        rm -rf "$target_dir"
                    fi
                fi

                # Create symlink
                if [[ ! -e "$target_dir" ]]; then
                    ln -s "$source_dir" "$target_dir"
                    print_success "Symlinked: $source_dir → $target_dir"
                else
                    print_info "Already exists: $target_dir"
                fi
            fi
        done
    else
        # Create standard media directories
        local media_dirs=(
            "$MEDIA_PATH/Movies"
            "$MEDIA_PATH/TV"
            "$MEDIA_PATH/Music"
        )

        for dir in "${media_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                mkdir -p "$dir"
                print_success "Created: $dir"
            else
                print_info "Already exists: $dir"
            fi
        done
    fi

    # Handle existing downloads directories with symlinks
    if [[ -n "${USE_EXISTING_DOWNLOADS:-}" ]] && [[ "$USE_EXISTING_DOWNLOADS" == "1" ]]; then
        print_info "Creating symlinks to existing downloads structure..."

        # Create standard download subdirectories as symlinks
        local download_mappings=(
            "$EXISTING_DOWNLOADS_PATH/usenet:$DOWNLOADS_PATH/usenet"
            "$EXISTING_DOWNLOADS_PATH/torrents:$DOWNLOADS_PATH/torrents"
        )

        for mapping in "${download_mappings[@]}"; do
            IFS=':' read -r source_dir target_dir <<< "$mapping"

            if [[ -d "$source_dir" ]]; then
                mkdir -p "$(dirname "$target_dir")"

                if [[ -L "$target_dir" ]] || [[ -d "$target_dir" ]]; then
                    if [[ ! "$target_dir" -ef "$source_dir" ]]; then
                        rm -rf "$target_dir"
                    fi
                fi

                if [[ ! -e "$target_dir" ]]; then
                    ln -s "$source_dir" "$target_dir"
                    print_success "Symlinked: $source_dir → $target_dir"
                else
                    print_info "Already exists: $target_dir"
                fi
            fi
        done
    else
        # Create standard download directories
        local download_dirs=(
            "$DOWNLOADS_PATH/usenet"
            "$DOWNLOADS_PATH/torrents"
        )

        for dir in "${download_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                mkdir -p "$dir"
                print_success "Created: $dir"
            else
                print_info "Already exists: $dir"
            fi
        done
    fi

    # Validate symlinks after creation
    if [[ -n "${USE_EXISTING_MEDIA:-}" ]] || [[ -n "${USE_EXISTING_DOWNLOADS:-}" ]]; then
        validate_symlinks
    fi
}

# Function to validate symlinks are working correctly
validate_symlinks() {
    print_step "Validating symlink integrity..."

    local broken_symlinks=0
    local symlink_count=0

    # Check all symlinks in /data/arrmematey
    find /data/arrmematey -type l -print0 2>/dev/null | while IFS= read -r -d '' symlink; do
        symlink_count=$((symlink_count + 1))

        # Check if symlink target exists
        if [[ ! -e "$symlink" ]]; then
            print_error "BROKEN SYMLINK: $symlink"
            print_error "  → Target does not exist: $(readlink "$symlink")"
            broken_symlinks=$((broken_symlinks + 1))
        fi
    done

    # Check filesystem compatibility
    check_filesystem_compatibility

    # Check permissions
    check_directory_permissions

    if [[ $broken_symlinks -gt 0 ]]; then
        echo ""
        print_error "Found $broken_symlinks broken symlink(s)!"
        echo ""
        print_info "This usually means the source directory was moved or deleted."
        print_info "Please restore the source directories and re-run the installer."
        echo ""
        error_exit "Symlink validation failed"
    else
        print_success "All symlinks validated successfully"
        if [[ $symlink_count -gt 0 ]]; then
            print_info "Checked $symlink_count symlink(s)"
        fi
    fi
}

# Function to check filesystem compatibility
check_filesystem_compatibility() {
    print_info "Checking filesystem compatibility..."

    # Check if /data and source directories exist
    if [[ ! -d "/data/arrmematey" ]] || [[ ! -d "${EXISTING_MEDIA_PATH:-$EXISTING_DOWNLOADS_PATH}" ]]; then
        return 0
    fi

    # Get device numbers
    local data_dev=$(stat -c %d "/data/arrmematey" 2>/dev/null || echo "0")
    local media_dev=$(stat -c %d "${EXISTING_MEDIA_PATH}" 2>/dev/null || echo "0")
    local downloads_dev=$(stat -c %d "${EXISTING_DOWNLOADS_PATH}" 2>/dev/null || echo "0")

    local cross_filesystem=0

    if [[ $media_dev -ne 0 ]] && [[ $data_dev -ne 0 ]] && [[ $media_dev -ne $data_dev ]]; then
        print_warning "Media directory is on different filesystem than /data"
        cross_filesystem=1
    fi

    if [[ $downloads_dev -ne 0 ]] && [[ $data_dev -ne 0 ]] && [[ $downloads_dev -ne $data_dev ]]; then
        print_warning "Downloads directory is on different filesystem than /data"
        cross_filesystem=1
    fi

    if [[ $cross_filesystem -eq 1 ]]; then
        echo ""
        print_warning "⚠️  Cross-Filesystem Symlinks Detected"
        print_info "Some directories are on different filesystems."
        print_info "This is usually OK, but symlinks on different filesystems may have:"
        print_info "  • Slightly more CPU overhead"
        print_info "  • Potential reliability issues with network storage (NFS/CIFS)"
        print_info "  • Different performance characteristics"
        echo ""
        read -p "Continue anyway? (Y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            error_exit "Aborted by user"
        fi
    else
        print_success "All directories are on compatible filesystems"
    fi
}

# Function to check directory permissions
check_directory_permissions() {
    print_info "Checking directory permissions..."

    # Get current PUID/PGID
    local current_uid=$(id -u)
    local current_gid=$(id -g)

    # Check if we have read access to source directories
    local permission_issues=0

    if [[ -n "${EXISTING_MEDIA_PATH:-}" ]] && [[ -d "$EXISTING_MEDIA_PATH" ]]; then
        if [[ ! -r "$EXISTING_MEDIA_PATH" ]]; then
            print_warning "No read permission for: $EXISTING_MEDIA_PATH"
            permission_issues=1
        fi
    fi

    if [[ -n "${EXISTING_DOWNLOADS_PATH:-}" ]] && [[ -d "$EXISTING_DOWNLOADS_PATH" ]]; then
        if [[ ! -r "$EXISTING_DOWNLOADS_PATH" ]]; then
            print_warning "No read permission for: $EXISTING_DOWNLOADS_PATH"
            permission_issues=1
        fi
    fi

    if [[ -n "${PUID:-}" ]] && [[ -n "${PGID:-}" ]]; then
        if [[ $PUID -ne $current_uid ]] || [[ $PGID -ne $current_gid ]]; then
            print_warning "PUID/PGID ($PUID:$PGID) differs from current user ($current_uid:$current_gid)"
            print_info "Ensure Docker containers run with correct PUID/PGID"
            print_info "Check docker-compose.yml has 'user: ${PUID:-}:${PGID:-}' set"
        fi
    fi

    if [[ $permission_issues -eq 1 ]]; then
        echo ""
        print_warning "Permission issues detected with source directories"
        print_info "This may cause problems when Docker containers try to access media"
        print_info "Consider running: chmod -R 755 $EXISTING_MEDIA_PATH $EXISTING_DOWNLOADS_PATH"
        echo ""
        read -p "Continue anyway? (Y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            error_exit "Aborted by user"
        fi
    else
        print_success "Directory permissions look OK"
    fi
}

# Function to show symlink status
show_symlink_status() {
    echo ""
    echo -e "${CYAN}📋 Symlink Status:${NC}"
    echo ""

    if [[ -d "/data/arrmematey/Media" ]]; then
        echo -e "${BLUE}Media Directories:${NC}"
        ls -lah /data/arrmematey/Media/ 2>/dev/null | grep "^l" | awk '{print "  " $0}' || echo "  No symlinks found"
        echo ""
    fi

    if [[ -d "/data/arrmematey/Downloads" ]]; then
        echo -e "${BLUE}Download Directories:${NC}"
        ls -lah /data/arrmematey/Downloads/ 2>/dev/null | grep "^l" | awk '{print "  " $0}' || echo "  No symlinks found"
        echo ""
    fi

    echo -e "${YELLOW}💡 Tip: You can monitor progress in real-time:${NC}"
    echo "  • Docker shows progress bars during image downloads"
    echo "  • You'll see package names during installation"
    echo "  • Spinner indicates activity during other operations"
    echo ""
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
    print_info "Pulling Docker images (this will take 5-10 minutes)..."
    print_info "⏳ Downloading all container images - please be patient..."
    print_info "Progress bars will show download status..."
    echo ""

    # Show Docker pull progress - this includes progress bars!
    if ! docker-compose pull 2>&1; then
        print_error "Failed to pull Docker images"
        exit 1
    fi

    echo ""
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

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
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

    print_warning "$service_name may not be fully ready"
    return 1
}

# Function to configure service via API
configure_service_via_api() {
    local service_name=$1
    local port=$2
    local api_endpoint=$3
    local api_data=$4
    local max_attempts=10
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s -X POST "http://localhost:$port$api_endpoint" \
            -H "Content-Type: application/json" \
            -d "$api_data" > /dev/null 2>&1; then
            print_success "Configured $service_name"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 3
    done

    print_warning "Could not fully configure $service_name (may need manual setup)"
    return 1
}

# Function to configure media library paths
configure_media_libraries() {
    print_step "Configuring Media Libraries..."

    source ~/.env

    # Wait for services
    wait_for_service "Prowlarr" "$PROWLARR_PORT"
    wait_for_service "Sonarr" "$SONARR_PORT"
    wait_for_service "Radarr" "$RADARR_PORT"
    wait_for_service "Lidarr" "$LIDARR_PORT"

    print_info "Configuring Sonarr (TV Shows)..."
    # Sonarr - Add TV path
    configure_service_via_api "Sonarr" "$SONARR_PORT" "/api/rootfolder" \
        "{\"path\": \"$TV_PATH\"}" 2>/dev/null || print_warning "Sonarr may need manual library setup"

    print_info "Configuring Radarr (Movies)..."
    # Radarr - Add Movies path
    configure_service_via_api "Radarr" "$RADARR_PORT" "/api/rootfolder" \
        "{\"path\": \"$MOVIES_PATH\"}" 2>/dev/null || print_warning "Radarr may need manual library setup"

    print_info "Configuring Lidarr (Music)..."
    # Lidarr - Add Music path
    configure_service_via_api "Lidarr" "$LIDARR_PORT" "/api/v1/rootfolder" \
        "{\"path\": \"$MUSIC_PATH\"}" 2>/dev/null || print_warning "Lidarr may need manual library setup"

    print_success "Media library paths configured"
}

# Function to configure download clients
configure_download_clients() {
    print_step "Configuring Download Clients..."

    source ~/.env

    print_info "Configuring SABnzbd..."
    # SABnzbd will use default config on first run
    print_info "SABnzbd will auto-configure on first access"

    print_info "Configuring qBittorrent..."
    # qBittorrent will use default config on first run
    print_info "qBittorrent will auto-configure on first access"

    print_success "Download clients ready for configuration"
}

# Function to display automation completion
display_automation_status() {
    print_step "Automation Setup Complete!"

    source ~/.env

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  🎯 POST-INSTALLATION CONFIGURATION REQUIRED:${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}To complete the setup, you need to:${NC}"
    echo ""
    echo -e "${BLUE}1. Prowlarr (http://localhost:$PROWLARR_PORT)${NC}"
    echo "   → Add your indexers (NZB/Torrent providers)"
    echo "   → The API key will be needed for Sonarr/Radarr/Lidarr"
    echo ""
    echo -e "${BLUE}2. SABnzbd (http://localhost:$SABNZBD_PORT)${NC}"
    echo "   → Username: arrmematey"
    echo "   → Password: $SABNZBD_PASSWORD"
    echo "   → Configure your news server (host, port, SSL, username, password)"
    echo "   → Configure categories for Sonarr/Radarr"
    echo ""
    echo -e "${BLUE}3. qBittorrent (http://localhost:$QBITTORRENT_PORT)${NC}"
    echo "   → Configure Web UI (username: admin, password: $QBITTORRENT_PORT)"
    echo "   → Set download directory to: $TORRENTS_PATH"
    echo "   → Configure category saves for Sonarr/Radarr"
    echo ""
    echo -e "${BLUE}4. Sonarr (http://localhost:$SONARR_PORT)${NC}"
    echo "   → Settings → Indexers → Add Prowlarr"
    echo "   → Settings → Download Clients → Add SABnzbd & qBittorrent"
    echo ""
    echo -e "${BLUE}5. Radarr (http://localhost:$RADARR_PORT)${NC}"
    echo "   → Settings → Indexers → Add Prowlarr"
    echo "   → Settings → Download Clients → Add SABnzbd & qBittorrent"
    echo ""
    echo -e "${BLUE}6. Lidarr (http://localhost:$LIDARR_PORT)${NC}"
    echo "   → Settings → Indexers → Add Prowlarr"
    echo "   → Settings → Download Clients → Add SABnzbd & qBittorrent"
    echo ""
    echo -e "${CYAN}📝 All paths have been automatically configured:${NC}"
    echo "   • Config: $CONFIG_PATH"
    echo "   • Movies: $MOVIES_PATH"
    echo "   • TV: $TV_PATH"
    echo "   • Music: $MUSIC_PATH"
    echo "   • Downloads: $DOWNLOADS_PATH"
    echo ""
    echo -e "${GREEN}🔗 Directory Structure:${NC}"
    echo "   All Arrmematey data is organized under /data/arrmematey/"
    echo "   Existing media is linked via symlinks"
    echo "   This keeps Docker volumes clean and organized"
    echo ""

    # Show symlink status if any were created
    if [[ -n "${USE_EXISTING_MEDIA:-}" ]] || [[ -n "${USE_EXISTING_DOWNLOADS:-}" ]]; then
        show_symlink_status
    fi
}

automate_stack_configuration() {
    print_step "Automating Stack Configuration..."

    # Wait for services to be fully ready
    print_info "Waiting for all services to start..."
    sleep 30

    # Configure media libraries
    configure_media_libraries

    # Configure download clients
    configure_download_clients

    # Show post-installation steps
    display_automation_status
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
    if ! check_npm; then
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

    # Automate stack configuration
    automate_stack_configuration
    echo ""

    # Success!
    display_completion
}

# Run main function
main "$@"
