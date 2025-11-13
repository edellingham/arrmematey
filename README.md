# 🏴‍☠️ Arrmematey - Arr... Me Matey!

At your service! Arrmematey is your trusty pirate crew for all your media treasure! 🏴‍☠️🍿

## 🚀 Quick Start

**One-command installation with your pirate captain:**

```bash
./quick-install.sh
```

## 🚀 Quick GitHub Setup

**One-command GitHub repository creation:**

```bash
./github-setup.sh
```

Your pirate captain will create a private GitHub repository and push all the treasure maps safely!

## 🚀 Quick Proxmox LXC Deployment

**Deploy Arrmematey to Proxmox with one command:**

```bash
# Run on Proxmox host - creates LXC container with Docker and Arrmematey
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
```

This single command will:
- ✅ Download deployment script from GitHub
- ✅ Interactive storage passthrough selection
- ✅ Create LXC container with optimal settings
- ✅ Install Docker inside container
- ✅ Deploy complete Arrmematey stack
- ✅ Configure storage mounts for media/files

Your butler will handle everything - Docker installation, VPN protection, service configuration, and setup!

## 🎭 What Your Butler Does

### Core Services (All Managed by Your Butler)
- 🔍 **Prowlarr** - Indexer Manager (handles all your indexers)
- 🎬 **Sonarr** - TV Series Butler (finds and organizes your shows)
- 🎥 **Radarr** - Movie Butler (finds and organizes your movies)
- 🎵 **Lidarr** - Music Butler (finds and organizes your music)
- 📥 **SABnzbd** - Usenet Butler (downloads from usenet)
- ⬇️ **qBittorrent** - Torrent Butler (downloads torrents)
- 🍿 **Jellyseerr** - Request Butler (handles media requests)

### Butler's Special Skills
- 🌐 **VPN Butler** - Privacy protection with Mullvad + Kill Switch
- 🎛️ **Management Butler** - Beautiful UI for controlling everything
- 🔍 **Prowlarr Integration** - Centralized indexer management
- 📊 **Quality Butler** - Recyclarr integration for optimal quality
- 🏥 **Health Butler** - Monitors all services continuously
- 💾 **Backup Butler** - Protects your configurations

## 🏰 Butler's Security Features

### 🔐 VPN Protection (Always On Duty)
- **Kill Switch Active**: Blocks traffic if VPN disconnects
- **DNS Leak Protection**: Prevents DNS monitoring
- **Firewall Rules**: 50+ iptables rules for maximum protection
- **Process Isolation**: All download services forced through VPN
- **Emergency Testing**: Built-in kill switch verification
- **Butler's Vigilance**: Constant VPN status monitoring

### Security Commands
```bash
./vpn-security.sh check      # Butler's security audit
./kill-switch-test.sh       # Emergency kill switch test
./health.sh monitor          # Butler's health monitoring
```

## 🎨 Butler's Management UI

Access your butler at `http://localhost:8080`

### Butler's Interface Features
- 🎭 **Personalized Butler Theme**: Beautiful purple gradient with butler mascot
- 📊 **Real-time Service Status**: Butler monitors all services continuously
- 🔄 **Service Control**: Start/stop/restart with butler's precision
- 📋 **Log Viewer**: Butler shows you what's happening
- 🎯 **Quick Access**: Direct links to all service web interfaces
- 💬 **Butler Messages**: Fun butler interactions and tooltips
- 📈 **System Dashboard**: Butler's system report

### Butler's Special Touches
- Floating butler mascot with animations
- Butler-themed service names and descriptions
- Personalized messages and feedback
- Smooth animations and transitions
- Mobile-responsive butler interface

## 🔧 Butler's Configuration

### Interactive Butler Setup
Your butler will ask you:
- 🔐 **Mullvad Account ID** (required for VPN protection)
- 📺 **Media Server Choice** (Jellyfin/Emby/Plex/None)
- 🎯 **Quality Profile** (Standard/Quality/Archive)
- 🌐 **Cloudflare Tunnel** (optional for remote access)
- 📁 **Directory Preferences** (custom paths)

### Butler's Auto-Configuration
- ✅ **Service Connections**: Automatically connects all services
- ✅ **API Key Management**: Extracts and stores all API keys
- ✅ **Download Client Setup**: Configures SABnzbd and qBittorrent
- ✅ **Indexer Integration**: Sets up Prowlarr with all indexers
- ✅ **Quality Profiles**: Applies Recyclarr best practices
- ✅ **Media Server Integration**: Connects to your chosen media server

## 📁 Butler's Organization

Your butler creates a perfect directory structure:

```
/home/$USER/
├── Config/          # Butler keeps all configurations tidy
│   ├── prowlarr/   # Indexer butler's office
│   ├── sonarr/     # TV butler's workspace
│   ├── radarr/     # Movie butler's workspace
│   ├── lidarr/     # Music butler's workspace
│   ├── sabnzbd/    # Usenet butler's workshop
│   ├── qbittorrent/ # Torrent butler's workshop
│   ├── jellyseerr/ # Request butler's desk
│   └── gluetun/    # Security butler's office
├── Media/           # Butler's media library
│   ├── tv/         # Organized TV shows
│   ├── movies/     # Organized movies
│   └── music/      # Organized music
└── Downloads/      # Butler's download staging area
    ├── complete/   # Finished downloads
    └── incomplete/ # Downloads in progress
```

