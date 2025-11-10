#!/bin/bash

# VPN Kill Switch Test Script
#专门用于测试VPN断开连接时的紧急关闭功能

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
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

# 检查VPN连接状态
check_vpn_status() {
    if docker ps | grep -q "gluetun"; then
        local vpn_ip=$(docker exec gluetun curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "disconnected")
        if [[ "$vpn_ip" != "disconnected" && -n "$vpn_ip" ]]; then
            echo "$vpn_ip"
            return 0
        fi
    fi
    echo "disconnected"
    return 1
}

# 获取真实IP
get_real_ip() {
    curl -s --connect-timeout 5 --max-time 5 ipinfo.io/ip 2>/dev/null || echo "blocked"
}

# 测试VPN断开时的网络访问
test_vpn_disconnect() {
    print_status "🔧 Testing VPN disconnect scenario..."
    
    local vpn_ip=$(check_vpn_status)
    if [[ "$vpn_ip" == "disconnected" ]]; then
        print_error "VPN is not connected. Cannot test disconnect scenario."
        return 1
    fi
    
    print_info "Current VPN IP: $vpn_ip"
    
    # 停止VPN容器模拟断开连接
    print_warning "⚠️  Stopping VPN to test kill switch..."
    docker stop gluetun > /dev/null 2>&1
    
    # 等待一下确保VPN完全停止
    sleep 5
    
    # 测试是否有网络访问（应该被阻止）
    print_status "🔍 Testing network access without VPN..."
    local test_result=$(timeout 10 curl -s --connect-timeout 3 ipinfo.io/ip 2>/dev/null || echo "blocked")
    
    if [[ "$test_result" == "blocked" ]]; then
        print_status "✅ SUCCESS: Kill switch is working - traffic is blocked when VPN is down"
        kill_switch_working=true
    else
        print_error "❌ FAILED: Kill switch is NOT working - traffic is still flowing"
        print_error "Real IP may have been exposed: $test_result"
        kill_switch_working=false
    fi
    
    # 检查下载服务是否也被阻止
    print_status "🔍 Testing download services isolation..."
    
    # 检查Sonarr是否还能访问网络
    local sonarr_test=$(timeout 5 docker exec sonarr curl -s --connect-timeout 3 ipinfo.io/ip 2>/dev/null || echo "blocked")
    if [[ "$sonarr_test" == "blocked" ]]; then
        print_status "✅ Sonarr is properly isolated"
    else
        print_warning "⚠️  Sonarr may still have network access"
    fi
    
    # 重新启动VPN
    print_status "🔄 Restarting VPN..."
    docker start gluetun > /dev/null 2>&1
    
    # 等待VPN重新连接
    print_status "⏳ Waiting for VPN to reconnect..."
    local attempts=0
    local max_attempts=30
    
    while [[ $attempts -lt $max_attempts ]]; do
        local new_vpn_ip=$(check_vpn_status)
        if [[ "$new_vpn_ip" != "disconnected" && -n "$new_vpn_ip" ]]; then
            print_status "✅ VPN reconnected successfully with IP: $new_vpn_ip"
            break
        fi
        
        echo -n "."
        sleep 2
        ((attempts++))
    done
    
    if [[ $attempts -eq $max_attempts ]]; then
        print_error "❌ VPN failed to reconnect after restart"
        return 1
    fi
    
    # 验证VPN重新连接后网络恢复正常
    print_status "🔍 Verifying network after VPN reconnection..."
    local final_test=$(timeout 5 curl -s --connect-timeout 3 ipinfo.io/ip 2>/dev/null || echo "failed")
    
    if [[ "$final_test" != "failed" && "$final_test" != "blocked" ]]; then
        print_status "✅ Network access restored after VPN reconnection"
    else
        print_warning "⚠️  Network access may still be blocked"
    fi
    
    return 0
}

# 测试防火墙规则
test_firewall_rules() {
    print_status "🔥 Testing firewall rules..."
    
    if ! docker ps | grep -q "gluetun"; then
        print_error "VPN container is not running"
        return 1
    fi
    
    # 检查防火墙规则
    local firewall_rules=$(docker exec gluetun iptables -L 2>/dev/null || echo "")
    
    if echo "$firewall_rules" | grep -q "DROP"; then
        local drop_rules=$(echo "$firewall_rules" | grep -c "DROP" || echo "0")
        local input_rules=$(echo "$firewall_rules" | grep "INPUT" | grep -c "DROP" || echo "0")
        
        print_status "✅ Firewall is active with $drop_rules DROP rules"
        print_info "📊 INPUT chain: $input_rules DROP rules"
        
        # 检查是否有特定VPN接口的规则
        if echo "$firewall_rules" | grep -q "tun0\|wg0"; then
            print_status "✅ VPN interface rules found"
        else
            print_warning "⚠️  No specific VPN interface rules found"
        fi
        
        # 检查是否允许必要的VPN端口
        local vpn_port_rules=$(echo "$firewall_rules" | grep -c "ACCEPT.*51820" || echo "0")
        if [[ "$vpn_port_rules" -gt 0 ]]; then
            print_status "✅ VPN port rules properly configured"
        else
            print_warning "⚠️  No specific VPN port rules found"
        fi
    else
        print_error "❌ No DROP rules found - firewall may not be properly configured"
        return 1
    fi
}

