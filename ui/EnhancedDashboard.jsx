import React, { useState, useEffect } from 'react';
import { SERVICES_CONFIG, CATEGORY_ICONS } from './enhanced-services';
import EnhancedServiceCard from './EnhancedServiceCard';
import ContainerMappingsDashboard from './ContainerMappingsDashboard';

// Main Enhanced Dashboard Component
const EnhancedArrmemateyDashboard = () => {
  const [services, setServices] = useState({});
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState('dashboard'); // 'dashboard' | 'mappings'
  const [filter, setFilter] = useState('all');

  // Fetch container status from API
  useEffect(() => {
    const fetchContainerStatus = async () => {
      try {
        const response = await fetch('/api/containers/status');
        const containers = await response.json();
        
        // Merge service config with container status
        const servicesWithStatus = Object.entries(SERVICES_CONFIG).reduce((acc, [key, config]) => {
          const containerInfo = containers[key] || {};
          acc[key] = {
            ...config,
            key,
            status: containerInfo.status || 'stopped',
            health: containerInfo.health || 'unknown',
            volumeMappings: config.volumeMappings?.map(mapping => ({
              ...mapping,
              status: mapping.hostPath && containerInfo.volumes?.includes(mapping.containerPath) ? 'mapped' : 'warning'
            })) || []
          };
          return acc;
        }, {});
        
        setServices(servicesWithStatus);
      } catch (error) {
        console.error('Failed to fetch container status:', error);
        // Use defaults if API fails
        setServices(Object.entries(SERVICES_CONFIG).reduce((acc, [key, config]) => {
          acc[key] = { ...config, key, status: 'unknown' };
          return acc;
        }, {}));
      } finally {
        setLoading(false);
      }
    };

    fetchContainerStatus();
    const interval = setInterval(fetchContainerStatus, 30000); // Update every 30s
    return () => clearInterval(interval);
  }, []);

  // Calculate statistics
  const stats = React.useMemo(() => {
    const servicesList = Object.values(services);
    const running = servicesList.filter(s => s.status === 'running').length;
    const totalMappings = servicesList.reduce((acc, s) => acc + (s.volumeMappings?.length || 0), 0);
    const mappedVolumes = servicesList.reduce((acc, s) => 
      acc + (s.volumeMappings?.filter(m => m.status === 'mapped').length || 0), 0
    );
    const unhealthy = servicesList.filter(s => s.status === 'unhealthy').length;

    return { total: servicesList.length, running, totalMappings, mappedVolumes, unhealthy };
  }, [services]);

  // Filter services
  const filteredServices = React.useMemo(() => {
    const servicesList = Object.entries(services);
    if (filter === 'all') return servicesList;
    return servicesList.filter(([key, service]) => service.category === filter);
  }, [services, filter]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-950 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mb-4"></div>
          <p className="text-gray-400">Loading Arrmematey Dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950">
      {/* Header */}
      <header className="bg-gray-900 border-b border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div className="flex items-center space-x-3">
              {/* Logo */}
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-xl">🏴</span>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-white">Arrmematey</h1>
                <p className="text-gray-400 text-sm">Media Automation Stack</p>
              </div>
            </div>
            
            {/* View Toggle */}
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setView('dashboard')}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  view === 'dashboard' 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                }`}
              >
                🎛️ Dashboard
              </button>
              <button
                onClick={() => setView('mappings')}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  view === 'mappings' 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                }`}
              >
                📁 Mappings
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Summary Stats */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">Total Services</p>
                <p className="text-2xl font-bold text-white">{stats.total}</p>
              </div>
              <img src={CATEGORY_ICONS.management} alt="Services" className="w-8 h-8 opacity-50" />
            </div>
          </div>
          
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">Running</p>
                <p className="text-2xl font-bold text-green-400">{stats.running}</p>
              </div>
              <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                <span className="text-white text-sm">●</span>
              </div>
            </div>
          </div>
          
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">Volume Mappings</p>
                <p className="text-2xl font-bold text-white">{stats.totalMappings}</p>
              </div>
              <img src={CATEGORY_ICONS.downloads} alt="Volumes" className="w-8 h-8 opacity-50" />
            </div>
          </div>
          
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">Mapped Volumes</p>
                <p className="text-2xl font-bold text-green-400">{stats.mappedVolumes}</p>
              </div>
              <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                <span className="text-white text-sm">✅</span>
              </div>
            </div>
          </div>
          
          <div className="bg-gray-900 rounded-lg p-4 border border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">Unhealthy</p>
                <p className="text-2xl font-bold text-red-400">{stats.unhealthy}</p>
              </div>
              <div className="w-8 h-8 bg-red-500 rounded-full flex items-center justify-center">
                <span className="text-white text-sm">⚠</span>
              </div>
            </div>
          </div>
        </div>

        {/* Category Filter */}
        <div className="flex items-center space-x-4 mb-6">
          <span className="text-gray-400">Filter:</span>
          <select 
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="bg-gray-900 border border-gray-700 text-white rounded px-3 py-1 text-sm"
          >
            <option value="all">All Services</option>
            <option value="media">Media Managers</option>
            <option value="downloader">Downloaders</option>
            <option value="indexer">Indexer</option>
            <option value="server">Media Server</option>
            <option value="request">Request System</option>
            <option value="network">Network/VPN</option>
          </select>
        </div>

        {/* Content Area */}
        {view === 'dashboard' ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {filteredServices.map(([key, service]) => (
              <EnhancedServiceCard 
                key={key} 
                service={service} 
                containerStatus={service.status}
              />
            ))}
          </div>
        ) : (
          <ContainerMappingsDashboard />
        )}
      </main>
    </div>
  );
};

export default EnhancedArrmemateyDashboard;