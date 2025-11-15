# 🏴‍☠️ Arrmematey — Your Pirate Crew for Media Treasure

Arrmematey sails in with a crew that keeps every media service steady and every download route protected. It bundles the monitoring UI, download managers, VPN-fortified tunnels, and orchestration scripts you need to keep your pirate fleet at the ready.

## ⚓ Quick Start

Run the express setup to get Arrmematey going with smart defaults (VPN, Docker, services, and UI all configured automatically):
```bash
./quick-install.sh
```

Once the script is done, the stack is up and the management UI is available at `http://localhost:8080`.

## 🚀 Proxmox LXC One-Liner

Deploy directly from your Proxmox host with a single command. The `deploy.sh` wrapper fetches the full `proxmox-deploy.sh`, creates the container, installs Docker, runs `quick-install.sh`, and leaves the UI running:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
```

Follow the prompts for storage, Mullvad VPN ID, and media server choices—everything else is automated.

The storage prompt now lists every detected media/download path (including ZFS mountpoints) and automatically creates the folder you select before the container starts, so you do not need to prepare directories manually.

## ⚔️ Core Services on Deck
- 🔍 **Prowlarr** – Indexer commander (https://localhost:9696)
- 🎬 **Sonarr** – TV series scout (https://localhost:8989)
- 🎥 **Radarr** – Movie captain (https://localhost:7878)
- 🎵 **Lidarr** – Music quartermaster (https://localhost:8686)
- 📥 **SABnzbd** – Usenet pulpit (https://localhost:8080)
- ⬇️ **qBittorrent** – Torrent launchpad (https://localhost:8081)
- 🍿 **Jellyseerr** – Request desk (https://localhost:5055)
- 📺 **Emby / Jellyfin / Plex** – Media theater (depending on your choice)
- 🧭 **Arrmematey UI** – Command center (https://localhost:3000 internal / 8080 exposed via compose)

## 🛡️ Security & Privacy Watch
- Mullvad VPN is baked in for all download services.
- Kill-switch and firewall rules enforce that no traffic leaks if VPN disconnects.
- DNS leak protection and hardened iptables keep the crew hidden.
- `vpn-security.sh`, `kill-switch-test.sh`, and `health.sh` give you command-line peace of mind.

## 🧭 Configuration Flow
`quick-install.sh` walks you through the following pirate choices:
1. Mullvad Account ID (required for VPN protection).
2. Media server selection (Jellyfin, Emby, Plex, or none).
3. Quality profile (Standard / Quality / Archive).
4. Optional Cloudflare tunnel setup for remote access.

Once configured, the script generates an `.env`, builds the UI, and launches `docker-compose` to orchestrate everything.

## 🗂️ Repository Layout
```
/home/$USER/
├── Config/            # Service configs (prowlarr, sonarr, etc.)
├── Media/             # Organized TV, movie, and music libraries
├── Downloads/         # In-progress and completed downloads
│   ├── complete/
│   └── incomplete/
├── scripts/           # Helper scripts and automation gear
└── arrmematey/        # This repo housing the UI, compose files, and deployment helpers
```

## 🧭 Service Access Table
| Service | URL | Role |
|---------|-----|------|
| Management UI | http://localhost:8080 | Control center for everything (also proxies to http://localhost:3000 internally) |
| Prowlarr | http://localhost:9696 | Indexer command bridge |
| Sonarr | http://localhost:8989 | TV show automation |
| Radarr | http://localhost:7878 | Movie automation |
| Lidarr | http://localhost:8686 | Music automation |
| SABnzbd | http://localhost:8080 | Usenet downloader |
| qBittorrent | http://localhost:8081 | Torrent downloader |
| Jellyseerr | http://localhost:5055 | Media request desk |
| Emby/Jellyfin/Plex | http://localhost:8096 | Media streaming theater |

## 🏴‍☠️ Script Arsenal
- `quick-install.sh` – Full-stack pirate install with VPN and services.
- `setup.sh` – Alternative step-by-step setup flow.
- `configure.sh` – Re-run service-level configuration.
- `manage.sh` – Start/stop/restart/status helpers for every container.
- `health.sh` – Continuous crew health reporting.
- `profiles.sh` – Quality profile management and Recyclarr wiring.
- `vpn-security.sh` – Security audit for VPN policies.
- `kill-switch-test.sh` – Simulate VPN failure to verify the kill switch.

## 🧭 Operational Best Practices
- Keep the Mullvad ID and port mapping in `.env` so the services restart the same way.
- Update `docker-compose.yml` if you add new services; the UI automatically discovers those port links.
- Use `manage.sh restart` if you tweak environment variables or the UI code—no need to shut down every container manually.

## 🧱 Troubleshooting Commands
```bash
./health.sh check           # Full health report
./health.sh monitor         # Continuous watch
./health.sh report          # Detailed report (logs + metrics)
./vpn-security.sh check     # Ensure VPN rules are intact
./kill-switch-test.sh       # Confirm kill switch closes all traffic
./manage.sh status          # Current container status
./manage.sh logs sonarr     # View Sonarr logs (swap service name as needed)
./manage.sh backup          # Snapshot configs before upgrades
./manage.sh ui              # Open the management UI in your browser
```

## 🧭 Final Notes
- The deployment scripts already handle every step: from spinning up the LXC (via `deploy.sh`/`proxmox-deploy.sh`) to running `quick-install.sh` inside the container.
- Keep an eye on `/tmp/arrmematey-ui.log` (when running locally) for Docker permission warnings—giving the service principal access to `/var/run/docker.sock` or adding it to the `docker` group solves those errors.
- If you want remote dashboards, plug in the Cloudflare tunnel options during the quick install or rely on Proxmox VPN routing.

Happy treasure hunting! 🏴‍☠️🍿
