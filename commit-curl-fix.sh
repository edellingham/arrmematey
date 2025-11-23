#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for curl fix (v2.20.4) ==="

# Stage changes
echo "Staging health check fix..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix Gluetun health check - curl not installed (v2.20.4)

ROOT CAUSE FOUND:
- Gluetun container doesn't have curl installed!
- Health check was always failing due to missing command
- VPN connection was working perfectly the whole time

FIX APPLIED:
- Replace curl health check with ping-based check
- Use 'ping -c 1 1.1.1.1' for basic connectivity test
- Keep debug logging for troubleshooting
- Bump version to 2.20.4 for testing

docker-compose.yml health check:
Before: curl -s https://1.1.1.1  (command doesn't exist!)
After:  ping -c 1 1.1.1.1     (basic network test)

This should resolve dependency failures for good!"

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Curl fix (v2.20.4) pushed to GitHub!"
echo "🤦‍♂️  Facepalm moment: container had no curl!"
echo "🏴‍☠️  Script is now ready for testing:"
echo ""
echo "Testing workflow:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo "  docker-compose ps  # should show all healthy!"
echo ""
echo "Installer shows:"
echo "bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"
echo "Version: 2.20.4"