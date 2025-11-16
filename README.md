# 🏴‍☠️ Arrmematey — Your Pirate Crew for Media Treasure

Arrmematey is a complete containerized media automation stack with VPN protection. Just one command gets you a full media management system with Prowlarr, Sonarr, Radarr, Lidarr, download clients, and a management UI.

## ⚓ One-Line Installation

**Super simple!** Just run this single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/install.sh)"
```

**What it does:**
- ✅ Checks Docker and storage configuration
- ✅ Asks for your Mullvad VPN ID  
- ✅ Auto-fixes storage issues if detected
- ✅ Downloads and configures everything
- ✅ Starts all services automatically

**Requirements:** Docker, curl, and a Mullvad VPN account

**Alternative (with git):**
```bash
git clone https://github.com/edellingham/arrmematey.git
cd arrmematey
./quick-install.sh
```

## ⚔️ Complete Media Automation Stack
- 🔍 **Prowlarr** – Indexer management (https://localhost:9696)
- 🎬 **Sonarr** – TV series automation (https://localhost:8989)
- 🎥 **Radarr** – Movie automation (https://localhost:7878)
- 🎵 **Lidarr** – Music automation (https://localhost:8686)
- 📥 **SABnzbd** – Usenet downloader (https://localhost:8080)
- ⬇️ **qBittorrent** – BitTorrent client (https://localhost:8081)
- 🍿 **Jellyseerr** – Media request system (https://localhost:5055)
- 🧭 **Management UI** – Control center (https://localhost:8080)

## 🛡️ Security & Privacy
- **Mullvad VPN** protects all downloads with kill-switch
- **Network isolation** keeps services secure
- **Automatic configuration** requires no manual setup

## 🔧 Smart Installation Features
- **Docker Storage Check**: Automatically detects and fixes storage issues
- **Overlay2 Monitoring**: Prevents image extraction failures
- **Storage Movement**: Moves Docker to locations with more space
- **Cleanup Options**: Built-in Docker cleanup for failed installations
- **Interactive Menu**: Choose installation or cleanup options

## 🧭 Service Access
| Service | URL | Role |
|---------|-----|------|
| Management UI | http://localhost:8080 | Main control center |
| Prowlarr | http://localhost:9696 | Indexer management |
| Sonarr | http://localhost:8989 | TV automation |
| Radarr | http://localhost:7878 | Movie automation |
| Lidarr | http://localhost:8686 | Music automation |
| SABnzbd | http://localhost:8080 | Usenet downloader |
| qBittorrent | http://localhost:8081 | BitTorrent downloader |
| Jellyseerr | http://localhost:5055 | Request system |

## 🧭 Quick Commands
```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f [service]

# Restart all services
docker-compose restart

# Stop everything
docker-compose down

# Start again
docker-compose up -d
```

## 🧭 Setup Tips
After installation:
1. **Configure indexers** in Prowlarr (add your NZB/Torrent providers)
2. **Set up download clients** in SABnzbd/qBittorrent
3. **Add your media libraries** to Sonarr, Radarr, and Lidarr
4. **Configure Jellyseerr** to connect to your services

## 🧱 Troubleshooting
```bash
# View service logs
docker-compose logs -f [service-name]

# Check VPN connection
docker exec gluetun curl -s ipinfo.io/ip

# Restart single service
docker-compose restart sonarr

# Update all containers
docker-compose pull && docker-compose up -d
```

**Happy treasure hunting!** 🏴‍☠️🍿
```
