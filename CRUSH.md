# CRUSH.md - Arrmematey Repository Guide

## Project Overview

**Arrmematey** is a comprehensive Docker-based media management stack with a pirate theme. It provides automated media acquisition, organization, and management services with VPN protection and a beautiful web-based management interface.

### Core Services
- **Prowlarr** - Indexer Manager (Port: 9696)
- **Sonarr** - TV Series Management (Port: 8989)
- **Radarr** - Movie Management (Port: 7878)
- **Lidarr** - Music Management (Port: 8686)
- **SABnzbd** - Usenet Downloader (Port: 8080)
- **qBittorrent** - Torrent Downloader (Port: 8081)
- **Jellyseerr** - Media Requests (Port: 5055)
- **Management UI** - Web-based control panel (Port: 8080)

### Key Features
- VPN protection via Gluetun (Mullvad)
- Docker Compose orchestration with profiles
- Pirate-themed management UI (Node.js + Express)
- Automated health monitoring and notifications
- Quality profile management via Recyclarr

## Essential Commands

### Setup and Installation
```bash
# Quick installation (recommended for new users)
./quick-install.sh

# Manual setup with detailed configuration
./setup.sh

# GitHub repository setup
./github-setup.sh

# Proxmox LXC deployment
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
```

### Daily Management
```bash
# Service status and control
./manage.sh status          # Show all service statuses
./manage.sh start           # Start all services
./manage.sh stop            # Stop all services
./manage.sh restart         # Restart all services
./manage.sh logs <service>  # View specific service logs
./manage.sh backup          # Backup configurations

# Health monitoring
./health.sh check            # Complete health assessment
./health.sh monitor          # Continuous monitoring
./health.sh report          # Detailed health report

# Security and VPN
./vpn-security.sh check     # Security audit and leak testing
./kill-switch-test.sh       # Emergency kill switch test
```

### Pirate-Themed Interface
```bash
# Pirate captain commands (fun theme)
./pirate.sh daily           # Complete daily routine
./pirate.sh status          # Crew status report
./pirate.sh greet           # Pirate greeting
./pirate.sh chant           # Sea shanty
./pirate.sh announce        # Captain announcement
./pirate.sh treasure        # Today's treasure found
./pirate.sh ui              # Open management UI
```

### Configuration Management
```bash
# Service configuration
./configure.sh              # Interactive service setup
./profiles.sh               # Quality profile management
```

## Project Structure

### Root Files
- `docker-compose.yml` - Main orchestration file with profiles
- `.env.example` - Environment configuration template
- `quick-install.sh` - One-command installation
- `manage.sh` - Daily service management
- `health.sh` - Health monitoring
- `pirate.sh` - Pirate-themed interface
- `configure.sh` - Service configuration
- `profiles.sh` - Profile management
- `vpn-security.sh` - Security auditing
- `kill-switch-test.sh` - Kill switch testing

### UI Directory (`ui/`)
- `server.js` - Node.js Express server with Docker API integration
- `public/index.html` - Pirate-themed web interface
- Features: Real-time service status, log viewing, container control

### Environment Configuration
Copy `.env.example` to `.env` and configure:
- VPN settings (Mullvad account ID, country, city)
- Port configurations for each service
- Media and download paths
- Quality profile selection
- Service enable/disable flags

## Docker Compose Architecture

### Service Profiles
- `full` - All services
- `vpn` - VPN and related services
- `indexers` - Prowlarr
- `media` - Sonarr, Radarr, Lidarr, Jellyseerr
- `downloaders` - SABnzbd, qBittorrent
- `ui` - Management UI
- `tunnel` - Cloudflare Tunnel
- `automation` - Recyclarr

### VPN Security
All download services (SABnzbd, qBittorrent, Sonarr, Radarr, Lidarr, Prowlarr) use `network_mode: "service:gluetun"` for forced VPN routing through Mullvad.

### Volume Structure
```
/home/$USER/
├── Config/          # Service configurations
├── Media/           # Organized media library
└── Downloads/       # Download staging area
```

## Code Patterns and Conventions

### Script Patterns
- All shell scripts use `set -e` for error handling
- Consistent color scheme: GREEN (success), RED (error), YELLOW (warning), BLUE (info)
- Pirate theme throughout with nautical terminology
- Environment loading from `.env` file

### UI Code Patterns
- Node.js Express with Socket.io for real-time updates
- Docker API integration for container management
- Async/await pattern for API calls
- Component-based service configuration

### Docker Patterns
- LinuxServer images for consistency
- Environment variable configuration
- Health checks on all critical services
- Profile-based service grouping

## Important Gotchas

### Security
- `.env` file is excluded from git (contains credentials)
- VPN kill switch is always active for download services
- DNS leak protection enabled
- All download services forced through VPN network

### Port Conflicts
- Management UI and SABnzbd both default to port 8080
- Use environment variables to change ports if conflicts occur
- VPN opens firewall ports for all services

### Dependencies
- Docker and Docker Compose required
- Mullvad VPN subscription required
- External DNS (1.1.1.1, 1.0.0.1) configured
- Health checks depend on service availability

### File Permissions
- Scripts expect non-root user with proper UID/GID
- Configuration files use user permissions (PUID/PGID)
- Docker volumes mapped to user directories

## Development Workflow

### Testing Changes
1. Test scripts locally with `bash -n script.sh` for syntax
2. Run health checks: `./health.sh check`
3. Verify VPN security: `./vpn-security.sh check`
4. Test UI functionality via web interface

### Configuration Changes
1. Modify `.env` for user settings
2. Edit `docker-compose.yml` for service changes
3. Run `./configure.sh` for service integration
4. Use `./profiles.sh` for quality profile changes

### Adding New Services
1. Add service to `docker-compose.yml` with appropriate profile
2. Update UI service configuration in `server.js`
3. Add service to health monitoring in `health.sh`
4. Update management scripts as needed

## Troubleshooting

### Common Issues
- **VPN Connection**: Check `./vpn-security.sh check` and Mullvad account
- **Port Conflicts**: Verify port settings in `.env` file
- **Service Health**: Use `./health.sh check` for comprehensive diagnostics
- **Container Issues**: Check logs with `./manage.sh logs <service>`

### Log Locations
- Application logs: Docker container logs via `./manage.sh logs`
- Script logs: Console output during execution
- UI logs: Browser developer tools

### Recovery Commands
```bash
# Complete restart
./manage.sh stop && ./manage.sh start

# Configuration reset
./configure.sh

# Health recovery
./health.sh check && ./manage.sh restart
```

## Security Considerations

- Always keep `.env` file private and out of version control
- VPN kill switch provides network protection
- Download services are isolated through VPN network
- Regular security audits via `./vpn-security.sh`
- Container updates managed through Docker Compose

## Performance Notes

- Health checks run every 5 seconds in UI
- Real-time updates via Socket.io
- Service start order respects dependencies
- Resource monitoring through Docker API
- Profile-based startup for resource optimization