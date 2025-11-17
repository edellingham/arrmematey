# 🔐 Wireguard-Only Migration Guide

## Executive Summary

**Critical Update**: Mullvad will remove OpenVPN support on **January 1, 2026**. Arrmematey is transitioning to a **Wireguard-only** approach to ensure future compatibility.

## Quick Start: Wireguard Setup

### Method 1: Using the Setup Script

```bash
# Download Mullvad Wireguard zip from your account:
# https://mullvad.net/en/account/#/wireguard-config

# Place the zip file in the Arrmematey directory, then run:
./wireguard-setup.sh mullvad_wireguard_linux_us_chi.zip

# Follow the prompts to configure your city
# Example cities: us-ny, us-chi, de-fra, nl-ams, uk-lon
```

### Method 2: Manual Configuration

#### Step 1: Extract Credentials
```bash
# Extract your Mullvad zip file
unzip mullvad_wireguard_linux_us_chi.zip

# View any of the .conf files
cat us-chi-wg-201.conf
```

**Extract these values:**
- `PrivateKey` (from `[Interface]` section)
- `Address` (from `[Interface]` section, IPv4 portion before comma)

#### Step 2: Update docker-compose.yml

Add to the `gluetun` service environment section:

```yaml
environment:
  - VPN_SERVICE_PROVIDER=mullvad
  - VPN_TYPE=wireguard
  - WIREGUARD_PRIVATE_KEY=2LJoWfUCFHejetq3m7ezIBx/GrZjPNY8WlAR9C9qalM=
  - WIREGUARD_ADDRESSES=10.68.81.251/32
  - SERVER_Countries=us
  - SERVER_Cities=chi
  - TZ=UTC
  - FIREWALL=on
  - AUTOCONNECT=true
  - KILLSWITCH=true
  - SHADOWSOCKS=off
```

**Note**: Both PrivateKey and Address are the same across all Mullvad servers - they identify your device, not the server location.

#### Step 3: Start Services
```bash
docker compose up -d
```

## SSH File Transfer

### For Remote Server Deployment

If your Arrmematey server is remote, use these methods to transfer the zip file:

#### Method 1: SCP (Secure Copy)
```bash
# From your local machine to remote server
scp mullvad_wireguard_linux_us_chi.zip user@your-server-ip:/opt/arrmematey/

# Example:
# scp mullvad_wireguard_linux_us_chi.zip root@192.168.1.100:/opt/arrmematey/
```

#### Method 2: RSYNC (More Efficient)
```bash
# Sync with progress bar
rsync -avz mullvad_wireguard_linux_us_chi.zip user@server:/opt/arrmematey/

# Resume interrupted transfers
rsync -avz --partial mullvad_wireguard_linux_us_chi.zip user@server:/opt/arrmematey/
```

#### Method 3: Pull from Remote (if you have the file on server)
```bash
# On your local machine, pull from remote server
scp user@server:/path/to/mullvad_wireguard_linux_us_chi.zip ./
```

#### Method 4: Base64 Encoding (for very restricted environments)
```bash
# On source machine - encode file
base64 mullvad_wireguard_linux_us_chi.zip > mullvad_wireguard_linux_us_chi.zip.base64

# Copy base64 content to clipboard and paste into remote

# On destination machine - decode file
base64 -d mullvad_wireguard_linux_us_chi.zip.base64 > mullvad_wireguard_linux_us_chi.zip
```

#### Method 5: Using wget/curl (if file is accessible via web)
```bash
# Upload to a temporary file sharing service or your own web server
# Then download on server:
wget https://your-server.com/mullvad_wireguard_linux_us_chi.zip
```

### Quick SSH Command Reference
```bash
# Standard port (22)
scp file.zip user@host:/path/

# Custom port
scp -P 2222 file.zip user@host:/path/

# With SSH key
scp -i ~/.ssh/id_rsa file.zip user@host:/path/

# Recursive (entire directory)
scp -r directory/ user@host:/path/
```

## Configuration Reference

