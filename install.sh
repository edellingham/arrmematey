#!/bin/bash
# Arrmematey One-Line Installer with Cleanup Options
#
# MAIN COMMAND:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)"
#
# This script includes a menu with:
# 1. Install - Normal Arrmematey installation
# 2. Clean Up - Remove Docker containers and unused images
# 3. Nuclear Clean Up - Aggressive Docker/containerd cleanup

set -e

# Script version information
SCRIPT_VERSION="2.15.0"
SCRIPT_DATE="2025-11-17"

# Check if running the right version
if [[ -z "$SCRIPT_VERSION" || -z "$SCRIPT_DATE" ]]; then
    echo -e "${RED}❌ Version information missing!${NC}"
    echo "You may be running a cached version of the script."
    echo -e "${BLUE}Please run:${NC}"
    echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)\""
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

# ==========================================
# INSTALLATION FUNCTIONS (Moved to top)
# ==========================================

# Check requirements and setup docker-compose command
check_docker() {
    echo -e "${BLUE}[STEP]${NC} Checking Docker..."

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is required but not installed${NC}"
        echo "Install Docker first:"
        echo "  Ubuntu/Debian: sudo apt install docker.io"
        echo "  CentOS/RHEL: sudo dnf install docker"
        echo "  Or follow: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check if docker daemon is running
    if ! docker ps &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker daemon not running${NC}"
        echo "Start Docker:"
        echo "  sudo systemctl start docker"
        echo "  Or start Docker Desktop"
        exit 1
    fi

    echo -e "${GREEN}✅ Docker found and running${NC}"

    # Check Docker storage driver and space
    check_docker_storage

    # Set docker-compose command (supports both docker-compose and 'docker compose')
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        echo -e "${GREEN}✅ Using docker-compose${NC}"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
        echo -e "${GREEN}✅ Using docker compose${NC}"
    else
        echo -e "${RED}❌ Neither 'docker-compose' nor 'docker compose' is available${NC}"
        echo "Install docker-compose:"
        echo "  Ubuntu/Debian: sudo apt install docker-compose"
        echo "  Or install Docker Desktop which includes compose"
        exit 1
    fi
}

# Check Docker storage configuration
check_docker_storage() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Checking Docker storage configuration..."

    # Get Docker info
    local docker_info=$(docker info 2>/dev/null)
    local storage_driver=$(echo "$docker_info" | grep "Storage Driver:" | awk '{print $3}')
    local docker_root_dir=$(echo "$docker_info" | grep "Docker Root Dir:" | awk '{print $4}')

    echo -e "${GREEN}✅ Storage Driver: ${storage_driver}${NC}"
    echo -e "${GREEN}✅ Root Directory: ${docker_root_dir}${NC}"

    # Check space on Docker root directory
    if [[ -n "$docker_root_dir" && -d "$docker_root_dir" ]]; then
        local root_available=$(df "$docker_root_dir" | tail -1 | awk '{print $4}')
        local root_size=$(df "$docker_root_dir" | tail -1 | awk '{print $2}')
        local root_used=$(df "$docker_root_dir" | tail -1 | awk '{print $3}')

        echo -e "${BLUE}Docker Storage Space:${NC}"
        echo "  Total: $(echo $root_size | numfmt --to=iec)"
        echo "  Used:  $(echo $root_used | numfmt --to=iec)"
        echo "  Free:  $(echo $root_available | numfmt --to=iec)"

        # Check if space is critically low (less than 10GB)
        local root_available_gb=$((root_available / 1024 / 1024))
        if [[ $root_available_gb -lt 10 ]]; then
            echo -e "${YELLOW}⚠️ Docker storage is running low (${root_available_gb}GB free)${NC}"
            echo ""
            echo "⚠️ Docker storage space is low. This can cause installation failures."
            echo "Would you like to:"
            echo ""
            echo "1) Clean Docker storage (recommended for cluttered storage)"
            echo "2) Move Docker storage to location with more space"
            echo "3) Return to storage management menu"
            echo ""
            read -p "Select option (1-3): " fix_choice

            case $fix_choice in
                1)
                    echo -e "${BLUE}🧹 Cleaning Docker storage...${NC}"
                    perform_docker_cleanup
                    ;;
                2)
                    echo -e "${BLUE}🔧 Moving Docker storage to larger location...${NC}"
                    offer_move_docker_storage
                    ;;
                3)
                    echo "Returning to storage management menu..."
                    return
                    ;;
                *)
                    echo -e "${YELLOW}Invalid choice. Returning to storage management menu...${NC}"
                    return
                    ;;
            esac
        elif [[ $root_available_gb -lt 20 ]]; then
            echo -e "${YELLOW}⚠️ Docker storage is getting tight (${root_available_gb}GB free)${NC}"
            echo -e "${BLUE}Consider moving Docker storage to prevent future issues${NC}"
            read -p "Move Docker storage now? (y/N): " move_choice
            if [[ "$move_choice" =~ ^[Yy]$ ]]; then
                offer_move_docker_storage
            fi
        else
            echo -e "${GREEN}✅ Docker storage has sufficient space${NC}"
        fi
    fi

    # Check overlay2 filesystem specifically
    if [[ "$storage_driver" == "overlay2" || "$storage_driver" == "overlayfs" ]]; then
        check_overlay2_space
    fi

    echo ""
    echo -e "${GREEN}✅ Storage status check complete${NC}"
}

# Check overlay2 filesystem space
check_overlay2_space() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Checking overlay2 filesystem..."

    local overlay_mount=$(findmnt -t overlay -o SOURCE | head -1)
    if [[ -n "$overlay_mount" ]]; then
        echo -e "${GREEN}✅ Overlay2 mount: $overlay_mount${NC}"

        # Check space on overlay mount
        local overlay_available=$(df "$overlay_mount" | tail -1 | awk '{print $4}')
        local overlay_available_gb=$((overlay_available / 1024 / 1024))

        echo -e "${BLUE}Overlay2 Space:${NC}"
        echo "  Available: $(echo $overlay_available | numfmt --to=iec)"

        if [[ $overlay_available_gb -lt 5 ]]; then
            echo -e "${RED}❌ Overlay2 filesystem is critically low (${overlay_available_gb}GB free)${NC}"
            echo -e "${YELLOW}This will cause image extraction failures!${NC}"
            offer_storage_fix
        else
            echo -e "${GREEN}✅ Overlay2 filesystem has adequate space${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Could not find overlay2 mount point${NC}"
    fi
}

# Offer to fix storage issues
offer_storage_fix() {
    echo ""
    echo -e "${YELLOW}Docker storage space is low. This can cause installation failures.${NC}"
    echo "Would you like to:"
    echo ""
    echo "1) Clean Docker storage (recommended for cluttered storage)"
    echo "2) Move Docker storage to location with more space"
    echo "3) Continue anyway (risky)"
    echo ""
    read -p "Select option (1-3): " fix_choice

    case $fix_choice in
        1)
            echo -e "${BLUE}🧹 Cleaning Docker storage...${NC}"
            perform_docker_cleanup
            ;;
        2)
            echo -e "${BLUE}🔧 Moving Docker storage to larger location...${NC}"
            move_docker_storage
            ;;
        3)
            echo -e "${YELLOW}Continuing despite low storage space...${NC}"
            echo -e "${YELLOW}Installation may fail!${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Continuing...${NC}"
            ;;
    esac
}

# Perform Docker cleanup
perform_docker_cleanup() {
    echo "🛑 Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true

    echo "🗑️ Removing unused images..."
    docker image prune -af

    echo "🗑️ Removing unused volumes..."
    docker volume prune -f

    echo "🗑️ Removing unused networks..."
    docker network prune -f

    echo "🧽 Pruning system..."
    docker system prune -af

    echo "🔄 Restarting Docker..."
    sudo systemctl restart docker
    sleep 3

    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker cleanup completed successfully${NC}"
    else
        echo -e "${RED}❌ Docker restart failed${NC}"
        exit 1
    fi
}

