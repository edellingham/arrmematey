#!/bin/bash

# Proxmox Single-Line Deployment for Arrmematey
# Run this single command on your Proxmox host to deploy Arrmematey

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_pirate() {
    echo -e "${PURPLE}🏴‍☠️ Captain:${NC} $1"
}

# Single-line deployment function
deploy_arrmematey() {
    print_pirate "Starting single-line Proxmox deployment, captain!"
    print_pirate "Setting up your pirate crew in LXC container..."
    
    # Check if we're on Proxmox
    if ! command -v pct &> /dev/null; then
        print_error "This command must be run on a Proxmox host!"
        exit 1
    fi
    
    print_status "✅ Proxmox environment detected"
    
    # Create temporary directory for the script
    local temp_dir="/tmp/arrmematey-deploy-$(date +%s)"
    mkdir -p "$temp_dir"
    
    # Download the deployment script
    print_status "📥 Downloading Arrmematey deployment script..."
    if curl -fsSL "https://raw.githubusercontent.com/edellingham/arrmematey/main/proxmox-deploy.sh" -o "$temp_dir/proxmox-deploy.sh"; then
        print_status "✅ Deployment script downloaded successfully"
        chmod +x "$temp_dir/proxmox-deploy.sh"
    else
        print_error "❌ Failed to download deployment script"
        exit 1
    fi
    
    # Execute the deployment script
    print_status "🚀 Launching Arrmematey deployment..."
    print_status "Follow the interactive prompts to configure your container"
    echo ""
    
    "$temp_dir/proxmox-deploy.sh"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_pirate "🎉 Arrmematey deployment completed!"
}

# Main execution
case "${1:-deploy}" in
    "deploy"|"")
        deploy_arrmematey
        ;;
    "help"|"-h"|"--help")
        echo "🏴‍☠️ Arrmematey Proxmox Single-Line Deployment"
        echo "=================================================="
        echo ""
        echo "Usage: $0 [deploy|help]"
        echo ""
        echo "Commands:"
        echo "  deploy    (default) Deploy Arrmematey to Proxmox LXC"
        echo "  help      Show this help message"
        echo ""
        echo "Single-line deployment:"
        echo "  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)\""
        echo ""
        echo "🏴‍☠️ Arr... Me Matey! Deploy your pirate crew with one command!"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac