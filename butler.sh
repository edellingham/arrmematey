#!/bin/bash

# Arrmematey Butler - Your Trustworthy Media Butler
# This script provides butler-themed commands and interactions

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

butler_greet() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎭 Arrmematey Butler                  ║"
    echo "║                                                              ║"
    echo "║  At your service! Your trustworthy media butler.          ║"
    echo "║  I arrange everything perfectly!                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

butler_speak() {
    echo -e "${PURPLE}🎭 Butler:${NC} $1"
}

butler_notify() {
    echo -e "${GREEN}✅ Butler:${NC} $1"
}

butler_warning() {
    echo -e "${YELLOW}⚠️ Butler:${NC} $1"
}

butler_error() {
    echo -e "${RED}❌ Butler:${NC} $1"
}

# Butler's service status with personality
butler_service_status() {
    butler_speak "Let me check on your services, master..."
    echo ""
    
    if docker-compose ps | grep -q "Up"; then
        butler_notify "All services are running perfectly! ✨"
        
        echo -e "${PURPLE}🎭 Butler's Service Report:${NC}"
        echo "======================================"
        docker-compose ps
    else
        butler_warning "Some services need attention, master."
        docker-compose ps
    fi
}

# Butler's health check with flair
butler_health_check() {
    butler_speak "Performing comprehensive health examination..."
    
    if command -v ./health.sh &> /dev/null; then
        ./health.sh check
        butler_notify "Health examination complete, master!"
    else
        butler_error "Health check script not found, master."
    fi
}

# Butler's security check
butler_security_audit() {
    butler_speak "Checking security arrangements, master..."
    
    if command -v ./vpn-security.sh &> /dev/null; then
        ./vpn-security.sh check
        butler_notify "Security arrangements verified, master!"
    else
        butler_warning "Security script not found, master."
    fi
}

# Butler's management interface
butler_manage_services() {
    local action=$1
    local service=$2
    
    case $action in
        "start")
            butler_speak "Starting services as requested, master..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh start $service
            else
                docker-compose start $service
            fi
            butler_notify "Services started successfully, master!"
            ;;
        "stop")
            butler_speak "Stopping services as requested, master..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh stop $service
            else
                docker-compose stop $service
            fi
            butler_notify "Services stopped successfully, master!"
            ;;
        "restart")
            butler_speak "Restarting services as requested, master..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh restart $service
            else
                docker-compose restart $service
            fi
            butler_notify "Services restarted successfully, master!"
            ;;
        "logs")
            butler_speak "Fetching service logs, master..."
            if command -v ./manage.sh &> /dev/null && [[ -n "$service" ]]; then
                ./manage.sh logs $service
            else
                docker-compose logs -f
            fi
            ;;
        "status"|*)
            butler_service_status
            ;;
    esac
}

# Butler's daily routine
butler_daily_routine() {
    butler_greet
    butler_speak "Good day, master! Let me run my daily routine..."
    echo ""
    
    butler_notify "🧹 Tidying up system health..."
    butler_health_check
    echo ""
    
    butler_notify "🔐 Arranging security measures..."
    butler_security_audit
    echo ""
    
    butler_notify "📊 Checking service status..."
    butler_service_status
    echo ""
    
    butler_notify "🎭 Daily routine complete, master!"
    butler_speak "Everything is arranged perfectly! 🍿"
}

# Butler's quick status
butler_quick_status() {
    echo -e "${PURPLE}🎭 Butler's Quick Status:${NC}"
    echo "============================="
    
    local running=$(docker-compose ps | grep "Up" | wc -l)
    local total=$(docker-compose ps | wc -l)
    
    if [[ $running -eq $total && $total -gt 0 ]]; then
        butler_notify "All $running services are running perfectly, master! ✨"
    elif [[ $running -gt 0 ]]; then
        butler_warning "$running of $total services are running, master."
    else
        butler_error "No services are currently running, master."
    fi
    
    # Check VPN status
    if docker ps | grep -q "gluetun"; then
        local vpn_ip=$(docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "disconnected")
        if [[ "$vpn_ip" != "disconnected" && -n "$vpn_ip" ]]; then
            butler_notify "🔐 VPN is active and protecting your privacy, master!"
        else
            butler_warning "⚠️ VPN may be disconnected, master."
        fi
    fi
}

