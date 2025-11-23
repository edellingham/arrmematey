#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for Emby volume mapping fix (v2.20.7) ==="

# Stage changes
echo "Staging Emby volume fix..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix Emby volume mappings to use NFS mounts (v2.20.7)

ISSUE IDENTIFIED:
- Emby was using Docker named volumes (sonarr-media, radarr-media)
- These volumes were empty - no media access
- Emby couldn't see any media files

FIX APPLIED:
- Replace named volumes with host path mappings
- Map /root/Media/* → /data/* in Emby container
- Use proper NFS mount paths from Ubuntu VM

docker-compose.yml changes:
emby volumes:
- /root/Media/Movies:/data/movies:ro    (was sonarr-media)
- /root/Media/TV:/data/tvshows:ro      (was missing)
- /root/Media/Music:/data/music:ro      (was missing)

Flow Now:
Proxmox ZFS → Ubuntu NFS → Docker Emby → Media Libraries
Working end-to-end!"

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Emby volume fix (v2.20.7) pushed to GitHub!"
echo "🎬 Emby can now access media libraries!"
echo ""
echo "Restart needed:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo ""
echo "Emby libraries should now show:"
echo "  Movies: /data/movies  → /root/Media/Movies"
echo "  TV:     /data/tvshows → /root/Media/TV"
echo "  Music:   /data/music   → /root/Media/Music"
echo ""
echo "Version: 2.20.7"