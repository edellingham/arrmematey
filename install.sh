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

    # Check Docker storage driver and space
    check_docker_storage

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

# Check Docker storage configuration
check_docker_storage() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Checking Docker storage configuration..."

    # Get Docker info
    local docker_info=$(docker info 2>/dev/null)
    local storage_driver=$(echo "$docker_info" | grep "Storage Driver:" | awk '{print $3}')
    local docker_root_dir=$(echo "$docker_info" | grep "Docker Root Dir:" | awk '{print $4}')

    echo -e "${GREEN}✅ Storage Driver: ${storage_driver}${NC}"
    echo -e "${GREEN}✅ Root Directory: ${docker_root_dir}${NC}"

    # Check space on Docker root directory
    if [[ -n "$docker_root_dir" && -d "$docker_root_dir" ]]; then
        local root_available=$(df "$docker_root_dir" | tail -1 | awk '{print $4}')
        local root_size=$(df "$docker_root_dir" | tail -1 | awk '{print $2}')
        local root_used=$(df "$docker_root_dir" | tail -1 | awk '{print $3}')

        echo -e "${BLUE}Docker Storage Space:${NC}"
        echo "  Total: $(echo $root_size | numfmt --to=iec)"
        echo "  Used:  $(echo $root_used | numfmt --to=iec)"
        echo "  Free:  $(echo $root_available | numfmt --to=iec)"

        # Check if space is critically low (less than 10GB)
        local root_available_gb=$((root_available / 1024 / 1024))
        if [[ $root_available_gb -lt 10 ]]; then
            echo -e "${YELLOW}⚠️ Docker storage is running low (${root_available_gb}GB free)${NC}"
            offer_storage_fix
        elif [[ $root_available_gb -lt 20 ]]; then
            echo -e "${YELLOW}⚠️ Docker storage is getting tight (${root_available_gb}GB free)${NC}"
            echo -e "${BLUE}Consider moving Docker storage to prevent future issues${NC}"
            read -p "Move Docker storage now? (y/N): " move_choice
            if [[ "$move_choice" =~ ^[Yy]$ ]]; then
                move_docker_storage
            fi
        else
            echo -e "${GREEN}✅ Docker storage has sufficient space${NC}"
        fi
    fi

    # Check overlay2 filesystem specifically
    if [[ "$storage_driver" == "overlay2" ]]; then
        check_overlay2_space
    fi
}

# Check overlay2 filesystem space
check_overlay2_space() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Checking overlay2 filesystem..."

    local overlay_mount=$(findmnt -t overlay -o SOURCE | head -1)
    if [[ -n "$overlay_mount" ]]; then
        echo -e "${GREEN}✅ Overlay2 mount: $overlay_mount${NC}"

        # Check space on overlay mount
        local overlay_available=$(df "$overlay_mount" | tail -1 | awk '{print $4}')
        local overlay_available_gb=$((overlay_available / 1024 / 1024))

        echo -e "${BLUE}Overlay2 Space:${NC}"
        echo "  Available: $(echo $overlay_available | numfmt --to=iec)"

        if [[ $overlay_available_gb -lt 5 ]]; then
            echo -e "${RED}❌ Overlay2 filesystem is critically low (${overlay_available_gb}GB free)${NC}"
            echo -e "${YELLOW}This will cause image extraction failures!${NC}"
            offer_storage_fix
        else
            echo -e "${GREEN}✅ Overlay2 filesystem has adequate space${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Could not find overlay2 mount point${NC}"
    fi
}

# Offer to fix storage issues
offer_storage_fix() {
    echo ""
    echo -e "${YELLOW}Docker storage space is low. This can cause installation failures.${NC}"
    echo "Would you like to:"
    echo ""
    echo "1) Clean Docker storage (recommended for cluttered storage)"
    echo "2) Move Docker storage to location with more space"
    echo "3) Continue anyway (risky)"
    echo ""
    read -p "Select option (1-3): " fix_choice

    case $fix_choice in
        1)
            echo -e "${BLUE}🧹 Cleaning Docker storage...${NC}"
            perform_docker_cleanup
            ;;
        2)
            echo -e "${BLUE}🔧 Moving Docker storage to larger location...${NC}"
            move_docker_storage
            ;;
        3)
            echo -e "${YELLOW}Continuing despite low storage space...${NC}"
            echo -e "${YELLOW}Installation may fail!${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Continuing...${NC}"
            ;;
    esac
}

# Perform Docker cleanup
perform_docker_cleanup() {
    echo "🛑 Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true

    echo "🗑️ Removing unused images..."
    docker image prune -af

    echo "🗑️ Removing unused volumes..."
    docker volume prune -f

    echo "🗑️ Removing unused networks..."
    docker network prune -f

    echo "🧽 Pruning system..."
    docker system prune -af

    echo "🔄 Restarting Docker..."
    sudo systemctl restart docker
    sleep 3

    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker cleanup completed successfully${NC}"
    else
        echo -e "${RED}❌ Docker restart failed${NC}"
        exit 1
    fi
}

