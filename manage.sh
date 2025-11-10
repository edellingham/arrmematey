#!/bin/bash

# Arr Stack Quick Management Script
# A quick script to manage your Arr stack services

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment
if [[ -f ".env" ]]; then
    source .env
else
    echo -e "${RED}Error: .env file not found. Run setup.sh first.${NC}"
    exit 1
fi

show_status() {
    echo -e "${GREEN}📊 Arr Stack Status${NC}"
    echo "===================="
    docker-compose ps
}

start_services() {
    echo -e "${GREEN}🚀 Starting Arr Stack...${NC}"
    docker-compose up -d
    show_status
}

stop_services() {
    echo -e "${YELLOW}⏹️ Stopping Arr Stack...${NC}"
    docker-compose down
}

restart_services() {
    echo -e "${YELLOW}🔄 Restarting Arr Stack...${NC}"
    docker-compose restart
    show_status
}

update_services() {
    echo -e "${GREEN}🔄 Updating Arr Stack...${NC}"
    docker-compose pull
    docker-compose up -d
    show_status
}

view_logs() {
    if [[ -z "$1" ]]; then
        echo "Available services:"
        echo "sonarr, radarr, lidarr, sabnzbd, qbittorrent, jellyseerr, gluetun, cloudflared, arrstack-ui"
        echo "Usage: $0 logs <service-name>"
    else
        echo -e "${GREEN}📋 Logs for $1:${NC}"
        docker-compose logs -f "$1"
    fi
}

access_ui() {
    echo -e "${GREEN}🌐 Opening Management UI...${NC}"
    xdg-open "http://localhost:${MANAGEMENT_UI_PORT}" 2>/dev/null || \
    open "http://localhost:${MANAGEMENT_UI_PORT}" 2>/dev/null || \
    echo "Management UI available at: http://localhost:${MANAGEMENT_UI_PORT}"
}

backup_config() {
    echo -e "${GREEN}💾 Backing up configurations...${NC}"
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$CONFIG_PATH" ]]; then
        cp -r "$CONFIG_PATH" "$BACKUP_DIR/"
        echo "Configuration backed up to: $BACKUP_DIR"
    else
        echo "Configuration directory not found: $CONFIG_PATH"
    fi
}

case "$1" in
    "status")
        show_status
        ;;
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "update")
        update_services
        ;;
    "logs")
        view_logs "$2"
        ;;
    "ui")
        access_ui
        ;;
    "backup")
        backup_config
        ;;
    *)
        echo "Arr Stack Management Script"
        echo "=========================="
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  status   - Show status of all services"
        echo "  start    - Start all services"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  update   - Pull updates and restart"
        echo "  logs     - View logs (specify service)"
        echo "  ui       - Open management UI"
        echo "  backup   - Backup configurations"
        echo ""
        echo "Services for logs:"
        echo "  sonarr, radarr, lidarr, sabnzbd, qbittorrent, jellyseerr"
        echo "  gluetun, cloudflared, arrstack-ui"
        exit 1
        ;;
esac