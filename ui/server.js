const express = require('express');
const Docker = require('dockerode');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

dotenv.config();

// Fanart.tv API configuration
const FANART_API_KEY = process.env.FANART_API_KEY || '809f4d10e36810f6f0a15445d11ec78d';
const FANART_BASE_URL = 'https://webservice.fanart.tv/v3';

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const docker = new Docker();

const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));
app.use('/images', express.static('../images'));

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

// Fanart.tv API routes for movie backdrops
app.get('/api/fanart/backdrop', async (req, res) => {
  try {
    if (!FANART_API_KEY) {
      return res.status(500).json({ error: 'Fanart.tv API key not configured' });
    }

    // User's complete movie list with correct TMDB IDs
    const movieIds = [
      { id: 620, title: 'Ghostbusters' },
      { id: 10428, title: 'Hackers' },
      { id: 105, title: 'Back to the Future' },
      { id: 1648, title: 'Bill & Ted\'s Excellent Adventure' },
      { id: 85, title: 'Raiders of the Lost Ark' },
      { id: 8872, title: 'Wayne\'s World' },
      { id: 11381, title: 'Tommy Boy' },
      { id: 11827, title: 'Heavy Metal' },
      { id: 6978, title: 'Big Trouble in Little China' },
      { id: 377, title: 'A Nightmare on Elm Street' },
      { id: 1642, title: 'The Net' },
      { id: 15239, title: 'The Toxic Avenger' },
      { id: 1498, title: 'Teenage Mutant Ninja Turtles' },
      { id: 9015, title: 'Beverly Hills Cop' },
      { id: 11649, title: 'Masters of the Universe' },
      { id: 15301, title: 'Twilight Zone: The Movie' },
      { id: 9872, title: 'Explorers' },
      { id: 13841, title: 'Rad' },
      { id: 2617, title: 'The Great Outdoors' },
      { id: 10136, title: 'The Golden Child' },
      { id: 957, title: 'Spaceballs' },
      { id: 2616, title: 'Uncle Buck' },
      { id: 13997, title: 'Black Sheep' },
      { id: 9749, title: 'Fletch' },
      { id: 11153, title: 'National Lampoon\'s Vacation' },
      { id: 562, title: 'Die Hard' },
      { id: 10999, title: 'Commando' },
      { id: 927, title: 'Gremlins' },
      { id: 11977, title: 'Caddyshack' },
      { id: 525, title: 'The Blues Brothers' },
      { id: 1621, title: 'Trading Places' },
      { id: 150, title: '48 Hrs' },
      { id: 9397, title: 'Evolution' },
      { id: 11974, title: 'The Burbs' },
      { id: 13, title: 'Forrest Gump' },
      { id: 20678, title: 'Blankman' },
      { id: 29444, title: 'SFW' },
      { id: 137, title: 'Groundhog Day' },
      { id: 19908, title: 'Zombieland' },
      { id: 764, title: 'The Evil Dead' },
      { id: 25969, title: 'Angus' }
    ];

    // Pick a random movie
    const randomMovie = movieIds[Math.floor(Math.random() * movieIds.length)];
    console.log(`Fetching Fanart.tv for movie: ${randomMovie.title} (ID: ${randomMovie.id})`);

    // Fetch fanart for this movie
    const response = await fetch(`${FANART_BASE_URL}/movies/${randomMovie.id}?api_key=${FANART_API_KEY}`);
    
    if (!response.ok) {
      console.log(`Fanart.tv API error: ${response.status} for movie ${randomMovie.id}`);
      throw new Error(`Fanart.tv API error: ${response.status}`);
    }

    const data = await response.json();
    console.log(`Fanart.tv response for ${randomMovie.title}:`, JSON.stringify(data, null, 2));
    
    // Check if we got valid data
    if (!data || Object.keys(data).length === 0) {
      console.log(`No fanart data for movie ${randomMovie.title}`);
      return res.json({ backdropUrl: null, title: null, overview: null });
    }

    // Check for movie backgrounds/backdrops (try different types)
    let backdropUrl = null;
    
    if (data.moviethumb && data.moviethumb.length > 0) {
      backdropUrl = data.moviethumb[Math.floor(Math.random() * data.moviethumb.length)].url;
    } else if (data.moviebackground && data.moviebackground.length > 0) {
      backdropUrl = data.moviebackground[Math.floor(Math.random() * data.moviebackground.length)].url;
    } else if (data.movieposter && data.movieposter.length > 0) {
      backdropUrl = data.movieposter[Math.floor(Math.random() * data.movieposter.length)].url;
    }
    
    if (backdropUrl) {
      console.log(`Found backdrop for ${randomMovie.title}`);
      return res.json({
        backdropUrl: backdropUrl,
        title: randomMovie.title,
        overview: 'Movie backdrop from Fanart.tv'
      });
    } else {
      console.log(`No usable backdrops for ${randomMovie.title}`);
      return res.json({ backdropUrl: null, title: null, overview: null });
    }
  } catch (error) {
    console.error('Error fetching Fanart.tv backdrop:', error);
    res.json({ backdropUrl: null, title: null, overview: null });
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
  console.log(`Captain's crew be ready to set sail!`);
});