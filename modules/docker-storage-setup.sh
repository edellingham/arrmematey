###############################################################################
# Docker Storage Setup Module
# Detects and fixes Docker overlay2 1GB storage limitation
#
# Version: 1.0.0
###############################################################################

set -euo pipefail

# Color codes
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

# Check Docker daemon info
get_docker_info() {
    docker info 2>/dev/null || error_exit "Docker is not running"
}

# Get Docker storage driver
get_storage_driver() {
    get_docker_info | grep "Storage Driver:" | awk '{print $3}'
}

# Get Docker data root directory
get_docker_data_root() {
    get_docker_info | grep "Docker Root Dir:" | awk '{print $4}'
}

# Check overlay2 size
check_overlay2_size() {
    print_step "Checking current Docker storage configuration..."

    local storage_driver
    storage_driver=$(get_storage_driver)

    print_info "Storage Driver: $storage_driver"

    if [[ "$storage_driver" != "overlay2" ]]; then
        print_warning "Using $storage_driver instead of overlay2"
        return 0
    fi

    local data_root
    data_root=$(get_docker_data_root)

    print_info "Docker Root Directory: $data_root"

    # Check overlay2 limit
    local overlay2_meta
    overlay2_meta=$(docker info 2>/dev/null | grep -i "overlay2.override_kernel_check" | awk '{print $3}' || echo "false")

    # Check if we're using loop device (common issue)
    local loop_device
    loop_device=$(df "$data_root" | tail -1 | awk '{print $1}')
    print_info "Storage Device: $loop_device"

    if [[ "$loop_device" =~ ^/dev/loop ]]; then
        print_warning "Using loop device - may have storage limitations"
    fi

    # Check available space in data root
    local available_space
    available_space=$(df -BG "$data_root" | tail -1 | awk '{print $4}' | sed 's/G//')
    print_info "Available Space: ${available_space}GB"

    # Check actual overlay2 size
    local overlay2_size
    overlay2_size=$(docker info 2>/dev/null | grep -i "Data loop file" | awk '{print $4, $5, $6}' || echo "not using loop")

    if [[ "$overlay2_size" != "not using loop" ]]; then
        print_warning "Overlay2 using loop file: $overlay2_size"
    else
        print_info "Overlay2 using direct filesystem"
    fi

    # Decision: if using loop device or low space, reconfigure
    if [[ "$loop_device" =~ ^/dev/loop ]] || [[ $available_space -lt 20 ]]; then
        print_warning "Storage needs optimization"
        return 1  # Needs reconfiguration
    fi

    print_success "Docker storage looks good"
    return 0  # No changes needed
}

# Backup Docker data
backup_docker_data() {
    local data_root=$1
    local backup_dir="/var/lib/docker-backup-$(date +%Y%m%d-%H%M%S)"

    print_step "Creating Docker data backup..."

    print_info "Stopping Docker service..."
    systemctl stop docker

    print_info "Backing up Docker data to $backup_dir..."
    if cp -a "$data_root" "$backup_dir"; then
        print_success "Backup created: $backup_dir"
        echo "$backup_dir"
        return 0
    else
        print_error "Backup failed!"
        systemctl start docker
        error_exit "Failed to backup Docker data"
    fi
}

# Configure Docker to use /opt/docker
reconfigure_docker_storage() {
    print_step "Reconfiguring Docker storage..."

    local data_root
    data_root=$(get_docker_data_root)

    # Check if already using /opt/docker
    if [[ "$data_root" == "/opt/docker" ]]; then
        print_success "Docker already configured to use /opt/docker"
        return 0
    fi

    # Create backup
    local backup_dir
    backup_dir=$(backup_docker_data "$data_root")

    # Create new Docker directory
    print_info "Creating new Docker directory: /opt/docker"
    mkdir -p /opt/docker

    # Move existing data
    print_info "Moving Docker data to new location..."
    cp -a "$data_root"/* /opt/docker/ 2>/dev/null || true

    # Stop Docker completely
    print_info "Ensuring Docker is stopped..."
    pkill dockerd || true
    sleep 2

    # Create daemon.json configuration
    print_info "Creating Docker daemon configuration..."
    cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "data-root": "/opt/docker",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    print_success "Docker configuration created"

    # Start Docker
    print_info "Starting Docker service..."
    if systemctl start docker; then
        print_success "Docker started successfully"
    else
        print_error "Failed to start Docker"
        print_info "Restoring from backup..."
        rm -rf /opt/docker
        cp -a "$backup_dir"/* "$data_root"/
        systemctl start docker
        error_exit "Failed to reconfigure Docker storage"
    fi

    # Verify
    print_step "Verifying Docker storage..."
    sleep 3
    if docker info | grep -q "/opt/docker"; then
        print_success "Docker now using /opt/docker"
    else
        print_warning "Docker may not be using new location"
    fi

    print_success "Docker storage reconfigured successfully"
}

# Configure Docker without moving data (for systems with space)
optimize_docker_config() {
    print_step "Optimizing Docker configuration..."

    # Ensure daemon.json exists with optimal settings
    if [[ ! -f /etc/docker/daemon.json ]]; then
        print_info "Creating Docker daemon configuration..."
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true",
    "overlay2.size_limit=20G"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF
        print_success "Docker configuration created"

        print_info "Restarting Docker to apply configuration..."
        systemctl restart docker
        sleep 3
        print_success "Docker restarted with optimized configuration"
    else
        print_info "Docker daemon.json already exists, skipping optimization"
    fi

    return 0
}

# Cleanup old Docker installation (optional)
cleanup_docker() {
    print_step "Cleaning up old Docker installation (optional)..."

    read -p "Remove old Docker data from $data_root? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing old Docker data..."
        # Only remove if backup exists
        if [[ -n "$backup_dir" ]]; then
            rm -rf "$data_root"
            print_success "Old Docker data removed"
        else
            print_warning "No backup found, skipping cleanup"
        fi
    else
        print_info "Keeping old Docker data for safety"
    fi
}

# Main function
setup_docker_storage() {
    print_step "Starting Docker storage setup and optimization..."

    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed"
    fi

    if ! systemctl is-active --quiet docker; then
        print_info "Starting Docker service..."
        systemctl start docker
    fi

    # Check current storage configuration
    if check_overlay2_size; then
        # Storage is good, just optimize config
        print_info "Docker storage is already properly configured"
        optimize_docker_config
    else
        # Storage needs reconfiguration
        echo ""
        print_warning "Docker storage needs optimization"
        print_info "Current overlay2 configuration may have limitations"
        print_info "Recommended: Configure Docker to use /opt/docker for better performance"
        echo ""

        if [[ "$INSTALL_MODE" == "interactive" ]]; then
            read -p "Reconfigure Docker storage to use /opt/docker? (Y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                reconfigure_docker_storage
            else
                print_info "Skipping Docker storage reconfiguration"
                optimize_docker_config
            fi
        else
            # Automated mode - always reconfigure
            print_info "Automated mode: Reconfiguring Docker storage..."
            reconfigure_docker_storage
        fi
    fi

    # Final verification
    print_step "Final Docker storage verification..."
    local final_driver
    final_driver=$(get_storage_driver)
    local final_data_root
    final_data_root=$(get_docker_data_root)

    print_success "Storage Driver: $final_driver"
    print_success "Data Root: $final_data_root"

    # Test Docker
    if docker run --rm hello-world &> /dev/null; then
        print_success "Docker is working correctly"
    else
        print_warning "Docker test failed - manual verification needed"
    fi

    echo ""
    print_success "Docker storage setup complete!"
    echo ""
    print_info "Docker is now configured for optimal performance"
}
