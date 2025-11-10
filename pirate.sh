#!/bin/bash

# Arrmematey Pirate Crew - Arr... Me Matey!
# This script provides pirate-themed commands and interactions

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

pirate_greet() {
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 🏴‍☠️ Arrmematey - Arr... Me Matey!      ║"
    echo "║                                                              ║"
    echo "║  Ahoy! Your trusty pirate crew for media treasure!       ║"
    echo "║  We find all of booty!                                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

pirate_speak() {
    echo -e "${RED}🏴‍☠️ Captain:${NC} $1"
}

pirate_notify() {
    echo -e "${GREEN}✅ Crew:${NC} $1"
}

pirate_warning() {
    echo -e "${YELLOW}⚠️ Lookout:${NC} $1"
}

pirate_error() {
    echo -e "${RED}❌ Mutiny:${NC} $1"
}

# Pirate crew service status
pirate_service_status() {
    pirate_speak "Let me check on the crew, captain..."
    echo ""
    
    if docker-compose ps | grep -q "Up"; then
        pirate_notify "All hands on deck! Crew is ready for action! ✨"
        
        echo -e "${RED}🏴‍☠️ Captain's Crew Report:${NC}"
        echo "=================================="
        docker-compose ps
    else
        pirate_warning "Some crew members are sleeping, captain."
        docker-compose ps
    fi
}

# Pirate crew health check
pirate_health_check() {
    pirate_speak "Checking the ship's condition, captain..."
    
    if command -v ./health.sh &> /dev/null; then
        ./health.sh check
        pirate_notify "Ship is in perfect condition, captain!"
    else
        pirate_error "Ship's log not found, captain."
    fi
}

# Pirate crew security check
pirate_security_audit() {
    pirate_speak "Checking for enemy ships and spies, captain..."
    
    if command -v ./vpn-security.sh &> /dev/null; then
        ./vpn-security.sh check
        pirate_notify "All clear! No enemies spotted, captain!"
    else
        pirate_warning "Lookout not on duty, captain."
    fi
}

# Pirate crew management
pirate_manage_crew() {
    local action=$1
    local service=$2
    
    case $action in
        "start")
            pirate_speak "All hands on deck! Starting crew..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh start $service
            else
                docker-compose start $service
            fi
            pirate_notify "Crew is ready for action, captain!"
            ;;
        "stop")
            pirate_speak "Stand down! Crew taking a rest..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh stop $service
            else
                docker-compose stop $service
            fi
            pirate_notify "Crew is resting, captain!"
            ;;
        "restart")
            pirate_speak "All hands on deck again! Restarting crew..."
            if command -v ./manage.sh &> /dev/null; then
                ./manage.sh restart $service
            else
                docker-compose restart $service
            fi
            pirate_notify "Crew is back in action, captain!"
            ;;
        "logs")
            pirate_speak "Reading the ship's log, captain..."
            if command -v ./manage.sh &> /dev/null && [[ -n "$service" ]]; then
                ./manage.sh logs $service
            else
                docker-compose logs -f
            fi
            ;;
        "status"|*)
            pirate_service_status
            ;;
    esac
}

# Pirate crew daily routine
pirate_daily_routine() {
    pirate_greet
    pirate_speak "Ahoy, captain! Let's prepare the ship for today's treasure hunt..."
    echo ""
    
    pirate_notify "🧹 Swabbing the deck... (health check)"
    pirate_health_check
    echo ""
    
    pirate_notify "🔐 Checking for enemy ships... (security check)"
    pirate_security_audit
    echo ""
    
    pirate_notify "📊 Checking crew status..."
    pirate_service_status
    echo ""
    
    pirate_notify "🏴‍☠️ Ship is ready for treasure hunting!"
    pirate_speak "All systems shipshape! Let's find some booty! 🍿"
}

