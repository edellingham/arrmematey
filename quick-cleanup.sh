#!/bin/bash
# Quick Docker Cleanup One-Liner
# Run this to clean up failed Docker installation:

docker ps -aq 2>/dev/null | xargs -r docker rm -f
docker system prune -f
docker image prune -f
docker volume prune -f
sudo rm -rf /var/lib/containerd 2>/dev/null || true
sudo rm -rf /var/lib/docker 2>/dev/null || true
echo "🧹 Cleanup complete! Run the installer now:"