# Expand Docker storage to location with more space
expand_docker_storage() {
    echo ""
    echo -e "${BLUE}🔄 Expanding Docker Storage Capacity${NC}"
    echo "=================================="
    echo ""

    # Get current Docker storage info
    local storage_driver=$(docker info 2>/dev/null | grep "Storage Driver:" | awk '{print $3}')
    local backing_fs=$(docker info 2>/dev/null | grep "Backing Filesystem:" | awk '{print $3}')
    
    # If backing filesystem is empty, try to detect it
    if [[ -z "$backing_fs" ]]; then
        local docker_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
        if [[ -n "$docker_root" ]]; then
            backing_fs=$(df -T "$docker_root" | tail -1 | awk '{print $2}')
        else
            backing_fs="unknown"
        fi
    fi

    echo -e "${BLUE}Current setup:${NC}"
    echo "  Storage Driver: $storage_driver"
    echo "  Backing Filesystem: ${backing_fs:-unknown}"
    echo ""

    # Show expansion options based on storage driver
    echo -e "${BLUE}Storage expansion options for $storage_driver:${NC}"
    echo ""

    case $storage_driver in
        "overlay2")
            echo "Overlay2 expansion requires expanding the underlying filesystem."
            echo "Available options:"
            echo "1) Expand backing filesystem (LVM/XFS recommended)"
            echo "2) Add block device to existing filesystem"
            echo "3) Use different backing filesystem with more space"
            ;;
        "devicemapper")
            echo "Devicemapper (LVM) expansion methods:"
            echo "Your backing filesystem: $backing_fs"
            echo ""
            echo "Available expansion options:"
            echo "1) 🔧 Extend existing LVM volume group"
            echo "2) 📦 Add physical volume to volume group"
            echo "3) 📁 Move Docker to different filesystem with more space"
            echo ""
            ;;
        "zfs")
            echo "ZFS expansion methods:"
            echo "Your backing filesystem: $backing_fs"
            echo ""
            echo "Available expansion options:"
            echo "1) 🔧 Add disk to existing ZFS pool"
            echo "2) 🔄 Replace smaller disks with larger ones"
            echo "3) 📁 Move Docker to different filesystem with more space"
            echo ""
            ;;
        "btrfs")
            echo "Btrfs expansion methods:"
            echo "Your backing filesystem: $backing_fs"
            echo ""
            echo "Available expansion options:"
            echo "1) 🔧 Add new block device to btrfs filesystem"
            echo "2) 🔄 Convert to larger filesystem"
            echo "3) 📁 Move Docker to different filesystem with more space"
            echo ""
            ;;
        *)
            echo "Storage driver: $storage_driver"
            echo "Your backing filesystem: $backing_fs"
            echo ""
            echo "Available expansion options:"
            echo "1) 🔧 Expand current filesystem if possible"
            echo "2) 📦 Add storage device if supported"
            echo "3) 📁 Move Docker to different filesystem with more space"
            echo ""
            ;;
    esac

    echo ""
    read -p "Select expansion method (1-3): " expansion_choice

    case $expansion_choice in
        1)
            echo -e "${BLUE}🔧 Expanding current filesystem...${NC}"
            if [[ "$storage_driver" == "overlay2" || "$storage_driver" == "overlayfs" ]]; then
                echo "Choose expansion method for Overlay2/OverlayFS:"
                echo "1) 🔧 Automated LVM expansion (recommended)"
                echo "2) 📖 Manual guidance only"
                echo "3) 📁 Move Docker storage"
                read -p "Select method (1-3): " overlay2_choice

                case $overlay2_choice in
                    1)
                        safe_expand_lvm
                        ;;
                    2)
                        expand_overlay2_fs
                        ;;
                    3)
                        offer_move_docker_storage
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            elif [[ "$storage_driver" == "devicemapper" ]]; then
                echo "Choose expansion method for Devicemapper:"
                echo "1) 🔧 Automated LVM expansion (recommended)"
                echo "2) 📖 Manual guidance only"
                echo "3) 📁 Move Docker storage"
                read -p "Select method (1-3): " devicemapper_choice

                case $devicemapper_choice in
                    1)
                        safe_expand_lvm
                        ;;
                    2)
                        expand_devicemapper_lvm
                        ;;
                    3)
                        offer_move_docker_storage
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            elif [[ "$storage_driver" == "zfs" ]]; then
                echo "Choose expansion method for ZFS:"
                echo "1) 🔧 Automated ZFS expansion (recommended)"
                echo "2) 📖 Manual guidance only"
                echo "3) 📁 Move Docker storage"
                read -p "Select method (1-3): " zfs_choice

                case $zfs_choice in
                    1)
                        safe_expand_zfs
                        ;;
                    2)
                        expand_zfs_pool
                        ;;
                    3)
                        offer_move_docker_storage
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            elif [[ "$storage_driver" == "btrfs" ]]; then
                echo "Choose expansion method for Btrfs:"
                echo "1) 🔧 Automated Btrfs expansion (recommended)"
                echo "2) 📖 Manual guidance only"
                echo "3) 📁 Move Docker storage"
                read -p "Select method (1-3): " btrfs_choice

                case $btrfs_choice in
                    1)
                        safe_expand_btrfs
                        ;;
                    2)
                        expand_btrfs_filesystem
                        ;;
                    3)
                        offer_move_docker_storage
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            else
                echo -e "${YELLOW}Generic filesystem expansion for $storage_driver${NC}"
                echo "This system uses: $storage_driver"
                echo ""
                echo "Available expansion methods:"
                echo "1) 🔧 Automated LVM expansion (if available)"
                echo "2) 📖 Manual guidance only"
                echo "3) 📁 Move Docker storage"
                read -p "Select method (1-3): " generic_choice

                case $generic_choice in
                    1)
                        safe_expand_lvm
                        ;;
                    2)
                        expand_generic_filesystem
                        ;;
                    3)
                        offer_move_docker_storage
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            fi
            ;;
        2)
            echo -e "${BLUE}📦 Adding storage device...${NC}"
            add_storage_device
            ;;
        3)
            echo -e "${YELLOW}📁 Moving Docker to different filesystem...${NC}"
            offer_move_docker_storage
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 1-3.${NC}"
            ;;
    esac
}

# Expand overlay2 filesystem
expand_overlay2_fs() {
    echo ""
    echo -e "${BLUE}🔧 Expanding Overlay2 Backing Filesystem${NC}"
    echo "========================================="
    echo ""

    local backing_mount=$(findmnt -t xfs -o SOURCE | head -1)
    if [[ -z "$backing_mount" ]]; then
        backing_mount=$(df /var/lib/docker | tail -1 | awk '{print $1}')
        echo -e "${YELLOW}Found backing filesystem: $backing_mount${NC}"
    else
        echo -e "${GREEN}Found XFS filesystem: $backing_mount${NC}"
    fi

    echo ""
    echo "Overlay2 storage driver uses XFS filesystem for backing."
    echo "To expand Docker storage, you need to expand the underlying filesystem."
    echo ""
    echo "Available expansion approaches:"
    echo "1) 🔧 Expand existing XFS partition with LVM"
    echo "2) 📦 Add new disk and expand volume group"
    echo "3) 📁 Move Docker to different filesystem with more space"
    echo ""
    read -p "Select expansion approach (1-3): " overlay_choice

    case $overlay_choice in
        1)
            echo -e "${BLUE}🔧 Expanding XFS with LVM${NC}"
            echo ""
            echo "To expand XFS filesystem with LVM:"
            echo "1. Check available disk space: sudo fdisk -l"
            echo "2. Create new partition: sudo fdisk /dev/sdX"
            echo "3. Create physical volume: sudo pvcreate /dev/sdX1"
            echo "4. Extend volume group: sudo vgextend vg-name /dev/sdX1"
            echo "5. Extend logical volume: sudo lvextend -l+100%FREE /dev/vg-name/lv-name"
            echo "6. Expand filesystem: sudo xfs_growfs /mount/point"
            echo ""
            echo "⚠️  This requires system administration knowledge!"
            ;;
        2)
            echo -e "${BLUE}📦 Adding disk to volume group${NC}"
            echo ""
            echo "To add disk to existing volume group:"
            echo "1. Check current volume groups: sudo vgdisplay"
            echo "2. Initialize new disk: sudo pvcreate /dev/sdX"
            echo "3. Add to volume group: sudo vgextend <vg-name> /dev/sdX"
            echo "4. Extend logical volume: sudo lvextend -l+100%FREE <vg-name>/<lv-name>"
            echo "5. Grow filesystem: sudo xfs_growfs /mount/point"
            echo ""
            echo "⚠️  This requires an available disk partition!"
            ;;
        3)
            echo -e "${BLUE}📁 Moving Docker to different filesystem${NC}"
            offer_move_docker_storage
            return
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 1-3.${NC}"
            ;;
    esac

    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Expand devicemapper LVM setup
