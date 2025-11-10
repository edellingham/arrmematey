#!/bin/bash

# Advanced Docker Compose profiles management
# Allows running different service combinations

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment
if [[ -f ".env" ]]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

start_profile() {
    local profile=$1
    echo -e "${GREEN}🚀 Starting profile: $profile${NC}"
    
    case $profile in
        "minimal")
            docker-compose --profile ui up -d
            echo "Started Management UI only"
            ;;
        "media")
            docker-compose --profile media --profile ui up -d
            echo "Started Media services (Sonarr, Radarr, Lidarr) + Management UI"
            ;;
        "downloaders")
            docker-compose --profile downloaders --profile vpn --profile ui up -d
            echo "Started Download services (SABnzbd, qBittorrent) + VPN + Management UI"
            ;;
        "core")
            docker-compose --profile media --profile downloaders --profile vpn --profile ui up -d
            echo "Started core services (media + downloaders + VPN + Management UI)"
            ;;
        "full"|*)
            docker-compose up -d
            echo "Started all services"
            ;;
    esac
}

stop_profile() {
    local profile=$1
    echo -e "${YELLOW}⏹️ Stopping profile: $profile${NC}"
    
    case $profile in
        "minimal")
            docker-compose --profile ui down
            ;;
        "media")
            docker-compose --profile media down
            ;;
        "downloaders")
            docker-compose --profile downloaders down
            ;;
        "vpn")
            docker-compose --profile vpn down
            ;;
        "tunnel")
            docker-compose --profile tunnel down
            ;;
        "ui")
            docker-compose --profile ui down
            ;;
        "full"|*)
            docker-compose down
            ;;
    esac
}

list_profiles() {
    echo -e "${GREEN}📋 Available Profiles:${NC}"
    echo "======================"
    echo "minimal      - Management UI only"
    echo "media        - Sonarr, Radarr, Lidarr + Management UI"
    echo "downloaders  - SABnzbd, qBittorrent + VPN + Management UI"
    echo "core         - Media + Downloaders + VPN + Management UI"
    echo "full         - All services (default)"
    echo ""
    echo "Additional profiles for granular control:"
    echo "vpn          - Gluetun VPN service"
    echo "tunnel       - Cloudflare Tunnel"
    echo "ui           - Management UI"
}

status_profiles() {
    echo -e "${GREEN}📊 Profile Status${NC}"
    echo "================="
    docker-compose ps
}

quick_start() {
    echo -e "${GREEN}⚡ Quick Start Options:${NC}"
    echo "1. Minimal (UI only)"
    echo "2. Media Management"
    echo "3. Download Station"
    echo "4. Full Stack"
    echo ""
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1) start_profile "minimal" ;;
        2) start_profile "media" ;;
        3) start_profile "downloaders" ;;
        4) start_profile "full" ;;
        *) echo "Invalid choice" ;;
    esac
}

case "$1" in
    "start")
        if [[ -z "$2" ]]; then
            quick_start
        else
            start_profile "$2"
        fi
        ;;
    "stop")
        if [[ -z "$2" ]]; then
            stop_profile "full"
        else
            stop_profile "$2"
        fi
        ;;
    "restart")
        stop_profile "${2:-full}"
        sleep 2
        start_profile "${2:-full}"
        ;;
    "list")
        list_profiles
        ;;
    "status")
        status_profiles
        ;;
    *)
        echo "Docker Compose Profile Manager"
        echo "=============================="
        echo "Usage: $0 <command> [profile]"
        echo ""
        echo "Commands:"
        echo "  start [profile] - Start specific profile"
        echo "  stop [profile]  - Stop specific profile"
        echo "  restart [profile] - Restart specific profile"
        echo "  list           - List available profiles"
        echo "  status         - Show current status"
        echo ""
        list_profiles
        exit 1
        ;;
esac