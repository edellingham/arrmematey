# Arrmematey VPN Fixes - Session Summary

## Session Objective
Fix VPN container failures in Arrmematey media automation stack, with user emphasis on "make sure the core script works. Not just fix this device."

## Critical Issues Resolved

### 1. DNS Configuration Error (v2.14.0+)
- **Problem**: `ERROR reading DNS settings: ParseAddr("1.1.1.1,1.0.0.1"): unexpected character`
- **Fix**: Removed `DNS_ADDRESS` to use gluetun's internal DNS (127.0.0.1)
- **Impact**: Primary blocker preventing VPN container startup

### 2. VPN Authentication Variables (v2.14.0+)
- **Problem**: `ERROR VPN settings: Wireguard settings: private key is not set` and `ERROR VPN settings: OpenVPN settings: user is empty`
- **Fix**: Used official Gluetun variables (`OPENVPN_USER`, `WIREGUARD_PRIVATE_KEY`)
- **Impact**: Proper VPN authentication for both OpenVPN and Wireguard protocols

### 3. Healthcheck Endpoint Failure (v2.14.0+)
- **Problem**: `ExitCode: 8` on wget to ifconfig.me
- **User Feedback**: "I've always used ifconfig.io" - suggested curl instead of wget
- **Fix**: Changed to curl-based healthcheck: `curl -s https://ifconfig.io >/dev/null && exit 0 || exit 1`
- **Impact**: Reliable health monitoring without VPN blocking

### 4. Healthcheck Timeout (v2.14.0+)
- **Problem**: 420 second max wait time (start_period=120s, retries=10)
- **Fix**: Reduced to 150 seconds max (start_period=60s, retries=3)
- **Impact**: Faster startup with reasonable failure timeout

### 5. Port Conflict (v2.13.1+)
- **Problem**: `Bind for 0.0.0.0:8080 failed: port is already allocated`
- **Fix**: Changed Management UI from 8080 to 8787
- **Impact**: Both SABnzbd and Management UI can run simultaneously

### 6. Gluetun Internal Healthcheck Conflict (v2.14.5) - LATEST
- **Problem**: `dependency failed to start: container gluetun is unhealthy` despite working perfectly
- **Root Cause**: Gluetun has internal healthcheck targeting cloudflare.com:443 during startup, fails before VPN fully ready
- **Investigation**: Logs showed successful VPN connection and valid Swiss IP (81.17.16.78)
- **Fix**: Added `HEALTH_STATUS=off` to disable internal healthcheck
- **Impact**: Eliminates false unhealthy status during VPN initialization

## Files Modified

### Core Configuration
1. **docker-compose.yml**
   - Added `HEALTH_STATUS=off` and `SHADOWSOCKS=off`
   - Updated gluetun environment variables
   - Reduced healthcheck timeouts

### Installers (All Version Bumped to Avoid CDN Cache)
2. **install-arrmematey.sh** (v2.14.4 → v2.14.5)
   - Interactive VPN type selection (OpenVPN/Wireguard)
   - Sets OPENVPN_USER and WIREGUARD_PRIVATE_KEY appropriately
   - Improved installation visibility
   - Added HEALTH_STATUS=off

3. **install.sh** (v2.1.4 → v2.1.5)
   - Menu-based installer with cleanup options
   - Docker storage management
   - Added HEALTH_STATUS=off

4. **fresh-install.sh** (latest)
   - Simplified Debian 13 installer
   - Added HEALTH_STATUS=off and SHADOWSOCKS=off

### Documentation
5. **CONVERSATION_SUMMARY.md**
   - 520-line comprehensive documentation
   - All fixes documented with technical details
   - Version history and troubleshooting guide

## User Contributions

Key user inputs that shaped the solution:
- "Not just fix this device" → Systematic fixes across all installer scripts
- "Let's make it an option" → VPN type selection (OpenVPN/Wireguard)
- "I've always used ifconfig.io" → Healthcheck endpoint recommendation
- "Did you push it?" → Version bumping to avoid CDN caching
- Demand for version increment on every change

## Technical Architecture

### VPN-First Security Model
All download services route through gluetun container using `network_mode: "service:gluetun"`:
- Kill-switch protection: traffic blocked if VPN disconnects
- Process isolation: download services cannot bypass VPN
- Port exposure: all service ports exposed through gluetun container

### Service Dependency Chain
```
Gluetun (VPN) → Prowlarr (indexers) → Sonarr/Radarr/Lidarr (media managers) → SABnzbd/qBittorrent (downloaders)
```

### Healthcheck Configuration
```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -s https://ifconfig.io >/dev/null && exit 0 || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Gluetun Configuration
```yaml
environment:
  - VPN_SERVICE_PROVIDER=mullvad
  - VPN_TYPE=${VPN_TYPE:-openvpn}
  - OPENVPN_USER=${OPENVPN_USER:-${MULLVAD_USER:-${MULLVAD_ACCOUNT_ID}}}
  - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY:-${MULLVAD_PRIVATE_KEY:-}}
  - SERVER_Countries=${MULLVAD_COUNTRY:-us}
  - SERVER_Cities=${MULLVAD_CITY:-ny}
  - FIREWALL=on
  - AUTOCONNECT=true
  - KILLSWITCH=true
  - SHADOWSOCKS=off
  - HEALTH_STATUS=off  # Disables internal healthcheck
```

## Version Strategy
- Every script modification triggers version increment
- Avoids CDN caching of installer scripts
- Latest versions:
  - install-arrmematey.sh: v2.14.5
  - install.sh: v2.1.5
  - docker-compose.yml: latest with all fixes

## Testing & Validation
Successful deployment verified with:
- VPN connection established (Switzerland IP: 81.17.16.78)
- Healthcheck passing (curl ifconfig.io)
- All services starting without dependency failures
- Stack fully operational through gluetun VPN

## Key Lessons
1. Check official documentation first (Gluetun wiki for correct variables)
2. Version bump on every change (CDN caching causes user confusion)
3. Test with real VPN (some endpoints blocked by Mullvad)
4. Show installation progress (hidden operations appear broken)
5. Cross-script consistency (all installers must have same fixes)
6. Healthchecks matter (false failures cause unnecessary troubleshooting)

## Current Status
All VPN-related issues resolved. Stack deploys successfully with Mullvad VPN protection. Latest fix (HEALTH_STATUS=off) prevents false unhealthy status during VPN initialization.

## Next Steps for Users
1. Run latest installer (v2.14.5) to get all fixes
2. Configure Mullvad account ID in .env
3. Add indexers in Prowlarr
4. Configure SABnzbd news server
5. Set up Emby user account