expand_devicemapper_lvm() {
    echo ""
    echo -e "${BLUE}🔧 Expanding Devicemapper LVM Storage${NC}"
    echo "=================================="
    echo ""

    # Check if LVM is available
    if ! command -v vgs &> /dev/null; then
        echo -e "${RED}❌ LVM tools not available${NC}"
        echo "Install LVM: sudo apt install lvm2"
        read -p "Press Enter to return to storage management menu..."
        return
    fi

    # Show current LVM setup
    echo -e "${BLUE}Current LVM setup:${NC}"
    vgs 2>/dev/null | grep docker || echo "No docker volume group found"
    lvs 2>/dev/null | grep thin || echo "No thin logical volumes found"

    echo ""
    echo "To expand devicemapper storage:"
    echo "1) Add new physical volume: sudo pvcreate /dev/sdb"
    echo "2) Add to volume group: sudo vgextend docker /dev/sdb"
    echo "3) Extend thin pool: sudo lvextend -l+100%FREE docker/thinpool"
    echo ""
    echo "This requires available disk space and may need Docker restart."
    echo ""
    echo "⚠️  LVM operations require system administration knowledge!"
    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Expand ZFS pool
expand_zfs_pool() {
    echo ""
    echo -e "${BLUE}🔧 Expanding ZFS Pool${NC}"
    echo "======================"
    echo ""

    if ! command -v zpool &> /dev/null; then
        echo -e "${RED}❌ ZFS tools not available${NC}"
        echo "Install ZFS: sudo apt install zfsutils-linux"
        read -p "Press Enter to return to storage management menu..."
        return
    fi

    # Show current ZFS pool
    echo -e "${BLUE}Current ZFS pools:${NC}"
    zpool list 2>/dev/null || echo "No ZFS pools found"

    echo ""
    echo "To expand ZFS pool:"
    echo "1) Check available disks: sudo fdisk -l"
    echo "2) Add disk to pool: sudo zpool add <pool-name> /dev/sdb"
    echo "3) Verify expansion: zpool list"
    echo ""
    echo "⚠️  ZFS operations require careful planning!"
    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Expand btrfs filesystem
expand_btrfs_filesystem() {
    echo ""
    echo -e "${BLUE}🔧 Expanding Btrfs Filesystem${NC}"
    echo "=============================="
    echo ""

    if ! command -v btrfs &> /dev/null; then
        echo -e "${RED}❌ Btrfs tools not available${NC}"
        echo "Install btrfs: sudo apt install btrfs-progs"
        read -p "Press Enter to return to storage management menu..."
        return
    fi

    # Show current btrfs setup
    echo -e "${BLUE}Current btrfs filesystem:${NC}"
    btrfs filesystem show 2>/dev/null || echo "No btrfs filesystem found for Docker"

    echo ""
    echo "To expand btrfs filesystem:"
    echo "1) Check available disks: sudo fdisk -l"
    echo "2) Add device: sudo btrfs device add /dev/sdb /var/lib/docker"
    echo "3) Balance filesystem: sudo btrfs filesystem balance /var/lib/docker"
    echo ""
    echo "⚠️  Btrfs operations can take time to complete!"
    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Offer to move Docker storage as fallback
offer_move_docker_storage() {
    echo ""
    echo -e "${YELLOW}Moving Docker storage to location with more space...${NC}"

    # Get current Docker root directory
    local current_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
    echo -e "${BLUE}Current Docker root: ${current_root}${NC}"

    # Show available locations with more space
    echo ""
    echo -e "${BLUE}Available locations with more space:${NC}"

    local available_locations=()
    local location_counter=1

    # Check home directory
    local home_available=$(df $HOME | tail -1 | awk '{print $4}')
    local home_available_gb=$((home_available / 1024 / 1024))
    if [[ $home_available_gb -gt 10 ]]; then
        echo "  $location_counter) $HOME (${home_available_gb}GB free)"
        available_locations+=("$HOME")
        ((location_counter++))
    fi

    # Check common mount points
    for mount_point in /opt /usr/local /var/lib; do
        if [[ -d "$mount_point" && "$mount_point" != "$current_root" ]]; then
            local mount_available=$(df $mount_point | tail -1 | awk '{print $4}')
            local mount_available_gb=$((mount_available / 1024 / 1024))
            if [[ $mount_available_gb -gt 10 ]]; then
                echo "  $location_counter) $mount_point (${mount_available_gb}GB free)"
                available_locations+=("$mount_point")
                ((location_counter++))
            fi
        fi
    done

    # Check if we found any suitable locations
    if [[ ${#available_locations[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No suitable locations found with sufficient space${NC}"
        echo -e "${YELLOW}Please ensure you have at least 10GB free space in:${NC}"
        echo "  - $HOME"
        echo "  - /opt"
        echo "  - /usr/local"
        echo "  - /var/lib"
        return 1
    fi

    echo ""
    read -p "Select location (1-${#available_locations[@]}): " location_choice

    # Validate choice
    if ! [[ "$location_choice" =~ ^[0-9]+$ ]] || [[ $location_choice -lt 1 ]] || [[ $location_choice -gt ${#available_locations[@]} ]]; then
        echo -e "${RED}Invalid choice${NC}"
        return 1
    fi

    local selected_location="${available_locations[$((location_choice - 1))]}"
    local new_docker_root="$selected_location/docker-data"
    local backup_name="docker-backup-$(date +%Y%m%d-%H%M%S)"

    echo ""
    echo -e "${YELLOW}Moving Docker from ${current_root} to ${new_docker_root}${NC}"
    echo -e "${YELLOW}Creating backup at: ${current_root}.${backup_name}${NC}"
    echo ""

    read -p "Continue? This will restart Docker. (y/N): " confirm_move
    if [[ ! "$confirm_move" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return 1
    fi

    echo ""
    echo "🛑 Stopping Docker daemon..."
    sudo systemctl stop docker

    echo "🗃️ Creating backup..."
    sudo mv "$current_root" "$current_root.$backup_name"

    echo "📁 Creating new Docker directory..."
    sudo mkdir -p "$new_docker_root"

    echo "🔗 Creating symlink..."
    sudo ln -sf "$new_docker_root" "$current_root"

    echo "⚙️ Updating Docker daemon configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$new_docker_root"
}
EOF

    echo "🚀 Starting Docker daemon..."
    sudo systemctl start docker
    sleep 5

    echo "🔍 Verifying Docker is working..."
    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker storage moved successfully!${NC}"
        local new_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
        echo -e "${GREEN}✅ New Docker root: ${new_root}${NC}"
        echo -e "${BLUE}Backup location: ${current_root}.${backup_name}${NC}"
        echo ""
        echo -e "${GREEN}You can safely remove the backup once everything is working:${NC}"
        echo "sudo rm -rf ${current_root}.${backup_name}"
    else
        echo -e "${RED}❌ Docker failed to start after move${NC}"
        echo "🛠️ Restoring from backup..."
        sudo rm -rf "$current_root"
        sudo mv "$current_root.$backup_name" "$current_root"
        sudo rm -f /etc/docker/daemon.json
        sudo systemctl start docker
        echo "🔄 Docker restored to original location"
        return 1
    fi
}

# Get Mullvad zip file for Wireguard configuration
get_mullvad_zip() {
    echo ""
    echo -e "${BLUE}🔐 Mullvad Wireguard Configuration${NC}"
    echo "Get your configuration from: https://mullvad.net/en/account/#/wireguard-config"
    echo ""
    echo "Mullvad removed OpenVPN support in January 2026."
    echo "Wireguard is now the only supported protocol."
    echo ""
    read -p "Enter path to Mullvad Wireguard zip file: " ZIP_FILE
    while [[ -z "$ZIP_FILE" || ! -f "$ZIP_FILE" ]]; do
        echo -e "${RED}Zip file not found${NC}"
        read -p "Enter path to Mullvad Wireguard zip file: " ZIP_FILE
    done
    echo -e "${GREEN}✅ Zip file configured: $ZIP_FILE${NC}"
}

# Create configuration
create_config() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Creating configuration..."

    INSTALL_DIR="$HOME/arrmematey"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    cat > .env << EOF
# Arrmematey Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC

# Mullvad VPN Configuration (REQUIRED)
MULLVAD_USER=your_mullvad_id_here
MULLVAD_ACCOUNT_ID=your_mullvad_id_here
MULLVAD_COUNTRY=us
MULLVAD_CITY=ny

# VPN Type: Wireguard only (OpenVPN removed January 2026)
VPN_TYPE=wireguard

# Wireguard credentials (extract from Mullvad zip file)
WIREGUARD_PRIVATE_KEY=
WIREGUARD_ADDRESSES=

# Docker volume paths
MEDIA_PATH=/data/media
DOWNLOADS_PATH=/data/downloads
CONFIG_PATH=/data/config

# Management UI
MANAGEMENT_UI_PORT=8787

# Service ports
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
SABNZBD_PORT=8080
QBITTORRENT_PORT=8081
JELLYSEERR_PORT=5055

# Service passwords
SABNZBD_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
JELLYSEERR_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

# Quality profile
QUALITY_PROFILE=standard

# Enable services
ENABLE_PROWLARR=true
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_LIDARR=true
ENABLE_SABNZBD=true
ENABLE_QBITTORRENT=true
ENABLE_JELLYSEERR=true
ENABLE_EMBY=true
ENABLE_CLOUDFLARE_TUNNEL=false
EOF

    echo -e "${GREEN}✅ Configuration created${NC}"
}

# Download docker-compose.yml
download_compose() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Downloading service configuration..."

    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add: [NET_ADMIN]
    environment:
      - VPN_SERVICE_PROVIDER=mullvad
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY:-}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES:-}
      - SERVER_Countries=${MULLVAD_COUNTRY:-us}
      - SERVER_Cities=${MULLVAD_CITY:-ny}
      - TZ=${TZ:-UTC}
      - FIREWALL=on
      - FIREWALL_VPN_INPUT_PORTS=${SONARR_PORT:-8989},${RADARR_PORT:-7878},${LIDARR_PORT:-8686},${SABNZBD_PORT:-8080},${QBITTORRENT_PORT:-8081}
      - AUTOCONNECT=true
      - KILLSWITCH=true
      - SHADOWSOCKS=off
    volumes:
      - gluetun-config:/config
    ports:
      - ${SONARR_PORT:-8989}:8989
      - ${RADARR_PORT:-7878}:7878
      - ${LIDARR_PORT:-8686}:8686
      - ${SABNZBD_PORT:-8080}:8080
      - ${QBITTORRENT_PORT:-8081}:8081
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -s https://ifconfig.io >/dev/null && exit 0 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  prowlarr:
    image: linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - prowlarr-config:/config
    network_mode: "service:gluetun"
    depends_on:
      gluetun:
        condition: service_healthy
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - sonarr-config:/config
      - sonarr-media:/tv
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - radarr-config:/config
      - radarr-media:/movies
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  lidarr:
    image: linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    volumes:
      - lidarr-config:/config
      - lidarr-media:/music
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - prowlarr
    restart: unless-stopped

  sabnzbd:
    image: linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - SABNZBD_USERNAME=arrmematey
      - SABNZBD_PASSWORD=${SABNZBD_PASSWORD:-changeme}
    volumes:
      - sabnzbd-config:/config
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - WEBUI_PORT=8081
    volumes:
      - qbittorrent-config:/config
      - downloads:/downloads
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
      - PORT=5055
      - JELLYSEERR_PASSWORD=${JELLYSEERR_PASSWORD:-changeme}
    volumes:
      - jellyseerr-config:/app/config
    ports:
      - ${JELLYSEERR_PORT:-5055}:5055
    restart: unless-stopped

volumes:
  gluetun-config:
  prowlarr-config:
  sonarr-config:
  radarr-config:
  lidarr-config:
  sabnzbd-config:
  qbittorrent-config:
  jellyseerr-config:
  sonarr-media:
  radarr-media:
  lidarr-media:
  downloads:
EOF

    echo -e "${GREEN}✅ Service configuration downloaded${NC}"
}

# Start services
start_services() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} Starting services..."

    # Create directories
    mkdir -p ./data/{media/{tv,movies,music},downloads/{complete,incomplete},config}

    # Start services using the detected compose command
    echo -e "${BLUE}🚀 Starting containers...${NC}"
    $DOCKER_COMPOSE_CMD up -d

    echo -e "${GREEN}✅ Services started${NC}"
}

# Show completion
show_completion() {
    INSTALL_DIR="$HOME/arrmematey"
    echo ""
    echo -e "${GREEN}🎉 Arrmematey is ready!${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}🌐 Access Points:${NC}"
    echo "  Management UI:  http://localhost:8080"
    echo "  Prowlarr:       http://localhost:9696"
    echo "  Sonarr:         http://localhost:8989"
    echo "  Radarr:         http://localhost:7878"
    echo "  Lidarr:         http://localhost:8686"
    echo "  SABnzbd:        http://localhost:8080"
    echo "  qBittorrent:    http://localhost:8081"
    echo "  Jellyseerr:     http://localhost:5055"
    echo ""
    echo -e "${BLUE}📁 Installation:${NC}"
    echo "  Directory:      $INSTALL_DIR"
    echo ""
    echo -e "${BLUE}🔧 Management:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  $DOCKER_COMPOSE_CMD ps             # Check status"
    echo "  $DOCKER_COMPOSE_CMD logs -f        # View logs"
    echo "  $DOCKER_COMPOSE_CMD down           # Stop all"
    echo ""
    echo -e "${GREEN}🏴‍☠️ Happy treasure hunting!${NC}"
}

# ==========================================
# CLEANUP FUNCTIONS
# ==========================================

# Regular cleanup function
cleanup_docker() {
    echo -e "${BLUE}🧹 Docker Cleanup${NC}"
    echo "=================="
    echo ""

    # Stop and remove containers
    echo "🛑 Stopping containers..."
    docker ps -aq 2>/dev/null | xargs -r docker stop 2>/dev/null || echo "No containers to stop"
    docker ps -aq 2>/dev/null | xargs -r docker rm -f 2>/dev/null || echo "No containers to remove"

    # Clean system
    echo "🧽 Cleaning Docker system..."
    docker system prune -f 2>/dev/null || echo "System prune failed"
    docker image prune -f 2>/dev/null || echo "Image prune failed"
    docker volume prune -f 2>/dev/null || echo "Volume prune failed"
    docker network prune -f 2>/dev/null || echo "Network prune failed"

    # Clean specific directories
    echo "🧽 Cleaning Docker directories..."
    sudo rm -rf /var/lib/docker-tmp 2>/dev/null || true
    sudo rm -rf /tmp/docker-* 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✅ Docker cleanup complete!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Nuclear cleanup function
nuclear_cleanup() {
    echo -e "${RED}💥 Nuclear Docker Cleanup${NC}"
    echo "=========================="
    echo ""
    echo -e "${RED}WARNING: This will remove ALL Docker data!${NC}"
    read -p "Are you sure? Type 'yes' to continue: " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    echo ""
    echo "🛑 Stopping services..."
    sudo systemctl stop docker containerd 2>/dev/null || true

    echo "🔥 Killing processes..."
    sudo pkill -9 -f docker 2>/dev/null || true
    sudo pkill -9 -f containerd 2>/dev/null || true

    echo "🗑️ Removing ALL Docker data..."
    sudo rm -rf /var/lib/docker* 2>/dev/null || true
    sudo rm -rf /var/lib/containerd* 2>/dev/null || true
    sudo rm -rf /run/docker* 2>/dev/null || true
    sudo rm -rf /run/containerd* 2>/dev/null || true
    sudo rm -f /var/run/docker.sock /run/docker.sock 2>/dev/null || true

    echo "🧽 Cleaning configuration..."
    sudo rm -rf ~/.docker 2>/dev/null || true

    echo "🚀 Restarting services..."
    sudo systemctl start containerd 2>/dev/null || true
    sudo systemctl start docker 2>/dev/null || true

    sleep 5

    echo "🔍 Testing Docker..."
    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker restarted successfully!${NC}"
    else
        echo -e "${RED}❌ Docker restart failed. You may need to reinstall Docker.${NC}"
    fi

    echo ""
    echo -e "${GREEN}✅ Nuclear cleanup complete!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# ==========================================
# MENU SYSTEM
# ==========================================

# Main menu
show_menu() {
    echo -e "${BLUE}🏴‍☠️ Arrmematey - Choose Your Action${NC}"
    echo "===================================="
    echo ""
    echo -e "${CYAN}1) 🚀 Install Arrmematey${NC}"
    echo "   Complete media automation stack installation"
    echo ""
    echo -e "${YELLOW}2) 🧹 Clean Up Docker${NC}"
    echo "   Remove containers, unused images, and volumes"
    echo ""
    echo -e "${RED}3) 💥 Nuclear Clean Up${NC}"
    echo "   Aggressive cleanup - fixes severe Docker issues"
    echo ""
    echo -e "${BLUE}4) 🗄️  Storage Management${NC}"
    echo "   Expand, move, or manage Docker storage"
    echo ""
    echo -e "${GREEN}5) ℹ️  Help${NC}"
    echo "   Show detailed information about each option"
    echo ""
    read -p "Select an option (1-5): " choice
}

# Docker Storage Driver Configuration Management
configure_docker_storage_driver() {
    echo ""
    echo -e "${BLUE}🔧 Docker Storage Driver Configuration${NC}"
    echo "======================================"
    echo ""

    # Show current Docker storage configuration
    echo -e "${BLUE}Current Docker Storage Configuration:${NC}"
    local docker_info=$(docker info 2>/dev/null)
    local storage_driver=$(echo "$docker_info" | grep "Storage Driver:" | awk '{print $3}')
    local backing_fs=$(echo "$docker_info" | grep "Backing Filesystem:" | awk '{print $3}')
    local docker_root=$(echo "$docker_info" | grep "Docker Root Dir:" | awk '{print $4}')

    echo "  Storage Driver: $storage_driver"
    echo "  Backing Filesystem: ${backing_fs:-unknown}"
    echo "  Docker Root Dir: ${docker_root:-unknown}"
    echo ""

    # Check current Docker root usage
    if [[ -n "$docker_root" && -d "$docker_root" ]]; then
        local root_used=$(df "$docker_root" | tail -1 | awk '{print $3}')
        local root_available=$(df "$docker_root" | tail -1 | awk '{print $4}')
        local root_total=$(df "$docker_root" | tail -1 | awk '{print $2}')
        echo -e "${BLUE}Docker Root Usage:${NC}"
        echo "  Total: $(echo $root_total | numfmt --to=iec)"
        echo "  Used:  $(echo $root_used | numfmt --to=iec)"
        echo "  Free:  $(echo $root_available | numfmt --to=iec)"
        echo ""

        # Check overlay2 usage if applicable
        if [[ "$storage_driver" == "overlay2" || "$storage_driver" == "overlayfs" ]]; then
            echo -e "${BLUE}Overlay2 Layer Management:${NC}"
            local overlay_count=$(find "$docker_root/overlay2" -maxdepth 1 -type d 2>/dev/null | wc -l)
            local overlay_usage=$(du -sh "$docker_root/overlay2" 2>/dev/null | awk '{print $1}')
            echo "  Layers: $((overlay_count - 1)) directories"
            echo "  Usage: $overlay_usage"
            echo ""
        fi
    fi

    echo -e "${CYAN}Docker Storage Configuration Options:${NC}"
    echo ""
    echo "1) 🔧 Increase container writable layer size limits"
    echo "2) 🧹 Clean unused image layers and volumes"
    echo "3) 📁 Expand Docker root directory to more space"
    echo "4) ⚙️  Change storage driver (advanced)"
    echo "5) 📊 Detailed storage analysis"
    echo "6) 🔄 Return to storage management menu"
    echo ""
    read -p "Select option (1-6): " driver_choice

    case $driver_choice in
        1)
            configure_container_size_limits
            ;;
        2)
            perform_docker_cleanup
            ;;
        3)
            expand_docker_root_directory
            ;;
        4)
            change_storage_driver
            ;;
        5)
            detailed_storage_analysis
            ;;
        6)
            fix_broken_docker
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac

    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Configure container writable layer size limits
configure_container_size_limits() {
    echo ""
    echo -e "${BLUE}🔧 Container Writable Layer Size Limits${NC}"
    echo "========================================"
    echo ""

    local storage_driver=$(docker info 2>/dev/null | grep "Storage Driver:" | awk '{print $3}')
    echo -e "${BLUE}Current storage driver: $storage_driver${NC}"
    echo ""

    # Check which drivers support size limits
    case $storage_driver in
        "overlay2"|"overlayfs")
            echo -e "${BLUE}Overlay2/OverlayFS Size Configuration:${NC}"
            echo "Current container size limits can be set per-container or globally."
            echo ""
            echo "Global size limit for new containers:"
            echo "  Current: Often defaults to unlimited (depends on backing filesystem)"
            echo "  Recommended: 10G-50G for most use cases"
            echo ""
            echo "⚠️  Changing this requires Docker daemon restart!"
            echo ""
            read -p "Would you like to configure overlay2 size limits? (yes/NO): " configure_overlay

            if [[ "$configure_overlay" == "yes" ]]; then
                echo ""
                echo -e "${YELLOW}Available overlay2 size options:${NC}"
                echo "1) Set global size limit (e.g., 20G per container)"
                echo "2) Show current daemon.json configuration"
                echo "3) Set per-container size limit on next run"
                echo ""
                read -p "Select option (1-3): " overlay_choice

                case $overlay_choice in
                    1)
                        configure_overlay2_global_size
                        ;;
                    2)
                        check_current_daemon_config
                        ;;
                    3)
                        show_per_container_size_example
                        ;;
                    *)
                        echo "Invalid choice."
                        ;;
                esac
            fi
            ;;
        "vfs")
            echo -e "${BLUE}VFS Storage Driver Size Configuration:${NC}"
            echo "VFS supports global size limits. Example configuration:"
            echo ""
            echo '{"storage-driver": "vfs", "storage-opts": ["size=256M"]}'
            echo ""
            echo "This sets 256MB limit for each container writable layer."
            ;;
        "zfs")
            echo -e "${BLUE}ZFS Storage Driver Size Configuration:${NC}"
            echo "ZFS supports container size quotas. Example:"
            echo ""
            echo '{"storage-driver": "zfs", "storage-opts": ["size=256M"]}'
            echo ""
            echo "This sets 256MB limit for each container writable layer."
            ;;
        *)
            echo -e "${YELLOW}⚠️  Storage driver $storage_driver may not support size limits${NC}"
            echo "Check Docker documentation for $storage_driver size configuration."
            ;;
    esac
}

