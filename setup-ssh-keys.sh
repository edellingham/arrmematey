#!/bin/bash
###############################################################################
# SSH Key Setup for Arrmematey
# Easily setup SSH keys for password-less file transfer
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  🔑 SSH KEY SETUP FOR ARRMEMATEY  🔑                      ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if we're on local or remote
check_location() {
    echo "Where are you running this script?"
    echo "  1. Local machine (where Mullvad zip is)"
    echo "  2. Remote server (where to install Arrmematey)"
    echo ""
    read -p "Select option [1-2]: " choice

    if [[ "$choice" == "1" ]]; then
        setup_local
    elif [[ "$choice" == "2" ]]; then
        setup_server
    else
        print_error "Invalid option"
        exit 1
    fi
}

# Setup on local machine
setup_local() {
    print_header
    echo -e "${CYAN}LOCAL MACHINE SETUP${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    # Check for Mullvad zip
    if ! ls mullvad_wireguard*.zip 1> /dev/null 2>&1; then
        print_error "Mullvad zip file not found!"
        echo ""
        echo "Please download it first from:"
        echo "https://mullvad.net/en/account/#/wireguard-config"
        echo ""
        exit 1
    fi

    print_success "Found Mullvad zip file"
    echo ""

    # Get server details
    echo "Enter your server details:"
    read -p "Server IP/Hostname: " server
    read -p "Username: " username
    read -p "SSH Port [22]: " port
    port=${port:-22}

    # Generate SSH key if doesn't exist
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        print_info "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "arrmematey-transfer"
        print_success "SSH key generated: ~/.ssh/id_rsa"
    else
        print_info "SSH key already exists: ~/.ssh/id_rsa"
    fi

    # Copy public key to server
    print_info "Copying public key to server..."
    if ssh-copy-id -p "$port" "$username@$server"; then
        print_success "SSH key copied to server"
    else
        print_error "Failed to copy SSH key"
        echo ""
        echo "Manual method:"
        echo "  cat ~/.ssh/id_rsa.pub"
        echo "  (copy output and paste into server's ~/.ssh/authorized_keys)"
        echo ""
        exit 1
    fi

    # Test connection
    print_info "Testing SSH connection..."
    if ssh -p "$port" -o BatchMode=yes "$username@$server" "echo 'SSH connection successful'" 2>/dev/null; then
        print_success "SSH connection working!"
    else
        print_error "SSH connection failed"
        exit 1
    fi

    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo -e "${GREEN}✅ READY TO TRANSFER!${NC}"
    echo ""
    echo "Your SSH key is configured. You can now transfer files:"
    echo ""
    echo "  scp -P $port mullvad_wireguard*.zip $username@$server:/opt/arrmematey/"
    echo ""
    echo "Then SSH to server and run installer:"
    echo "  ssh $username@$server"
    echo "  cd /opt/arrmematey"
    echo "  ./install-arrmematey.sh"
    echo ""
}

# Setup on remote server
setup_server() {
    print_header
    echo -e "${CYAN}REMOTE SERVER SETUP${NC}"
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    print_info "Installing Arrmematey..."

    # Check for Mullvad zip
    if ! ls mullvad_wireguard*.zip 1> /dev/null 2>&1; then
        print_warning "Mullvad zip not found on server"
        echo ""
        echo "Options:"
        echo "1. Transfer from local using the SSH key method"
        echo "2. Download directly if you have a download link"
        echo ""
        echo "Press Enter after transferring the file..."
        read

        if ! ls mullvad_wireguard*.zip 1> /dev/null 2>&1; then
            print_error "Still not found. Exiting."
            exit 1
        fi
    fi

    print_success "Found Mullvad zip file"
    echo ""

    # Download installer
    if [[ ! -f install-arrmematey.sh ]]; then
        print_info "Downloading Arrmematey installer..."
        curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh -o install-arrmematey.sh
        chmod +x install-arrmematey.sh
    fi

    print_success "Installer ready"
    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo -e "${GREEN}🚀 RUNNING INSTALLER${NC}"
    echo ""
    ./install-arrmematey.sh
}

main() {
    if [[ $# -eq 0 ]]; then
        check_location
    else
        print_header
        case "$1" in
            "local")
                setup_local
                ;;
            "server")
                setup_server
                ;;
            *)
                echo "Usage: $0 [local|server]"
                echo "  local  - Setup on local machine (with zip file)"
                echo "  server - Setup on remote server (to install)"
                exit 1
                ;;
        esac
    fi
}

main "$@"