### Wireguard Environment Variables

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `VPN_SERVICE_PROVIDER` | Yes | `mullvad` | VPN provider |
| `VPN_TYPE` | Yes | `wireguard` | Protocol type |
| `WIREGUARD_PRIVATE_KEY` | Yes | `2LJoWfUC...` | 32-byte base64 key from zip |
| `WIREGUARD_ADDRESSES` | Yes | `10.68.81.251/32` | IP address in CIDR format |
| `SERVER_Countries` | No | `us` | Country code(s) |
| `SERVER_Cities` | No | `chi` | City code(s) - determines server location |
| `WIREGUARD_ENDPOINT_PORT` | No | `51820` | Default port (optional) |

### Common City Codes

| Region | Code | City |
|--------|------|------|
| US | `us-ny` | New York |
| US | `us-chi` | Chicago |
| US | `us-la` | Los Angeles |
| US | `us-mia` | Miami |
| DE | `de-fra` | Frankfurt |
| NL | `nl-ams` | Amsterdam |
| UK | `uk-lon` | London |
| CA | `ca-tor` | Toronto |
| AU | `au-syd` | Sydney |
| JP | `jp-tyo` | Tokyo |

### Complete Example docker-compose.yml

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=mullvad
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=2LJoWfUCFHejetq3m7ezIBx/GrZjPNY8WlAR9C9qalM=
      - WIREGUARD_ADDRESSES=10.68.81.251/32
      - SERVER_Countries=us
      - SERVER_Cities=chi
      - TZ=UTC
      - FIREWALL=on
      - FIREWALL_VPN_INPUT_PORTS=8989,7878,8686,8080,8081
      - AUTOCONNECT=true
      - KILLSWITCH=true
      - SHADOWSOCKS=off
    volumes:
      - gluetun-config:/config
    ports:
      - '8989:8989'   # Sonarr
      - '7878:7878'   # Radarr
      - '8686:8686'   # Lidarr
      - '8080:8080'   # SABnzbd
      - '8081:8081'   # qBittorrent
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -s https://ifconfig.io >/dev/null && exit 0 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # ... other services (prowlarr, sonarr, radarr, etc.)
```

## Troubleshooting

### Issue: "dependency failed to start: container gluetun is unhealthy"

**Solution**: Remove `HEALTH_STATUS=off` and rely only on Docker's healthcheck. The gluetun internal healthcheck has known issues. Use this configuration:

```yaml
gluetun:
  environment:
    # ... other vars
    # HEALTH_STATUS=off  ← Remove this line
  healthcheck:
    test: ["CMD-SHELL", "curl -s https://ifconfig.io >/dev/null && exit 0 || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Issue: Wireguard Connection Fails

**Checks**:
1. Verify `WIREGUARD_PRIVATE_KEY` is exactly as in conf file (32-byte base64)
2. Verify `WIREGUARD_ADDRESSES` matches conf file (IPv4/CIDR format)
3. Check logs: `docker logs gluetun`

**Common Error**: Using Mullvad's "Manage devices" key instead of the zip file's PrivateKey

### Issue: Wrong IP Location

**Solution**: Set `SERVER_Cities` to your desired location:
```yaml
- SERVER_Cities=us-ny  # For New York
- SERVER_Cities=de-fra # For Frankfurt
- SERVER_Cities=uk-lon # For London
```

## Migration Timeline

| Date | Action |
|------|--------|
| **Now** | Deploy Wireguard-only configuration |
| **December 2025** | Test Wireguard exclusively |
| **January 1, 2026** | OpenVPN support ends - Wireguard only |

## Benefits of Wireguard

- ✅ **Faster**: Lower latency, higher throughput
- ✅ **Modern**: Latest VPN protocol (OpenVPN is legacy)
- ✅ **Efficient**: Fewer lines of code = fewer vulnerabilities
- ✅ **Future-proof**: Active development and support
- ✅ **Simpler**: Fewer configuration options = easier setup

## Additional Resources

- [Mullvad Wireguard Setup](https://mullvad.net/en/guides/wireguard/)
- [Mullvad Account: Generate Wireguard Config](https://mullvad.net/en/account/#/wireguard-config)
- [Gluetun Wiki: Mullvad](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/mullvad.md)

---

**Questions or Issues?** Check the logs: `docker logs gluetun` or view health status: `docker compose ps`