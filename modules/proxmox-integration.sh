###############################################################################
# Proxmox Integration Module
# Handles Proxmox Debian 13 VM creation
###############################################################################

set -euo pipefail

# Color codes (same as main script)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
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

error_exit() {
    print_error "$1"
    exit 1
}

# Check if already on Debian 13 or have Proxmox setup
check_system() {
    print_step "Checking current system..."

    # Check if on Proxmox
    if command -v pveversion &> /dev/null; then
        print_success "Running on Proxmox VE host"

        # Check if already Debian 13
        if grep -q "bullseye\|bookworm" /etc/os-release; then
            print_info "Detected Debian 11/12 - Debian 13 will be installed in VM"
            return 0
        elif grep -q "trixie" /etc/os-release; then
            print_success "Already running Debian 13"
            print_info "No VM creation needed - can install Arrmematey directly"
            return 1  # Signal that we should skip VM creation
        fi
    else
        print_info "Not on Proxmox VE host"
        print_info "Script expects to run on Proxmox for optimal setup"
    fi
}

# Download and execute Proxmox Debian 13 VM script
download_and_run_proxmox_script() {
    print_step "Downloading Proxmox Debian 13 VM installation script..."

    local script_url="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/debian-13-vm.sh"
    local temp_script="/tmp/debian-13-vm.sh"

    if ! curl -fsSL "$script_url" -o "$temp_script"; then
        error_exit "Failed to download Proxmox script"
    fi

    chmod +x "$temp_script"

    print_success "Downloaded Proxmox script successfully"
    print_info "Script location: $temp_script"

    # Show what the script does
    echo ""
    print_info "The Proxmox script will:"
    echo "  - Create a new LXC container"
    echo "  - Install Debian 13 (Trixie)"
    echo "  - Configure basic settings"
    echo "  - Set up networking"
    echo ""
    print_info "You will be prompted for:"
    echo "  - VM ID (default: 9000)"
    echo "  - Hostname (default: debian-13)"
    echo "  - Root password"
    echo "  - Storage location"
    echo ""

    # Execute the script
    print_step "Executing Proxmox Debian 13 VM script..."
    print_warning "The script will run interactively. Please follow the prompts."
    echo ""

    if bash "$temp_script"; then
        print_success "Proxmox Debian 13 VM created successfully!"
        rm -f "$temp_script"
        return 0
    else
        error_exit "Failed to create Proxmox Debian 13 VM"
    fi
}

# Provide instructions for manual execution
manual_proxmox_setup() {
    print_step "Manual Proxmox VM Setup Required"
    echo ""
    print_info "Please execute the following command on your Proxmox host:"
    echo ""
    echo -e "${CYAN}bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/debian-13-vm.sh)\"${NC}"
    echo ""
    print_info "After creating the VM:"
    echo "  1. Note the VM ID"
    echo "  2. Note the VM IP address"
    echo "  3. SSH into the VM: ssh root@[VM-IP]"
    echo "  4. Re-run this installer from within the VM"
    echo ""
    read -p "Press Enter after creating the VM and SSH'ing into it..."
}

# Main function
proxmox_setup() {
    print_step "Checking system for Proxmox integration..."

    # Check system
    local should_create_vm=0
    check_system
    local check_result=$?

    # If check returns 1, we're already on Debian 13, skip VM creation
    if [[ $check_result -eq 1 ]]; then
        print_success "Already on Debian 13 - skipping VM creation"
        return 0
    fi

    # Check if we should create VM
    if command -v pveversion &> /dev/null; then
        should_create_vm=1
    else
        print_warning "Not running on Proxmox host"
        read -p "Do you want to run this script anyway? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Continuing without Proxmox..."
            return 0
        else
            exit 0
        fi
    fi

    if [[ $should_create_vm -eq 1 ]]; then
        echo ""
        print_info "Since you're on Proxmox, we can create a Debian 13 VM for Arrmematey"
        read -p "Create Debian 13 VM automatically? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            download_and_run_proxmox_script
        else
            manual_proxmox_setup
        fi
    fi

    print_success "Proxmox setup phase complete"
}