## 🌐 Butler's Service Access

| Service | URL | Butler's Role |
|---------|-----|---------------|
| Management UI | http://localhost:8080 | Butler's Control Center |
| Prowlarr | http://localhost:9696 | Butler's Indexer Manager |
| Sonarr | http://localhost:8989 | Butler's TV Assistant |
| Radarr | http://localhost:7878 | Butler's Movie Assistant |
| Lidarr | http://localhost:8686 | Butler's Music Assistant |
| SABnzbd | http://localhost:8080 | Butler's Usenet Handler |
| qBittorrent | http://localhost:8081 | Butler's Torrent Handler |
| Jellyseerr | http://localhost:5055 | Butler's Request Desk |

## 🎭 Butler's Scripts Reference

### Main Butler Scripts
- `quick-install.sh` - Butler's express setup
- `setup.sh` - Butler's detailed setup
- `configure.sh` - Butler's service configuration
- `manage.sh` - Butler's daily management
- `health.sh` - Butler's health monitoring
- `profiles.sh` - Butler's profile management

### Security Butler Scripts
- `vpn-security.sh` - Butler's security audit
- `kill-switch-test.sh` - Butler's emergency testing

## 🎯 Butler's Best Practices

### Butler's Recyclarr Integration
- **Standard Quality**: Perfect for most users (720p/1080p)
- **Quality Profile**: Better quality (1080p/4K)
- **Archive Profile**: Maximum quality (4K only)

### Butler's Service Dependencies
- All download services protected by VPN
- Prowlarr connects before media managers
- Health checks ensure proper startup
- Automatic recovery from failures

## 🛠️ Butler's Troubleshooting

### Butler's Health Check
```bash
./health.sh check      # Butler's complete health assessment
./health.sh monitor     # Butler's continuous monitoring
./health.sh report      # Butler's detailed health report
```

### Butler's Security Check
```bash
./vpn-security.sh check    # Butler's security audit
./kill-switch-test.sh      # Butler's kill switch test
```

### Butler's Service Management
```bash
./manage.sh status         # Butler's service status report
./manage.sh logs sonarr    # Butler shows Sonarr logs
./manage.sh restart        # Butler restarts all services
./manage.sh backup        # Butler backs up configurations
./manage.sh ui            # Butler opens management UI
```

### Butler's Personal Commands (Pirate Version!)
```bash
./pirate.sh daily        # Captain's complete daily routine
./pirate.sh status       # Captain's quick crew status report
./pirate.sh greet        # Captain's formal greeting
./pirate.sh chant        # Crew sings sea shanty
./pirate.sh announce     # Captain makes an announcement
./pirate.sh treasure     # Show today's treasure found
./pirate.sh ui           # Open captain's command bridge
```

### Butler's Script Collection (Pirate Edition!)
- `quick-install.sh` - Captain's express setup
- `setup.sh` - Captain's detailed setup
- `configure.sh` - Crew service configuration
- `manage.sh` - Crew management
- `health.sh` - Ship's health monitoring
- `profiles.sh` - Crew profile management
- `vpn-security.sh` - Ship's security and leak testing
- `kill-switch-test.sh` - Ship's emergency security testing
- `pirate.sh` - Captain's personal assistance script
- `github-setup.sh` - GitHub treasure map creation

## 🚀 GitHub Repository Setup

**Create your private GitHub repository with one command:**

```bash
./github-setup.sh
```

Your pirate captain will:
- ✅ Create a private GitHub repository named `arrmematey`
- ✅ Initialize git repository
- ✅ Create secure `.gitignore` file (excludes passwords and media)
- ✅ Commit all files with pirate-themed message
- ✅ Push to your private GitHub repository

### Manual GitHub Setup
If you prefer manual setup:
1. Go to [github.com/new](https://github.com/new)
2. Create private repository named `arrmematey`
3. Run the setup commands from `SETUP.md`

## 🎭 Butler's Personality (Pirate Edition!)

Your butler is now a pirate! 🏴‍☠️
- Always ready for treasure hunting
- Uses proper pirate terminology
- Provides helpful pirate guidance
- Animated pirate mascot with swaying effect
- Personalized pirate messages and feedback
- Pirate-themed service descriptions

### Butler's (Pirate) Messages
- "Ahoy! Your pirate captain is ready to set sail! 🏴‍☠️"
- "Arr... me matey! Captain at your service! 🏴‍☠️"
- "Let me check on the crew, captain..."
- "All hands on deck! Crew is ready for action! ✨"
- "Ship is ready for treasure hunting! 🍿"

## 🎉 Butler's Final Words

Your butler is dedicated to providing you with the perfect media management experience. With enterprise-grade VPN protection, automated service integration, and a beautiful butler-themed interface, Arrmematey truly arranges everything!

**🏴‍☠️ Arrmematey - Arr... Me Matey! 🍿**

---

*"Your trustworthy media butler that arranges everything perfectly."*