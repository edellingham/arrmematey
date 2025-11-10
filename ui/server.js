const express = require('express');
const Docker = require('dockerode');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const docker = new Docker();

const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Arrmematey service configuration
const getServiceConfig = () => {
  return {
    prowlarr: { port: process.env.PROWLARR_PORT || 9696, name: 'Prowlarr', icon: '🔍' },
    sonarr: { port: process.env.SONARR_PORT || 8989, name: 'Sonarr', icon: '🎬' },
    radarr: { port: process.env.RADARR_PORT || 7878, name: 'Radarr', icon: '🎥' },
    lidarr: { port: process.env.LIDARR_PORT || 8686, name: 'Lidarr', icon: '🎵' },
    sabnzbd: { port: process.env.SABNZBD_PORT || 8080, name: 'SABnzbd', icon: '📥' },
    qbittorrent: { port: process.env.QBITTORRENT_PORT || 8081, name: 'qBittorrent', icon: '⬇️' },
    jellyseerr: { port: process.env.JELLYSEERR_PORT || 5055, name: 'Jellyseerr', icon: '🍿' }
  };
};

// API Routes
app.get('/api/services', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const services = [];
    const config = getServiceConfig();
    
    for (const [key, service] of Object.entries(config)) {
      const container = containers.find(c => c.Names.includes(`/${key}`));
      services.push({
        id: key,
        name: service.name,
        icon: service.icon,
        port: service.port,
        url: `http://localhost:${service.port}`,
        status: container ? container.State : 'not_found',
        health: container ? container.Status : 'Container not found'
      });
    }
    
    res.json(services);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/service/:id/:action', async (req, res) => {
  try {
    const { id, action } = req.params;
    const container = docker.getContainer(id);
    
    if (action === 'start') {
      await container.start();
    } else if (action === 'stop') {
      await container.stop();
    } else if (action === 'restart') {
      await container.restart();
    } else {
      return res.status(400).json({ error: 'Invalid action' });
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/service/:id/logs', async (req, res) => {
  try {
    const { id } = req.params;
    const container = docker.getContainer(id);
    const logs = await container.logs({
      stdout: true,
      stderr: true,
      timestamps: true,
      tail: 100
    });
    
    res.json({ logs: logs.toString() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/system/info', async (req, res) => {
  try {
    const info = await docker.info();
    const containers = await docker.listContainers({ all: true });
    const images = await docker.listImages();
    
    res.json({
      docker: {
        version: info.ServerVersion,
        containers: containers.length,
        running: containers.filter(c => c.State === 'running').length,
        images: images.length
      },
      services: containers.filter(c => c.Names.some(name => 
        Object.keys(getServiceConfig()).some(service => name.includes(service))
      ))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Socket.io for real-time updates
setInterval(async () => {
  try {
    const containers = await docker.listContainers({ all: true });
    io.emit('containerUpdate', containers);
  } catch (error) {
    console.error('Error fetching container status:', error);
  }
}, 5000);

// Serve main HTML
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

server.listen(PORT, () => {
  console.log(`🏴‍☠️ Arrmematey Management UI running on port ${PORT}`);
  console.log(`Your pirate crew is ready to set sail!`);
});