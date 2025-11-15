#!/bin/bash

# Proxmox Arrmematey LXC Deployment Script
# Creates and configures LXC container with Docker and Arrmematey

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_pirate() {
    echo -e "${PURPLE}🏴‍☠️ Captain:${NC} $1"
}

get_available_space() {
    local target="$1"
    if [[ -d "$target" ]]; then
        df -h "$target" 2>/dev/null | awk 'NR==2{print $4}' || echo "N/A"
    else
        echo "N/A"
    fi
}

normalize_storage_path() {
    local path="${1:-}"
    path="${path#/}"
    path="${path%/}"
    printf '%s' "$path"
}

add_unique_path() {
    local -n target_array=$1
    local raw_path=$2
    local normalized
    normalized="$(normalize_storage_path "$raw_path")"
    [[ -z "$normalized" ]] && return

    for existing in "${target_array[@]:-}"; do
        [[ "$existing" == "$normalized" ]] && return
    done

    target_array+=("$normalized")
}

ensure_host_directory() {
    local host_path="$1"
    [[ -z "$host_path" ]] && return
    if [[ ! -d "$host_path" ]]; then
        if mkdir -p "$host_path"; then
            print_status "Created host storage path: $host_path"
        else
            print_warning "Unable to create host storage path: $host_path (will proceed)"
        fi
    fi
}

# Check if running on Proxmox
check_proxmox() {
    if ! command -v pct &> /dev/null; then
        print_error "This script must be run on a Proxmox host with 'pct' command available."
        exit 1
    fi
    
    if ! command -v pveversion &> /dev/null; then
        print_warning "pveversion command not found, but proceeding anyway..."
    fi
    
    print_status "✅ Proxmox environment detected"
}

# Get Proxmox storage pools
get_storage_pools() {
    print_pirate "Scanning available storage pools, captain..."
    
    local storages=$(pvesm status -content vztmpl -json 2>/dev/null | jq -r '.[] | .storage' 2>/dev/null || echo "local")
    echo "$storages"
}

# Get available CT templates
get_ct_templates() {
    print_pirate "Checking available CT templates..."
    
    local templates=$(pvesm list -content vztmpl -json 2>/dev/null | jq -r '.[] | select(.volid | contains("ubuntu") or contains("debian")) | .volid' 2>/dev/null || echo "")
    if [[ -z "$templates" ]]; then
        print_warning "No Ubuntu/Debian templates found. You may need to download one first."
        print_info "Download templates from: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pve_2_ct_templates"
    fi
    echo "$templates"
}

