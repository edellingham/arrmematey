#!/bin/bash
###############################################################################
# Arrmematey Proxmox Installer - Single Line Installation
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-proxmox-one-line.sh)
#
# Version: 1.0.0
# Last Updated: 2025-11-16
###############################################################################

set -euo pipefail

# Version information
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DATE="2025-11-16"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    echo -e "${PURPLE}║${NC}                                                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Version: ${GREEN}$SCRIPT_VERSION${PURPLE}  |  Date: ${GREEN}$SCRIPT_DATE${PURPLE}               ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print version information
print_version() {
    echo -e "${CYAN}Arrmematey Proxmox Installer${NC}"
    echo -e "  Version: ${GREEN}$SCRIPT_VERSION${NC}"
    echo -e "  Date: ${GREEN}$SCRIPT_DATE${NC}"
    echo -e "  Repository: ${CYAN}https://github.com/edellingham/arrmematey${NC}"
    echo ""
}

# Check for version flag
check_version_flag() {
    if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
        print_version
        exit 0
    fi
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

###############################################################################
# Module Management
###############################################################################

# Download module from GitHub
download_module() {
    local module_name=$1
    # Add version-based cache busting
    local cache_param="v=$SCRIPT_VERSION"
    local module_url="https://raw.githubusercontent.com/edellingham/arrmematey/main/modules/${module_name}.sh?$cache_param"
    local module_file="/tmp/${module_name}.sh"

    print_info "Downloading module: $module_name (v$SCRIPT_VERSION)"

    if ! curl -fsSL "$module_url" -o "$module_file"; then
        error_exit "Failed to download module: $module_name"
    fi

    chmod +x "$module_file"
    print_success "Downloaded: $module_name"

    # Source the module
    source "$module_file"
}

# Download all modules
download_all_modules() {
    print_step "Downloading installer modules..."

    mkdir -p /tmp/arrmematey-installer

    local modules=(
        "proxmox-integration"
        "dependency-manager"
        "docker-storage-setup"
        "arrmematey-installer"
        "config-prompt"
    )

    for module in "${modules[@]}"; do
        download_module "$module"
    done

    print_success "All modules downloaded successfully"
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

    proxmox_setup
}

phase_dependency_check() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 2: Dependency Checking and Installation               ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_and_install_dependencies
}

phase_docker_storage_setup() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 3: Docker Storage Configuration                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    setup_docker_storage
}

phase_arrmematey_install() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 4: Arrmematey Installation                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    install_arrmematey
}

phase_configuration() {
    print_header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  PHASE 5: Configuration                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

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

    # Download all modules
    download_all_modules
    echo ""

    # Run all phases
    phase_proxmox_setup
    echo ""

    phase_dependency_check
    echo ""

    phase_docker_storage_setup
    echo ""

    phase_arrmematey_install
    echo ""

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

    # Cleanup
    print_step "Cleaning up temporary files..."
    rm -rf /tmp/arrmematey-installer
    print_success "Cleanup complete"
}

###############################################################################
# Entry Point
###############################################################################

main() {
    # Check for version flag first
    check_version_flag "$@"

    check_root
    select_install_mode
    run_installation
}

# Run main function
main "$@"
