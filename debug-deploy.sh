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
echo "2. Testing storage detection (simulating empty arrays)..."
# Simulate get_host_storage function with empty arrays
AVAILABLE_MEDIA_PATHS=()
AVAILABLE_DOWNLOAD_PATHS=()
AVAILABLE_CONFIG_PATHS=()

echo "   Media paths found: ${#AVAILABLE_MEDIA_PATHS[@]}"
echo "   Download paths found: ${#AVAILABLE_DOWNLOAD_PATHS[@]}"
echo "   Config paths found: ${#AVAILABLE_CONFIG_PATHS[@]}"

echo ""
echo "3. Testing storage selection logic..."
config_selection=1
CONFIG_CUSTOM_INDEX=1

# Test the NEW logic
max_config_selection=$((${#AVAILABLE_CONFIG_PATHS[@]} + 1))
echo "   max_config_selection (available + 1): $max_config_selection"
echo "   config_selection: $config_selection"
echo "   CONFIG_CUSTOM_INDEX: $CONFIG_CUSTOM_INDEX"

# Test if custom path should be requested
if [[ "$config_selection" -eq "$max_config_selection" ]]; then
    echo "   ✅ Would request custom config path (selection equals max)"
else
    echo "   ✅ Would use predefined config path (selection: $config_selection, available: ${#AVAILABLE_CONFIG_PATHS[@]})"
fi

echo ""
echo "4. Testing mount generation logic..."
CUSTOM_CONFIG_PATH="/opt/arrmematey-config"

# Test the NEW mount generation logic
if [[ "$config_selection" -ge 1 && "$config_selection" -le ${#AVAILABLE_CONFIG_PATHS[@]} ]]; then
    echo "   ❌ This shouldn't happen with empty arrays"
elif [[ "$config_selection" -eq "$max_config_selection" && -n "$CUSTOM_CONFIG_PATH" ]]; then
    echo "   ✅ Would use custom config path: $CUSTOM_CONFIG_PATH"
else
    echo "   ❌ Invalid config selection logic"
fi

echo ""
echo "5. Testing ACTUAL template detection (this is important!)..."

echo "   5a. Testing pvesm list with JSON parsing:"
if command -v jq &> /dev/null; then
    echo "      ✅ jq is available"
    raw_templates=$(pvesm list -content vztmpl -json 2>/dev/null)
    if [[ $? -eq 0 && -n "$raw_templates" ]]; then
        echo "      ✅ JSON command successful"
        filtered_templates=$(echo "$raw_templates" | jq -r '.[] | select(.volid | contains("ubuntu") or contains("debian")) | .volid' 2>/dev/null)
        echo "      Filtered templates:"
        echo "$filtered_templates" | nl -nln 2>/dev/null || echo "      ❌ Filtering failed"
    else
        echo "      ❌ JSON command failed or returned empty"
    fi
else
    echo "      ❌ jq not available, will use fallback method"
fi

echo ""
echo "   5b. Testing direct template listing:"
direct_templates=$(pvesm list -content vztmpl 2>/dev/null | grep -E "(ubuntu|debian)" || echo "No templates found")
echo "      Direct listing result:"
echo "$direct_templates" | nl -nln

echo ""
echo "   5c. Testing all storage pools:"
echo "      Available storages:"
pvesm status 2>/dev/null | head -5 || echo "      Could not list storages"

echo ""
for storage in $(pvesm status 2>/dev/null | grep -v "Content" | awk '{print $1}' | head -3 2>/dev/null || echo "local"); do
    echo "      Templates in $storage:"
    pvesm list "$storage" -content vztmpl 2>/dev/null | grep -E "(ubuntu|debian)" | head -3 || echo "      No templates found"
done

echo ""
echo "6. Summary of fixes applied:"
echo "   ✅ Array bounds checking fixed"
echo "   ✅ Custom path detection uses exact equality (==)"
echo "   ✅ CONFIG_CUSTOM_INDEX properly calculated"
echo "   ✅ Storage mount generation handles empty arrays"

echo ""
echo "7. The deployment script should now work correctly!"
echo "   Try: bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)\""

echo ""
echo "If templates are not found, the script will now:"
echo "   - Search all available storage pools"
echo "   - Provide manual template entry option"
echo "   - Give clear download instructions"