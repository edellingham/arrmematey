#!/bin/bash
# One-Liner Arrmematey Upgrade Script
# Usage: curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-upgrade-oneline.sh | bash

echo "🏴‍☠️  One-Liner Arrmematey Upgrade"
echo "================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if in correct directory
if [ ! -d "/opt/arrmematey" ]; then
    echo "❌ Arrmematey not found at /opt/arrmematey"
    echo "   Ensure you're running on the correct server"
    exit 1
fi

cd /opt/arrmematey

echo "🔄 Step 1: Pulling latest code..."
git pull origin main

echo "📦 Step 2: Pulling latest Docker images..."
docker compose pull

echo "🏗️  Step 3: Rebuilding UI with enhancements..."
docker compose build arrstack-ui --no-cache

echo "🛑 Step 4: Stopping containers..."
docker-compose down

echo "🚀 Step 5: Starting with new configuration..."
docker-compose up -d

echo "⏳ Step 6: Waiting for services to initialize..."
sleep 20

echo "🔍 Step 7: Verifying upgrade..."
docker-compose ps

echo ""
echo "✅ Upgrade Complete! Version: 2.20.9"
echo ""
echo "🎨 New UI Features:"
echo "  • Professional SVG icons (no emojis)"
echo "  • Container ↔ host volume mapping display"
echo "  • Real-time service status tracking"
echo "  • Dual-view dashboard (Dashboard + Mappings)"
echo "  • Service filtering by category"
echo ""
echo "🌐 Access your enhanced dashboard:"
echo "  http://192.168.6.137:8787"
echo ""
echo "🎬 Your media stack is upgraded and ready!"