#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for DNS + health check fix (v2.20.2) ==="

# Stage changes
echo "Staging updated files..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix Gluetun DNS resolution causing health check failures (v2.20.2)

DNS Issue Identified:
- Gluetun was using 127.0.0.1 for DNS (localhost)
- Should use Cloudflare DNS 1.1.1.1 for proper resolution
- Health check was failing due to DNS issues, not VPN problems

Changes Made:
- Add DNS_ADDRESS=1.1.1.1 to docker-compose.yml
- Add DNS_KEEP_NAMESERVER=false to prevent localhost DNS
- Keep improved health check with 1.1.1.1 endpoint
- Bump version to 2.20.2 for testing clarity

docker-compose.yml additions:
+ DNS_ADDRESS=1.1.1.1
+ DNS_KEEP_NAMESERVER=false

This should resolve both DNS and health check issues."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! DNS fix (v2.20.2) pushed to GitHub!"
echo "🏴‍☠️  Updated files are now live:"
echo "   • docker-compose.yml: proper DNS + health check"
echo "   • install-arrmematey.sh: v2.20.2"
echo ""
echo "Expected Result:"
echo "  - Gluetun DNS: 1.1.1.1 (not 127.0.0.1)"
echo "  - Health check: should pass consistently"
echo "  - All containers: start successfully"
echo ""
echo "Remote testing commands:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo "  docker exec gluetun curl -s 1.1.1.1  # should work"
echo "  docker-compose ps  # all containers healthy"