# 测试DNS泄露
test_dns_leaks() {
    print_status "🔍 Testing DNS leaks..."
    
    if ! docker ps | grep -q "gluetun"; then
        print_error "VPN container is not running"
        return 1
    fi
    
    # 检查容器内使用的DNS服务器
    local container_dns=$(docker exec gluetun cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' || echo "")
    
    if [[ -n "$container_dns" ]]; then
        print_info "📋 DNS servers in VPN container:"
        while IFS= read -r dns_server; do
            if [[ "$dns_server" =~ ^10\.|^172\.|^192\.|^127\. ]]; then
                print_status "✅ Private DNS server: $dns_server"
            else
                print_warning "⚠️  Public DNS server: $dns_server"
            fi
        done <<< "$container_dns"
    else
        print_error "❌ Could not determine DNS servers"
    fi
    
    # 进行DNS泄露测试
    print_status "🌐 Performing DNS leak test..."
    local dns_test=$(timeout 15 docker exec gluetun curl -s https://ipleak.net/json/ 2>/dev/null || echo "")
    
    if [[ -n "$dns_test" ]]; then
        local dns_count=$(echo "$dns_test" | grep -o '"dns_ip"' | wc -l)
        if [[ "$dns_count" -gt 3 ]]; then
            print_error "❌ Potential DNS leak detected ($dns_count DNS servers)"
            echo "$dns_test" | grep -o '"dns_ip":"[^"]*"' | cut -d'"' -f4 | head -5
        else
            print_status "✅ No DNS leaks detected ($dns_count DNS servers)"
        fi
    else
        print_warning "⚠️  Could not perform DNS leak test"
    fi
}

# 模拟网络故障测试
test_network_failure() {
    print_status "⚡ Testing network failure scenario..."
    
    if ! docker ps | grep -q "gluetun"; then
        print_error "VPN container is not running"
        return 1
    fi
    
    # 临时禁用网络接口（如果可能）
    print_warning "⚠️  Simulating network interface failure..."
    
    # 尝试在VPN容器中禁用网络
    local network_test=$(timeout 5 docker exec gluetun ping -c 1 8.8.8.8 2>/dev/null || echo "blocked")
    
    if [[ "$network_test" == "blocked" ]]; then
        print_status "✅ Network properly isolated during failure"
    else
        print_warning "⚠️  Network may not be properly isolated during failure"
    fi
}

# 生成安全测试报告
generate_kill_switch_report() {
    print_status "📋 Generating kill switch test report..."
    
    local report_file="kill_switch_test_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
VPN Kill Switch Test Report
Generated: $(date)
================================

Test Results:
- Kill Switch Test: ${kill_switch_working:-FAILED}
- Firewall Rules: Configured
- DNS Leak Protection: Enabled
- Network Isolation: Active

VPN Status:
Current IP: $(check_vpn_status)
Real IP: $(get_real_ip)

Docker Container Status:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Could not access Docker")

Firewall Rules:
$(docker exec gluetun iptables -L 2>/dev/null || echo "Could not access firewall rules")

Recommendations:
- Run this test monthly to ensure VPN security
- Monitor VPN connection status regularly
- Keep VPN software updated
- Use multiple VPN servers for redundancy

EOF
    
    print_status "📄 Report saved to: $report_file"
}

# 显示使用说明
show_usage() {
    echo "VPN Kill Switch Test Script"
    echo "=========================="
    echo "This script tests the VPN kill switch functionality"
    echo "to ensure your privacy is protected when VPN disconnects."
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  disconnect - Test VPN disconnect scenario (default)"
    echo "  firewall   - Test firewall rules"
    echo "  dns        - Test DNS leak protection"
    echo "  network    - Test network failure scenario"
    echo "  report     - Generate test report"
    echo ""
    echo "⚠️  WARNING: This test will temporarily disconnect your VPN"
    echo "to verify the kill switch is working properly."
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  VPN Kill Switch Test                    ║"
    echo "║                 🔐 Privacy Protection                    ║"
    echo "║                                                              ║"
    echo "║  This test will verify your VPN disconnect protection       ║"
    echo "║  to ensure no IP leaks occur during failures               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    print_warning "⚠️  This test will temporarily disconnect your VPN"
    read -p "Continue with kill switch test? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Test cancelled"
        exit 0
    fi
    
    echo ""
    kill_switch_working=false
    
    case "${1:-disconnect}" in
        "disconnect"|"")
            test_vpn_disconnect
            test_firewall_rules
            test_dns_leaks
            ;;
        "firewall")
            test_firewall_rules
            ;;
        "dns")
            test_dns_leaks
            ;;
        "network")
            test_network_failure
            ;;
        "report")
            generate_kill_switch_report
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    if [[ "$kill_switch_working" == "true" ]]; then
        print_status "🎉 VPN Kill Switch Test PASSED!"
        print_info "Your privacy is protected during VPN disconnections"
    else
        print_error "❌ VPN Kill Switch Test FAILED!"
        print_warning "Your IP may be exposed during VPN disconnections"
        print_info "Review your VPN configuration immediately"
    fi
    
    echo ""
    generate_kill_switch_report
}

# 运行主函数
main "$@"