###############################################################################
# Dependency Manager Module
# Progressive dependency checking and installation
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

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check package version
check_version() {
    local package=$1
    local version_check=$2

    if command_exists "$package"; then
        local current_version
        current_version=$($package $version_check 2>/dev/null | head -n1 || echo "unknown")
        echo "$current_version"
        return 0
    else
        return 1
    fi
}

# Install package via apt
install_package() {
    local package=$1

    print_info "Installing $package..."
    if apt-get install -y "$package" &> /tmp/apt-install.log; then
        print_success "Installed $package"
        return 0
    else
        print_error "Failed to install $package"
        cat /tmp/apt-install.log
        return 1
    fi
}

# Phase 1: Basic System Dependencies
check_basic_dependencies() {
    print_step "Phase 1: Checking basic system dependencies..."

    local basic_deps=("curl" "wget" "git" "gnupg" "ca-certificates" "software-properties-common" "apt-transport-https")
    local missing_deps=()

    for dep in "${basic_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
            print_warning "Missing: $dep"
        else
            print_success "Found: $dep"
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_step "Installing missing basic dependencies..."
        for dep in "${missing_deps[@]}"; do
            install_package "$dep"
        done
    else
        print_success "All basic dependencies are installed"
    fi

    return 0
}

# Phase 2: Docker Dependencies
check_docker_dependencies() {
    print_step "Phase 2: Checking Docker and related dependencies..."

    local docker_deps=("docker" "docker-compose" "containerd" "runc")
    local missing_deps=()

    for dep in "${docker_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
            print_warning "Missing: $dep"
        else
            print_success "Found: $dep"
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_step "Installing missing Docker dependencies..."

        # Update package lists
        print_info "Updating package lists..."
        apt-get update &> /tmp/apt-update.log

        # Install Docker via official script
        print_info "Installing Docker..."
        if curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
            sh /tmp/get-docker.sh &> /tmp/docker-install.log
            print_success "Docker installed successfully"

            # Install docker-compose plugin
            print_info "Installing Docker Compose plugin..."
            apt-get install -y docker-compose-plugin &> /tmp/docker-compose-install.log
            print_success "Docker Compose installed"

            # Cleanup
            rm -f /tmp/get-docker.sh
        else
            print_error "Failed to download Docker installation script"
            return 1
        fi

        # Start and enable Docker
        print_info "Starting Docker service..."
        systemctl start docker
        systemctl enable docker
        print_success "Docker service started and enabled"
    else
        print_success "All Docker dependencies are installed"
    fi

    # Verify Docker is working
    print_step "Verifying Docker installation..."
    if docker run --rm hello-world &> /dev/null; then
        print_success "Docker is working correctly"
    else
        print_warning "Docker may not be working properly"
        print_info "You may need to log out and back in, or run: newgrp docker"
    fi

    return 0
}

# Phase 3: Arrmematey Specific Dependencies
check_arrmematey_dependencies() {
    print_step "Phase 3: Checking Arrmematey-specific dependencies..."

    # Check for Node.js (for UI)
    if ! command_exists node; then
        print_warning "Node.js not found - will install"
        # Install Node.js from NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &> /tmp/nodejs-install.log
        apt-get install -y nodejs &>> /tmp/nodejs-install.log
        print_success "Node.js installed"
    else
        local node_version
        node_version=$(node --version)
        print_success "Found Node.js: $node_version"
    fi

    # Check for npm
    if ! command_exists npm; then
        print_warning "npm not found - installing"
        apt-get install -y npm &> /tmp/npm-install.log
        print_success "npm installed"
    else
        print_success "npm found"
    fi

    # Check for jq (for JSON processing)
    if ! command_exists jq; then
        print_warning "jq not found - installing"
        apt-get install -y jq &> /tmp/jq-install.log
        print_success "jq installed"
    else
        print_success "jq found"
    fi

    # Check available disk space (need at least 10GB)
    print_step "Checking disk space..."
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    local available_gb=$((available_space / 1024 / 1024))

    if [[ $available_gb -lt 10 ]]; then
        print_warning "Low disk space: ${available_gb}GB available"
        print_info "Arrmematey recommends at least 20GB for comfortable operation"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error_exit "Insufficient disk space"
        fi
    else
        print_success "Sufficient disk space: ${available_gb}GB available"
    fi

    # Check available memory (need at least 2GB)
    print_step "Checking system memory..."
    local total_mem
    total_mem=$(free -m | awk 'NR==2{print $2}')
    local total_gb=$((total_mem / 1024))

    if [[ $total_gb -lt 2 ]]; then
        print_warning "Low memory: ${total_gb}GB available"
        print_info "Arrmematey recommends at least 4GB for optimal performance"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error_exit "Insufficient memory"
        fi
    else
        print_success "Sufficient memory: ${total_gb}GB available"
    fi

    return 0
}

# Main function
check_and_install_dependencies() {
    print_step "Starting progressive dependency checking..."
    echo ""

    # Update package lists first
    print_info "Updating package lists..."
    apt-get update -qq

    # Run all phases
    check_basic_dependencies
    echo ""

    check_docker_dependencies
    echo ""

    check_arrmematey_dependencies
    echo ""

    print_success "All dependencies are installed and verified!"
    echo ""
    print_info "System is ready for Arrmematey installation"
}
