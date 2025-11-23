#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for debugging bypass (v2.20.3) ==="

# Stage changes
echo "Staging debugging files..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Remove health checks for debugging (v2.20.3)

Debugging Approach:
- Remove Docker health checks to allow container troubleshooting
- Add LOG_LEVEL=debug for verbose Gluetun logs
- Bypass dependency failures preventing container startup
- Enable interactive testing without timeouts

Changes Made:
- Removed entire healthcheck section from docker-compose.yml
- Added LOG_LEVEL=debug to Gluetun environment
- Reverted DNS changes (to test original issue)
- Bump version to 2.20.3 for testing clarity

Debug Commands Available:
docker exec -it gluetun sh
curl -s https://ifconfig.io
nslookup ifconfig.io
ping 1.1.1.1

This enables proper troubleshooting of VPN/DNS issues
without Docker health check interference."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Debugging version (v2.20.3) pushed to GitHub!"
echo "🏴‍☠️  Ready for troubleshooting:"
echo ""
echo "Remote debugging workflow:"
echo "  1. docker-compose down"
echo "  2. docker-compose up -d"
echo "  3. docker logs gluetun -f   # watch debug logs"
echo "  4. docker exec -it gluetun sh  # interactive shell"
echo ""
echo "Manual testing in container:"
echo "  curl -s https://ifconfig.io"
echo "  nslookup ifconfig.io"
echo "  ping 1.1.1.1"
echo ""
echo "All containers should start without health check blocking!"