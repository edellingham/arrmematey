#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🔧 Git commit for docker compose fix (v2.20.10)"
echo "=============================================="

# Stage docker compose fixes
echo "Staging docker compose corrections..."
git add arrmematey-upgrade-corrected.sh
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix outdated docker-compose commands (v2.20.10)

DOCKER COMPOSE SYNTAX FIX:
- Replace docker-compose with docker compose (space syntax)
- Align with latest Docker CLI standards
- Fix upgrade script command execution
- Update installer output message

COMMANDS FIXED:
Before: docker-compose pull
After:  docker compose pull

Before: docker-compose down  
After:  docker compose down

Before: docker-compose up -d
After:  docker compose up -d

Before: docker-compose ps
After:  docker compose ps

FILES UPDATED:
+ arrmematey-upgrade-corrected.sh (all commands fixed)
~ install-arrmematey.sh (version + comment)

This resolves 'command not found' errors with docker-compose
and ensures compatibility with latest Docker installations."

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Docker compose fix (v2.20.10) pushed to GitHub!"
echo "🔧 All commands now use 'docker compose' syntax!"
echo ""
echo "Fixed upgrade command:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-corrected.sh | sudo bash"
echo ""
echo "Version: 2.20.10 - Docker compose ready!"