# Get host storage locations
get_host_storage() {
    print_pirate "Scanning host storage locations..."

    # Create arrays for storage options
    local media_paths=()
    local download_paths=()
    local config_paths=()

    local home_dir
    home_dir=$(getent passwd "$(logname)" | cut -d: -f6)

    local default_media_dirs=("/mnt/media" "/mnt/tv" "/mnt/movies" "/mnt/music")
    for path in "${default_media_dirs[@]}"; do
        [[ -d "$path" ]] && add_unique_path media_paths "$path"
    done

    if [[ -n "$home_dir" ]]; then
        [[ -d "$home_dir/Media" ]] && add_unique_path media_paths "$home_dir/Media"
        [[ -d "$home_dir/Downloads" ]] && add_unique_path download_paths "$home_dir/Downloads"
    fi

    [[ -d "/data" ]] && add_unique_path media_paths "/data"
    [[ -d "/data/downloads" ]] && add_unique_path download_paths "/data/downloads"
    [[ -d "/mnt/downloads" ]] && add_unique_path download_paths "/mnt/downloads"

    # Detect ZFS mountpoints as additional storage options
    if command -v zfs &> /dev/null; then
        while read -r mountpoint; do
            [[ -z "$mountpoint" ]] && continue
            [[ "$mountpoint" == "none" || "$mountpoint" == "legacy" || "$mountpoint" == "/" ]] && continue
            add_unique_path media_paths "$mountpoint"
            add_unique_path download_paths "$mountpoint"
        done < <(zfs list -H -o mountpoint | sort -u)
    fi

    # Fallback defaults if nothing detected
    [[ ${#media_paths[@]} -eq 0 ]] && add_unique_path media_paths "/mnt/media"
    [[ ${#download_paths[@]} -eq 0 ]] && add_unique_path download_paths "/mnt/downloads"

    # Default config backup location
    add_unique_path config_paths "$home_dir/arrmematey-config"
    [[ -d "/mnt/config" ]] && add_unique_path config_paths "/mnt/config/arrmematey"

    # Store in global variables
    AVAILABLE_MEDIA_PATHS=("${media_paths[@]}")
    AVAILABLE_DOWNLOAD_PATHS=("${download_paths[@]}")
    AVAILABLE_CONFIG_PATHS=("${config_paths[@]}")
}

# Interactive storage selection
select_storage() {
    echo ""
    print_pirate "Select storage locations to pass through to container:"
    echo "================================================================="
    
    # Media storage selection
    echo ""
    echo "🎬 Media Storage (for your media library):"
    if [[ ${#AVAILABLE_MEDIA_PATHS[@]} -gt 0 ]]; then
        for i in "${!AVAILABLE_MEDIA_PATHS[@]}"; do
            local path="${AVAILABLE_MEDIA_PATHS[$i]}"
            local display="/$path"
            local size=$(get_available_space "$display")
            echo "  $((i+1))) $display [$size available]"
        done
        echo "  $((i+2))) Custom path"
    else
        echo "  1) Custom path (no common locations found)"
    fi
    
    echo ""
    read -p "Select media storage (number): " media_selection
    
    # Download storage selection
    echo ""
    echo "📥 Download Storage (for downloads):"
    if [[ ${#AVAILABLE_DOWNLOAD_PATHS[@]} -gt 0 ]]; then
        for i in "${!AVAILABLE_DOWNLOAD_PATHS[@]}"; do
            local path="${AVAILABLE_DOWNLOAD_PATHS[$i]}"
            local display="/$path"
            local size=$(get_available_space "$display")
            echo "  $((i+1))) $display [$size available]"
        done
        echo "  $((i+2))) Custom path"
    else
        echo "  1) Custom path (no common locations found)"
    fi
    
    echo ""
    read -p "Select download storage (number): " download_selection
    
    # Config backup selection
    echo ""
    echo "💾 Config Backup Storage (for Docker configs):"
    echo "  1) /$(logname)/arrmematey-config"
    if [[ -d "/mnt/config" ]]; then
        echo "  2) /mnt/config/arrmematey"
    fi
    echo "  3) Custom path"
    echo ""
    read -p "Select config storage (number): " config_selection
    
    echo ""
}

# Get custom paths if needed
get_custom_paths() {
    CUSTOM_MEDIA_PATH=""
    CUSTOM_DOWNLOAD_PATH=""
    CUSTOM_CONFIG_PATH=""
    
    # Custom media path
    if [[ "$media_selection" -eq $((${#AVAILABLE_MEDIA_PATHS[@]} + 1)) ]]; then
        read -p "Enter custom media path (e.g., /mnt/my-media): " CUSTOM_MEDIA_PATH
        if [[ ! -d "$CUSTOM_MEDIA_PATH" ]]; then
            print_warning "Media path doesn't exist. It will be created if possible."
        fi
    fi
    
    # Custom download path
    if [[ "$download_selection" -eq $((${#AVAILABLE_DOWNLOAD_PATHS[@]} + 1)) ]]; then
        read -p "Enter custom download path (e.g., /tmp/downloads): " CUSTOM_DOWNLOAD_PATH
        if [[ ! -d "$CUSTOM_DOWNLOAD_PATH" ]]; then
            print_warning "Download path doesn't exist. It will be created if possible."
        fi
    fi
    
    # Custom config path
    if [[ "$config_selection" -eq 3 ]]; then
        read -p "Enter custom config path (e.g., /opt/arrmematey-config): " CUSTOM_CONFIG_PATH
    fi
}

# Generate storage mount configuration
generate_storage_mounts() {
    STORAGE_MOUNTS=""
    MOUNT_COUNTER=0
    
    # Media storage
    local media_path=""
    if [[ "$media_selection" -le ${#AVAILABLE_MEDIA_PATHS[@]} ]]; then
        media_path="/${AVAILABLE_MEDIA_PATHS[$((media_selection-1))]}"
    else
        media_path="$CUSTOM_MEDIA_PATH"
    fi
    
    if [[ -n "$media_path" ]]; then
        ensure_host_directory "$media_path"
        STORAGE_MOUNTS+="--mp$MOUNT_COUNTER $media_path:/home/ed/Media,shared=1 "
        ((MOUNT_COUNTER++))
        print_status "Media storage: $media_path → /home/ed/Media"
    fi
    
    # Download storage
    local download_path=""
    if [[ "$download_selection" -le ${#AVAILABLE_DOWNLOAD_PATHS[@]} ]]; then
        download_path="/${AVAILABLE_DOWNLOAD_PATHS[$((download_selection-1))]}"
    else
        download_path="$CUSTOM_DOWNLOAD_PATH"
    fi
    
    if [[ -n "$download_path" ]]; then
        ensure_host_directory "$download_path"
        STORAGE_MOUNTS+="--mp$MOUNT_COUNTER $download_path:/home/ed/Downloads,shared=1 "
        ((MOUNT_COUNTER++))
        print_status "Download storage: $download_path → /home/ed/Downloads"
    fi
    
    # Config storage
    local config_path=""
    case $config_selection in
        1) config_path="/$(logname)/arrmematey-config" ;;
        2) config_path="/mnt/config/arrmematey" ;;
        *) config_path="$CUSTOM_CONFIG_PATH" ;;
    esac
    
    if [[ -n "$config_path" ]]; then
        ensure_host_directory "$config_path"
        STORAGE_MOUNTS+="--mp$MOUNT_COUNTER $config_path:/home/ed/Config,shared=1 "
        ((MOUNT_COUNTER++))
        print_status "Config storage: $config_path → /home/ed/Config"
    fi
}

# Container configuration
configure_container() {
    echo ""
    print_pirate "Configure container resources, captain:"
    echo "======================================"
    
    # Default values
    DEFAULT_CTID=200
    DEFAULT_HOSTNAME="arrmematey"
    DEFAULT_CORES=4
    DEFAULT_MEMORY=4096
    DEFAULT_SWAP=2048
    DEFAULT_DISK=32
    DEFAULT_STORAGE="local"
    
    # Get storage options
    local storages=$(get_storage_pools)
    
    # Container ID
    read -p "Container ID [$DEFAULT_CTID]: " CTID
    CTID=${CTID:-$DEFAULT_CTID}
    
    # Check if CTID already exists
    if pct status $CTID 2>/dev/null; then
        print_error "Container with ID $CTID already exists!"
        read -p "Choose different ID or enter to continue: " CTID
        if [[ -z "$CTID" ]]; then
            exit 1
        fi
    fi
    
    # Hostname
    read -p "Hostname [$DEFAULT_HOSTNAME]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    
    # CPU cores
    read -p "CPU cores [$DEFAULT_CORES]: " CORES
    CORES=${CORES:-$DEFAULT_CORES}
    
    # Memory
    read -p "Memory (MB) [$DEFAULT_MEMORY]: " MEMORY
    MEMORY=${MEMORY:-$DEFAULT_MEMORY}
    
    # Swap
    read -p "Swap (MB) [$DEFAULT_SWAP]: " SWAP
    SWAP=${SWAP:-$DEFAULT_SWAP}
    
    # Disk size
    read -p "Disk size (GB) [$DEFAULT_DISK]: " DISK
    DISK=${DISK:-$DEFAULT_DISK}
    
    # Storage pool
    echo ""
    print_info "Available storage pools:"
    echo "$storages" | tr ' ' '\n' | nl -nln
    read -p "Storage pool [$DEFAULT_STORAGE]: " STORAGE
    STORAGE=${STORAGE:-$DEFAULT_STORAGE}
    
    # Network
    DEFAULT_BRIDGE="vmbr0"
    read -p "Network bridge [$DEFAULT_BRIDGE]: " BRIDGE
    BRIDGE=${BRIDGE:-$DEFAULT_BRIDGE}
    
    print_status "Container configuration complete!"
}

# Template selection
select_template() {
    echo ""
    print_pirate "Select CT template:"
    echo "====================="
    
    local templates=$(get_ct_templates)
    
    if [[ -z "$templates" ]]; then
        print_error "No Ubuntu/Debian templates found!"
        print_info "Please download a template first:"
        print_info "1. Go to Proxmox web UI > Storage > Content"
        print_info "2. Click 'Templates' and download Ubuntu/Debian template"
        print_info "3. Re-run this script"
        exit 1
    fi
    
    echo "$templates" | tr ' ' '\n' | nl -nln
    echo ""
    read -p "Select template (number): " template_selection
    
    # Get selected template
    local selected_template=$(echo "$templates" | tr ' ' '\n' | sed -n "${template_selection}p")
    
    if [[ -z "$selected_template" ]]; then
        print_error "Invalid template selection"
        exit 1
    fi
    
    print_status "Selected template: $selected_template"
    TEMPLATE=$selected_template
}

# Create container
create_container() {
    print_pirate "Creating Arrmematey LXC container, captain..."
    
    local cmd="pct create $CTID $TEMPLATE"
    cmd+=" --hostname $HOSTNAME"
    cmd+=" --cores $CORES"
    cmd+=" --memory $MEMORY"
    cmd+=" --swap $SWAP"
    cmd+=" --storage $STORAGE"
    cmd+=" --rootfs local:$DISK"
    cmd+=" --net0 bridge=$BRIDGE,firewall=1"
    cmd+=" --ostype ubuntu"
    cmd+=" --unprivileged 1"
    cmd+=" --features nesting=1"
    
    # Add storage mounts
    cmd+=" $STORAGE_MOUNTS"
    
    print_info "Executing: $cmd"
    
    if eval $cmd; then
        print_status "✅ Container created successfully!"
    else
        print_error "❌ Failed to create container"
        exit 1
    fi
}

# Start container
start_container() {
    print_pirate "Starting container..."
    
    if pct start $CTID; then
        print_status "✅ Container started successfully!"
    else
        print_error "❌ Failed to start container"
        exit 1
    fi
}

# Wait for container to be ready
wait_for_container() {
    print_pirate "Waiting for container to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if pct status $CTID | grep -q "running"; then
            print_status "✅ Container is running!"
            break
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        print_error "❌ Container failed to start within timeout"
        exit 1
    fi
}

# Install Docker and Arrmematey
install_arrmematey() {
    print_pirate "Installing Docker and Arrmematey in container..."
    
    # Wait a bit for container to be fully ready
    sleep 10
    
    # Update system
    pct exec $CTID -- bash -c "apt-get update"
    
    # Install Docker
    pct exec $CTID -- bash -c "apt-get install -y curl ca-certificates gnupg lsb-release"
    pct exec $CTID -- bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
    pct exec $CTID -- bash -c "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null"
    pct exec $CTID -- bash -c "apt-get update"
    pct exec $CTID -- bash -c "apt-get install -y docker-ce docker-ce-cli containerd.io"
    pct exec $CTID -- bash -c "systemctl enable docker"
    pct exec $CTID -- bash -c "systemctl start docker"
    
    # Create user
    pct exec $CTID -- bash -c "useradd -m -s /bin/bash ed"
    pct exec $CTID -- bash -c "usermod -aG docker ed"
    
    # Clone Arrmematey
    pct exec $CTID -- bash -c "cd /home/ed && git clone https://github.com/edellingham/arrmematey.git"
    
    # Make scripts executable
    pct exec $CTID -- bash -c "chmod +x /home/ed/arrmematey/*.sh"
    
    # Run quick install
    pct exec $CTID -- bash -c "cd /home/ed/arrmematey && ./quick-install.sh"
    
    print_status "✅ Docker and Arrmematey installed!"
}

# Show container info
show_container_info() {
    echo ""
    print_pirate "🎉 Arrmematey container deployed successfully!"
    echo "================================================"
    echo ""
    print_info "Container Details:"
    echo "  ID: $CTID"
    echo "  Hostname: $HOSTNAME"
    echo "  Template: $TEMPLATE"
    echo "  Storage: $STORAGE"
    echo "  Bridge: $BRIDGE"
    echo "  CPU: $CORES cores"
    echo "  Memory: $MEMORY MB"
    echo "  Disk: $DISK GB"
    echo ""
    print_info "Storage Mounts:"
    echo "$STORAGE_MOUNTS" | tr ' ' '\n' | sed 's/^--mp[0-9]* /'
    echo ""
    print_info "Next Steps:"
    echo "1. Access Arrmematey UI: http://$(pct exec $CTID -- hostname -I | awk '{print $1}'):8080"
    echo "2. Configure Mullvad VPN ID in container"
    echo "3. Set up your media services"
    echo ""
    print_pirate "Arr... me matey! Your pirate crew is ready for treasure hunting! 🏴‍☠️🍿"
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🏴‍☠️ Arrmematey Proxmox Deployment          ║"
    echo "║                                                              ║"
    echo "║         Deploy pirate crew to Proxmox LXC container      ║"
    echo "║         Arr... Me Matey!                                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_proxmox
    get_host_storage
    select_storage
    get_custom_paths
    generate_storage_mounts
    select_template
    configure_container
    create_container
    start_container
    wait_for_container
    install_arrmematey
    show_container_info
}

# Run the deployment
main "$@"
