###############################################################################
# Proxmox Integration Module
# Handles Proxmox Debian 13 VM creation
#
# Version: 1.0.0
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

# Check if we're on Debian 13 (Trixie)
check_debian_version() {
    # Check if OS is Debian and version is Trixie (Debian 13)
    if grep -q "^ID=debian" /etc/os-release; then
        local version_codename
        version_codename=$(grep "^VERSION_CODENAME=" /etc/os-release | cut -d= -f2)

        if [[ "$version_codename" == "trixie" ]]; then
            return 0  # Already on Debian 13
        fi
    fi
    return 1  # Not on Debian 13
}

# Check if already on Debian 13 or have Proxmox setup
check_system() {
    print_step "Checking current system..."

    # First, check if we're already on Debian 13 (running in a VM or on bare metal)
    if check_debian_version; then
        print_success "Detected Debian 13 (Trixie)"
        print_info "Already running on Debian 13 - skipping VM creation"
        print_info "Proceeding directly to Arrmematey installation"
        return 1  # Signal that we should skip VM creation
    fi

    # Check if on Proxmox
    if command -v pveversion &> /dev/null; then
        print_success "Running on Proxmox VE host"
        print_info "Debian 13 not detected - VM creation required"

        local current_os
        current_os=$(grep "^VERSION_CODENAME=" /etc/os-release | cut -d= -f2)
        print_info "Current OS: $current_os"
        print_info "Will create Debian 13 VM for Arrmematey"
        return 0  # Need to create VM
    else
        print_info "Not on Proxmox VE host"
        print_info "Script expects to run on Proxmox for optimal setup"
        print_info "Alternatively, if you're already on Debian 13 VM, this script will work"
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
    print_warning "⚠ IMPORTANT: VM Resource Allocation"
    echo ""
    print_info "The default settings from the community script may be insufficient."
    print_info "After the script creates the VM, you MUST manually increase resources:"
    echo ""
    echo -e "${CYAN}Required Resources:${NC}"
    echo "  • CPU: 2-4 cores (minimum 2)"
    echo "  • RAM: 4-8 GB (minimum 4)"
    echo "  • Storage: 40-100 GB (minimum 40)"
    echo ""
    print_info "To modify resources after VM creation:"
    echo "  1. Shutdown the VM"
    echo "  2. In Proxmox Web UI: Hardware → Edit"
    echo "  3. Increase CPU, RAM, and Disk size"
    echo "  4. Start the VM"
    echo "  5. SSH into VM and re-run installer"
    echo ""

    if [[ "$INSTALL_MODE" == "interactive" ]]; then
        print_info "The Proxmox script will prompt you for:"
        echo "  - VM ID (default: 9000)"
        echo "  - Hostname (default: debian-13)"
        echo "  - Root password"
        echo "  - Storage location"
        echo ""
        read -p "After VM creation, edit resources and press Enter to continue..."
    fi

    # Execute the script
    print_step "Executing Proxmox Debian 13 VM script..."
    print_warning "The script will run interactively. Please follow the prompts."
    echo ""

    if bash "$temp_script"; then
        print_success "Proxmox Debian 13 VM created successfully!"
        rm -f "$temp_script"

        echo ""
        print_warning "⚠ Don't forget to increase VM resources as shown above!"
        echo ""
        print_info "Once you've edited the VM resources and started it:"
        print_info "  1. SSH into the VM: ssh root@[VM-IP]"
        print_info "  2. Re-run installer: bash <(curl -fsSL .../arrmematey-proxmox-one-line.sh)"
        echo ""

        if [[ "$INSTALL_MODE" == "interactive" ]]; then
            read -p "Press Enter after you've edited the VM resources..."
        fi

        return 0
    else
        error_exit "Failed to create Proxmox Debian 13 VM"
    fi
}

# Display recommended VM resources
show_recommended_resources() {
    print_step "Recommended VM Resources for Arrmematey"
    echo ""
    echo -e "${CYAN}Minimum Requirements:${NC}"
    echo "  • CPU: 2 cores"
    echo "  • RAM: 4 GB (4,096 MB)"
    echo "  • Storage: 40 GB"
    echo ""
    echo -e "${CYAN}Recommended for Production:${NC}"
    echo "  • CPU: 4 cores"
    echo "  • RAM: 8 GB (8,192 MB)"
    echo "  • Storage: 100 GB"
    echo ""
    print_warning "The default Proxmox VM script may allocate fewer resources!"
    echo ""
    echo -e "${YELLOW}⚠ Important:${NC} You'll need to configure VM resources manually or edit the VM after creation."
    echo ""
}

