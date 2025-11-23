#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "🚀 Git commit for one-liner upgrade script (v2.20.9)"
echo "=============================================="

# Stage upgrade script
echo "Staging one-liner upgrade script..."
git add arrmematey-upgrade-oneline.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Add one-liner upgrade script for existing installs (v2.20.9)

ONE-LINER UPGRADE FEATURE:
- Simplify upgrade process for existing installations
- Single command upgrade: curl | bash
- Preserves all existing configuration
- Updates Docker images + UI + services

UPGRADE COMMAND:
ssh user@192.168.6.137 "curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-oneline.sh | sudo bash"

UPGRADE PROCESS:
1. Pull latest code from GitHub
2. Pull latest Docker images
3. Rebuild UI with professional icons
4. Restart containers with new config
5. Verify upgrade success

USAGE:
- SSH into Arrmematey VM
- Run one-liner upgrade command
- Enjoy enhanced UI (v2.20.9)

Makes upgrading Arrmematey as easy as: curl | bash"

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! One-liner upgrade script pushed to GitHub!"
echo "🚀 Existing installs can now upgrade with one command!"
echo ""
echo "One-Liner Upgrade:"
echo "  curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-oneline.sh | bash"
echo ""
echo "Remote SSH Upgrade:"
echo "  ssh user@192.168.6.137 \"curl ... | sudo bash\""
echo ""
echo "Version: 2.20.9 - Ready for upgrade!"