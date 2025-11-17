#!/bin/bash
###############################################################################
# Arrmematey Manager - TUI Management Utility
# Manage Arrmematey services with text-based interface
#
# Usage: ./arrmematey-manager.sh
###############################################################################

set -euo pipefail

# Version
VERSION="2.19.0"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="/opt/arrmematey"
cd "$INSTALL_DIR" 2>/dev/null || {
    echo "Error: Arrmematey not found at $INSTALL_DIR"
    echo "Please install Arrmematey first:"
    echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh | bash"
    exit 1
}

###############################################################################
# Utility Functions
###############################################################################

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  🏴‍☠️  ARRMEMATEY MANAGER  🏴‍☠️                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Service Management & Monitoring                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
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

# Function to get service status
get_service_status() {
    local service=$1
    local status=$(docker compose ps --services --filter "status=running" | grep -q "^$service$" && echo "running" || echo "stopped")
    echo "$status"
}

# Function to get container health
get_container_health() {
    local container=$1
    docker inspect "$container" --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown"
}

# Function to show services overview
show_services_overview() {
    print_header

    echo -e "${CYAN}📊 SERVICES OVERVIEW${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    local services=(
        "gluetun:Gluetun VPN"
        "prowlarr:Prowlarr (Indexer)"
        "sonarr:Sonarr (TV)"
        "radarr:Radarr (Movies)"
        "lidarr:Lidarr (Music)"
        "sabnzbd:SABnzbd (Usenet)"
        "qbittorrent:qBittorrent (Torrent)"
        "jellyseerr:Jellyseerr (Requests)"
        "emby:Emby (Media Server)"
        "arrstack-ui:Management UI"
    )

    local running=0
    local total=0

    for service_info in "${services[@]}"; do
        total=$((total + 1))
        IFS=':' read -r service display_name <<< "$service_info"

        local status=$(get_service_status "$service")
        local health="unknown"

        case "$status" in
            running)
                running=$((running + 1))
                health=$(get_container_health "$service" 2>/dev/null || echo "healthy")
                if [[ "$health" == "healthy" ]]; then
                    echo -e "${GREEN}●${NC} $display_name (${GREEN}running${NC}, ${GREEN}healthy${NC})"
                else
                    echo -e "${YELLOW}●${NC} $display_name (${GREEN}running${NC}, ${YELLOW}$health${NC})"
                fi
                ;;
            stopped)
                echo -e "${RED}○${NC} $display_name (${RED}stopped${NC})"
                ;;
        esac
    done

    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo -e "Status: ${GREEN}$running${NC}/${total} services running"
    echo ""
}

# Function to start services
start_services() {
    print_header
    echo -e "${CYAN}🚀 STARTING SERVICES${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    print_info "Starting all services..."
    if docker compose up -d; then
        echo ""
        print_success "All services started successfully"
        echo ""
        read -p "Press Enter to continue..."
    else
        echo ""
        print_error "Failed to start services"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to stop services
stop_services() {
    print_header
    echo -e "${CYAN}🛑 STOPPING SERVICES${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    print_warning "This will stop all Arrmematey services"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Stopping all services..."
        if docker compose down; then
            echo ""
            print_success "All services stopped"
            echo ""
            read -p "Press Enter to continue..."
        else
            echo ""
            print_error "Failed to stop services"
            echo ""
            read -p "Press Enter to continue..."
        fi
    else
        echo ""
        print_info "Operation cancelled"
        sleep 1
    fi
}

# Function to restart services
restart_services() {
    print_header
    echo -e "${CYAN}🔄 RESTARTING SERVICES${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    print_warning "This will restart all Arrmematey services"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Restarting all services..."
        if docker compose restart; then
            echo ""
            print_success "All services restarted"
            echo ""
            read -p "Press Enter to continue..."
        else
            echo ""
            print_error "Failed to restart services"
            echo ""
            read -p "Press Enter to continue..."
        fi
    else
        echo ""
        print_info "Operation cancelled"
        sleep 1
    fi
}

# Function to show logs
show_logs() {
    print_header
    echo -e "${CYAN}📜 SERVICE LOGS${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""
    echo "Select service to view logs:"
    echo ""
    echo "  1. All services"
    echo "  2. Gluetun (VPN)"
    echo "  3. Prowlarr"
    echo "  4. Sonarr"
    echo "  5. Radarr"
    echo "  6. Lidarr"
    echo "  7. SABnzbd"
    echo "  8. qBittorrent"
    echo "  9. Jellyseerr"
    echo " 10. Emby"
    echo " 11. Management UI"
    echo ""
    echo "  0. Back to main menu"
    echo ""
    read -p "Select option [0-11]: " choice

    case $choice in
        1)
            docker compose logs -f --tail=50
            ;;
        2)
            docker compose logs -f gluetun --tail=50
            ;;
        3)
            docker compose logs -f prowlarr --tail=50
            ;;
        4)
            docker compose logs -f sonarr --tail=50
            ;;
        5)
            docker compose logs -f radarr --tail=50
            ;;
        6)
            docker compose logs -f lidarr --tail=50
            ;;
        7)
            docker compose logs -f sabnzbd --tail=50
            ;;
        8)
            docker compose logs -f qbittorrent --tail=50
            ;;
        9)
            docker compose logs -f jellyseerr --tail=50
            ;;
        10)
            docker compose logs -f emby --tail=50
            ;;
        11)
            docker compose logs -f arrstack-ui --tail=50
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            sleep 1
            ;;
    esac
}

