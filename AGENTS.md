# Agent Development Guidelines for Arrmematey

## Project Overview

**Arrmematey** is a Docker-based media automation stack with VPN-first security architecture. This is an **orchestration and deployment project**, not a traditional software development project. There are no build/lint/test workflows - services are deployed via Docker Compose, and "development" primarily involves UI development and shell script modifications.

**Core Purpose**: Orchestrate media managers (Sonarr, Radarr, Lidarr), download clients (SABnzbd, qBittorrent), and indexer management (Prowlarr) through a Gluetun VPN container with kill-switch protection. Includes a pirate-themed Node.js management UI for real-time service monitoring and control.

## Commands

### UI Development
```bash
cd ui && npm install          # Install dependencies
cd ui && npm start            # Start UI server (http://localhost:3000)
# Or:
cd ui && node server.js       # Start directly
```

### Docker Stack Management
```bash
docker-compose --profile full up -d    # Start all services
docker-compose --profile media up -d    # Start media managers only
docker-compose --profile downloaders up -d    # Start downloaders only
docker-compose ps                          # View running containers
docker-compose logs -f <service>          # View service logs
docker-compose restart <service>          # Restart specific service
docker-compose down                        # Stop all services
```

### Current Management Commands
```bash
./arrmematey-manager.sh              # Interactive TUI manager (primary management tool)
./quick-install.sh                    # One-command installation
./install-arrmematey.sh              # Alternative installer
```

### Module System
```bash
# Modules are in modules/ directory - used by installers
source modules/dependency-manager.sh   # Load dependency management functions
source modules/config-prompt.sh        # Load configuration prompt functions
source modules/docker-storage-setup.sh # Load Docker storage functions
```

### Proxmox Deployment
```bash
# Deploy to Proxmox LXC (run on Proxmox host)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
# Or use local scripts:
./arrmematey-proxmox-installer.sh     # Interactive Proxmox installer
./arrmematey-proxmox-one-line.sh      # One-line Proxmox deployment
```

### Testing (manual - no framework configured)
```bash
# Test service endpoints
curl http://localhost:9696    # Test Prowlarr
curl http://localhost:8989    # Test Sonarr
curl http://localhost:7878    # Test Radarr
curl http://localhost:8686    # Test Lidarr
curl http://localhost:8080    # Test SABnzbd
curl http://localhost:8081    # Test qBittorrent
curl http://localhost:5055    # Test Jellyseerr
curl http://localhost:3000    # Test UI endpoint

# VPN verification
docker exec gluetun curl ifconfig.me    # Check VPN IP (should be Mullvad)
```

## Code Style Guidelines

### JavaScript (Node.js/Express)
- Use CommonJS `require()` syntax (not ES6 modules) - see ui/package.json
- Async/await for error handling with try/catch blocks
- Environment variables via `process.env` with dotenv
- Express middleware patterns: `express.json()`, `express.static()`
- Socket.io for real-time updates (broadcasts every 5 seconds)
- RESTful API endpoints with proper status codes
- Docker API integration via `dockerode` package
- Fanart.tv API integration for movie backdrops

### Bash Scripts
- Use `set -e` for error handling at script start (some use `set -euo pipefail`)
- Functions for reusable operations with `print_status()` patterns
- Color-coded output: `GREEN='\033[0;32m'`, `RED='\033[0;31m'`, `YELLOW='\033[1;33m'`, `BLUE='\033[0;34m'`, `PURPLE='\033[0;35m'`, `CYAN='\033[0;36m'`
- Environment loading: `source .env` with error checks
- Parameter validation with proper error messages
- Modular design: functions separated into modules/ directory
- TUI interfaces using dialog/whiptail for interactive management

### Docker & Configuration
- Use Docker Compose profiles (`full`, `vpn`, `media`, `downloaders`, `indexers`, `ui`, `tunnel`, `automation`)
- Health checks required for all services (30s interval, 10s timeout, 3 retries)
- Environment variables for all configuration (`.env` files)
- **Critical VPN Pattern**: `network_mode: "service:gluetun"` for VPN-protected services
- Volume mounts: `${CONFIG_PATH}`, `${MEDIA_PATH}`, `${DOWNLOADS_PATH}`
- Service dependencies via `depends_on` with `condition: service_healthy`
- LinuxServer images for consistency
- Port exposure through Gluetun container for VPN services

