#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Preparing git commit for health check fix (v2.20.1) ==="

# Stage changes
echo "Staging updated files..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix Gluetun health check timeout issue (v2.20.1)

- Replace failing ifconfig.io health check with 1.1.1.1 (Cloudflare DNS)
- ifconfig.io was timing out causing container unhealthy state
- VPN connection was working fine, only health check failing
- Uses more reliable endpoint for connectivity testing
- Resolves dependency failed to start errors
- Bump version to 2.20.1 for testing clarity

docker-compose.yml health check:
Before: curl -s https://ifconfig.io
After:  curl -s https://1.1.1.1

This fixes gluetun container unhealthy status while VPN works perfectly."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Health check fix (v2.20.1) pushed to GitHub!"
echo "🏴‍☠️  Updated files are now live:"
echo "   • docker-compose.yml: health check fix"
echo "   • install-arrmematey.sh: v2.20.1"
echo ""
echo "Remote testing commands:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo "  docker-compose ps  # should show gluetun healthy"
echo ""
echo "Installer will now show:"
echo "bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"
echo "Version: 2.20.1"