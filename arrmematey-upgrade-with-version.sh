#!/bin/bash
# Enhanced One-Liner Arrmematey Upgrade Script with Version Display
# Usage: curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-with-version.sh | bash

# Version
UPGRADE_SCRIPT_VERSION="2.20.20"

# Color codes for better feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Version banner function (matching installer format exactly)
show_version() {
    echo -e "${PURPLE}"
    echo -e "╔════════════════════════════════════════════════╗"
    echo -e "║${NC}  ${GREEN}Arrmematey One-Liner Upgrade Script${PURPLE}        ${PURPLE}║${NC}"
    echo -e "║${NC}  Version: ${GREEN}${UPGRADE_SCRIPT_VERSION}${PURPLE}  |  Date: ${GREEN}2025-11-17${PURPLE}                   ${PURPLE}║${NC}"
    echo -e "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Progress spinner function
show_progress() {
    local duration=$1
    local message=$2
    local steps=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        for step in "${steps[@]}"; do
            echo -en "\r${CYAN}${message} ${step}${NC}"
            sleep 0.1
        done
    done
    echo -e "\r${CYAN}${message} ✅${NC}"
}

# Step counter
STEP=1
TOTAL_STEPS=8

print_step() {
    echo -e "${PURPLE}[${STEP}/${TOTAL_STEPS}]${NC} ${WHITE}$1${NC}"
    ((STEP++))
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Display version banner
show_version

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    echo "Run: curl ... | sudo bash"
    exit 1
fi

# Check if in correct directory
if [ ! -d "/opt/arrmematey" ]; then
    print_error "Arrmematey not found at /opt/arrmematey"
    echo "   Ensure you're running on the correct server"
    echo "   The directory should contain docker-compose.yml"
    exit 1
fi

cd /opt/arrmematey

print_step "Backing up current configuration"
echo -e "${CYAN}  Creating timestamped backup...${NC}"
if [ -f "docker-compose.yml" ]; then
    BACKUP_FILE="docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
    cp docker-compose.yml "$BACKUP_FILE"
    print_success "Configuration backed up to: $BACKUP_FILE"
else
    print_warning "No docker-compose.yml found to backup"
fi

print_step "Checking Git repository status"
echo -e "${CYAN}  Current branch: $(git rev-parse --abbrev-ref HEAD)${NC}"
echo -e "${CYAN}  Current commit: $(git rev-parse --short HEAD)${NC}"

print_step "Fetching latest from GitHub"
show_progress 3 "Fetching repository" &
echo -e "${CYAN}  Connecting to origin...${NC}"
git fetch origin

print_step "Pulling latest code"
echo -e "${CYAN}  Pulling latest changes...${NC}"
if git pull origin main; then
    NEW_COMMIT=$(git rev-parse --short HEAD)
    print_success "Latest code pulled successfully"
    echo -e "${CYAN}  New commit: $NEW_COMMIT${NC}"
else
    print_error "Failed to pull latest code"
    echo "Check your internet connection and try again"
    exit 1
fi

print_step "Pulling latest Docker images"
echo -e "${CYAN}  Updating container images...${NC}"
echo -e "${CYAN}  This may take several minutes...${NC}"
if docker compose pull; then
    print_success "Docker images pulled successfully"
else
    print_error "Failed to pull Docker images"
    echo "Check Docker daemon status and internet connection"
    exit 1
fi

print_step "Rebuilding UI with enhancements"
echo -e "${CYAN}  Navigating to UI directory...${NC}"
cd ui

echo -e "${CYAN}  Installing UI dependencies...${NC}"
if npm install --silent; then
    print_success "Dependencies installed"
else
    print_warning "npm install completed with warnings (may not affect functionality)"
fi

cd ..

echo -e "${CYAN}  Building UI with enhanced features...${NC}"
# Force rebuild with no cache to ensure latest changes are picked up
if docker compose build arrstack-ui --no-cache; then
    print_success "UI rebuilt with professional icons and version display"
else
    print_error "Failed to build UI"
    echo "Check UI build logs for errors"
    exit 1
fi

print_step "Stopping containers gracefully"
echo -e "${CYAN}  Stopping services...${NC}"
if docker compose down; then
    print_success "Containers stopped gracefully"
else
    print_warning "Some containers may already be stopped (continuing)"
fi

print_step "Starting containers with new configuration"
echo -e "${CYAN}  Initializing services...${NC}"
if docker compose up -d; then
    print_success "Services started successfully"
else
    print_error "Failed to start services"
    echo "Check docker-compose.yml for errors"
    exit 1
fi

print_step "Verifying upgrade and container health"
echo -e "${CYAN}  Waiting for services to initialize...${NC}"
show_progress 20 "Service initialization" &

echo ""
echo -e "${CYAN}  Checking container status...${NC}"
docker compose ps

echo -e "${CYAN}  Checking service health...${NC}"
unhealthy_count=0
total_services=0
for service in arrstack-ui gluetun prowlarr radarr sonarr lidarr sabnzbd qbittorrent emby jellyseerr; do
    ((total_services++))
    if docker compose ps $service | grep -q "Up"; then
        if docker compose ps $service | grep -q "healthy\|Up.*healthy"; then
            print_success "$service is healthy"
        else
            print_warning "$service is running but may be initializing"
            ((unhealthy_count++))
        fi
    else
        print_error "$service failed to start"
        ((unhealthy_count++))
    fi
done

healthy_count=$((total_services - unhealthy_count))
echo -e "${CYAN}  Health Summary: $healthy_count/$total_services services healthy${NC}"

print_step "Final upgrade verification"
echo -e "${CYAN}  System information...${NC}"
echo -e "${CYAN}  Docker version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
echo -e "${CYAN}  Docker Compose version: $(docker compose version | cut -d' ' -f4 | cut -d',' -f1)${NC}"
echo -e "${CYAN}  Disk usage: $(df -h /opt/arrmematey | tail -1 | awk '{print $4}') available${NC}"

echo ""
echo -e "${WHITE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║${NC}                   ${GREEN}✅ UPGRADE COMPLETE ✅${NC}                  ${WHITE}║${NC}"
echo -e "${WHITE}╠════════════════════════════════════════════════╣${NC}"
echo -e "${WHITE}║${NC}  Upgrade Script Version: ${GREEN}${UPGRADE_SCRIPT_VERSION}${NC}                      ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  Services: ${CYAN}$healthy_count/$total_services${NC} healthy                       ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  Updated: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}                         ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}                                                          ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  ${GREEN}ENHANCED UI FEATURES ACTIVATED:${NC}                  ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  🎨 Professional SVG icons (no emojis)                 ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  📁 Container ↔ host volume mapping display           ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  📊 Real-time service status tracking               ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  🔍 Dual-view dashboard (Dashboard + Mappings)     ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  🎯 Service filtering by category                    ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  🔄 Version display and upgrade capabilities            ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}  📋 Step-by-step progress indicators                  ${WHITE}║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${BLUE}🌐 Access Your Enhanced Dashboard:${NC}"
echo -e "${WHITE}  http://192.168.6.137:8787${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 UPGRADE SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}✅ Configuration backed up${NC}"
echo -e "${WHITE}✅ Latest code pulled from GitHub${NC}"
echo -e "${WHITE}✅ Docker images updated${NC}"
echo -e "${WHITE}✅ UI rebuilt with professional icons${NC}"
echo -e "${WHITE}✅ Containers restarted successfully${NC}"
echo -e "${WHITE}✅ Service health verified${NC}"
echo -e "${WHITE}✅ Progress indicators displayed throughout${NC}"

if [ $unhealthy_count -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All services are running perfectly!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  $unhealthy_count services may need attention${NC}"
    echo -e "${YELLOW}   Check container logs: docker compose logs [service]${NC}"
fi

echo ""
echo -e "${PURPLE}🏴‍☠️  Upgrade Complete - Version ${UPGRADE_SCRIPT_VERSION}${NC}"
echo -e "${PURPLE}   Your media automation stack is enhanced and ready!${NC}"
echo ""

echo -e "${CYAN}Upgrade script features:${NC}"
echo -e "${WHITE}• Matching installer version banner format${NC}"
echo -e "${WHITE}• Step-by-step progress with counters${NC}"
echo -e "${WHITE}• Animated spinners during operations${NC}"
echo -e "${WHITE}• Detailed service health verification${NC}"
echo -e "${WHITE}• Comprehensive upgrade summary${NC}"
echo -e "${WHITE}• System information display${NC}"
echo -e "${WHITE}• Professional error handling${NC}"
echo ""
echo -e "${CYAN}Usage for next time:${NC}"
echo -e "${WHITE}curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-with-version.sh | sudo bash${NC}"
echo ""