### Error Handling
- Always wrap async operations in try/catch blocks
- Use meaningful error messages with context
- Return proper HTTP status codes in API endpoints
- Log errors with descriptive messages for debugging
- Graceful degradation for optional services
- Health check failures trigger service restarts automatically
- VPN connectivity failures block download services (kill-switch)

### Naming Conventions
- **Services**: `prowlarr`, `sonarr`, `radarr`, `lidarr`, `sabnzbd`, `qbittorrent`, `jellyseerr`, `emby`
- **Containers**: Same as services, prefixed with container name in Docker
- **Directories**: PascalCase for Docker volumes, snake_case for paths
- **Variables**: UPPERCASE for environment variables (MULLVAD_ACCOUNT_ID, PUID, PGID)
- **Functions**: snake_case with descriptive names (print_header, check_docker, print_status)
- **Files**: kebab-case for scripts (arrmematey-manager.sh), meaningful names for components

### Security & Patterns
- **VPN-first architecture**: All downloads route through Gluetun container
- **Kill-switch protection**: Traffic blocked if VPN disconnects (KILLSWITCH=true)
- **Process isolation**: Download services cannot bypass VPN
- **Network Mode**: Download services use `network_mode: "service:gluetun"`
- **Secrets Management**: All secrets in `.env` files (gitignored)
- **Read-only mounts**: Docker socket mounted read-only (`/var/run/docker.sock:ro`)
- **DNS Protection**: Cloudflare DNS (1.1.1.1) to prevent leaks
- **Firewall Rules**: Explicit port opening through VPN firewall

### UI Development
- **Framework**: Vanilla JavaScript (no framework) with Socket.io for real-time updates
- **Backend**: Express server (`ui/server.js`) with Docker API integration via `dockerode`
- **Real-time**: Socket.io broadcasts container status every 5 seconds
- **Static Files**: Express static file serving from `ui/public/`
- **API Design**: RESTful endpoints under `/api/` namespace
- **Theme**: Pirate theme with 🏴‍☠️ emojis and maritime terminology
- **Assets**: Local images served from `/images/` endpoint, movie backdrops from `ui/public/images/backgrounds/`
- **Responsive Design**: CSS Grid/Flexbox layouts
- **Debugging**: Console logs with emoji indicators for troubleshooting

### Project Structure
```
arrmematey/
├── ui/                          # Management UI (only development area)
│   ├── server.js                # Express server with Docker API integration
│   ├── package.json             # Dependencies: express, dockerode, socket.io, dotenv
│   ├── public/                  # Static web assets
│   │   ├── index.html           # Pirate-themed web interface
│   │   └── images/             # UI images and backgrounds
│   └── logs/                   # UI server logs
├── modules/                     # Modular script components
│   ├── arrmematey-installer.sh # Core installation logic
│   ├── config-prompt.sh         # Interactive configuration prompts
│   ├── dependency-manager.sh     # System dependency management
│   ├── docker-storage-setup.sh  # Docker storage configuration
│   └── proxmox-integration.sh  # Proxmox LXC deployment logic
├── images/                      # Project logos and assets
│   ├── arrmematey-logo.svg      # Main logo (2.9:1 aspect ratio)
│   ├── arrmematey-icon.png      # Icon file
│   └── arrmematey-ascii.txt     # ASCII art banner
├── docker-compose.yml           # Main orchestration file with profiles
├── .env.example                 # Environment configuration template
├── arrmematey-manager.sh        # Primary TUI management interface
├── quick-install.sh             # One-command installation
├── install-arrmematey.sh       # Alternative installer
└── Various deployment scripts   # Proxmox, cleanup, and setup utilities
```

### Testing Approach
- **No Traditional Testing Framework**: Project uses service-level testing via Docker health checks
- **Manual Endpoint Testing**: Use curl to test service accessibility
- **Health Verification**: Docker health checks monitor service availability (30s intervals)
- **VPN Security Testing**: Manual verification via `docker exec gluetun curl ifconfig.me`
- **UI Testing**: Browser-based testing with developer console for debugging
- **Container Management**: Test via arrmematey-manager.sh TUI interface
- **Service Dependencies**: Verify startup order through health check dependencies
- **Network Testing**: Confirm VPN routing and port accessibility