# Configure overlay2 global size limit
configure_overlay2_global_size() {
    echo ""
    echo -e "${BLUE}🔧 Configure Overlay2 Global Size Limit${NC}"
    echo "=========================================="
    echo ""

    echo "Current Docker daemon.json:"
    if [[ -f "/etc/docker/daemon.json" ]]; then
        cat /etc/docker/daemon.json 2>/dev/null || echo "  (empty or unreadable)"
    else
        echo "  (no daemon.json file exists)"
    fi
    echo ""

    echo -e "${YELLOW}Recommended overlay2 size configuration:${NC}"
    echo '{"storage-driver": "overlay2", "storage-opts": ["overlay2.size=20G"]}'
    echo ""
    echo "This sets a 20GB limit for each container writable layer."
    echo "Choose appropriate size for your use case:"
    echo "  - 10G: For lightweight containers"
    echo "  - 20G: For medium containers (recommended)"
    echo "  - 50G: For containers with large data volumes"
    echo ""

    read -p "Enter size limit (e.g., 20G) or press Enter to skip: " size_limit

    if [[ -n "$size_limit" ]]; then
        echo ""
        echo -e "${RED}⚠️  This will modify /etc/docker/daemon.json${NC}"
        echo -e "${RED}⚠️  Docker daemon must be restarted for changes to take effect${NC}"
        read -p "Proceed with configuration? (yes/NO): " confirm_config

        if [[ "$confirm_config" == "yes" ]]; then
            backup_and_configure_daemon_json "$size_limit"
        fi
    fi
}

