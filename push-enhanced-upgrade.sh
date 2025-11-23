#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🔄 PUSHING Enhanced Upgrade Script with Version Display"
echo "=================================================="

# Stage the new enhanced upgrade script
echo "📦 Staging enhanced upgrade script..."
git add arrmematey-upgrade-with-version.sh

echo ""
echo "📋 Git status:"
git status

echo ""
echo "🎯 Creating commit for enhanced upgrade script..."
git commit -m "Add detailed upgrade script with version display (v2.20.11)

📊 ENHANCED UPGRADE SCRIPT FEATURES:
- Matching version banner format (same as installer)
- Step-by-step progress counters [1/8] throughout process
- Animated progress spinners during long operations
- Real-time feedback (no freeze perception)
- Detailed container health verification
- Professional error handling and guidance

🎨 VERSION DISPLAY (MATCHING INSTALLER):
Installer Format:
╔════════════════════════════════════════════╗
║  Arrmematey Installer        Version: 2.20.11  ║
╚══════════════════════════════════════════════╝

Upgrade Script Format (NEW):
╔════════════════════════════════════════════╗
║  Arrmematey One-Liner Upgrade Script        ║
║  Version: 2.20.11  |  Date: 2025-11-17    ║
╚════════════════════════════════════════════╝

📋 DETAILED PROGRESS INDICATORS:
1. Version banner display (NEW)
2. Configuration backup (timestamped)
3. Git repository status (current/commit)
4. GitHub fetch with progress
5. Latest code pull (new commit)
6. Docker images pull (multi-minute process)
7. UI rebuild with step-by-step
8. Container graceful restart
9. Service health verification
10. System information display

🔄 ANIMATED FEATURES:
- Step counter: [1/8] throughout
- Progress spinners: ⠋ ⠙ ⠹ ⠸ during operations
- Real-time status: Always showing what's happening
- No freeze perception: Continuous updates
- Success/failure indicators: Clear visual feedback

📊 COMPREHENSIVE VERIFICATION:
- Individual container health checks
- Service status reporting
- Docker version display
- Disk usage information
- Upgrade summary report
- Error handling with guidance

🎨 PROFESSIONAL USER EXPERIENCE:
- Colored output for different message types
- Structured step-by-step process
- Detailed summary report with borders
- Clear success/failure indicators
- System resource information
- Ready-to-use access URL

USAGE:
curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-with-version.sh | sudo bash

This provides the same professional upgrade experience as the installer
with detailed progress indicators and version consistency."

echo ""
echo "⏳ Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Enhanced upgrade script pushed to GitHub!"
echo ""
echo "📊 NEW UPGRADE SCRIPT FEATURES:"
echo "  • Matching version banner (same as installer)"
echo "  • Step-by-step progress counters [1/8]"
echo "  • Animated progress spinners during operations"
echo "  • Real-time feedback (no freeze perception)"
echo "  • Detailed container health verification"
echo "  • Professional error handling and guidance"
echo ""
echo "🔄 USAGE:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-with-version.sh | sudo bash"
echo ""
echo "🏴‍☠️  ENHANCED UPGRADE SCRIPT LIVE!"
echo "   Same professional experience as installer!"