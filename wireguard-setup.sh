#!/bin/bash
###############################################################################
# Wireguard-Only Setup for Arrmematey
# Extracts Mullvad Wireguard zip file and configures environment
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  🔐 WIREGUARD SETUP FOR ARRMEMATEY  🔐                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Extract Mullvad Wireguard configuration                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Function to find zip file
find_zip_file() {
    local zip_path=""

    # Check if path provided as argument
    if [[ -n "${1:-}" ]]; then
        if [[ -f "$1" ]]; then
            zip_path="$1"
            print_success "Using provided path: $zip_path"
        else
            print_error "File not found: $1"
            return 1
        fi
    fi

    # If not provided, look in common locations
    if [[ -z "$zip_path" ]]; then
        local search_paths=(
            "./mullvad_wireguard_*.zip"
            "$HOME/Downloads/mullvad_wireguard_*.zip"
            "/tmp/mullvad_wireguard_*.zip"
            "$(pwd)/mullvad_wireguard_*.zip"
        )

        for pattern in "${search_paths[@]}"; do
            if ls $pattern 1> /dev/null 2>&1; then
                zip_path=$(ls $pattern | head -1)
                print_success "Found zip file: $zip_path"
                break
            fi
        done
    fi

    if [[ -z "$zip_path" ]]; then
        print_error "Could not find Mullvad Wireguard zip file"
        echo ""
        echo "Please provide the path to your Mullvad Wireguard zip file:"
        echo "Example: /path/to/mullvad_wireguard_linux_us_chi.zip"
        echo ""
        read -p "Enter zip file path: " zip_path

        if [[ ! -f "$zip_path" ]]; then
            print_error "File not found: $zip_path"
            return 1
        fi
    fi

    # Return only the zip path (no other output)
    printf "%s\n" "$zip_path"
}

# Function to extract and validate zip
extract_zip() {
    local zip_path="$1"
    local extract_dir="/tmp/mullvad_wireguard_extract_$$"

    print_info "Extracting zip file to temporary directory..."

    # Create temp directory
    mkdir -p "$extract_dir"

    # Extract zip
    if ! unzip -q "$zip_path" -d "$extract_dir"; then
        print_error "Failed to extract zip file"
        rm -rf "$extract_dir"
        return 1
    fi

    # List contents
    print_info "Zip contents:"
    ls -lh "$extract_dir" >&2

    # Find first conf file
    local conf_file=$(find "$extract_dir" -name "*.conf" | head -1)

    if [[ -z "$conf_file" ]]; then
        print_error "No .conf files found in zip"
        rm -rf "$extract_dir"
        return 1
    fi

    print_success "Found configuration file: $(basename $conf_file)"
    echo "$extract_dir|$conf_file"
}

# Function to parse conf file
parse_conf_file() {
    local conf_file="$1"

    print_info "Parsing configuration file..."

    # Extract PrivateKey
    local private_key=$(grep "^PrivateKey" "$conf_file" | awk '{print $3}')

    if [[ -z "$private_key" ]]; then
        print_error "Could not find PrivateKey in conf file"
        return 1
    fi

    # Extract Address (IPv4 only, before comma)
    local address=$(grep "^Address" "$conf_file" | awk '{print $3}' | cut -d',' -f1)

    if [[ -z "$address" ]]; then
        print_error "Could not find Address in conf file"
        return 1
    fi

    print_success "Extracted configuration:"
    echo "  PrivateKey: ${private_key:0:20}..." >&2
    echo "  Address: $address" >&2
    echo "" >&2

    echo "$private_key|$address"
}

