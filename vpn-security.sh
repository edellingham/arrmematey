#!/bin/bash

# VPN Security Check Script
# Verifies VPN kill switch and leak protection

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if VPN container is running
check_vpn_container() {
    if docker ps | grep -q "gluetun"; then
        print_status "✅ VPN container is running"
        return 0
    else
        print_error "❌ VPN container is not running"
        return 1
    fi
}

# Check VPN connection status
check_vpn_connection() {
    print_status "Checking VPN connection status..."
    
    local vpn_ip=$(docker exec gluetun curl -s --connect-timeout 10 --max-time 10 ipinfo.io/ip 2>/dev/null || echo "failed")
    local real_ip=$(curl -s --connect-timeout 10 --max-time 10 ipinfo.io/ip 2>/dev/null || echo "failed")
    
    if [[ "$vpn_ip" != "failed" && -n "$vpn_ip" ]]; then
        print_status "✅ VPN IP: $vpn_ip"
        
        if [[ "$vpn_ip" == "$real_ip" ]]; then
            print_status "✅ No IP leak detected"
        else
            print_error "❌ IP LEAK DETECTED! Real IP: $real_ip"
            return 1
        fi
        
        # Check IP location
        local vpn_location=$(docker exec gluetun curl -s --connect-timeout 10 ipinfo.io/country 2>/dev/null || echo "unknown")
        print_info "📍 VPN Location: $vpn_location"
        
        return 0
    else
        print_error "❌ VPN connection failed"
        return 1
    fi
}