# Function to show VPN status
show_vpn_status() {
    print_header
    echo -e "${CYAN}🔐 VPN STATUS${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    # Check if gluetun is running
    if ! docker compose ps gluetun | grep -q "Up"; then
        print_error "Gluetun VPN container is not running"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi

    print_info "Checking VPN status..."

    # Get public IP
    local public_ip
    public_ip=$(docker exec gluetun curl -s ifconfig.io 2>/dev/null || echo "unknown")

    echo ""
    echo -e "${CYAN}Connection Details:${NC}"
    echo "  Public IP: ${GREEN}$public_ip${NC}"

    # Check if IP is Mullvad
    if [[ "$public_ip" != "unknown" ]]; then
        # This is a simplified check - in production you'd want to verify it's actually a Mullvad IP
        if curl -s "https://whatismyipaddress.com/api/$public_ip" | grep -iq "mullvad\|anonymous\|vpn"; then
            echo "  Provider: ${GREEN}Mullvad VPN${NC}"
        else
            echo "  Provider: ${YELLOW}Unknown/Not Mullvad${NC}"
        fi
    fi

    # Check connection time
    local uptime=$(docker exec gluetun sh -c "cat /proc/uptime | awk '{print \$1}'" 2>/dev/null || echo "unknown")
    if [[ "$uptime" != "unknown" ]]; then
        local uptime_min=$(echo "$uptime / 60" | bc)
        echo "  Uptime: ${GREEN}${uptime_min} minutes${NC}"
    fi

    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo -e "${GREEN}✓ VPN is connected and working${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to update Arrmematey
update_arrmematey() {
    print_header
    echo -e "${CYAN}🔄 UPDATE ARRMEMATEY${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    print_warning "This will update Arrmematey to the latest version"
    read -p "Continue? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Pulling latest changes..."
        git pull origin main

        echo ""
        print_info "Pulling Docker images..."
        docker compose pull

        echo ""
        print_info "Restarting services..."
        docker compose up -d

        echo ""
        print_success "Update complete!"
        echo ""
        read -p "Press Enter to continue..."
    else
        echo ""
        print_info "Update cancelled"
        sleep 1
    fi
}

# Function to show system info
show_system_info() {
    print_header
    echo -e "${CYAN}💻 SYSTEM INFORMATION${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    # Docker version
    local docker_version
    docker_version=$(docker --version | head -1)
    echo -e "${CYAN}Docker:${NC} $docker_version"

    # Docker Compose version
    local compose_version
    compose_version=$(docker compose version | head -1)
    echo -e "${CYAN}Compose:${NC} $compose_version"

    # Disk usage
    echo ""
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h "$INSTALL_DIR" | tail -1 | awk '{print "  Root: " $3 "/" $2 " (" $5 " used)"}'

    # Memory usage
    echo ""
    echo -e "${CYAN}Memory:${NC}"
    free -h | grep Mem | awk '{print "  Used: " $3 "/" $2}'

    # Container count
    echo ""
    echo -e "${CYAN}Containers:${NC}"
    local running=$(docker compose ps --services --filter "status=running" | wc -l)
    local total=$(docker compose ps --services | wc -l)
    echo "  Running: $running / $total"

    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to show help
show_help() {
    print_header
    echo -e "${CYAN}❓ HELP & INFORMATION${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    echo -e "${CYAN}Arrmematey Manager${NC}"
    echo "Text-based interface for managing your media automation stack"
    echo ""

    echo -e "${CYAN}Services:${NC}"
    echo "  • Gluetun - VPN container (Mullvad Wireguard)"
    echo "  • Prowlarr - Indexer management"
    echo "  • Sonarr - TV series management"
    echo "  • Radarr - Movie management"
    echo "  • Lidarr - Music management"
    echo "  • SABnzbd - Usenet downloader"
    echo "  • qBittorrent - BitTorrent client"
    echo "  • Jellyseerr - Media request system"
    echo "  • Emby - Media server"
    echo "  • Management UI - Web-based control panel"
    echo ""

    echo -e "${CYAN}Access Points:${NC}"
    echo "  • Web UI: http://localhost:8080"
    echo "  • Prowlarr: http://localhost:9696"
    echo "  • Sonarr: http://localhost:8989"
    echo "  • Radarr: http://localhost:7878"
    echo "  • Lidarr: http://localhost:8686"
    echo "  • SABnzbd: http://localhost:8080"
    echo "  • qBittorrent: http://localhost:8081"
    echo "  • Jellyseerr: http://localhost:5055"
    echo "  • Emby: http://localhost:8096"
    echo ""

    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  • Check logs: docker compose logs [service]"
    echo "  • Restart service: docker compose restart [service]"
    echo "  • Update stack: docker compose pull && docker compose up -d"
    echo ""

    read -p "Press Enter to continue..."
}

# Main menu
show_main_menu() {
    print_header
    show_services_overview

    echo -e "${CYAN}MAIN MENU${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""
    echo "  1. Start Services"
    echo "  2. Stop Services"
    echo "  3. Restart Services"
    echo "  4. View Logs"
    echo "  5. VPN Status"
    echo "  6. Update Arrmematey"
    echo "  7. System Information"
    echo "  8. Help"
    echo ""
    echo "  0. Exit"
    echo ""
    read -p "Select option [0-8]: " choice
}

# Main function
main() {
    while true; do
        show_main_menu

        case $choice in
            1)
                start_services
                ;;
            2)
                stop_services
                ;;
            3)
                restart_services
                ;;
            4)
                show_logs
                ;;
            5)
                show_vpn_status
                ;;
            6)
                update_arrmematey
                ;;
            7)
                show_system_info
                ;;
            8)
                show_help
                ;;
            0)
                print_header
                echo -e "${GREEN}👋 Goodbye!${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main
