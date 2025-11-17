#!/bin/bash
###############################################################################
# SSH File Transfer Helper for Arrmematey
# Transfer Mullvad Wireguard zip file to remote server
###############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  📤 SSH FILE TRANSFER FOR ARRMEMATEY  📤                   ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if zip file exists locally
if [[ ! -f "mullvad_wireguard_linux_us_chi.zip" ]]; then
    echo -e "${YELLOW}⚠${NC} Mullvad zip file not found in current directory"
    echo ""
    echo "Please ensure you have downloaded your Wireguard zip from:"
    echo "https://mullvad.net/en/account/#/wireguard-config"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} Found: mullvad_wireguard_linux_us_chi.zip"
echo ""

# Get remote server details
echo "Enter your server details:"
echo ""
read -p "Server IP/Hostname: " server
read -p "Username: " username
read -p "Port [22]: " port
port=${port:-22}
read -p "Target directory [/opt/arrmematey]: " target_dir
target_dir=${target_dir:-/opt/arrmematey}

echo ""
echo -e "${BLUE}Transfer Options:${NC}"
echo "1) SCP (Secure Copy) - Standard, simple"
echo "2) RSYNC - Better for large files, shows progress"
echo "3) With SSH key - Use custom SSH key"
echo ""
read -p "Choose option [1-3] [1]: " transfer_method
transfer_method=${transfer_method:-1}

case $transfer_method in
    1)
        echo ""
        echo -e "${BLUE}Transferring via SCP...${NC}"
        scp -P "$port" mullvad_wireguard_linux_us_chi.zip "$username@$server:$target_dir/"
        ;;
    2)
        echo ""
        echo -e "${BLUE}Transferring via RSYNC...${NC}"
        rsync -avz -e "ssh -p $port" mullvad_wireguard_linux_us_chi.zip "$username@$server:$target_dir/"
        ;;
    3)
        echo ""
        read -p "SSH key path [~/.ssh/id_rsa]: " ssh_key
        ssh_key=${ssh_key:-~/.ssh/id_rsa}
        echo ""
        echo -e "${BLUE}Transferring with SSH key...${NC}"
        scp -P "$port" -i "$ssh_key" mullvad_wireguard_linux_us_chi.zip "$username@$server:$target_dir/"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓${NC} File transferred successfully!"
    echo ""
    echo -e "${BLUE}Next steps on your server:${NC}"
    echo "1. SSH into your server: ssh -p $port $username@$server"
    echo "2. Navigate to Arrmematey directory: cd $target_dir"
    echo "3. Run the Wireguard setup: ./wireguard-setup.sh mullvad_wireguard_linux_us_chi.zip"
    echo "4. Start services: docker compose up -d"
    echo ""
else
    echo ""
    echo -e "${RED}✗${NC} Transfer failed!"
    echo "Please check your server credentials and try again."
    exit 1
fi