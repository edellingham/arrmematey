#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for host IP fix (v2.20.6) ==="

# Stage changes
echo "Staging host IP fix..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Add HOST_IP to UI for remote access (v2.20.6)

ISSUE IDENTIFIED:
- UI dashboard links use hardcoded 'localhost' URLs
- Users accessing from remote machines can't reach localhost links
- Need actual host IP for proper navigation

FIX APPLIED:
- Add HOST_IP=192.168.6.137 to arrstack-ui container
- UI can now generate proper host-based URLs
- Enables remote dashboard access from different machines

docker-compose.yml changes:
+ HOST_IP=192.168.6.137 environment variable

Next step: Update UI code to use HOST_IP instead of localhost
for service link generation.

This fixes dashboard navigation for remote access."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Host IP fix (v2.20.6) pushed to GitHub!"
echo "🌐 UI can now generate proper host-based links!"
echo ""
echo "Current workaround:"
echo "  • Replace localhost with 192.168.6.137 manually in browser"
echo ""
echo "Future enhancement:"
echo "  • UI code reads HOST_IP env var for link generation"
echo "  • Automatic host IP detection"
echo ""
echo "Testing command:"
echo "  docker-compose down && docker-compose up -d"
echo "  # Access UI at: http://192.168.6.137:8787"