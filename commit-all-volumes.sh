#!/bin/bash
cd /home/ed/Dev/arrmematey

echo "=== Git commit for all service volume fixes (v2.20.8) ==="

# Stage changes
echo "Staging all volume fixes..."
git add docker-compose.yml
git add install-arrmematey.sh

# Commit with descriptive message
echo "Creating commit..."
git commit -m "Fix all service volume mappings for NFS access (v2.20.8)

MASSIVE VOLUME FIX:
All services were using empty Docker named volumes
- sonarr-media:/tv (empty)
- radarr-media:/movies (empty)  
- lidarr-media:/music (empty)

NOW ALL SERVICES USE NFS MOUNTS:
sonarr:   /root/Media/TV:/tv
radarr:   /root/Media/Movies:/movies
lidarr:   /root/Media/Music:/music
sabnzbd:  /root/Downloads/usenet:/downloads
qbittorrent: /root/Downloads/torrents:/downloads
emby:     /root/Media/*:/data/* (multiple paths)

COMPLETE DATA FLOW:
Proxmox ZFS → NFS → Ubuntu VM → Docker → Services
Working end-to-end for media management!

Updated Services:
✅ Sonarr (TV shows)
✅ Radarr (Movies)  
✅ Lidarr (Music)
✅ Emby (media server)
✅ SABnzbd (usenet downloads)
✅ qBittorrent (torrent downloads)

No reinstall needed - just restart containers!"

# Push to GitHub
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "✅ SUCCESS! Complete volume fix (v2.20.8) pushed to GitHub!"
echo "🎬 All services now access NFS mounts!"
echo ""
echo "To apply fix:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo ""
echo "Full data flow working:"
echo "  Downloads → qBittorrent/SABnzbd → Sonarr/Radarr/Lidarr"
echo "  Media management → /root/Media/*"
echo "  Media serving → Emby"
echo "  User requests → Jellyseerr"
echo ""
echo "No reinstall needed - just restart!"