# Backup and configure daemon.json
backup_and_configure_daemon_json() {
    local size_limit="$1"
    local config_dir="/etc/docker"

    echo ""
    echo -e "${BLUE}🔧 Configuring Docker daemon.json...${NC}"

    # Create backup
    if [[ -f "$config_dir/daemon.json" ]]; then
        sudo cp "$config_dir/daemon.json" "$config_dir/daemon.json.backup.$(date +%Y%m%d-%H%M%S)"
        echo -e "${GREEN}✅ Backed up existing daemon.json${NC}"
    fi

    # Create or update daemon.json
    sudo tee "$config_dir/daemon.json" > /dev/null << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.size=$size_limit"
  ]
}
EOF

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Updated daemon.json successfully${NC}"
        echo ""
        echo -e "${YELLOW}To apply changes, run:${NC}"
        echo "sudo systemctl restart docker"
        echo ""
        read -p "Restart Docker daemon now? (yes/NO): " restart_choice

        if [[ "$restart_choice" == "yes" ]]; then
            echo "Restarting Docker daemon..."
            if sudo systemctl restart docker && sleep 5 && docker ps &>/dev/null; then
                echo -e "${GREEN}✅ Docker daemon restarted successfully${NC}"
                echo "New container size limit: $size_limit per container"
            else
                echo -e "${RED}❌ Docker daemon restart failed${NC}"
                echo "This usually means overlay2.size is not supported on your filesystem."
                echo ""
                echo "🔧 Automatic fix: Remove the problematic configuration..."
                
                # Find the most recent backup
                local latest_backup=$(ls "$config_dir/daemon.json.backup."* 2>/dev/null | sort | tail -1)
                if [[ -n "$latest_backup" ]]; then
                    echo "Restoring from backup: $latest_backup"
                    sudo cp "$latest_backup" "$config_dir/daemon.json"
                else
                    echo "Creating minimal working configuration..."
                    sudo tee "$config_dir/daemon.json" > /dev/null << EOF
{
  "storage-driver": "overlay2"
}
EOF
                fi
                
                echo "Restarting Docker with safe configuration..."
                if sudo systemctl restart docker && sleep 3 && docker ps &>/dev/null; then
                    echo -e "${GREEN}✅ Docker restored to working state${NC}"
                    echo ""
                    echo -e "${YELLOW}Note: overlay2.size limits are not supported on your current filesystem${NC}"
                    echo "Consider upgrading to XFS or using a different storage approach."
                else
                    echo -e "${RED}❌ Docker still broken - manual intervention required${NC}"
                    echo "Use Storage Management → Fix Broken Docker Daemon for advanced options"
                fi
            fi
        fi
    else
        echo -e "${RED}❌ Failed to update daemon.json${NC}"
    fi
}

