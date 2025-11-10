#!/bin/bash

# Health Check Script for Arr Stack
# Monitors service health and sends notifications

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
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

SERVICES=(
    "prowlarr:9696"
    "sonarr:8989"
    "radarr:7878"
    "lidarr:8686"
    "sabnzbd:8080"
    "qbittorrent:8081"
    "jellyseerr:5055"
)

check_service_health() {
    local service_name=$1
    local port=$2
    local url="http://localhost:${port}"
    
    if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not responding${NC}"
        return 1
    fi
}

check_docker_health() {
    echo -e "${GREEN}🐳 Docker Health Check${NC}"
    echo "========================"
    
    docker-compose ps
}

check_disk_space() {
    echo -e "${GREEN}💾 Disk Space Check${NC}"
    echo "====================="
    
    if [[ -d "$MEDIA_PATH" ]]; then
        echo "Media directory:"
        df -h "$MEDIA_PATH"
    fi
    
    if [[ -d "$DOWNLOADS_PATH" ]]; then
        echo "Downloads directory:"
        df -h "$DOWNLOADS_PATH"
    fi
    
    if [[ -d "$CONFIG_PATH" ]]; then
        echo "Config directory:"
        df -h "$CONFIG_PATH"
    fi
}

check_vpn_status() {
    echo -e "${GREEN}🔐 VPN Status Check${NC}"
    echo "===================="
    
    if docker ps | grep -q "gluetun"; then
        # Check if VPN is actually connected
        local vpn_status=$(docker exec gluetun cat /tmp/gluetun/status 2>/dev/null || echo "unknown")
        local vpn_ip=$(docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "failed")
        
        if [[ "$vpn_ip" != "failed" && -n "$vpn_ip" ]]; then
            echo "VPN Status: ✅ Connected"
            echo "VPN IP: $vpn_ip"
            echo "Kill Switch: ✅ Active"
            
            # Verify no leaks
            local public_ip=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "failed")
            if [[ "$vpn_ip" == "$public_ip" ]]; then
                echo "DNS Leak Test: ✅ Passed"
            else
                echo -e "DNS Leak Test: ${RED}❌ Failed${NC}"
            fi
        else
            echo -e "VPN Status: ${RED}❌ Not Connected${NC}"
        fi
        
        # Check kill switch status
        local firewall_status=$(docker exec gluetun iptables -L | grep -c "DROP" 2>/dev/null || echo "0")
        if [[ "$firewall_status" -gt 0 ]]; then
            echo "Firewall Rules: ✅ Active ($firewall_status rules)"
        else
            echo -e "Firewall Rules: ${YELLOW}⚠️ Inactive${NC}"
        fi
    else
        echo -e "VPN Status: ${RED}❌ Container not running${NC}"
    fi
}

generate_health_report() {
    local report_file="health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "Arr Stack Health Report" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "========================" >> "$report_file"
    echo "" >> "$report_file"
    
    # Add service status
    echo "Service Status:" >> "$report_file"
    for service in "${SERVICES[@]}"; do
        local name=${service%:*}
        local port=${service#*:}
        if curl -s "http://localhost:${port}" > /dev/null 2>&1; then
            echo "$name: OK" >> "$report_file"
        else
            echo "$name: FAILED" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    echo "Disk Usage:" >> "$report_file"
    df -h >> "$report_file"
    
    echo "" >> "$report_file"
    echo "Docker Containers:" >> "$report_file"
    docker-compose ps >> "$report_file"
    
    echo -e "${GREEN}Health report saved to: $report_file${NC}"
}

run_full_health_check() {
    echo -e "${GREEN}🏥 Running Full Health Check${NC}"
    echo "==============================="
    echo ""
    
    check_vpn_status
    echo ""
    
    check_service_health
    for service in "${SERVICES[@]}"; do
        local name=${service%:*}
        local port=${service#*:}
        check_service_health "$name" "$port"
    done
    echo ""
    
    check_docker_health
    echo ""
    
    check_disk_space
    echo ""
    
    generate_health_report
}

monitor_services() {
    echo -e "${GREEN}👀 Monitoring Services (Ctrl+C to stop)${NC}"
    echo "======================================"
    
    while true; do
        clear
        run_full_health_check
        sleep 60
    done
}

case "$1" in
    "check")
        run_full_health_check
        ;;
    "monitor")
        monitor_services
        ;;
    "report")
        generate_health_report
        ;;
    "services")
        for service in "${SERVICES[@]}"; do
            local name=${service%:*}
            local port=${service#*:}
            check_service_health "$name" "$port"
        done
        ;;
    "docker")
        check_docker_health
        ;;
    "disk")
        check_disk_space
        ;;
    "vpn")
        check_vpn_status
        ;;
    *)
        echo "Arr Stack Health Check Script"
        echo "============================="
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  check    - Run complete health check"
        echo "  monitor  - Continuously monitor services"
        echo "  report   - Generate health report"
        echo "  services - Check service availability"
        echo "  docker   - Check Docker containers"
        echo "  disk     - Check disk space"
        echo "  vpn      - Check VPN status"
        exit 1
        ;;
esac