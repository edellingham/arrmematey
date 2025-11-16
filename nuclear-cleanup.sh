#!/bin/bash
# ULTRA-AGGRESSIVE Docker One-Liner Cleanup
# Use this if previous cleanup didn't work

echo "🧹 ULTRA-AGGRESSIVE Docker Cleanup"
echo "=================================="

# Kill everything and remove everything
sudo systemctl stop docker containerd 2>/dev/null || true
sudo pkill -9 -f docker containerd 2>/dev/null || true

# Nuclear option - remove ALL Docker/containerd data
sudo rm -rf /var/lib/docker* /var/lib/containerd* /run/docker* /run/containerd* 2>/dev/null || true

# Clean any hanging files
sudo rm -f /var/run/docker.sock /run/docker.sock 2>/dev/null || true

# Restart services
sudo systemctl start containerd docker 2>/dev/null || true

# Wait and test
sleep 5
docker ps &>/dev/null && echo "✅ Docker restarted successfully" || echo "❌ Docker restart failed"

echo "🚀 Ready to install now:"