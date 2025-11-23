#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🔄 PUSHING v2.20.11 - Version + Upgrade Features (Design Preserved)"
echo "======================================================================"

# Stage all new version/upgrade files
echo "📦 Staging version + upgrade features..."
git add ui/enhanced-services-with-versions.js
git add ui/ServiceCardWithVersion.jsx
git add ui/EnhancedHeader.jsx
git add ui/UpgradeAPI.jsx
git add ui/EnhancedDashboardWithVersions.jsx
git add install-arrmematey.sh

echo ""
echo "📋 Git status:"
git status

echo ""
echo "🎯 Creating commit for v2.20.11..."
git commit -m "Add version display + upgrade system (design preserved) (v2.20.11)

🔧 VERSION + UPGRADE FEATURES:
- Add current version display for all services
- Add latest version checking and comparison
- Add upgrade buttons for individual services
- Add Arrmematey version display in header
- Add global 'Upgrade All' button
- Add upgrade modal with confirmation
- Add upgrade progress indicators
- Add automatic update checking

🎨 DESIGN PRESERVED:
- NO changes to UI layout or design
- NO changes to color scheme
- NO changes to card design
- NO changes to navigation
- Same header, same cards, same icons
- Only adds version info + upgrade buttons

📋 NEW FILES (no design changes):
+ ui/enhanced-services-with-versions.js (version config)
+ ui/ServiceCardWithVersion.jsx (service card + versions)
+ ui/EnhancedHeader.jsx (header + arrmematey version)
+ ui/UpgradeAPI.jsx (upgrade backend integration)
+ ui/EnhancedDashboardWithVersions.jsx (main dashboard + versions)

🔄 VERSION DISPLAY:
- Service cards show: v{currentVersion} → v{latestVersion}
- Header shows: Arrmematey v{version}
- Upgrade indicators when updates available
- Upgrade progress during operations

🚀 UPGRADE FEATURES:
- Individual service upgrade buttons
- Global 'Upgrade All' button
- Upgrade confirmation modals
- Real-time upgrade progress
- Version comparison and update detection
- Integration with docker compose commands

📊 ENHANCED STATISTICS:
- Updates Available count
- Current vs latest versions
- Upgrade status tracking
- Service health with version info

USAGE:
- Same UI layout you love
- Same design and colors
- Same navigation and cards
- NEW: Version info display
- NEW: One-click upgrades
- NEW: Automatic update checking

This adds powerful version management and upgrade capabilities
while preserving the exact UI design you specified."

echo ""
echo "⏳ Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! v2.20.11 pushed to GitHub!"
echo ""
echo "🔄 VERSION + UPGRADE FEATURES LIVE:"
echo "  • Version display for all services (v{currentVersion})"
echo "  • Latest version checking and comparison"
echo "  • Individual service upgrade buttons"
echo "  • Arrmematey version in header"
echo "  • Global 'Upgrade All' button"
echo "  • Upgrade modals with confirmation"
echo "  • Real-time upgrade progress"
echo "  • Automatic update checking"
echo ""
echo "🎨 DESIGN PRESERVED:"
echo "  • Same UI layout (no changes)"
echo "  • Same color scheme (no changes)"
echo "  • Same card design (no changes)"
echo "  • Same navigation (no changes)"
echo "  • Same icons (no changes)"
echo ""
echo "🚀 NEW INSTALL:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install-arrmematey.sh)"
echo ""
echo "🔄 EXISTING UPGRADE:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-corrected.sh | sudo bash"
echo ""
echo "🏴‍☠️  VERSION 2.20.11 - VERSION MANAGEMENT + UPGRADES!"
echo "   Same beautiful UI + powerful upgrade capabilities!"