# Pirate quick status
pirate_quick_status() {
    echo -e "${RED}🏴‍☠️ Captain's Quick Status:${NC}"
    echo "==============================="
    
    local running=$(docker-compose ps | grep "Up" | wc -l)
    local total=$(docker-compose ps | wc -l)
    
    if [[ $running -eq $total && $total -gt 0 ]]; then
        pirate_notify "All $running crew members are ready for action, captain! ✨"
    elif [[ $running -gt 0 ]]; then
        pirate_warning "$running of $total crew members are ready, captain."
    else
        pirate_error "No crew members are currently on duty, captain."
    fi
    
    # Check VPN status
    if docker ps | grep -q "gluetun"; then
        local vpn_ip=$(docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "disconnected")
        if [[ "$vpn_ip" != "disconnected" && -n "$vpn_ip" ]]; then
            pirate_notify "🔐 Ship is in stealth mode and protected, captain!"
        else
            pirate_warning "⚠️ Ship may be visible to enemies, captain."
        fi
    fi
}

# Pirate assistance menu
pirate_show_menu() {
    echo -e "${RED}🏴‍☠️ Captain's Commands Menu:${NC}"
    echo "=============================="
    echo ""
    echo "📋 Daily Treasure Hunt Commands:"
    echo "  daily      - Captain's complete daily routine"
    echo "  status     - Captain's quick crew status report"
    echo "  health     - Ship's condition check"
    echo "  security   - Check for enemy ships and spies"
    echo ""
    echo "🔧 Crew Management:"
    echo "  start      - Get crew on deck"
    echo "  stop       - Crew takes shore leave"
    echo "  restart    - Get crew back on deck"
    echo "  logs       - Read the ship's log"
    echo ""
    echo "🏠 Ship Management:"
    echo "  greet      - Captain's formal greeting"
    echo "  announce   - Captain makes announcement"
    echo "  tidy       - Swab the deck"
    echo "  backup     - Protect treasure maps"
    echo ""
    echo "🌐 Navigation:"
    echo "  ui         - Open captain's command bridge"
    echo "  ports      - Show all crew stations"
    echo ""
    echo "🏴‍☠️ Pirate Life:"
    echo "  chant      - Crew sings sea shanty"
    echo "  weather    - Check the winds"
    echo "  announce   - Captain makes special announcement"
    echo "  treasure   - Show today's treasure found"
    echo ""
    echo -e "${CYAN}Usage: $0 <command> [crew-member]${NC}"
}

# Captain's greeting
pirate_greet_captain() {
    pirate_greet
    pirate_speak "Ahoy, captain! What treasure shall we hunt today? 🏴‍☠️"
}

