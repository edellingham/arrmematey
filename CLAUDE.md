# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Arrmematey** is a Docker-based media automation stack with VPN-first security architecture. It orchestrates media managers (Sonarr, Radarr, Lidarr), download clients (SABnzbd, qBittorrent), and indexer management (Prowlarr) through a Gluetun VPN container with kill-switch protection. The project includes a pirate-themed Node.js management UI for real-time service monitoring and control.

## Core Architecture

### VPN-First Security Model
All download services route through the Gluetun VPN container using Docker's `network_mode: "service:gluetun"`. This ensures:
- **Kill-switch protection**: Traffic blocked if VPN disconnects
- **Process isolation**: Download services cannot bypass VPN
- **Port exposure**: All service ports exposed through Gluetun container

**Critical**: When adding new download-related services, they MUST use `network_mode: "service:gluetun"` and expose ports through the Gluetun service in `docker-compose.yml`.

### Service Dependency Chain
```
Gluetun (VPN) → Prowlarr (indexers) → Sonarr/Radarr/Lidarr (media managers) → SABnzbd/qBittorrent (downloaders)
```

Services use health checks and `depends_on` to ensure proper startup order. Prowlarr must be running before media managers can configure indexers.

### Docker Compose Profiles
The stack uses profiles for flexible deployment:
- `full` - Complete stack (default for production)
- `vpn` - VPN and related services only
- `media` - Media managers (Sonarr/Radarr/Lidarr)
- `downloaders` - Download clients (SABnzbd/qBittorrent)
- `indexers` - Prowlarr only
- `ui` - Management UI only

**Usage**: `docker-compose --profile full up -d` or `docker-compose --profile media --profile downloaders up -d`

### Management UI Architecture
- **Backend**: Express server (`ui/server.js`) with Dockerode for container management
- **Real-time Updates**: Socket.io broadcasts container status every 5 seconds
- **API Endpoints**:
  - `GET /api/services` - List all services with status
  - `POST /api/service/:id/:action` - Control services (start/stop/restart)
  - `GET /api/service/:id/logs` - Fetch container logs
  - `GET /api/system/info` - System and Docker info
  - `GET /api/background/random` - Serve random local background images
- **Frontend**: Vanilla JavaScript with pirate theme, no framework
- **Static Assets**: Served from `ui/public/`, images from `images/`

## Development Commands

### UI Development
```bash
# Install dependencies
cd ui && npm install

# Start UI server (development)
cd ui && node server.js

# UI runs on http://localhost:3000 (or PORT env var)
# Requires Docker socket access (/var/run/docker.sock)
```

### Docker Stack Management
```bash
# Start full stack
docker-compose --profile full up -d

# Start specific profiles
docker-compose --profile media --profile downloaders up -d

# View running containers
docker-compose ps

# View logs for specific service
docker-compose logs -f sonarr

# Stop all services
docker-compose down

# Restart single service
docker-compose restart prowlarr
```

### Setup and Configuration
```bash
# Quick installation (interactive)
./quick-install.sh

# Manual setup with configuration
./setup.sh

# Configure service connections
./configure.sh

# Health monitoring
./health.sh check         # One-time health check
./health.sh monitor       # Continuous monitoring
./health.sh report        # Detailed health report

# Security auditing
./vpn-security.sh check   # VPN and firewall audit
./kill-switch-test.sh     # Test VPN kill-switch

# Service management
./manage.sh status        # Service status report
./manage.sh logs sonarr   # View service logs
./manage.sh restart       # Restart all services
./manage.sh backup        # Backup configurations
```

### Proxmox Deployment
```bash
# Deploy to Proxmox LXC (run on Proxmox host)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"

# Or use local deployment script
./proxmox-deploy.sh
```

## Key Implementation Patterns

### Script Organization
- **Modular Scripts**: Each script has single responsibility (setup, configure, manage, health)
- **Butler Theme**: UI uses butler/pirate personality in user-facing messages
- **Color Coding**: Scripts use consistent color codes (RED/GREEN/YELLOW/PURPLE)
- **Environment Loading**: All scripts source `.env` for configuration

### Configuration Management
- **Primary Config**: `.env` file (copy from `.env.example`)
- **Required Variables**: `MULLVAD_ACCOUNT_ID`, directory paths, ports
- **Auto-Configuration**: `configure.sh` extracts and stores API keys automatically
- **Profile Management**: `profiles.sh` handles quality profile application via Recyclarr

### Service Integration Pattern
When adding new services:
1. Add to `docker-compose.yml` with appropriate profile
2. Add health check for startup verification
3. Use `depends_on` for dependency ordering
4. If download-related, use `network_mode: "service:gluetun"`
5. Add to UI service config in `ui/server.js` (getServiceConfig function)
6. Update management scripts to recognize new service

## Important File Locations

### Core Configuration
- `docker-compose.yml` - Service definitions and orchestration
- `.env` - Environment configuration (not in git, copy from `.env.example`)
- `.env.example` - Template with all configuration options

### UI Components
- `ui/server.js` - Express server with Docker API integration, Fanart.tv integration
- `ui/public/index.html` - Main UI with pirate theme, backdrop system
- `ui/package.json` - Dependencies: express, dockerode, socket.io, dotenv
- `images/` - Project logos and assets (arrmematey-logo.svg, arrmematey-icon.png)

