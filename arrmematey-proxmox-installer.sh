#!/bin/bash
###############################################################################
# Arrmematey Proxmox Installer
# Complete automated installation of Proxmox + Arrmematey media stack
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory and module directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/modules"

# Installation mode
INSTALL_MODE=""

###############################################################################
# Utility Functions
###############################################################################

print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  🏴‍☠️  ARRMEMATEY PROXMOX INSTALLER  🏴‍☠️                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Automated Proxmox + Arrmematey Deployment                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Complete media automation stack with VPN protection          ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

check_proxmox() {
    if ! command -v pveversion &> /dev/null; then
        print_warning "Not running on a Proxmox VE host"
        print_info "This installer expects to be run on Proxmox VE host"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Load module if it exists
load_module() {
    local module_name="$1"
    local module_file="${MODULE_DIR}/${module_name}.sh"

    if [[ ! -f "$module_file" ]]; then
        error_exit "Module not found: $module_file"
    fi

    source "$module_file"
    print_success "Loaded module: $module_name"
}

###############################################################################
# Mode Selection
###############################################################################

select_install_mode() {
    print_header
    echo -e "${CYAN}Choose installation mode:${NC}"
    echo ""
    echo "  1) Automated Mode"
    echo "     - Uses sensible defaults"
    echo "     - Minimal user interaction"
    echo "     - Best for experienced users"
    echo ""
    echo "  2) Interactive Mode"
    echo "     - User controls each step"
    echo "     - More options and choices"
    echo "     - Best for customization"
    echo ""
    read -p "Select option (1 or 2): " choice

    case $choice in
        1)
            INSTALL_MODE="automated"
            echo -e "${GREEN}Selected: Automated Mode${NC}"
            ;;
        2)
            INSTALL_MODE="interactive"
            echo -e "${GREEN}Selected: Interactive Mode${NC}"
            ;;
        *)
            error_exit "Invalid choice. Please select 1 or 2."
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
}

###############################################################################
# Installation Phases
###############################################################################

phase_proxmox_setup() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 1: Proxmox Debian 13 VM Setup                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_module "proxmox-integration"
    proxmox_setup
}

phase_dependency_check() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 2: Dependency Checking and Installation               ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_module "dependency-manager"
    check_and_install_dependencies
}

phase_docker_storage_setup() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 3: Docker Storage Configuration                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_module "docker-storage-setup"
    setup_docker_storage
}

phase_arrmematey_install() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 4: Arrmematey Installation                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_module "arrmematey-installer"
    install_arrmematey
}

phase_configuration() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 5: Configuration                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_module "config-prompt"
    configure_arrmematey
}

###############################################################################
# Main Installation Flow
###############################################################################

run_installation() {
    print_header

    echo -e "${GREEN}Starting Arrmematey installation in ${INSTALL_MODE} mode...${NC}"
    echo ""
    echo -e "${CYAN}Installation will proceed through these phases:${NC}"
    echo "  1. Proxmox Debian 13 VM Setup"
    echo "  2. Dependency Checking and Installation"
    echo "  3. Docker Storage Configuration"
    echo "  4. Arrmematey Installation"
    echo "  5. Configuration"
    echo ""

    if [[ "$INSTALL_MODE" == "interactive" ]]; then
        read -p "Continue with installation? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    echo ""
    print_step "Beginning installation process..."

    # Create module directory if it doesn't exist
    mkdir -p "$MODULE_DIR"

    # Run all phases
    phase_proxmox_setup
    phase_dependency_check
    phase_docker_storage_setup
    phase_arrmematey_install
    phase_configuration

    # Installation complete
    print_header
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  🎉 INSTALLATION COMPLETE! 🎉                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_success "Arrmematey is now installed and configured!"
    echo ""
    print_info "Your media automation stack is ready:"
    echo "  - Management UI: http://[VM-IP]:8080"
    echo "  - Prowlarr: http://[VM-IP]:9696"
    echo "  - Sonarr: http://[VM-IP]:8989"
    echo "  - Radarr: http://[VM-IP]:7878"
    echo ""
    print_info "Access your VM and start using Arrmematey!"
    echo ""
}

###############################################################################
# Entry Point
###############################################################################

main() {
    check_root
    select_install_mode
    run_installation
}

# Run main function
main "$@"