### Environment Configuration
- **Primary Config**: `.env` file (copy from `.env.example`)
- **Required Variables**: `MULLVAD_ACCOUNT_ID`, `PUID`, `PGID`, directory paths
- **VPN Settings**: `MULLVAD_COUNTRY`, `MULLVAD_CITY`, `VPN_TYPE` (openvpn/wireguard)
- **Port Configuration**: All services have configurable ports with defaults
- **Path Configuration**: `CONFIG_PATH`, `MEDIA_PATH`, `DOWNLOADS_PATH`
- **Service Flags**: Enable/disable specific services via environment variables
- **API Keys**: `FANART_API_KEY` for UI backdrop functionality

### Documentation
- Shell-style comments with descriptive context in scripts
- Function documentation with parameter descriptions in module files
- API endpoint documentation in code comments
- Pirate-themed messaging for user-facing content in UI
- Comprehensive README.md with setup instructions
- Inline documentation in docker-compose.yml for service descriptions

## Critical Implementation Patterns

### VPN-First Security Model
**MANDATORY**: All download services MUST use `network_mode: "service:gluetun"`:
- Services requiring VPN: `prowlarr`, `sonarr`, `radarr`, `lidarr`, `sabnzbd`, `qbittorrent`
- Port exposure: Must be exposed through Gluetun container, not directly
- Dependencies: Must depend on `gluetun` with `condition: service_healthy`
- Result: Complete traffic isolation through Mullvad VPN

### Service Dependency Chain
```
gluetun (VPN) → prowlarr (indexers) → sonarr/radarr/lidarr (media managers) → sabnzbd/qbittorrent (downloaders)
```
- Health checks ensure proper startup order
- Prowlarr must be healthy before media managers start
- Media managers configure indexers from Prowlarr automatically

### UI Service Integration Pattern
When adding new services that need UI management:
1. Add service configuration to `getServiceConfig()` in `ui/server.js`
2. Include: `port`, `name`, `icon` properties
3. Service will automatically appear in UI with status monitoring
4. Container discovery uses service name matching (container names include service name)

### Script Modularization Pattern
- Core functions separated into `modules/` directory
- Installers source modules: `source modules/dependency-manager.sh`
- Each module has single responsibility (config, storage, dependencies)
- Error handling and user interaction patterns shared across modules

### Configuration Management Pattern
- All user settings in `.env` (never hard-coded)
- Default values provided in `docker-compose.yml` with `${VAR:-default}` syntax
- Sensitive data (API keys, VPN credentials) excluded from git
- Auto-configuration scripts extract API keys from service web interfaces

## Important Gotchas & Non-Obvious Patterns

### Outdated Documentation References
- Several scripts referenced in older docs don't exist: `health.sh`, `manage.sh`, `configure.sh`, `pirate.sh`
- Current management uses `arrmematey-manager.sh` for TUI interface
- Installation primarily via `quick-install.sh` or `install-arrmematey.sh`

### VPN Kill-Switch Behavior
- **Critical**: If Gluetun container stops, all download services lose network access
- This is intentional security behavior, not an error
- Restart gluetun first, then dependent services will recover automatically

### Port Conflict Management
- Management UI defaults to port 3000, SABnzbd to 8080
- All service ports configurable via environment variables
- VPN firewall automatically opens configured ports for services

### Docker Socket Security
- UI container mounts Docker socket read-only: `/var/run/docker.sock:ro`
- Allows container monitoring but prevents container modification
- UI can start/stop services but cannot modify Docker configuration

### Proxmox Deployment Specifics
- Designed for unprivileged LXC containers
- Requires storage passthrough for media/downloads/config directories
- Nested virtualization needed for Docker-in-LXC functionality
- UID/GID mapping critical for file permissions

### Service Health Check Limitations
- Health checks only verify container responsiveness, not functionality
- Manual verification via web interfaces recommended for setup validation
- VPN connectivity verified separately via external IP checks

### Environment Variable Precedence
- `.env` file overrides docker-compose defaults
- Environment variables take precedence over `.env` file
- CLI arguments to docker-compose override all other sources