# Expand Docker root directory to different filesystem
expand_docker_root_directory() {
    echo ""
    echo -e "${BLUE}📁 Expand Docker Root Directory${NC}"
    echo "================================="
    echo ""

    local current_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
    echo -e "${BLUE}Current Docker root: $current_root${NC}"

    echo ""
    echo "This will move Docker to a location with more space."
    echo "Available locations with sufficient space:"
    echo ""

    local available_locations=()
    local location_counter=1

    # Check common mount points
    for mount_point in "$HOME" "/opt" "/usr/local" "/var/lib" "/tmp"; do
        if [[ -d "$mount_point" && "$mount_point" != "$current_root" ]]; then
            local mount_available=$(df "$mount_point" | tail -1 | awk '{print $4}')
            local mount_available_gb=$((mount_available / 1024 / 1024))
            if [[ $mount_available_gb -gt 50 ]]; then
                echo "  $location_counter) $mount_point (${mount_available_gb}GB free)"
                available_locations+=("$mount_point")
                ((location_counter++))
            fi
        fi
    done

    if [[ ${#available_locations[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No suitable locations found with 50GB+ free space${NC}"
        echo "Consider:"
        echo "  - Adding a new disk and mounting it"
        echo "  - Creating a symbolic link to a larger filesystem"
        echo "  - Expanding the current filesystem"
        return 1
    fi

    echo ""
    read -p "Select location (1-${#available_locations[@]}) or press Enter to cancel: " location_choice

    if [[ -z "$location_choice" ]] || ! [[ "$location_choice" =~ ^[0-9]+$ ]] || [[ $location_choice -lt 1 ]] || [[ $location_choice -gt ${#available_locations[@]} ]]; then
        echo "Operation cancelled."
        return 1
    fi

    local selected_location="${available_locations[$((location_choice - 1))]}"
    move_docker_to_location "$selected_location"
}

# Move Docker to specific location
move_docker_to_location() {
    local new_location="$1"
    local current_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
    local new_docker_root="$new_location/docker-data"
    local backup_name="docker-backup-$(date +%Y%m%d-%H%M%S)"

    echo ""
    echo -e "${YELLOW}Moving Docker from ${current_root} to ${new_docker_root}${NC}"
    echo -e "${YELLOW}Creating backup at: ${current_root}.${backup_name}${NC}"
    echo ""

    read -p "Continue? This will stop Docker and may take several minutes. (yes/NO): " confirm_move

    if [[ "$confirm_move" != "yes" ]]; then
        echo "Operation cancelled."
        return 1
    fi

    echo ""
    echo "🛑 Stopping Docker daemon..."
    sudo systemctl stop docker

    echo "📦 Creating backup..."
    sudo mv "$current_root" "$current_root.$backup_name"

    echo "📁 Creating new Docker directory..."
    sudo mkdir -p "$new_docker_root"
    sudo chmod 700 "$new_docker_root"

    echo "⚙️ Updating Docker daemon configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$new_docker_root"
}
EOF

    echo "🚀 Starting Docker daemon..."
    sudo systemctl start docker
    sleep 10

    echo "🔍 Verifying Docker is working..."
    if docker ps &>/dev/null; then
        echo -e "${GREEN}✅ Docker moved successfully!${NC}"
        local new_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
        echo -e "${GREEN}✅ New Docker root: ${new_root}${NC}"
        echo -e "${BLUE}Backup location: ${current_root}.${backup_name}${NC}"
        echo ""
        echo -e "${GREEN}You can safely remove the backup once everything is working:${NC}"
        echo "sudo rm -rf ${current_root}.${backup_name}"
    else
        echo -e "${RED}❌ Docker failed to start after move${NC}"
        echo "🛠️ Restoring from backup..."
        sudo rm -rf "$current_root"
        sudo mv "$current_root.$backup_name" "$current_root"
        sudo rm -f /etc/docker/daemon.json
        sudo systemctl start docker
        echo "🔄 Docker restored to original location"
        return 1
    fi
}

# Check current daemon.json configuration
check_current_daemon_config() {
    echo ""
    echo -e "${BLUE}Current Docker daemon.json Configuration:${NC}"
    if [[ -f "/etc/docker/daemon.json" ]]; then
        cat /etc/docker/daemon.json
    else
        echo "No daemon.json file exists. Using default configuration."
    fi
    echo ""
    echo -e "${BLUE}Active Docker storage settings:${NC}"
    docker info | grep -E "(Storage Driver|Backing Filesystem|Docker Root Dir)"
}

# Show per-container size limit example
show_per_container_size_example() {
    echo ""
    echo -e "${BLUE}🔧 Per-Container Size Limit Example${NC}"
    echo "====================================="
    echo ""
    echo "Set size limit when running a container:"
    echo ""
    echo "docker run --storage-opt size=20G your-image"
    echo ""
    echo "Or in docker-compose.yml:"
    echo ""
    echo "services:"
    echo "  your-service:"
    echo "    image: your-image"
    echo "    command: your-command"
    echo "    storage_opt:"
    echo "      - size=20G"
    echo ""
    echo "This sets a 20GB limit for that specific container."
}

# Detailed storage analysis
detailed_storage_analysis() {
    echo ""
    echo -e "${BLUE}📊 Detailed Docker Storage Analysis${NC}"
    echo "====================================="
    echo ""

    local docker_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')

    if [[ -z "$docker_root" ]]; then
        echo -e "${RED}❌ Could not determine Docker root directory${NC}"
        return 1
    fi

    echo -e "${BLUE}Docker Storage Breakdown:${NC}"

    # Check each storage component
    local components=("overlay2" "image" "containers" "volumes" "network")

    for component in "${components[@]}"; do
        local component_path="$docker_root/$component"
        if [[ -d "$component_path" ]]; then
            local component_size=$(du -sh "$component_path" 2>/dev/null | awk '{print $1}')
            local component_count=$(find "$component_path" -maxdepth 1 -type d 2>/dev/null | wc -l)
            echo "  ${component}: $component_size ($((component_count - 1)) items)"
        else
            echo "  ${component}: not found"
        fi
    done

    echo ""
    echo -e "${BLUE}Container Breakdown:${NC}"
    if command -v docker ps &>/dev/null; then
        local running_containers=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo "Could not get container info")
        echo "$running_containers"
    fi

    echo ""
    echo -e "${BLUE}Image Breakdown:${NC}"
    if command -v docker images &>/dev/null; then
        local images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || echo "Could not get image info")
        echo "$images"
    fi

    echo ""
    echo -e "${BLUE}Largest Docker Directories:${NC}"
    echo "Finding largest directories in $docker_root..."
    echo ""
    sudo du -h --max-depth=2 "$docker_root" 2>/dev/null | sort -hr | head -10
}

# Change storage driver (advanced)
change_storage_driver() {
    echo ""
    echo -e "${BLUE}⚙️  Change Docker Storage Driver (Advanced)${NC}"
    echo "=============================================="
    echo ""

    local current_driver=$(docker info 2>/dev/null | grep "Storage Driver:" | awk '{print $3}')
    echo -e "${BLUE}Current storage driver: $current_driver${NC}"
    echo ""

    echo -e "${RED}⚠️  WARNING: Changing storage drivers is dangerous!${NC}"
    echo -e "${RED}⚠️  This will delete all Docker data!${NC}"
    echo ""
    echo "Storage drivers available:"
    echo "  overlay2: Default, good performance, XFS recommended"
    echo "  devicemapper: Good performance, requires LVM setup"
    echo "  zfs: Good performance, requires ZFS setup"
    echo "  btrfs: Good performance, requires Btrfs filesystem"
    echo "  vfs: Simple but uses more space"
    echo ""

    read -p "Type 'YES-I-WANT-TO-LOSE-ALL-DOCKER-DATA' to continue: " confirm_change

    if [[ "$confirm_change" != "YES-I-WANT-TO-LOSE-ALL-DOCKER-DATA" ]]; then
        echo "Operation cancelled."
        return 1
    fi

    echo ""
    echo "Select new storage driver:"
    echo "1) overlay2 (recommended)"
    echo "2) devicemapper"
    echo "3) zfs"
    echo "4) btrfs"
    echo "5) vfs"
    echo ""
    read -p "Select driver (1-5): " driver_selection

    case $driver_selection in
        1)
            change_to_overlay2
            ;;
        2)
            change_to_devicemapper
            ;;
        3)
            change_to_zfs
            ;;
        4)
            change_to_btrfs
            ;;
        5)
            change_to_vfs
            ;;
        *)
            echo "Invalid selection."
            ;;
    esac
}

