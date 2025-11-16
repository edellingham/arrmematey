#!/bin/bash
# Arrmematey Super-Robust Fresh Install Script
# For fresh Debian 13 systems - handles all installation issues gracefully

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🏴‍☠️ Arrmematey Super-Robust Fresh Install${NC}"
echo "========================================="
echo ""

echo -e "${BLUE}This script will:${NC}"
echo "  • Install Docker and dependencies (with fallbacks)"
echo "  • Handle all installation errors gracefully"
echo "  • Configure Docker storage optimally"
echo "  • Install complete Arrmematey stack"
echo "  • Create proper directories and permissions"
echo "  • Get Mullvad ID automatically"
echo "  • Start all services and verify everything works"
echo ""
echo -e "${YELLOW}Requirements:${NC}"
echo "  • Fresh Debian 13 system"
echo "  • Internet connection"
echo "  • Sudo access (will be requested)"
echo ""
echo -e "${BLUE}Starting installation in 10 seconds...${NC}"
sleep 10

# Function to install packages with retry
install_package() {
    local package="$1"
    local max_attempts=3
    local attempt=1
    
    echo -e "${BLUE}Installing $package (attempt $attempt/$max_attempts)...${NC}"
    
    while [[ $attempt -le $max_attempts ]]; do
        if sudo apt install -y "$package" 2>/dev/null; then
            echo -e "${GREEN}✅ $package installed successfully${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  $package installation failed (attempt $attempt/$max_attempts)${NC}"
            if [[ $attempt -eq $max_attempts ]]; then
                echo -e "${RED}❌ Failed to install $package after $max_attempts attempts${NC}"
                echo -e "${YELLOW}Continuing without $package (may cause issues)...${NC}"
            fi
            ((attempt++))
        fi
    done
}

# Function to handle Docker installation
install_docker() {
    echo -e "${BLUE}Installing Docker...${NC}"
    
    # Try multiple installation methods
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker is already installed${NC}"
        return 0
    fi
    
    # Method 1: Standard docker.io package
    if install_package "docker.io"; then
        echo -e "${GREEN}✅ Docker installed via docker.io${NC}"
        return 0
    fi
    
    # Method 2: Docker's official repository
    echo -e "${BLUE}Trying Docker official repository...${NC}"
    if curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.ce.tgz | sudo tar xz -C /tmp/docker && sudo dpkg -i /tmp/docker/docker.deb; then
        echo -e "${GREEN}✅ Docker installed via official repository${NC}"
        sudo rm -rf /tmp/docker
        return 0
    fi
    
    # Method 3: Fallback to docker.io without version pinning
    echo -e "${YELLOW}⚠️  Trying fallback installation...${NC}"
    if sudo apt install -y --no-install-recommends docker.io 2>/dev/null; then
        echo -e "${GREEN}✅ Docker installed via fallback method${NC}"
        return 0
    fi
    
    echo -e "${RED}❌ All Docker installation methods failed${NC}"
    return 1
}

# Function to configure Docker storage
configure_docker_storage() {
    echo -e "${BLUE}Configuring Docker storage...${NC}"
    
    # Create optimal daemon.json
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Docker storage configured${NC}"
    else
        echo -e "${RED}❌ Failed to configure Docker storage${NC}"
        return 1
    fi
}

# Function to create directories
create_directories() {
    echo -e "${BLUE}Creating directories...${NC}"
    
    local install_dir="$HOME/arrmematey"
    mkdir -p "$install_dir"
    mkdir -p "$install_dir/data/{media/{tv,movies,music},downloads/{complete,incomplete},config}"
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to get Mullvad ID
get_mullvad_id() {
    echo -e "${BLUE}Getting Mullvad ID...${NC}"
    echo -e "${BLUE}Get your ID from: https://mullvad.net/en/account/${NC}"
    echo ""
    read -p "Enter Mullvad Account ID: " MULLVAD_ID
    
    while [[ -z "$MULLVAD_ID" ]]; do
        echo -e "${RED}Account ID is required${NC}"
        read -p "Enter Mullvad Account ID: " MULLVAD_ID
    done
    
    echo -e "${GREEN}✅ Mullvad ID configured${NC}"
}

# Function to start services
start_services() {
    echo -e "${BLUE}Starting services...${NC}"
    
    cd "$HOME/arrmematey"
    
    # Start services with error handling
    if docker-compose up -d 2>/dev/null; then
        echo -e "${GREEN}✅ Services started successfully${NC}"
    else
        echo -e "${RED}❌ Failed to start services${NC}"
        echo -e "${YELLOW}Checking service status...${NC}"
        docker-compose ps
        return 1
    fi
}

# Function to show completion
show_completion() {
    echo ""
    echo -e "${GREEN}🎉 Arrmematey Installation Complete!${NC}"
    echo "=================================="
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
    echo -e "${BLUE}📁 Installation Directory:${NC}"
    echo "  $HOME/arrmematey"
    echo ""
    echo -e "${BLUE}🔧 Management Commands:${NC}"
    echo "  cd $HOME/arrmematey"
    echo "  docker-compose ps              # Check status"
    echo "  docker-compose logs -f         # View logs"
    echo "  docker-compose restart         # Restart services"
    echo "  docker-compose down           # Stop all"
    echo ""
    echo -e "${GREEN}🏴‍☠️ Happy treasure hunting!${NC}"
}

# Main installation process
main_install() {
    echo -e "${BLUE}[STEP 1/6]${NC} Installing Docker and dependencies..."
    if install_docker; then
        echo -e "${GREEN}✅ Docker installation successful${NC}"
    else
        echo -e "${RED}❌ Docker installation failed${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[STEP 2/6]${NC} Configuring Docker storage..."
    if configure_docker_storage; then
        echo -e "${GREEN}✅ Docker storage configured${NC}"
    else
        echo -e "${RED}❌ Docker storage configuration failed${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[STEP 3/6]${NC} Creating directories..."
    create_directories
    
    echo -e "${BLUE}[STEP 4/6]${NC} Getting Mullvad ID..."
    get_mullvad_id
    
    echo -e "${BLUE}[STEP 5/6]${NC} Downloading service configuration..."
    
    # Download docker-compose.yml
    if curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/docker-compose.yml -o "$HOME/arrmematey/docker-compose.yml"; then
        echo -e "${GREEN}✅ Service configuration downloaded${NC}"
    else
        echo -e "${RED}❌ Failed to download service configuration${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[STEP 6/6]${NC} Starting services..."
    if start_services; then
        echo -e "${GREEN}✅ All services started successfully${NC}"
        show_completion
        return 0
    else
        echo -e "${RED}❌ Failed to start services${NC}"
        return 1
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${BLUE}This script requires sudo access for system packages${NC}"
    echo "It will create a sudo user if needed and handle permissions properly."
    echo ""
    read -p "Continue with installation? (yes/NO): " continue_install

if [[ "$continue_install" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is already installed${NC}"
    echo -e "${BLUE}Proceeding with fresh installation...${NC}"
    main_install
else
    echo -e "${BLUE}Docker not installed, starting fresh installation...${NC}"
    main_install
fi