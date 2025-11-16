#!/bin/bash
# Docker Cleanup Script for Failed Installation
# This cleans up residual Docker files and frees disk space

set -e

echo "🧹 Docker Cleanup and Space Recovery"
echo "===================================="
echo ""

# Check disk space before cleanup
echo "📊 Disk Space Before Cleanup:"
df -h / | tail -1
echo ""

# Stop any running Docker services
echo "🛑 Stopping any running Docker containers..."
docker ps -q 2>/dev/null | xargs -r docker stop 2>/dev/null || echo "No containers to stop"
docker ps -aq 2>/dev/null | xargs -r docker rm -f 2>/dev/null || echo "No containers to remove"

# Clean Docker system
echo "🧽 Cleaning Docker system..."
docker system prune -f

# Clean unused images
echo "🗑️ Removing unused images..."
docker image prune -f

# Clean unused volumes
echo "📦 Cleaning unused volumes..."
docker volume prune -f

# Clean unused networks
echo "🌐 Cleaning unused networks..."
docker network prune -f

# Remove containerd data if it exists
echo "🗂️ Cleaning containerd data..."
if [[ -d "/var/lib/containerd" ]]; then
    echo "Removing containerd data directory..."
    sudo rm -rf /var/lib/containerd
fi

# Clean Docker data directory
echo "🗄️ Cleaning Docker data directory..."
if [[ -d "/var/lib/docker" ]]; then
    echo "Removing Docker data directory..."
    sudo rm -rf /var/lib/docker
fi

# Clean temporary Docker files
echo "🗃️ Cleaning temporary Docker files..."
sudo rm -rf /tmp/docker-*
sudo rm -rf /var/lib/docker-tmp

# Clean any Sonarr container remnants
echo "🎬 Cleaning Sonarr remnants..."
docker images | grep sonarr | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || echo "No Sonarr images to remove"

# Clean any Arrmematey containers
echo "🏴‍☠️ Cleaning Arrmematey remnants..."
docker images | grep -E "(linuxserver|prowlarr|radarr|lidarr|sabnzbd|qbittorrent)" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || echo "No Arrmematey images to remove"

# Check disk space after cleanup
echo ""
echo "📊 Disk Space After Cleanup:"
df -h / | tail -1
echo ""

# Show what's using space in root
echo "🔍 Top space consumers in root:"
sudo du -h /var/lib 2>/dev/null | sort -hr | head -10

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "🚀 Ready to install Arrmematey:"
echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)\""
echo ""
echo "Or if you have local files:"
echo "cd arrmematey && ./quick-install.sh"