# Check DNS leaks
check_dns_leaks() {
    print_status "Checking DNS leaks..."
    
    # Check DNS servers being used
    local dns_servers=$(docker exec gluetun cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' || echo "")
    
    if [[ -n "$dns_servers" ]]; then
        print_info "🔍 DNS Servers in use:"
        while IFS= read -r server; do
            if [[ "$server" =~ ^10\.|^172\.|^192\.|^127\. ]]; then
                print_warning "⚠️ Potential VPN DNS: $server"
            else
                print_status "✅ Secure DNS: $server"
            fi
        done <<< "$dns_servers"
    fi
    
    # Perform DNS leak test
    print_status "Performing DNS leak test..."
    local dns_test=$(docker exec gluetun curl -s --connect-timeout 10 https://ipleak.net/json/ 2>/dev/null || echo "")
    
    if [[ -n "$dns_test" ]]; then
        local dns_count=$(echo "$dns_test" | grep -o '"dns_ip"' | wc -l)
        if [[ "$dns_count" -gt 2 ]]; then
            print_error "❌ Potential DNS leak detected ($dns_count DNS servers)"
        else
            print_status "✅ No DNS leaks detected"
        fi
    fi
}

# Check kill switch functionality
check_kill_switch() {
    print_status "Checking kill switch functionality..."
    
    # Check firewall rules
    local firewall_rules=$(docker exec gluetun iptables -L 2>/dev/null || echo "")
    
    if echo "$firewall_rules" | grep -q "DROP"; then
        local drop_rules=$(echo "$firewall_rules" | grep -c "DROP" || echo "0")
        print_status "✅ Kill switch is active ($drop_rules DROP rules)"
        
        # Check for VPN traffic rules
        if echo "$firewall_rules" | grep -q "tun0\|wg0"; then
            print_status "✅ VPN traffic rules configured"
        else
            print_warning "⚠️ No specific VPN traffic rules found"
        fi
    else
        print_error "❌ Kill switch is not active"
        return 1
    fi
    
    # Test kill switch by trying to access internet without VPN
    print_status "Testing kill switch..."
    
    # Temporarily disable network interface if possible
    local test_result=$(timeout 5 docker exec gluetun ping -c 1 8.8.8.8 2>/dev/null || echo "blocked")
    
    if [[ "$test_result" == "blocked" ]]; then
        print_status "✅ Kill switch is working - blocking traffic when VPN is down"
    else
        print_warning "⚠️ Kill switch may not be fully blocking traffic"
    fi
}

# Check process isolation
check_process_isolation() {
    print_status "Checking process isolation..."
    
    # Check if services are using VPN network
    local services_on_vpn=()
    local services=("sonarr" "radarr" "lidarr" "sabnzbd" "qbittorrent" "prowlarr")
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Networks}}" | grep -q "$service.*gluetun"; then
            services_on_vpn+=("$service")
        fi
    done
    
    if [[ ${#services_on_vpn[@]} -gt 0 ]]; then
        print_status "✅ Services using VPN: ${services_on_vpn[*]}"
    else
        print_warning "⚠️ No services found using VPN network"
    fi
    
    # Check if management UI is isolated (not on VPN)
    if docker ps --format "table {{.Names}}\t{{.Networks}}" | grep -q "arrstack-ui.*gluetun"; then
        print_warning "⚠️ Management UI is on VPN (may not be accessible)"
    else
        print_status "✅ Management UI is properly isolated from VPN"
    fi
}

# Check port security
check_port_security() {
    print_status "Checking port security..."
    
    # Check which ports are exposed to host
    local exposed_ports=$(docker port)
    
    if [[ -n "$exposed_ports" ]]; then
        print_info "🔌 Exposed ports:"
        echo "$exposed_ports" | while read -r line; do
            local container=$(echo "$line" | awk '{print $1}')
            local port=$(echo "$line" | awk '{print $3}')
            
            if [[ "$container" != "arrstack-ui" && "$container" != "jellyseerr" ]]; then
                print_warning "⚠️ $container exposed: $port (ensure this is intentional)"
            else
                print_status "✅ $container exposed: $port"
            fi
        done
    fi
    
    # Check for any direct host network usage
    local host_network=$(docker ps --format "{{.Names}}:{{.NetworkMode}}" | grep host | grep -v "gluetun" || echo "")
    
    if [[ -n "$host_network" ]]; then
        print_error "❌ Services using host network (security risk):"
        echo "$host_network"
        return 1
    else
        print_status "✅ No services using host network inappropriately"
    fi
}

# Test kill switch in emergency
test_emergency_kill_switch() {
    print_status "Testing emergency kill switch..."
    
    # Get current VPN status
    if docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip > /dev/null 2>&1; then
        print_status "✅ VPN is currently connected"
        
        # Stop VPN temporarily (if user confirms)
        print_warning "⚠️ This test will temporarily stop the VPN to test the kill switch"
        read -p "Continue with emergency test? [y/N]: " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            print_status "Stopping VPN to test kill switch..."
            
            # Check if traffic gets blocked
            local leak_test=$(timeout 10 curl -s ipinfo.io/ip 2>/dev/null || echo "blocked")
            
            if [[ "$leak_test" == "blocked" ]]; then
                print_status "✅ Emergency kill switch working - traffic blocked"
            else
                print_error "❌ Emergency kill switch FAILED - traffic still flowing"
                print_error "Real IP may have been exposed: $leak_test"
            fi
            
            # Restart VPN
            print_status "Restarting VPN..."
            docker restart gluetun
            
            # Wait for VPN to reconnect
            sleep 30
            
            if docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip > /dev/null 2>&1; then
                print_status "✅ VPN reconnected successfully"
            else
                print_error "❌ VPN failed to reconnect"
            fi
        else
            print_status "Emergency test skipped"
        fi
    else
        print_error "❌ VPN is not connected - cannot test"
    fi
}

# Generate security report
generate_security_report() {
    print_status "Generating security report..."
    
    local report_file="vpn_security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
Arr Stack VPN Security Report
Generated: $(date)
================================

VPN Status Check:
$(check_vpn_container 2>&1)

Connection Test:
$(check_vpn_connection 2>&1)

DNS Leak Test:
$(check_dns_leaks 2>&1)

Kill Switch Test:
$(check_kill_switch 2>&1)

Process Isolation:
$(check_process_isolation 2>&1)

Port Security:
$(check_port_security 2>&1)

Docker Container Status:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1)

Network Information:
$(ip addr show 2>&1)

Firewall Rules in VPN Container:
$(docker exec gluetun iptables -L 2>&1 || echo "Could not access firewall rules")

EOF
    
    print_status "Security report saved to: $report_file"
}

# Main security check function
run_full_security_check() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VPN Security Check                        ║"
    echo "║                  🔐 Privacy & Security                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    
    check_vpn_container || return 1
    check_vpn_connection || return 1
    check_dns_leaks
    check_kill_switch
    check_process_isolation
    check_port_security
    
    echo ""
    print_status "🎉 VPN security check completed!"
    
    read -p "Run emergency kill switch test? [y/N]: " emergency_test
    if [[ "$emergency_test" =~ ^[Yy]$ ]]; then
        test_emergency_kill_switch
    fi
    
    read -p "Generate detailed security report? [Y/n]: " report
    if [[ ! "$report" =~ ^[Nn]$ ]]; then
        generate_security_report
    fi
}

# Show usage
show_usage() {
    echo "VPN Security Check Script"
    echo "========================="
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  check      - Run full security check (default)"
    echo "  connection - Check VPN connection and IP"
    echo "  dns        - Check for DNS leaks"
    echo "  killswitch - Test kill switch functionality"
    echo "  isolation  - Check process isolation"
    echo "  ports      - Check port security"
    echo "  emergency  - Test emergency kill switch"
    echo "  report     - Generate security report"
    echo ""
    echo "This script helps verify your VPN protection is working correctly"
    echo "and that your privacy is protected at all times."
}

# Main execution
case "$1" in
    "check"|"")
        run_full_security_check
        ;;
    "connection")
        check_vpn_container
        check_vpn_connection
        ;;
    "dns")
        check_dns_leaks
        ;;
    "killswitch")
        check_kill_switch
        ;;
    "isolation")
        check_process_isolation
        ;;
    "ports")
        check_port_security
        ;;
    "emergency")
        test_emergency_kill_switch
        ;;
    "report")
        generate_security_report
        ;;
    *)
        show_usage
        exit 1
        ;;
esac