# Change to overlay2 driver
change_to_overlay2() {
    echo ""
    echo -e "${BLUE}Changing to overlay2 storage driver${NC}"
    echo ""

    echo "Creating daemon.json configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "overlay2"
}
EOF

    echo "Docker will use overlay2 on next restart."
    echo "All existing Docker data will be lost!"
    echo ""
    read -p "Restart Docker now? (yes/NO): " restart_choice

    if [[ "$restart_choice" == "yes" ]]; then
        sudo systemctl restart docker
        echo "Docker restarted with overlay2 driver."
    fi
}

# Change to devicemapper driver
change_to_devicemapper() {
    echo ""
    echo -e "${BLUE}Changing to devicemapper storage driver${NC}"
    echo ""

    echo "This requires LVM setup. Checking for LVM..."
    if ! command -v vgs &>/dev/null; then
        echo -e "${RED}❌ LVM tools not available${NC}"
        echo "Install LVM: sudo apt install lvm2"
        return 1
    fi

    echo "Creating devicemapper configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.thinpooldev=/dev/mapper/docker-thinpool",
    "dm.use_deferred_removal=true",
    "dm.use_deferred_deletion=true"
  ]
}
EOF

    echo "Devicemapper requires thin pool setup. Manual configuration needed."
    echo "Docker will use devicemapper on next restart."
    echo ""
    read -p "Restart Docker now? (yes/NO): " restart_choice

    if [[ "$restart_choice" == "yes" ]]; then
        sudo systemctl restart docker
        echo "Docker restarted with devicemapper driver."
    fi
}

# Change to ZFS driver
change_to_zfs() {
    echo ""
    echo -e "${BLUE}Changing to ZFS storage driver${NC}"
    echo ""

    if ! command -v zpool &>/dev/null; then
        echo -e "${RED}❌ ZFS tools not available${NC}"
        echo "Install ZFS: sudo apt install zfsutils-linux"
        return 1
    fi

    echo "Creating ZFS configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "zfs",
  "storage-opts": [
    "zfs.fsname=zroot/docker"
  ]
}
EOF

    echo "ZFS requires filesystem setup. Manual configuration needed."
    echo "Docker will use ZFS on next restart."
    echo ""
    read -p "Restart Docker now? (yes/NO): " restart_choice

    if [[ "$restart_choice" == "yes" ]]; then
        sudo systemctl restart docker
        echo "Docker restarted with ZFS driver."
    fi
}

# Change to Btrfs driver
change_to_btrfs() {
    echo ""
    echo -e "${BLUE}Changing to Btrfs storage driver${NC}"
    echo ""

    if ! command -v btrfs &>/dev/null; then
        echo -e "${RED}❌ Btrfs tools not available${NC}"
        echo "Install Btrfs: sudo apt install btrfs-progs"
        return 1
    fi

    echo "Creating Btrfs configuration..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "btrfs"
}
EOF

    echo "Btrfs requires filesystem setup. Manual configuration needed."
    echo "Docker will use Btrfs on next restart."
    echo ""
    read -p "Restart Docker now? (yes/NO): " restart_choice

    if [[ "$restart_choice" == "yes" ]]; then
        sudo systemctl restart docker
        echo "Docker restarted with Btrfs driver."
    fi
}

# Change to VFS driver
change_to_vfs() {
    echo ""
    echo -e "${BLUE}Changing to VFS storage driver${NC}"
    echo ""

    echo "Creating VFS configuration with size limits..."
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "storage-driver": "vfs",
  "storage-opts": [
    "size=256M"
  ]
}
EOF

    echo "VFS is simple but uses more disk space."
    echo "Docker will use VFS on next restart."
    echo ""
    read -p "Restart Docker now? (yes/NO): " restart_choice

    if [[ "$restart_choice" == "yes" ]]; then
        sudo systemctl restart docker
        echo "Docker restarted with VFS driver."
    fi
}

# Expand generic filesystem
expand_generic_filesystem() {
    echo ""
    echo -e "${BLUE}🔧 Generic Host Filesystem Expansion${NC}"
    echo "======================================"
    echo ""

    local docker_root=$(docker info 2>/dev/null | grep "Docker Root Dir:" | awk '{print $4}')
    if [[ -n "$docker_root" ]]; then
        local host_filesystem=$(df "$docker_root" | tail -1 | awk '{print $1}')
        local host_mount=$(df "$docker_root" | tail -1 | awk '{print $6}')

        echo -e "${BLUE}Host filesystem for Docker:${NC}"
        echo "  Device: $host_filesystem"
        echo "  Mount: $host_mount"
        echo ""

        echo "General filesystem expansion approaches:"
        echo ""
        echo "1. LVM-based systems:"
        echo "   sudo vgdisplay     # Check available space"
        echo "   sudo lvextend -l+100%FREE /dev/mapper/root-lv"
        echo "   sudo resize2fs /dev/mapper/root-lv     # ext4"
        echo "   sudo xfs_growfs /                     # XFS"
        echo ""
        echo "2. Direct disk partitions:"
        echo "   sudo fdisk -l           # Check unallocated space"
        echo "   sudo fdisk /dev/sdX     # Create new partition"
        echo "   sudo mkfs.ext4 /dev/sdX1   # Format new partition"
        echo "   sudo mkdir /mnt/new-docker"
        echo "   sudo mount /dev/sdX1 /mnt/new-docker"
        echo ""
        echo "3. Move Docker data:"
        echo "   This script can move Docker to a larger filesystem"
        echo ""

        echo -e "${YELLOW}Recommended: Use this script's Docker root expansion feature${NC}"
        echo "Go to: Storage Management → Expand Docker Storage → Move Docker Storage"
    fi

    echo ""
    read -p "Press Enter to return to storage management menu..."
}

