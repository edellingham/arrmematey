// Enhanced Service Configuration with Icons and Mappings
// Add this to your UI service definitions

export const SERVICES_CONFIG = {
  // Media Managers
  radarr: {
    name: 'Radarr',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg',
    port: 7878,
    category: 'media',
    description: 'Movie management',
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
    description: 'Indexer manager'
  },
  
  // Downloaders
  sabnzbd: {
    name: 'SABnzbd',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sabnzbd.svg',
    port: 8080,
    category: 'downloader',
    description: 'Usenet downloader',
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
    description: 'Media request system'
  },
  
  // VPN
  gluetun: {
    name: 'Gluetun VPN',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vpn.svg',
    category: 'network',
    description: 'VPN protection',
    status: 'protected'
  },
  
  // Management UI
  arrstack_ui: {
    name: 'Arrmematey UI',
    icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dashboard.svg',
    port: 8787,
    category: 'management', 
    description: 'Management interface'
  }
};

// Volume Mapping Status Types
export const VOLUME_STATUS = {
  MAPPED: 'mapped',
  WARNING: 'warning', 
  ERROR: 'error',
  MISSING: 'missing'
};

// Category Icons
export const CATEGORY_ICONS = {
  media: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/media.svg',
  indexer: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/indexer.svg',
  downloader: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/downloads.svg',
  server: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/server.svg',
  request: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/request.svg',
  network: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/network.svg',
  management: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dashboard.svg'
};