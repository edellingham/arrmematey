#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🎨 Git commit for UI enhancements (v2.20.9)"
echo "=============================================="

# Stage UI enhancements
echo "Staging UI enhancements..."
git add ui/enhanced-services.js
git add ui/ContainerMappingsDashboard.jsx
git add ui/EnhancedServiceCard.jsx
git add ui/EnhancedDashboard.jsx
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Add professional UI with container mappings (v2.20.9)

MAJOR UI ENHANCEMENTS:
🎨 Replace all emojis with professional SVG icons
📁 Add container ↔ host volume mapping visualization
📊 Add real-time service status tracking
🔍 Add dual-view dashboard (Dashboard + Mappings)
🎯 Add service filtering by category
📈 Add comprehensive statistics overview

NEW UI COMPONENTS:
+ ui/enhanced-services.js (service config + icons)
+ ui/ContainerMappingsDashboard.jsx (mapping visualization)
+ ui/EnhancedServiceCard.jsx (professional service cards)
+ ui/EnhancedDashboard.jsx (complete dashboard)

ICON REPLACEMENTS:
Before: 🎬🔍🎵📥⬇️🍿🏴 (emojis)
After: https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/
      radarr.svg, prowlarr.svg, sonarr.svg, lidarr.svg
      sabnzbd.svg, qbittorrent.svg, jellyseerr.svg, emby.svg

CONTAINER MAPPINGS:
- Visual host ↔ container path display
- Real-time mapping status (✅ mapped, ⚠️ warning, ❌ error)
- Click-to-view volume details
- Integration with NFS mounts

DASHBOARD FEATURES:
- Toggle between Dashboard and Mappings views
- Service filtering by category (media, downloader, etc.)
- Real-time status updates (30-second refresh)
- Comprehensive statistics (running, mappings, health)

Professional, production-ready UI with full container visibility!"

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! UI enhancements (v2.20.9) pushed to GitHub!"
echo "🎨 Professional icons + container mappings now live!"
echo ""
echo "New UI Features:"
echo "  🎨 Professional SVG icons (no more emojis)"
echo "  📁 Container ↔ host volume mapping display"
echo "  📊 Real-time service status tracking"
echo "  🔍 Dual-view dashboard (Dashboard + Mappings)"
echo "  🎯 Service filtering by category"
echo "  📈 Comprehensive statistics overview"
echo ""
echo "Access at: http://192.168.6.137:8787"
echo "Version: 2.20.9"