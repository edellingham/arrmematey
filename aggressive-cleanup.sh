#!/bin/bash
# Aggressive Docker Cleanup - Fixes Containerd Directory Issues
# This fixes the "no such file or directory" error in containerd

set -e

echo "🧹 Aggressive Docker Cleanup"
echo "============================"
echo ""

# Stop Docker daemon completely
echo "🛑 Stopping Docker daemon..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop containerd 2>/dev/null || true

# Kill any remaining Docker processes
echo "🔥 Killing remaining Docker processes..."
sudo pkill -f docker 2>/dev/null || true
sudo pkill -f containerd 2>/dev/null || true

# Remove ALL Docker and containerd data
echo "🗑️ Removing all Docker and containerd data..."
sudo rm -rf /var/lib/docker*
sudo rm -rf /var/lib/containerd*
sudo rm -rf /run/docker*
sudo rm -rf /run/containerd*

# Clean any overlay directories that might be corrupted
echo "🧽 Cleaning overlay data..."
sudo rm -rf /var/lib/docker/overlay2 2>/dev/null || true
sudo rm -rf /var/lib/docker/image 2>/dev/null || true
sudo rm -rf /var/lib/docker/network 2>/dev/null || true

# Remove Docker socket if it exists
echo "🧽 Cleaning Docker socket..."
sudo rm -f /var/run/docker.sock
sudo rm -f /run/docker.sock

# Clean Docker configuration
echo "🧽 Cleaning Docker configuration..."
sudo rm -rf ~/.docker 2>/dev/null || true

# Remove any docker-compose files in case they're corrupted
echo "🧽 Cleaning docker-compose files..."
sudo rm -f ~/.docker-compose.yml 2>/dev/null || true

# Clean Arrmematey directory if it exists
echo "🧽 Cleaning Arrmematey directory..."
rm -rf ~/arrmematey 2>/dev/null || true
rm -rf /tmp/arrmematey* 2>/dev/null || true

# Start Docker daemon with proper permissions
echo "🚀 Starting Docker daemon..."
sudo systemctl start containerd 2>/dev/null || true
sudo systemctl start docker 2>/dev/null || true

# Wait for Docker to be ready
echo "⏳ Waiting for Docker to be ready..."
sleep 5

# Verify Docker is working
echo "🔍 Verifying Docker installation..."
if docker ps &> /dev/null; then
    echo "✅ Docker is working properly"
else
    echo "❌ Docker is not working - you may need to reinstall Docker"
    exit 1
fi

# Check disk space
echo ""
echo "📊 Disk Space After Cleanup:"
df -h / | tail -1
echo ""

echo "✅ Aggressive cleanup complete!"
echo ""
echo "🚀 Ready to install Arrmematey:"
echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)\""
echo ""
echo "If you still get errors, you may need to:"
echo "1. Restart your system"
echo "2. Reinstall Docker completely"