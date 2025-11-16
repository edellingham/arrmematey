echo ""
echo "   5d. Testing the CLEANED UP template detection logic:"
echo "      Fixed storage pool parsing (skip headers):"
all_templates=""
for storage in $(pvesm status 2>/dev/null | grep -v "^Name" | grep -v "Content" | grep -v "Status" | awk '{print $1}' 2>/dev/null); do
    # Skip empty or invalid storage names
    if [[ -z "$storage" ]] || [[ "$storage" == "Name" ]] || [[ "$storage" == "Type" ]]; then
        continue
    fi

    echo "      Checking storage: $storage"
    echo "         Raw pvesm list output:"
    pvesm list "$storage" -content vztmpl 2>/dev/null | head -3 | sed 's/^/         /'

    storage_templates=$(pvesm list "$storage" -content vztmpl 2>/dev/null | grep -E "(ubuntu|debian)" | awk '{print "'$storage'":vztmpl/"$1"}' 2>/dev/null || echo "")
    echo "         Grep result: '$storage_templates'"

    if [[ -n "$storage_templates" ]]; then
        echo "      ✅ Found in $storage:"
        echo "$storage_templates" | nl -nln
        all_templates="$all_templates"$'\n'"$storage_templates"
    else
        echo "      ❌ No templates in $storage"
    fi
done

# Clean up
all_templates=$(echo "$all_templates" | grep -v '^[[:space:]]*$' | sort | uniq)
if [[ -n "$all_templates" ]]; then
    echo "      ✅ FINAL TEMPLATE LIST:"
    echo "$all_templates" | nl -nln
    echo "      🎯 This template should now be selectable in deployment!"
else
    echo "      ❌ Still no templates found with cleaned up method"
    echo ""
    echo "      🔍 Let's check if debian template exists with different patterns:"
    for storage in $(pvesm status 2>/dev/null | grep -v "^Name" | grep -v "Content" | grep -v "Status" | awk '{print $1}' 2>/dev/null); do
        if [[ -z "$storage" ]] || [[ "$storage" == "Name" ]] || [[ "$storage" == "Type" ]]; then
            continue
        fi
        echo "      Testing different patterns in $storage:"
        echo "         debian pattern:"
        pvesm list "$storage" -content vztmpl 2>/dev/null | grep "debian" | sed 's/^/         /'
        echo "         Debian pattern (uppercase):"
        pvesm list "$storage" -content vztmpl 2>/dev/null | grep "Debian" | sed 's/^/         /'
        echo "         tar.zst pattern:"
        pvesm list "$storage" -content vztmpl 2>/dev/null | grep "tar.zst" | sed 's/^/         /'
    done
fi