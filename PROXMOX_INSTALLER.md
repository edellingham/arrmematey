# 🏴‍☠️ Arrmematey Proxmox Installer

A comprehensive, automated installer for deploying Arrmematey media automation stack on Proxmox VE with Debian 13.

## Overview

This modular installer handles the complete deployment process:

### Single-Line Installation Approach
The installer uses a hybrid architecture:
- **Main Script** (`arrmematey-proxmox-one-line.sh`) - Downloads all modules and orchestrates installation
- **Module Scripts** (downloaded from GitHub) - Each handles a specific installation phase
- **One Command Install** - `bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-proxmox-one-line.sh)`

### Installation Phases
1. **Proxmox Integration** - Downloads and runs Debian 13 VM script
2. **Dependency Management** - Progressive checking (basic → docker → arrmematey)
3. **Docker Storage Setup** - Automatically detects and fixes overlay2 1GB limitation
4. **Arrmematey Installation** - Downloads, builds, and deploys the full stack
5. **Configuration** - Interactive prompting for all necessary settings

## Installation Modes

### Automated Mode
- Uses sensible defaults
- Minimal user interaction
- Best for experienced users or automated deployments

### Interactive Mode
- User controls each step
- More options and customizations
- Best for first-time users

## Quick Start

### Single Line Installation (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-proxmox-one-line.sh)
```

This downloads the main installer and all modules automatically - everything in one command!

### Alternative: Direct Download

```bash
curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/arrmematey-proxmox-one-line.sh | bash
```

## Features

### ✨ Automated Proxmox VM Creation
- Downloads and executes community Proxmox Debian 13 VM script
- Creates LXC container with Debian 13 (Trixie)
- Configures networking and storage

### 🔧 Progressive Dependency Checking
**Phase 1: Basic System Dependencies**
- curl, wget, git, gnupg, ca-certificates, software-properties-common, apt-transport-https

**Phase 2: Docker Dependencies**
- Docker Engine
- Docker Compose
- containerd, runc
- Automatic Docker installation via official script

**Phase 3: Arrmematey-Specific**
- Node.js (for UI)
- npm
- jq
- Disk space validation (minimum 10GB)
- Memory validation (minimum 2GB)

### 💾 Docker Storage Optimization
- Detects overlay2 storage configuration
- Identifies 1GB limitation issues
- Automatically reconfigures to `/opt/docker` for optimal performance
- Creates backups before making changes
- Verifies Docker functionality after changes

### 🚀 Complete Arrmematey Deployment
- Downloads Arrmematey from GitHub
- Creates necessary directories (Config, Media, Downloads)
- Sets up environment configuration
- Builds UI Docker image
- Starts full stack with all profiles
- Verifies installation

### ⚙️ Interactive Configuration
- Mullvad VPN account setup
- Directory configuration (customizable paths)
- Port configuration (with conflict detection)
- Service password setup
- Optional API keys (Fanart.tv, Cloudflare Tunnel)

## Architecture

### Hybrid Approach: Single Main Script + Downloaded Modules

The installer uses a hybrid architecture for the best of both worlds:

```
┌──────────────────────────────────────────────────────────────┐
│  arrmematey-proxmox-one-line.sh (Single Line Main Script)    │
│  - User runs: bash <(curl -fsSL ...)                         │
│  - Downloads all modules from GitHub                         │
│  - Sources and executes them                                 │
└────────────────────┬─────────────────────────────────────────┘
                     │
        ┌────────────▼───────────────┐
        │  Downloads from GitHub:    │
        │  modules/*.sh              │
        └────────────┬───────────────┘
                     │
        ┌────────────▼───────────────┐
        │  /tmp/arrmematey-installer │
        │  (modules cached locally)  │
        └────────────┬───────────────┘
                     │
    ┌────────────────▼────────────────────────────┐
    │  Execution Flow (same as before):           │
    │  1. proxmox-integration.sh                  │
    │  2. dependency-manager.sh                   │
    │  3. docker-storage-setup.sh                 │
    │  4. arrmematey-installer.sh                 │
    │  5. config-prompt.sh                        │
    └─────────────────────────────────────────────┘
```

### Benefits of This Approach

✅ **Single Line Installation** - One command, nothing more
✅ **Modular Organization** - Each module is separate and maintainable
✅ **Easy Updates** - Can update modules independently
✅ **Version Control** - Modules tracked in GitHub repo
✅ **Reusable** - Can run individual modules if needed
✅ **Testable** - Test each module separately

### Module Files (Stored in GitHub Repo)

- `modules/proxmox-integration.sh` - Proxmox VM setup
- `modules/dependency-manager.sh` - Progressive dependency checking
- `modules/docker-storage-setup.sh` - Docker storage optimization
- `modules/arrmematey-installer.sh` - Complete Arrmematey deployment
- `modules/config-prompt.sh` - Interactive configuration

## Module Descriptions

### proxmox-integration.sh
- Detects Proxmox VE host
- Downloads community Debian 13 VM script
- Handles automatic or manual execution
- Provides clear instructions for manual setup

### dependency-manager.sh
- **Progressive approach**: Checks basic → docker → arrmematey deps
- **Smart installation**: Only installs missing components
- **System validation**: Checks disk space and memory
- **Error handling**: Clear error messages and rollback capability

### docker-storage-setup.sh
- **Auto-detection**: Identifies overlay2 storage issues
- **Intelligent fix**: Reconfigures to /opt/docker for better performance
- **Safety first**: Creates backups before changes
- **Zero configuration**: "It just works" approach

### arrmematey-installer.sh
- **Git-based deployment**: Downloads latest from GitHub
- **Directory setup**: Creates all necessary directories
- **Environment config**: Sets up .env with defaults
- **UI build**: Compiles and builds Docker image
- **Service orchestration**: Starts all Arrmematey services

### config-prompt.sh
- **User-friendly**: Clear prompts for all settings
- **Validation**: Ensures required fields are filled
- **Sensible defaults**: Preserves existing config when possible
- **Access info**: Displays all URLs and credentials after completion

## Configuration

### Environment Variables (in ~/.env)

**Required:**
- `MULLVAD_ACCOUNT_ID` - Your Mullvad VPN account ID
- `MULLVAD_COUNTRY` - VPN country (default: us)
- `MULLVAD_CITY` - VPN city (default: ny)

**Directory Paths:**
- `CONFIG_PATH` - Configuration storage
- `MEDIA_PATH` - Media library base
- `DOWNLOADS_PATH` - Downloads staging area

**Ports:**
- `MANAGEMENT_UI_PORT` - Management UI (8080)
- `PROWLARR_PORT` - Prowlarr (9696)
- `SONARR_PORT` - Sonarr (8989)
- `RADARR_PORT` - Radarr (7878)
- `LIDARR_PORT` - Lidarr (8686)
- `SABNZBD_PORT` - SABnzbd (8080)
- `QBITTORRENT_PORT` - qBittorrent (8081)
- `JELLYSEERR_PORT` - Jellyseerr (5055)

**Optional:**
- `FANART_API_KEY` - For movie backdrops
- `CLOUDFLARE_TOKEN` - For remote access

## Access URLs

After installation, access your services at:

- **Management UI**: http://[VM-IP]:8080
- **Prowlarr**: http://[VM-IP]:9696
- **Sonarr**: http://[VM-IP]:8989
- **Radarr**: http://[VM-IP]:7878
- **Lidarr**: http://[VM-IP]:8686
- **SABnzbd**: http://[VM-IP]:8080
- **qBittorrent**: http://[VM-IP]:8081
- **Jellyseerr**: http://[VM-IP]:5055

## Default Credentials

- **SABnzbd**: username: `arrmematey`, password: `arrmematey_secure`
- **Jellyseerr**: username: `admin`, password: `arrmematey_secure`

⚠️ **Important**: Change these passwords after first login!

## Troubleshooting

### Docker Storage Issues
```bash
# Check Docker storage
docker info | grep -A 10 "Storage Driver"

# View Docker logs
journalctl -u docker.service
```

### Service Not Starting
```bash
# Check service status
cd /opt/arrmematey
docker-compose ps

# View logs
docker-compose logs [service-name]
```

### Network Connectivity
```bash
# Check VPN connection
docker exec gluetun curl ifconfig.me

# Check service ports
netstat -tulpn | grep [port-number]
```

### Re-run Configuration
```bash
# Edit environment file
nano ~/.env

# Restart services
cd /opt/arrmematey
docker-compose restart
```

### Reset Installation
```bash
# Stop all services
cd /opt/arrmematey
docker-compose down

# Remove volumes (WARNING: Deletes all data)
docker-compose down -v

# Re-run installer
./arrmematey-proxmox-installer.sh
```

## Requirements

### Proxmox VE Host
- Proxmox VE 7.0 or later
- Internet connection
- Sufficient disk space (20GB+ recommended)
- Available IP addresses for VM

### Target VM (Debian 13)
- Minimum 2GB RAM
- Minimum 20GB disk space
- Internet connection

### User
- Root access on Proxmox host
- Mullvad VPN account (required)

## Features

✅ **Zero-Configuration for Common Use Cases**
- Sensible defaults for most users
- Automatic storage optimization
- Smart dependency detection

✅ **Fail-Fast Error Handling**
- Clear error messages
- Detailed logging
- Easy to debug issues

✅ **Modular Architecture**
- Easy to maintain
- Can run modules independently
- Can update modules without full reinstall

✅ **Production-Ready**
- Health checks for all services
- Automatic service restart on failure
- Backup before major changes

## Development

### Testing
```bash
# Test script syntax
bash -n arrmematey-proxmox-installer.sh
bash -n modules/*.sh

# Run in dry-run mode (where applicable)
set -n  # No-op mode for bash
```

### Adding New Modules
1. Create module in `modules/` directory
2. Follow naming convention: `<module-name>.sh`
3. Export `INSTALL_MODE` variable for mode-aware behavior
4. Source module in main script
5. Add phase to installation flow

### Customization
- Modify default values in `modules/config-prompt.sh`
- Add new dependencies in `modules/dependency-manager.sh`
- Customize service configuration in `modules/arrmematey-installer.sh`

## License

Same as Arrmematey project - see main LICENSE file.

## Support

For issues with:
- **Arrmematey**: https://github.com/edellingham/arrmematey/issues
- **Proxmox Script**: https://github.com/community-scripts/ProxmoxVE/issues
- **Docker**: https://docs.docker.com/

---

**🏴‍☠️ Arrmematey Proxmox Installer - One command to rule them all!**
