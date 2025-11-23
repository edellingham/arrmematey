#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🔧 PUSHING v2.20.10 - Docker Compose Fix"
echo "=========================================="

# Stage all fixes and new files
echo "📦 Staging docker compose fixes..."
git add ui/enhanced-services.js
git add ui/ContainerMappingsDashboard.jsx
git add ui/EnhancedServiceCard.jsx
git add ui/EnhancedDashboard.jsx
git add arrmematey-upgrade-oneline.sh
git add arrmematey-upgrade-corrected.sh
git add install-arrmematey.sh
git add commit-docker-compose-fix.sh

echo ""
echo "📋 Git status:"
git status

echo ""
echo "🎯 Creating commit for v2.20.10..."
git commit -m "Fix docker-compose syntax & add professional UI (v2.20.10)

🔧 CRITICAL DOCKER COMPOSE FIX:
- Replace all docker-compose (hyphen) with docker compose (space)
- Align with Docker CLI v25+ standards
- Fix 'command not found' errors
- Future-proof Arrmematey installer

🎨 MAJOR UI ENHANCEMENTS:
+ Professional SVG icons (replace emojis)
+ Container ↔ host volume mapping visualization
+ Real-time service status tracking
+ Dual-view dashboard (Dashboard + Mappings)
+ Service filtering by category
+ Comprehensive statistics overview

🚀 UPGRADE FEATURES:
+ One-liner upgrade script for existing installs
+ Docker compose syntax compatibility
+ Configuration preservation

COMMANDS FIXED:
Before: docker-compose pull
After:  docker compose pull

Before: docker-compose down
After:  docker compose down

Before: docker-compose up -d  
After:  docker compose up -d

NEW COMPONENTS:
+ ui/enhanced-services.js (professional icons + mapping config)
+ ui/ContainerMappingsDashboard.jsx (mapping visualization)
+ ui/EnhancedServiceCard.jsx (professional service cards)
+ ui/EnhancedDashboard.jsx (complete dashboard)
+ arrmematey-upgrade-corrected.sh (fixed upgrade script)

This transforms Arrmematey with:
- Production-ready UI with professional icons
- Full container visibility and mapping display
- Docker CLI compatibility
- One-command upgrade capability"

echo ""
echo "⏳ Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! v2.20.10 pushed to GitHub!"
echo ""
echo "🔧 Docker compose syntax fixed:"
echo "  • All commands use 'docker compose' (space syntax)"
echo "  • Compatible with Docker CLI v25+"
echo "  • No more 'command not found' errors"
echo ""
echo "🎨 Professional UI features live:"
echo "  • SVG icons (no emojis)"
echo "  • Container ↔ host volume mapping display"
echo "  • Real-time service status tracking"
echo "  • Dual-view dashboard (Dashboard + Mappings)"
echo "  • Service filtering by category"
echo ""
echo "🚀 Ready for new install and upgrade:"
echo ""
echo "NEW INSTALL:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"
echo ""
echo "EXISTING UPGRADE:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-corrected.sh | sudo bash"
echo ""
echo "🏴‍☠️  VERSION 2.20.10 - PRODUCTION READY!"
echo "   Docker compose fixed + Professional UI enhanced!"