# Function to update docker-compose.yml
update_docker_compose() {
    local private_key="$1"
    local address="$2"

    print_info "Updating docker-compose.yml..."

    # Backup existing file
    if [[ -f "docker-compose.yml" ]]; then
        cp docker-compose.yml docker-compose.yml.backup
        print_success "Created backup: docker-compose.yml.backup"
    fi

    # Update WIREGUARD_PRIVATE_KEY
    if grep -q "WIREGUARD_PRIVATE_KEY" docker-compose.yml; then
        # Replace existing value
        sed -i "s|WIREGUARD_PRIVATE_KEY=.*|WIREGUARD_PRIVATE_KEY=$private_key|" docker-compose.yml
    else
        # Add after VPN_TYPE line
        sed -i "/VPN_TYPE=.*/a\\      - WIREGUARD_PRIVATE_KEY=$private_key" docker-compose.yml
    fi

    # Update WIREGUARD_ADDRESSES
    if grep -q "WIREGUARD_ADDRESSES" docker-compose.yml; then
        sed -i "s|WIREGUARD_ADDRESSES=.*|WIREGUARD_ADDRESSES=$address|" docker-compose.yml
    else
        sed -i "/WIREGUARD_PRIVATE_KEY=.*/a\\      - WIREGUARD_ADDRESSES=$address" docker-compose.yml
    fi

    # Set VPN_TYPE to wireguard
    sed -i "s|VPN_TYPE=.*|VPN_TYPE=wireguard|" docker-compose.yml

    print_success "docker-compose.yml updated"
}

# Function to update .env file
update_env_file() {
    local private_key="$1"
    local address="$2"
    local env_file="${HOME}/.env"

    print_info "Updating .env file..."

    # Create if doesn't exist
    if [[ ! -f "$env_file" ]]; then
        cat > "$env_file" <<EOF
# Arrmematey Configuration
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC

# VPN Configuration
VPN_TYPE=wireguard
EOF
        print_success "Created .env file"
    fi

    # Update or add variables
    update_env_var() {
        local var_name="$1"
        local var_value="$2"

        if grep -q "^${var_name}=" "$env_file"; then
            sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$env_file"
        else
            echo "${var_name}=${var_value}" >> "$env_file"
        fi
    }

    update_env_var "WIREGUARD_PRIVATE_KEY" "$private_key"
    update_env_var "WIREGUARD_ADDRESSES" "$address"
    update_env_var "VPN_TYPE" "wireguard"

    print_success ".env file updated: $env_file"
}

# Function to show summary
show_summary() {
    local private_key="$1"
    local address="$2"
    local city="$3"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ✅ WIREGUARD CONFIGURATION COMPLETE! ✅                     ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo "  VPN Type: Wireguard"
    echo "  Private Key: ${private_key:0:20}..."
    echo "  Address: $address"
    echo "  City: ${city:-not set}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Review updated files: docker-compose.yml and ~/.env"
    echo "  2. Set your desired city in docker-compose.yml:"
    echo "     - SERVER_Cities=us-ny  (for New York)"
    echo "     - SERVER_Cities=us-chi (for Chicago)"
    echo "     - SERVER_Cities=de-fra (for Frankfurt)"
    echo "  3. Start the stack: docker compose up -d"
    echo "  4. Check status: docker compose ps"
    echo ""
    echo -e "${YELLOW}Note:${NC} OpenVPN has been removed from Mullvad (Jan 2026)."
    echo "      Wireguard is now the only supported protocol."
    echo ""
}

# Main function
main() {
    print_header

    local zip_path
    local private_key
    local address
    local city

    # Find zip file
    zip_path=$(find_zip_file "${1:-}")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    # Extract zip
    local extract_result
    extract_result=$(extract_zip "$zip_path")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    local extract_dir="${extract_result%|*}"
    local conf_file="${extract_result#*|}"

    # Parse conf file
    local parse_result
    parse_result=$(parse_conf_file "$conf_file")
    if [[ $? -ne 0 ]]; then
        rm -rf "$extract_dir"
        exit 1
    fi

    private_key="${parse_result%|*}"
    address="${parse_result#*|}"

    # Cleanup temp directory
    rm -rf "$extract_dir"

    # Ask for city
    echo ""
    print_info "Select your VPN location:"
    echo "  Common cities: us-ny, us-chi, us-la, de-fra, nl-ams, uk-lon"
    echo ""
    read -p "Enter city code [us-chi]: " city
    [[ -z "$city" ]] && city="us-chi"

    # Update configuration files
    update_docker_compose "$private_key" "$address"
    update_env_file "$private_key" "$address"

    # Show summary
    show_summary "$private_key" "$address" "$city"

    # Final note about OpenVPN removal
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📢 IMPORTANT: OpenVPN Support Ending${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Mullvad will remove OpenVPN support on January 1, 2026."
    echo "This Wireguard-only configuration ensures future compatibility."
    echo ""
}

# Run main function
main "$@"