# Butler's assistance menu
butler_show_menu() {
    echo -e "${PURPLE}🎭 Butler's Assistance Menu:${NC}"
    echo "=============================="
    echo ""
    echo "📋 Daily Routine Commands:"
    echo "  daily      - Run butler's complete daily routine"
    echo "  status     - Butler's quick service status report"
    echo "  health     - Butler's health examination"
    echo "  security   - Butler's security arrangements check"
    echo ""
    echo "🔧 Service Management:"
    echo "  start      - Start services (butler's way)"
    echo "  stop       - Stop services (butler's way)"
    echo "  restart    - Restart services (butler's way)"
    echo "  logs       - View service logs (butler's inspection)"
    echo ""
    echo "🏠 Household Management:"
    echo "  greet      - Butler's formal greeting"
    echo "  announce   - Butler makes an announcement"
    echo "  tidy       - Butler tidies up configurations"
    echo "  backup     - Butler backs up household items"
    echo ""
    echo "🌐 Butler's Interface:"
    echo "  ui         - Open butler's management interface"
    echo "  ports      - Show all butler's service ports"
    echo ""
    echo "🎭 Butler's Personality:"
    echo "  quote      - Butler shares wisdom"
    echo "  weather    - Butler checks the weather (for mood)"
    echo "  announce   - Butler makes a special announcement"
    echo ""
    echo -e "${CYAN}Usage: $0 <command> [service]${NC}"
}

# Butler's greeting
butler_greet_master() {
    butler_greet
    butler_speak "At your service, master! How may I assist you today? 🎭"
}

# Butler's announcement
butler_announce() {
    local message="${1:-'Your butler is always at your service! 🎭'}"
    echo ""
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    📢 Butler Announcement                  ║"
    echo "║                                                              ║"
    printf "║  %-56s  ║\n" "$message"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Butler's wisdom quotes
butler_share_wisdom() {
    local quotes=(
        "A well-arranged media library is a thing of beauty, master. 🍿"
        "Patience is a virtue, even when waiting for downloads, master. ⏳"
        "Quality over quantity, always, master. ✨"
        "Privacy is paramount, master. I always keep your connections secure. 🔐"
        "A good butler anticipates needs before they arise, master. 🎭"
        "Organization is the key to happiness, master. 📚"
        "Your media collection reflects your excellent taste, master. 🌟"
        "Even butlers need their beauty sleep, master. 😴"
    )
    
    local random_quote=${quotes[$RANDOM % ${#quotes[@]}]}
    butler_speak "$random_quote"
}

# Butler's backup routine
butler_backup_household() {
    butler_speak "Backing up household configurations, master..."
    
    if command -v ./manage.sh &> /dev/null; then
        ./manage.sh backup
        butler_notify "Backup completed successfully, master!"
    else
        butler_error "Backup script not found, master."
    fi
}

# Butler's port display
butler_show_ports() {
    butler_speak "Here are all the household service ports, master:"
    echo ""
    
    echo -e "${PURPLE}🎭 Butler's Service Ports:${NC}"
    echo "============================="
    echo "• Management UI: http://localhost:8080 (butler's control room)"
    echo "• Prowlarr: http://localhost:9696 (indexer manager)"
    echo "• Sonarr: http://localhost:8989 (TV series butler)"
    echo "• Radarr: http://localhost:7878 (movie butler)"
    echo "• Lidarr: http://localhost:8686 (music butler)"
    echo "• SABnzbd: http://localhost:8080 (usenet butler)"
    echo "• qBittorrent: http://localhost:8081 (torrent butler)"
    echo "• Jellyseerr: http://localhost:5055 (request butler)"
    echo ""
    butler_notify "All ports are arranged perfectly, master! 🎭"
}

# Butler's UI launch
butler_open_ui() {
    butler_speak "Opening the butler's management interface, master..."
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:8080" 2>/dev/null
    elif command -v open &> /dev/null; then
        open "http://localhost:8080" 2>/dev/null
    else
        butler_notify "Management UI available at: http://localhost:8080, master"
    fi
    
    butler_notify "Management interface opened, master! 🎭"
}

# Main function
butler_main() {
    local command="${1:-help}"
    local service="$2"
    
    case $command in
        "greet"|"hello"|"hi")
            butler_greet_master
            ;;
        "daily"|"routine")
            butler_daily_routine
            ;;
        "status"|"report")
            butler_quick_status
            ;;
        "health"|"checkup")
            butler_health_check
            ;;
        "security"|"audit")
            butler_security_audit
            ;;
        "start")
            butler_manage_services "start" "$service"
            ;;
        "stop")
            butler_manage_services "stop" "$service"
            ;;
        "restart")
            butler_manage_services "restart" "$service"
            ;;
        "logs"|"inspection")
            butler_manage_services "logs" "$service"
            ;;
        "backup"|"archive")
            butler_backup_household
            ;;
        "ports"|"services")
            butler_show_ports
            ;;
        "ui"|"interface")
            butler_open_ui
            ;;
        "quote"|"wisdom")
            butler_share_wisdom
            ;;
        "announce")
            butler_announce "$service"
            ;;
        "help"|"menu"|"")
            butler_show_menu
            ;;
        *)
            butler_warning "Unknown command: $command, master."
            butler_speak "Let me show you how I can assist..."
            echo ""
            butler_show_menu
            ;;
    esac
}

# Run the butler
butler_main "$@"