### Orchestration Scripts
- `setup.sh` - Interactive installation and Docker setup
- `quick-install.sh` - One-command express setup
- `configure.sh` - Service configuration and API key management
- `butler.sh` - Butler-themed service interaction commands
- `manage.sh` - Service management (status, logs, restart, backup)
- `health.sh` - Health monitoring and reporting
- `vpn-security.sh` - VPN and security auditing
- `kill-switch-test.sh` - Emergency VPN kill-switch testing
- `profiles.sh` - Quality profile management via Recyclarr
- `proxmox-deploy.sh` - Proxmox LXC container deployment

### Documentation
- `README.md` - Main project documentation
- `PROXMOX.md` - Proxmox deployment guide
- `MEMORY.md` - Project context and recent changes
- `SETUP.md` - Manual setup instructions
- `GITHUB.md` - GitHub repository setup guide

## Testing and Validation

### Pre-Deployment Checks
```bash
# Verify Docker is running
docker ps

# Validate docker-compose configuration
docker-compose config

# Check VPN configuration
./vpn-security.sh check

# Verify all environment variables set
source .env && env | grep -E "(MULLVAD|CONFIG|MEDIA|DOWNLOADS)"
```

### Health Verification
```bash
# Full health check
./health.sh check

# Monitor continuously
./health.sh monitor

# Test VPN kill-switch
./kill-switch-test.sh
```

### Service Testing
```bash
# Verify service connectivity
curl http://localhost:9696  # Prowlarr
curl http://localhost:8989  # Sonarr
curl http://localhost:7878  # Radarr

# Check VPN IP (should be Mullvad IP, not local)
docker exec gluetun curl ifconfig.me

# Verify Docker socket access from UI
docker exec arrstack-ui ls -la /var/run/docker.sock
```

## Theme and Style Conventions

### Pirate Theme (Current)
- **Terminology**: Captain, crew, treasure hunting, sailing
- **Emojis**: 🏴‍☠️ (pirate flag), 🍿 (media), ⚓ (anchor), 🗺️ (map)
- **Messages**: "Ahoy!", "Arr... me matey!", "All hands on deck!"
- **Visual**: Custom SVG logo (arrmematey-logo.svg), light backgrounds (#f8fafc)

**Important**: No "butler" references in UI - project transitioned from butler to pirate theme (see MEMORY.md for history).

### UI Design Patterns
- **Logo Ratio**: 2.9:1 aspect ratio (300x103px arrmematey-logo.svg)
- **Backgrounds**: Light (#f8fafc), no gradients; random movie backdrops via local images
- **Z-index Layering**: backdrop (-1), overlay (1), content (2)
- **Debugging**: Console logs with emoji indicators for troubleshooting
- **Cache-Busting**: Timestamp parameters for dynamic image loading

### Code Style
- **Bash Scripts**: Consistent color codes, modular functions, error handling with `set -e`
- **JavaScript**: Vanilla JS (no framework), Socket.io for real-time, fetch API for requests
- **Docker**: Health checks required, explicit dependencies, profile-based organization
- **Configuration**: Environment variables preferred over hard-coded values

## Security Considerations

### VPN Configuration
- **Kill-Switch**: Always enabled (`KILLSWITCH=true`)
- **Firewall**: Active with explicit port rules
- **DNS Protection**: Uses Cloudflare DNS (1.1.1.1) to prevent leaks
- **Service Isolation**: Download services cannot bypass VPN

### File Permissions
- **Docker Socket**: Mounted read-only in UI (`/var/run/docker.sock:ro`)
- **Media Paths**: Use PUID/PGID from environment for proper permissions
- **Configuration**: Config directories in `~/Config/` with service-specific subdirectories

### Secrets Management
- **API Keys**: Stored in `.env` (gitignored)
- **Passwords**: Generated or prompted during setup
- **VPN Credentials**: Mullvad account ID in environment variables
- **Fanart.tv API**: Key in `.env` (FANART_API_KEY)

## Deployment Targets

### Local Docker Host
- Standard `docker-compose` deployment
- Direct access to services via localhost ports
- Development and testing environment

### Proxmox LXC
- Automated deployment via `proxmox-deploy.sh`
- Storage passthrough for media/downloads/config
- Nested virtualization for Docker containers
- Unprivileged container with proper UID mapping

### Remote/Cloud
- Cloudflare Tunnel integration (optional profile)
- Remote access without port forwarding
- Configured via `CLOUDFLARE_TOKEN` in `.env`

## Common Workflows

### Initial Setup
1. Clone repository
2. Copy `.env.example` to `.env`
3. Configure `MULLVAD_ACCOUNT_ID` and directory paths
4. Run `./quick-install.sh` or `./setup.sh`
5. Access UI at `http://localhost:8080`

### Adding New Service
1. Add service definition to `docker-compose.yml`
2. Set appropriate profile (`media`, `downloaders`, etc.)
3. Add health check and dependencies
4. Update `ui/server.js` getServiceConfig() if web UI needed
5. Test with `docker-compose --profile <profile> up -d`

### Updating Quality Profiles
1. Edit quality settings in desired profile
2. Run `./profiles.sh` to apply Recyclarr configurations
3. Verify in Sonarr/Radarr web UI

### Backup and Recovery
```bash
# Backup all configurations
./manage.sh backup

# Configurations stored in ~/Config/ directories
# Restore by copying directories back to CONFIG_PATH
```

### UI Development Iteration
1. Edit `ui/server.js` or `ui/public/index.html`
2. Restart UI: `docker-compose restart arrstack-ui`
3. Clear browser cache if static assets changed
4. Check browser console (F12) for debugging output
