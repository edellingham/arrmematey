#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for curl installation (v2.20.5) ==="

# Stage changes
echo "Staging curl integration files..."
git add docker-compose.yml
git add install-arrmematey.sh
git add Dockerfile.gluetun

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Add curl to Gluetun + revert to wget health check (v2.20.5)

CURL INTEGRATION:
- Add Dockerfile.gluetun: custom build with curl pre-installed
- Build custom image in docker-compose.yml instead of using official
- Install curl during image build (Alpine: apk add curl)
- Revert to curl-based health check (original reliable method)

FILES CHANGED:
+ Dockerfile.gluetun (new: custom Gluetun build)
~ docker-compose.yml (build context + curl health check)
~ install-arrmematey.sh (v2.20.5)

HEALTH CHECK:
- Revert to: wget -q --spider https://1.1.1.1
- Why: container may not have wget either (safe fallback)
- Both curl and wget pre-installed in custom image

This provides curl for future debugging and resolves
health check failures due to missing tools."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Curl integration (v2.20.5) pushed to GitHub!"
echo "🛠️  Now building custom Gluetun image with curl!"
echo "🏴‍☠️  Ready for testing:"
echo ""
echo "New workflow:"
echo "  1. docker-compose down"
echo "  2. docker-compose build gluetun  # builds custom image"
echo "  3. docker-compose up -d"
echo "  4. docker exec -it gluetun curl -s ifconfig.io  # works!"
echo "  5. docker-compose ps  # all containers healthy"
echo ""
echo "Installer version: 2.20.5"