# Captain's announcement
pirate_announce() {
    local message="${1:-'Arr... me matey! All hands on deck for treasure hunting! 🏴‍☠️'}"
    echo ""
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    📢 Captain's Announcement          ║"
    echo "║                                                              ║"
    printf "║  %-56s  ║\n" "$message"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Crew sings sea shanty
pirate_sing_chant() {
    local shanties=(
        "🎵 Yo ho ho and a bottle of media! 🍿"
        "🎵 Fifteen men on a dead media server! 🏴‍☠️"
        "🎵 We're downloading till the sun goes down! 🌅"
        "🎵 Arr... me matey! We found treasure! 💰"
        "🎵 Haul the streams and set the sails! ⛵"
        "🎵 We hunt for booty day and night! 🌙"
        "🎵 VPN be our shield from enemy ships! 🛡️"
        "🎵 More media than a pirate can count! 📊"
    )
    
    local random_shanty=${shanties[$RANDOM % ${#shanties[@]}]}
    pirate_speak "$random_shanty"
    
    echo -e "${CYAN}"
    echo "🎵⚓ The crew sings along... ⚓🎵"
    echo "~~ Yo ho ho, ho ho ho ~~"
    echo "~~ Downloading booty, make it show ~~"
    echo "~~ VPN protects us, don't you know ~~"
    echo "~~ Arr... me matey, here we go! ~~"
    echo "⚓🎵 Ahoy! ⚓🎵"
    echo -e "${NC}"
}

# Show today's treasure
pirate_show_treasure() {
    pirate_speak "Let's count today's treasure, captain..."
    
    local media_count=0
    if [[ -d "$HOME/Media" ]]; then
        media_count=$(find "$HOME/Media" -type f 2>/dev/null | wc -l)
    fi
    
    local download_count=0
    if [[ -d "$HOME/Downloads" ]]; then
        download_count=$(find "$HOME/Downloads/complete" -type f 2>/dev/null | wc -l)
    fi
    
    pirate_notify "🏴‍☠️ Today's Treasure Report:"
    echo "  Media Library: $media_count pieces of treasure"
    echo "  Downloaded Today: $download_count new pieces of booty"
    echo "  Total Value: Priceless to the captain!"
    echo ""
    pirate_speak "The crew has brought in quite a haul, captain! 💰"
}

# Pirate crew backup
pirate_backup_treasure() {
    pirate_speak "Protecting treasure maps, captain..."
    
    if command -v ./manage.sh &> /dev/null; then
        ./manage.sh backup
        pirate_notify "Treasure maps are safely stored, captain!"
    else
        pirate_error "Treasure chest not found, captain."
    fi
}

# Pirate crew port display
pirate_show_ports() {
    pirate_speak "Here are all of the crew's stations, captain:"
    echo ""
    
    echo -e "${RED}🏴‍☠️ Captain's Crew Stations:${NC}"
    echo "==============================="
    echo "• Command Bridge: http://localhost:8080 (captain's quarters)"
    echo "• Navigator: http://localhost:9696 (treasure mapping)"
    echo "• TV Crew: http://localhost:8989 (TV series hunters)"
    echo "• Movie Crew: http://localhost:7878 (movie hunters)"
    echo "• Music Crew: http://localhost:8686 (music hunters)"
    echo "• Usenet Crew: http://localhost:8080 (deep sea divers)"
    echo "• Torrent Crew: http://localhost:8081 (fast swimmers)"
    echo "• Request Officer: http://localhost:5055 (wish fulfillment)"
    echo ""
    pirate_notify "All stations are ready for treasure hunting! 🏴‍☠️"
}

# Pirate UI launch
pirate_open_ui() {
    pirate_speak "Opening the captain's command bridge..."
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:8080" 2>/dev/null
    elif command -v open &> /dev/null; then
        open "http://localhost:8080" 2>/dev/null
    else
        pirate_notify "Command bridge available at: http://localhost:8080, captain"
    fi
    
    pirate_notify "Command bridge ready, captain! 🏴‍☠️"
}

# Main function
pirate_main() {
    local command="${1:-help}"
    local service="$2"
    
    case $command in
        "greet"|"ahoy"|"hello"|"hi")
            pirate_greet_captain
            ;;
        "daily"|"routine"|"hunt")
            pirate_daily_routine
            ;;
        "status"|"report"|"crew")
            pirate_quick_status
            ;;
        "health"|"condition"|"ship")
            pirate_health_check
            ;;
        "security"|"enemies"|"spies")
            pirate_security_audit
            ;;
        "start")
            pirate_manage_crew "start" "$service"
            ;;
        "stop")
            pirate_manage_crew "stop" "$service"
            ;;
        "restart")
            pirate_manage_crew "restart" "$service"
            ;;
        "logs"|"log"|"journal")
            pirate_manage_crew "logs" "$service"
            ;;
        "backup"|"treasure"|"maps")
            pirate_backup_treasure
            ;;
        "ports"|"stations"|"crew-stations")
            pirate_show_ports
            ;;
        "ui"|"bridge"|"command")
            pirate_open_ui
            ;;
        "chant"|"sing"|"shanty")
            pirate_sing_chant
            ;;
        "announce")
            pirate_announce "$service"
            ;;
        "treasure"|"booty"|"haul")
            pirate_show_treasure
            ;;
        "help"|"menu"|"")
            pirate_show_menu
            ;;
        *)
            pirate_warning "Unknown command: $command, captain."
            pirate_speak "Let me show you how we hunt treasure..."
            echo ""
            pirate_show_menu
            ;;
    esac
}

# Run pirate crew
pirate_main "$@"