# Provide instructions for manual execution
manual_proxmox_setup() {
    print_step "Manual Proxmox VM Setup Required"
    echo ""
    show_recommended_resources

    print_info "Step 1: Create VM with adequate resources"
    echo "  1. Go to Proxmox Web UI"
    echo "  2. Create a new LXC container"
    echo "  3. Allocate resources (see recommended above)"
    echo "  4. Use Debian 13 (Trixie) template"
    echo "  5. Note the VM ID and IP address"
    echo ""
    print_info "Step 2: SSH into the VM"
    echo "  ssh root@[VM-IP]"
    echo ""
    print_info "Step 3: Re-run installer from within VM"
    echo "  bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-proxmox-one-line.sh)"
    echo ""
    read -p "Press Enter after creating the VM with adequate resources and SSH'ing into it..."
}

# Check VM resources (if running in VM)
check_vm_resources() {
    print_step "Checking VM resources..."

    # Check RAM
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))

    # Check CPU
    local cpu_cores
    cpu_cores=$(nproc)

    # Check storage
    local root_avail_gb
    root_avail_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

    echo ""
    echo -e "${CYAN}Current VM Resources:${NC}"
    echo "  • CPU: $cpu_cores cores"
    echo "  • RAM: ${total_mem_gb} GB"
    echo "  • Storage: ${root_avail_gb}GB available"
    echo ""

    # Check minimums
    local issues=0

    if [[ $cpu_cores -lt 2 ]]; then
        print_warning "CPU cores ($cpu_cores) below recommended (2+)"
        issues=$((issues + 1))
    fi

    if [[ $total_mem_gb -lt 4 ]]; then
        print_warning "RAM (${total_mem_gb}GB) below recommended (4GB+)"
        issues=$((issues + 1))
    fi

    if [[ $root_avail_gb -lt 20 ]]; then
        print_warning "Storage (${root_avail_gb}GB) below recommended (40GB+)"
        issues=$((issues + 1))
    fi

    if [[ $issues -gt 0 ]]; then
        echo ""
        print_error "VM resources are insufficient for Arrmematey!"
        echo ""
        print_info "Please:"
        echo "  1. Shutdown the VM"
        echo "  2. Increase resources in Proxmox"
        echo "  3. Restart VM"
        echo "  4. Re-run this installer"
        echo ""
        if [[ "$INSTALL_MODE" == "interactive" ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_warning "Installation aborted due to insufficient resources"
                exit 1
            fi
        else
            print_warning "Automated mode: Insufficient resources detected"
            print_warning "Installation may fail or have performance issues"
            print_info "Recommend at least 4GB RAM, 2 CPU cores, 40GB storage"
        fi
    else
        print_success "VM resources are adequate"
    fi
}

# Main function
proxmox_setup() {
    print_step "Checking system for Proxmox integration..."

    # Check system
    check_system
    local check_result=$?

    # If check returns 1, we're already on Debian 13, skip VM creation
    if [[ $check_result -eq 1 ]]; then
        # Already on Debian 13 - skip VM creation
        print_success "Detected Debian 13 - skipping VM creation"
        echo ""
        print_info "Proceeding to check VM resources and install Arrmematey..."
        echo ""

        # Check VM resources
        check_vm_resources

        print_success "Proxmox setup phase complete"
        return 0
    fi

    # Show resource requirements when creating VM
    show_recommended_resources

    # If we're on Proxmox, offer to create VM
    if command -v pveversion &> /dev/null; then
        echo ""
        print_info "Since you're on Proxmox, we can create a Debian 13 VM for Arrmematey"
        print_warning "Make sure to allocate adequate resources (see above)!"
        echo ""
        read -p "Create Debian 13 VM automatically? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            download_and_run_proxmox_script
        else
            manual_proxmox_setup
        fi
    else
        # Not on Proxmox and not on Debian 13
        print_warning "Not on Proxmox and not on Debian 13"
        print_warning "You'll need to create a VM manually with adequate resources"
        read -p "Do you want to create a VM manually and re-run this script? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            manual_proxmox_setup
        else
            exit 0
        fi
    fi

    print_success "Proxmox setup phase complete"
}
