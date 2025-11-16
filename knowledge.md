# Arrmematey Project Knowledge

## Project Overview

Arrmematey is a Docker-based media automation stack with VPN-first security. It orchestrates media managers (Sonarr, Radarr, Lidarr), download clients (SABnzbd, qBittorrent), and indexer management (Prowlarr) through a Gluetun VPN container with kill-switch protection.

## Key Architecture Decisions

### VPN-First Security
- All download services route through Gluetun using `network_mode: "service:gluetun"`
- Kill-switch protection ensures traffic blocked if VPN disconnects
- When adding download-related services, they MUST use this network mode

### Service Dependency Chain
```
Gluetun (VPN) → Prowlarr (indexers) → Sonarr/Radarr/Lidarr → SABnzbd/qBittorrent
```

### Docker Compose Profiles
- `full` - Complete stack (default)
- `vpn` - VPN and related services
- `media` - Media managers only
- `downloaders` - Download clients only
- `indexers` - Prowlarr only
- `ui` - Management UI only

## UI Development

### Tech Stack
- Backend: Express server with Dockerode for container management
- Real-time: Socket.io for live updates
- Frontend: Vanilla JavaScript (no framework)
- Theme: Pirate-themed with butler personality

### Key Files
- `ui/server.js` - Express server with Docker API integration
- `ui/public/index.html` - Main UI with pirate theme
- `ui/package.json` - Dependencies

### Background Images
- Stored in `ui/public/images/backgrounds/`
- Rotated every 5 seconds via client-side JavaScript
- No external API dependencies (local files only)

## Development Workflow

### Running UI Locally
```bash
cd ui && node server.js
```
UI runs on port 3000 (or PORT env var). Requires Docker socket access.

### Testing Changes
1. Edit files in `ui/`
2. Restart UI: `docker-compose restart arrstack-ui`
3. Clear browser cache if static assets changed
4. Check browser console (F12) for errors

## Common Patterns

### Adding New Services
1. Add to `docker-compose.yml` with appropriate profile
2. Add health check and dependencies
3. If download-related, use `network_mode: "service:gluetun"`
4. Update `ui/server.js` getServiceConfig() for UI integration

### Script Organization
- Modular scripts with single responsibility
- Butler/pirate theme in user-facing messages
- Color coding: RED/GREEN/YELLOW/PURPLE
- All scripts source `.env` for configuration

## Security Notes

- VPN kill-switch always enabled (`KILLSWITCH=true`)
- Docker socket mounted read-only in UI
- API keys stored in `.env` (gitignored)
- Mullvad account ID required in environment

## File Locations

- Configuration: `.env` (copy from `.env.example`)
- Media/Downloads: User-defined paths in `.env`
- Service configs: `~/Config/` subdirectories
- Logs: `logs/` directory for startup processes
