# Agent Development Guidelines for Arrmematey

## Commands
```bash
# UI Development
cd ui && npm install          # Install dependencies
cd ui && npm start            # Start UI server (http://localhost:3000)

# Docker Stack Management
docker-compose --profile full up -d    # Start all services
docker-compose ps                          # View running containers
docker-compose logs -f <service>          # View service logs
./manage.sh status                         # Quick status check
./health.sh check                          # Full health report

# Testing (manual - no framework configured)
curl http://localhost:9696    # Test Prowlarr
curl http://localhost:8989    # Test Sonarr
curl http://localhost:7878    # Test Radarr
curl http://localhost:3000    # Test UI endpoint
```

## Code Style Guidelines

### JavaScript (Node.js/Express)
- Use CommonJS `require()` syntax (not ES6 modules)
- Async/await for error handling with try/catch blocks
- Environment variables via `process.env` with dotenv
- Express middleware patterns: `express.json()`, `express.static()`
- Socket.io for real-time updates
- RESTful API endpoints with proper status codes

### Bash Scripts
- Use `set -e` for error handling at script start
- Functions for reusable operations with `print_status()` patterns
- Color-coded output: `GREEN='\033[0;32m'`, `RED='\033[0;31m'`, `YELLOW='\033[1;33m'`
- Environment loading: `source .env` with error checks
- Parameter validation with proper error messages

### Docker & Configuration
- Use Docker Compose profiles (`full`, `vpn`, `media`, `downloaders`)
- Health checks required for all services
- Environment variables for all configuration (`.env` files)
- Network isolation: `network_mode: "service:gluetun"` for VPN-protected services
- Volume mounts: `${CONFIG_PATH}`, `${MEDIA_PATH}`, `${DOWNLOADS_PATH}`

### Error Handling
- Always wrap async operations in try/catch blocks
- Use meaningful error messages with context
- Return proper HTTP status codes in API endpoints
- Log errors with descriptive messages for debugging
- Graceful degradation for optional services

### Naming Conventions
- **Services**: `prowlarr`, `sonarr`, `radarr`, `lidarr`, `sabnzbd`, `qbittorrent`
- **Directories**: PascalCase for Docker services, snake_case for paths
- **Variables**: UPPERCASE for environment variables
- **Functions**: snake_case with descriptive names
- **Files**: kebab-case for scripts, meaningful names for components

### Security & Patterns
- VPN-first architecture: all downloads route through Gluetun container
- Kill-switch protection: traffic blocked if VPN disconnects
- Process isolation: download services cannot bypass VPN
- Secrets in `.env` files (gitignored)
- Read-only mounts where possible (`/var/run/docker.sock:ro`)

### UI Development
- Vanilla JavaScript (no framework)
- Socket.io for real-time container updates
- Express static file serving
- Pirate theme with 🏴‍☠️ emojis and maritime terminology
- Responsive design with CSS Grid/Flexbox
- API endpoints under `/api/` namespace

### Testing Approach
- Manual endpoint testing with curl
- Health check scripts: `./health.sh check`
- VPN security verification: `./vpn-security.sh check`
- Kill-switch testing: `./kill-switch-test.sh`
- Docker container status monitoring

### Documentation
- Shell-style comments with descriptive context
- Function documentation with parameter descriptions
- API endpoint documentation with request/response examples
- Pirate-themed messaging for user-facing content