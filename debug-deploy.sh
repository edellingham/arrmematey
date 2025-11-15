#!/bin/bash

# Debug script to test Arrmematey deployment step by step
echo "🏴‍☠️ Arrmematey Deployment Debug Script"
echo "====================================="

echo ""
echo "1. Checking Proxmox environment..."
if command -v pct &> /dev/null; then
    echo "✅ pct command available"
else
    echo "❌ pct command not found - not on Proxmox"
    exit 1
fi

echo ""
echo "2. Testing storage detection..."
# Simulate get_host_storage function
AVAILABLE_MEDIA_PATHS=()
AVAILABLE_DOWNLOAD_PATHS=()
AVAILABLE_CONFIG_PATHS=()

echo "   Media paths found: ${#AVAILABLE_MEDIA_PATHS[@]}"
echo "   Download paths found: ${#AVAILABLE_DOWNLOAD_PATHS[@]}"
echo "   Config paths found: ${#AVAILABLE_CONFIG_PATHS[@]}"

echo ""
echo "3. Testing user input simulation..."
echo "   Simulating config selection: 1"
config_selection=1
CONFIG_CUSTOM_INDEX=1

echo "   CONFIG_CUSTOM_INDEX: $CONFIG_CUSTOM_INDEX"
echo "   config_selection == CONFIG_CUSTOM_INDEX: $((config_selection == CONFIG_CUSTOM_INDEX))"

echo ""
echo "4. If you saw the above output, the basic logic works."
echo "   Try running the real deployment script now:"
echo "   bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)\""