# Storage management menu
show_storage_menu() {
    echo ""
    echo -e "${BLUE}🗄️  Docker Storage Management${NC}"
    echo "==============================="
    echo ""
    echo -e "${BLUE}Current Docker Status:${NC}"

    # Show current Docker storage info
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        local docker_info=$(docker info 2>/dev/null)
        local storage_driver=$(echo "$docker_info" | grep "Storage Driver:" | awk '{print $3}')
        local docker_root_dir=$(echo "$docker_info" | grep "Docker Root Dir:" | awk '{print $4}')

        echo "  Storage Driver: $storage_driver"
        echo "  Root Directory: $docker_root_dir"

        # Show storage space
        if [[ -n "$docker_root_dir" && -d "$docker_root_dir" ]]; then
            local root_available=$(df "$docker_root_dir" | tail -1 | awk '{print $4}')
            local root_available_gb=$((root_available / 1024 / 1024))
            echo "  Available Space: ${root_available_gb}GB"
        fi
        echo ""
    else
        echo "  ❌ Docker not running or not installed"
        echo ""
        read -p "Press Enter to return to main menu..."
        return
    fi

    echo -e "${CYAN}Storage Management Options:${NC}"
    echo ""
    echo "1) 📊 Check Storage Status"
    echo "2) 🔧 Configure Docker Storage Drivers"
    echo "3) 📦 Move Docker to Different Location"
    echo "4) 🧹 Clean Docker Storage"
    echo "5) 🔄 Return to Main Menu"
    echo ""
    read -p "Select option (1-5): " storage_choice

    case $storage_choice in
        1)
            check_docker_storage
            echo ""
            read -p "Press Enter to continue..."
            show_storage_menu
            ;;
        2)
            configure_docker_storage_driver
            echo ""
            read -p "Press Enter to continue..."
            show_storage_menu
            ;;
        3)
            expand_docker_root_directory
            echo ""
            read -p "Press Enter to continue..."
            show_storage_menu
            ;;
        4)
            perform_docker_cleanup
            echo ""
            read -p "Press Enter to continue..."
            show_storage_menu
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 2
            show_storage_menu
            ;;
    esac
}

# Help function
show_help() {
    echo ""
    echo -e "${BLUE}📖 Detailed Help${NC}"
    echo "================="
    echo ""
    echo -e "${CYAN}🚀 Option 1 - Install Arrmematey${NC}"
    echo "  • Installs complete media automation stack"
    echo "  • Includes Prowlarr, Sonarr, Radarr, Lidarr, SABnzbd, qBittorrent, Jellyseerr"
    echo "  • Sets up Mullvad VPN protection"
    echo "  • Creates management UI"
    echo "  • Automatically detects and fixes Docker storage issues"
    echo "  • Requires: Docker, curl, Mullvad account"
    echo ""
    echo -e "${YELLOW}🧹 Option 2 - Clean Up Docker${NC}"
    echo "  • Removes all Docker containers"
    echo "  • Prunes unused images and volumes"
    echo "  • Cleans system cache"
    echo "  • Use when: Installation fails or Docker is cluttered"
    echo ""
    echo -e "${RED}💥 Option 3 - Nuclear Clean Up${NC}"
    echo "  • Complete Docker/containerd rebuild"
    echo "  • Removes ALL Docker data and configuration"
    echo "  • Kills hanging processes"
    echo "  • Use when: Severe Docker issues or containerd errors"
    echo ""
    echo -e "${BLUE}🗄️  Option 4 - Storage Management${NC}"
    echo "  • Comprehensive Docker storage driver management"
    echo "  • Configure container writable layer size limits"
    echo "  • Move Docker data to larger filesystem"
    echo "  • Detailed storage analysis and breakdown"
    echo "  • Safe Docker data relocation with backup/restore"
    echo "  • Use when: Docker storage issues or need capacity expansion"
    echo ""
    echo -e "${ORANGE}🔧 Option 5 - Emergency Docker Fix${NC}"
    echo "  • Quick fix for broken Docker daemon"
    echo "  • Remove problematic daemon.json configuration"
    echo "  • Restore from backup or create working config"
    echo "  • Works even when Docker won't start"
    echo "  • Use when: Docker daemon fails to start"
    echo ""
    echo -e "${GREEN}💡 Docker Storage Features (v$SCRIPT_VERSION):${NC}"
    echo "  • Container writable layer size limit configuration"
    echo "  • Automated Docker daemon.json backup and configuration"
    echo "  • Docker root directory expansion to different filesystems"
    echo "  • Detailed overlay2/overlayfs storage analysis"
    echo "  • Safe storage driver configuration and changes"
    echo "  • Per-container and global size limit management"
    echo "  • Comprehensive Docker storage breakdown and analysis"
    echo "  • Emergency Docker recovery tools (works when broken)"
    echo ""
    echo -e "${GREEN}ℹ️  Option 6 - Help (this page)${NC}"
    echo "  • Shows detailed information"
    echo ""
    echo "Press Enter to return to menu..."
    read
}

# Check for script updates
check_for_updates() {
    echo -e "${BLUE}📦 Checking for script updates...${NC}"
    echo ""

    # Get remote script info
    local remote_script=""
    local remote_version=""
    local remote_date=""

    # Try to fetch remote version (non-blocking)
    remote_script=$(timeout 5s curl -s -f "https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh" 2>/dev/null || echo "")
    if [[ -n "$remote_script" ]]; then
        remote_version=$(echo "$remote_script" | grep -E 'SCRIPT_VERSION=".*"' | sed 's/SCRIPT_VERSION="//g' | sed 's/"//g' | head -1)
        remote_date=$(echo "$remote_script" | grep -E 'SCRIPT_DATE=".*"' | sed 's/SCRIPT_DATE="//g' | sed 's/"//g' | head -1)
    fi

    # Show version info
    echo -e "${BLUE}Script Version Information:${NC}"
    echo "  Local Version: $SCRIPT_VERSION ($SCRIPT_DATE)"
    if [[ -n "$remote_version" ]]; then
        echo "  Remote Version: $remote_version ($remote_date)"
        if [[ "$remote_version" != "$SCRIPT_VERSION" ]]; then
            echo ""
            echo -e "${YELLOW}⚠️  Update Available!${NC}"
            echo "You're running an older version of the script."
            echo "New features and fixes are available."
            echo ""
            echo -e "${BLUE}To get the latest version:${NC}"
            echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)\""
            echo ""
            read -p "Continue with current version? (yes/NO): " continue_choice
            if [[ "$continue_choice" != "yes" ]]; then
                echo -e "${GREEN}Exiting to download latest version...${NC}"
                exit 0
            fi
        else
            echo -e "${GREEN}✅ You're running the latest version!${NC}"
        fi
    else
        echo "  Remote Version: Unable to check (network issue)"
        echo -e "${YELLOW}⚠️  Could not verify latest version${NC}"
        echo "This may be due to network issues or GitHub being unavailable."
    fi
    echo ""
}

# ==========================================
# MAIN EXECUTION
# ==========================================

echo -e "${BLUE}🏴‍☠️ Arrmematey One-Line Installer${NC}"
echo "================================="
echo ""
echo -e "${BLUE}Version: $SCRIPT_VERSION ($SCRIPT_DATE)${NC}"
echo ""

# Check for updates
check_for_updates

# Check if Docker is broken and offer immediate fix
if command -v docker &> /dev/null; then
    if ! docker ps &> /dev/null 2>&1; then
        echo -e "${RED}🚨 Docker daemon appears to be broken!${NC}"
        echo ""
        echo "Options:"
        echo "1) 🗄️  Storage Management → Fix Broken Docker (recommended)"
        echo "2) 🚀 Continue to main menu"
        echo ""
        read -p "Select option (1-2): " docker_fix_choice

        if [[ "$docker_fix_choice" == "1" ]]; then
            echo ""
            show_storage_menu
            docker fix_broken_docker
            read -p "Press Enter to continue to main menu..."
        fi
        echo ""
    fi
fi

# Main menu loop
while true; do
    show_menu

    case $choice in
        1)
            echo ""
            echo -e "${GREEN}🚀 Starting Arrmematey Installation...${NC}"
            echo ""
            # Run the Wireguard-only installation process
            check_docker
            get_mullvad_zip
            create_config

            # Extract Wireguard credentials from zip
            if [[ -f "$(pwd)/wireguard-setup.sh" ]]; then
                bash wireguard-setup.sh "$ZIP_FILE"
            fi

            download_compose
            start_services
            show_completion
            break
            ;;
        2)
            cleanup_docker
            ;;
        3)
            nuclear_cleanup
            ;;
        4)
            show_storage_menu
            ;;
        5)
            # Emergency Docker fix
            echo ""
            echo -e "${ORANGE}🔧 Emergency Docker Fix${NC}"
            echo "========================"
            echo ""
            fix_broken_docker
            echo ""
            read -p "Press Enter to return to main menu..."
            ;;
        6)
            show_help
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-6.${NC}"
            sleep 2
            ;;
    esac
    echo ""
done