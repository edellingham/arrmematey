// Enhanced Service Configuration with Version Support
// Design preserved - only adding version and upgrade fields

export const SERVICES_CONFIG = {
  // Media Managers
  radarr: {
    name: 'Radarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg',
    port: 7878,
    category: 'media',
    description: 'Movie management',
    currentVersion: '5.3.6.8587',
    latestVersion: '5.3.6.8587',
    needsUpdate: false,
    containerName: 'radarr',
    volumeMappings: [
      {
        hostPath: '/root/Media/Movies',
        containerPath: '/movies',
        status: 'mapped'
      }
    ]
  },
  
  sonarr: {
    name: 'Sonarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg',
    port: 8989,
    category: 'media',
    description: 'TV show management',
    currentVersion: '4.0.2.2315',
    latestVersion: '4.0.2.2315',
    needsUpdate: false,
    containerName: 'sonarr',
    volumeMappings: [
      {
        hostPath: '/root/Media/TV',
        containerPath: '/tv',
        status: 'mapped'
      }
    ]
  },
  
  lidarr: {
    name: 'Lidarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/lidarr.svg',
    port: 8686,
    category: 'media',
    description: 'Music management',
    currentVersion: '2.4.3.8568',
    latestVersion: '2.4.3.8568',
    needsUpdate: false,
    containerName: 'lidarr',
    volumeMappings: [
      {
        hostPath: '/root/Media/Music',
        containerPath: '/music',
        status: 'mapped'
      }
    ]
  },
  
  // Indexer
  prowlarr: {
    name: 'Prowlarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg',
    port: 9696,
    category: 'indexer',
    description: 'Indexer manager',
    currentVersion: '1.8.0.3821',
    latestVersion: '1.8.0.3821',
    needsUpdate: false,
    containerName: 'prowlarr'
  },
  
  // Downloaders
  sabnzbd: {
    name: 'SABnzbd',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sabnzbd.svg',
    port: 8080,
    category: 'downloader',
    description: 'Usenet downloader',
    currentVersion: '4.3.3',
    latestVersion: '4.3.3',
    needsUpdate: false,
    containerName: 'sabnzbd',
    volumeMappings: [
      {
        hostPath: '/root/Downloads/usenet',
        containerPath: '/downloads',
        status: 'mapped'
      }
    ]
  },
  
  qbittorrent: {
    name: 'qBittorrent',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg',
    port: 8081,
    category: 'downloader',
    description: 'Torrent downloader',
    currentVersion: '4.6.5',
    latestVersion: '4.6.5',
    needsUpdate: false,
    containerName: 'qbittorrent',
    volumeMappings: [
      {
        hostPath: '/root/Downloads/torrents',
        containerPath: '/downloads',
        status: 'mapped'
      }
    ]
  },
  
  // Media Server
  emby: {
    name: 'Emby',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/emby.svg',
    port: 8096,
    category: 'server',
    description: 'Media server',
    currentVersion: '4.8.0.40',
    latestVersion: '4.8.0.40',
    needsUpdate: false,
    containerName: 'emby',
    volumeMappings: [
      {
        hostPath: '/root/Media/Movies',
        containerPath: '/data/movies',
        status: 'mapped'
      },
      {
        hostPath: '/root/Media/TV',
        containerPath: '/data/tvshows',
        status: 'mapped'
      },
      {
        hostPath: '/root/Media/Music',
        containerPath: '/data/music',
        status: 'mapped'
      }
    ]
  },
  
  // Request System
  jellyseerr: {
    name: 'Jellyseerr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyseerr.svg',
    port: 5055,
    category: 'request',
    description: 'Media request system',
    currentVersion: '1.8.5',
    latestVersion: '1.8.5',
    needsUpdate: false,
    containerName: 'jellyseerr'
  },
  
  // VPN
  gluetun: {
    name: 'Gluetun VPN',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vpn.svg',
    port: 8000,
    category: 'network',
    description: 'VPN protection',
    currentVersion: 'latest',
    latestVersion: 'latest',
    needsUpdate: false,
    containerName: 'gluetun',
    status: 'protected'
  },
  
  // Management UI
  arrstack_ui: {
    name: 'Arrmematey UI',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dashboard.svg',
    port: 8787,
    category: 'management',
    description: 'Management interface',
    currentVersion: '2.20.10',
    latestVersion: '2.20.10',
    needsUpdate: false,
    containerName: 'arrstack-ui'
  },

  // Additional Containers
  recyclarr: {
    name: 'Recyclarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/recyclarr.svg',
    port: 8789,
    category: 'utility',
    description: 'Download cleanup',
    currentVersion: '5.0',
    latestVersion: '5.0',
    needsUpdate: false,
    containerName: 'recyclarr'
  },

  flaresolverr: {
    name: 'FlareSolverr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/flaresolverr.svg',
    port: 8191,
    category: 'utility',
    description: 'Cloudflare bypass',
    currentVersion: '3.3.21',
    latestVersion: '3.3.21',
    needsUpdate: false,
    containerName: 'flaresolverr'
  }
};

// Arrmematey Version
export const ARRMEMATEY_CONFIG = {
  version: '2.20.10',
  latestVersion: '2.20.10',
  needsUpdate: false,
  containerName: 'arrmematey'
};

// Version Status Types
export const VERSION_STATUS = {
  UP_TO_DATE: 'up_to_date',
  UPDATE_AVAILABLE: 'update_available',
  CRITICAL_UPDATE: 'critical_update',
  CHECKING: 'checking',
  ERROR: 'error'
};

// Upgrade Actions
export const UPGRADE_ACTIONS = {
  PULL_IMAGE: 'pull_image',
  REBUILD_CONTAINER: 'rebuild_container',
  RESTART_SERVICE: 'restart_service',
  FULL_UPGRADE: 'full_upgrade'
};

// Category Icons
export const CATEGORY_ICONS = {
  media: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/media.svg',
  indexer: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/indexer.svg',
  downloader: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/downloads.svg',
  server: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/server.svg',
  request: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/request.svg',
  network: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/network.svg',
  management: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dashboard.svg',
  utility: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/utility.svg'
};