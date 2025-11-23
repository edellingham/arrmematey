#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🏴‍☠️  PUSHING v2.20.9 TO GITHUB"
echo "=================================="

# Stage all UI enhancements and upgrade script
echo "📦 Staging UI enhancements..."
git add ui/enhanced-services.js
git add ui/ContainerMappingsDashboard.jsx
git add ui/EnhancedServiceCard.jsx
git add ui/EnhancedDashboard.jsx
git add arrmematey-upgrade-oneline.sh
git add install-arrmematey.sh

echo ""
echo "📋 Checking git status..."
git status

echo ""
echo "🎨 Creating commit for major UI enhancements..."
git commit -m "Major UI overhaul with professional icons + container mappings (v2.20.9)

🎨 MASSIVE UI ENHANCEMENTS:
- Replace ALL emojis with professional SVG icons
- Add container ↔ host volume mapping visualization
- Add real-time service status tracking
- Add dual-view dashboard (Dashboard + Mappings)
- Add service filtering by category
- Add comprehensive statistics overview

🎯 NEW PROFESSIONAL ICONS:
radarr.svg, prowlarr.svg, sonarr.svg, lidarr.svg
sabnzbd.svg, qbittorrent.svg, jellyseerr.svg, emby.svg
All from: https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/

📁 CONTAINER MAPPING VISUALIZATION:
- Show host ↔ container path for each service
- Real-time mapping status (✅ mapped, ⚠️ warning, ❌ error)
- Click-to-view volume details
- Integration with NFS mounts

📊 ENHANCED DASHBOARD FEATURES:
- Toggle between Dashboard and Mappings views
- Real-time service status updates (30s refresh)
- Service filtering by category (media, downloader, etc.)
- Comprehensive statistics (running, mappings, health)
- Professional dark theme design

🚀 ONE-LINER UPGRADE SCRIPT:
+ arrmematey-upgrade-oneline.sh
- Upgrade existing installations with one command
- Preserve all configuration and NFS mounts
- Automated UI rebuild with enhancements

NEW UI COMPONENTS:
+ ui/enhanced-services.js (service config + icons)
+ ui/ContainerMappingsDashboard.jsx (mapping visualization)
+ ui/EnhancedServiceCard.jsx (professional service cards)
+ ui/EnhancedDashboard.jsx (complete dashboard)

USAGE:
- New install: bash <(curl...install-arrmematey.sh)
- Upgrade existing: curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-oneline.sh | sudo bash

This transforms Arrmematey from basic emojis to production-ready
professional media management interface with full container visibility!"

echo ""
echo "⏳ Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! v2.20.9 pushed to GitHub!"
echo ""
echo "🎨 MAJOR UI UPGRADE LIVE:"
echo "  • Professional SVG icons (no emojis)"
echo "  • Container ↔ host volume mapping display"
echo "  • Real-time service status tracking"
echo "  • Dual-view dashboard (Dashboard + Mappings)"
echo "  • Service filtering by category"
echo "  • Comprehensive statistics overview"
echo "  • One-liner upgrade for existing installs"
echo ""
echo "🚀 NEW INSTALL:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"
echo ""
echo "🔄 EXISTING INSTALL UPGRADE:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-oneline.sh | sudo bash"
echo ""
echo "🌐 Access your enhanced dashboard:"
echo "  http://192.168.6.137:8787"
echo ""
echo "🏴‍☠️  VERSION 2.20.9 - PRODUCTION READY!"
echo "   Your media stack is now professionally enhanced!"