# Move Docker storage to location with more space
move_docker_storage() {
    echo ""
    echo -e "${BLUE}🔄 Moving Docker Storage to Larger Location${NC}"
    echo "=============================================="
    echo ""

    # Get current Docker root directory
    local current_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
    echo -e "${BLUE}Current Docker root: ${current_root}${NC}"

    # Show available locations with more space
    echo ""
    echo -e "${BLUE}Available locations with more space:${NC}"

    local available_locations=()
    local location_counter=1

    # Check home directory
    local home_available=$(df $HOME | tail -1 | awk '{print $4}')
    local home_available_gb=$((home_available / 1024 / 1024))
    if [[ $home_available_gb -gt 10 ]]; then
        echo "  $location_counter) $HOME (${home_available_gb}GB free)"
        available_locations+=("$HOME")
        ((location_counter++))
    fi

    # Check common mount points
    for mount_point in /opt /usr/local /var/lib; do
        if [[ -d "$mount_point" && "$mount_point" != "$current_root" ]]; then
            local mount_available=$(df $mount_point | tail -1 | awk '{print $4}')
            local mount_available_gb=$((mount_available / 1024 / 1024))
            if [[ $mount_available_gb -gt 10 ]]; then
                echo "  $location_counter) $mount_point (${mount_available_gb}GB free)"
                available_locations+=("$mount_point")
                ((location_counter++))
            fi
        fi
    done

    # Check if we found any suitable locations
    if [[ ${#available_locations[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No suitable locations found with sufficient space${NC}"
        echo -e "${YELLOW}Please ensure you have at least 10GB free space in:${NC}"
        echo "  - $HOME"
        echo "  - /opt"
        echo "  - /usr/local"
        echo "  - /var/lib"
        return 1
    fi

    echo ""
    read -p "Select location (1-${#available_locations[@]}): " location_choice

    # Validate choice
    if ! [[ "$location_choice" =~ ^[0-9]+$ ]] || [[ $location_choice -lt 1 ]] || [[ $location_choice -gt ${#available_locations[@]} ]]; then
        echo -e "${RED}Invalid choice${NC}"
        return 1
    fi

    local selected_location="${available_locations[$((location_choice - 1))]}"
    local new_docker_root="$selected_location/docker-data"
    local backup_name="docker-backup-$(date +%Y%m%d-%H%M%S)"

    echo ""
    echo -e "${YELLOW}Moving Docker from ${current_root} to ${new_docker_root}${NC}"
    echo -e "${YELLOW}Creating backup at: ${current_root}.${backup_name}${NC}"
    echo ""

    read -p "Continue? This will restart Docker. (y/N): " confirm_move
    if [[ ! "$confirm_move" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return 1
    fi

    echo ""
    echo "🛑 Stopping Docker daemon..."
    sudo systemctl stop docker

    echo "🗃️ Creating backup..."
    sudo mv "$current_root" "$current_root.$backup_name"

    echo "📁 Creating new Docker directory..."
    sudo mkdir -p "$new_docker_root"

    echo "🔗 Creating symlink..."
    sudo ln -sf "$new_docker_root" "$current_root"

    echo "⚙️ Updating Docker daemon configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$new_docker_root"
}
EOF

    echo "🚀 Starting Docker daemon..."
    sudo systemctl start docker
    sleep 5

    echo "🔍 Verifying Docker is working..."
    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker storage moved successfully!${NC}"
        local new_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
        echo -e "${GREEN}✅ New Docker root: ${new_root}${NC}"
        echo -e "${BLUE}Backup location: ${current_root}.${backup_name}${NC}"
        echo ""
        echo -e "${GREEN}You can safely remove the backup once everything is working:${NC}"
        echo "sudo rm -rf ${current_root}.${backup_name}"
    else
        echo -e "${RED}❌ Docker failed to start after move${NC}"
        echo "🛠️ Restoring from backup..."
        sudo rm -rf "$current_root"
        sudo mv "$current_root.$backup_name" "$current_root"
        sudo rm -f /etc/docker/daemon.json
        sudo systemctl start docker
        echo "🔄 Docker restored to original location"
        return 1
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
    echo "  • Automatically detects and fixes Docker storage issues"
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
    echo -e "${GREEN}💡 Storage Features:${NC}"
    echo "  • Automatic Docker storage space detection"
    echo "  • Detection of overlay2 filesystem issues"
    echo "  • Interactive options to clean or move Docker storage"
    echo "  • Moves Docker to locations with more space"
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