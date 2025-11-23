import React from 'react';
import { SERVICES_CONFIG, CATEGORY_ICONS } from './enhanced-services';

// Enhanced Service Card Component with Icons
const EnhancedServiceCard = ({ service, key, containerStatus }) => {
  const { 
    name, 
    icon, 
    port, 
    category, 
    description,
    volumeMappings,
    healthCheck,
    status
  } = service;

  // Status styling
  const getStatusColor = (status) => {
    switch (status) {
      case 'running': return 'bg-green-500';
      case 'starting': return 'bg-yellow-500';
      case 'stopping': return 'bg-orange-500';
      case 'stopped': return 'bg-red-500';
      case 'unhealthy': return 'bg-red-600';
      default: return 'bg-gray-500';
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'running': return '● Online';
      case 'starting': return '● Starting';
      case 'stopping': return '● Stopping';
      case 'stopped': return '● Offline';
      case 'unhealthy': return '⚠️ Unhealthy';
      default: return '● Unknown';
    }
  };

  // Category styling
  const getCategoryColor = (category) => {
    switch (category) {
      case 'media': return 'text-blue-400';
      case 'indexer': return 'text-purple-400';
      case 'downloader': return 'text-green-400';
      case 'server': return 'text-orange-400';
      case 'request': return 'text-pink-400';
      case 'network': return 'text-cyan-400';
      case 'management': return 'text-gray-400';
      default: return 'text-gray-400';
    }
  };

  const hasMappings = volumeMappings && volumeMappings.length > 0;
  const mappedVolumes = hasMappings ? volumeMappings.filter(m => m.status === 'mapped').length : 0;
  const totalMappings = hasMappings ? volumeMappings.length : 0;

  return (
    <div className="bg-gray-900 rounded-lg p-5 border border-gray-700 hover:border-gray-600 transition-all duration-200 shadow-lg">
      {/* Service Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          {/* Service Icon with fallback */}
          <div className="relative">
            <img 
              src={icon} 
              alt={name}
              className="w-10 h-10 rounded-lg bg-gray-800 p-1"
              onError={(e) => {
                // Fallback to category icon
                e.target.src = CATEGORY_ICONS[category] || 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/generic.svg';
                e.target.className = 'w-10 h-10 rounded-lg bg-gray-800 p-2 opacity-75';
              }}
              loading="lazy"
            />
            {/* Status Indicator */}
            <div className={`absolute -top-1 -right-1 w-3 h-3 rounded-full ${getStatusColor(status)}`} />
          </div>
          <div>
            <h3 className="text-white font-semibold text-lg">{name}</h3>
            <div className="flex items-center space-x-2">
              <span className={`text-xs ${getCategoryColor(category)}`}>
                {category.toUpperCase()}
              </span>
              <span className="text-gray-500 text-xs">
                Port: {port}
              </span>
            </div>
          </div>
        </div>
        <div className="text-right">
          <div className={`text-sm font-medium ${status === 'running' ? 'text-green-400' : 'text-red-400'}`}>
            {getStatusText(status)}
          </div>
          {healthCheck && (
            <div className="text-xs text-gray-500 mt-1">
              Health: {healthCheck.status === 'pass' ? '✅' : '❌'}
            </div>
          )}
        </div>
      </div>

      {/* Description */}
      <p className="text-gray-400 text-sm mb-4">{description}</p>

      {/* Volume Mappings */}
      {hasMappings && (
        <div className="mb-4 p-3 bg-gray-800 rounded border border-gray-600">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <span className="text-gray-400">📁</span>
              <span className="text-gray-300 text-sm font-medium">Volume Mappings</span>
              <span className={`text-xs ${mappedVolumes === totalMappings ? 'text-green-400' : 'text-yellow-400'}`}>
                ({mappedVolumes}/{totalMappings})
              </span>
            </div>
          </div>
          <div className="space-y-1">
            {volumeMappings.map((mapping, index) => (
              <div key={index} className="flex items-center justify-between text-xs">
                <div className="flex items-center space-x-2">
                  <span className={`inline-block w-2 h-2 rounded-full ${
                    mapping.status === 'mapped' ? 'bg-green-400' : 
                    mapping.status === 'warning' ? 'bg-yellow-400' : 
                    'bg-red-400'
                  }`} />
                  <span className="text-gray-300">
                    Container: <span className="text-white font-mono">{mapping.containerPath}</span>
                  </span>
                </div>
                <div className="flex items-center space-x-1">
                  <span className="text-gray-500">↕️</span>
                  <span className="text-gray-300">
                    Host: <span className="text-white font-mono text-xs">{mapping.hostPath}</span>
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex space-x-2">
        <button
          onClick={() => window.open(`http://192.168.6.137:${port}`, '_blank')}
          className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm font-medium transition-colors duration-200 flex items-center justify-center space-x-2"
        >
          <span>🔗</span>
          <span>Open Service</span>
        </button>
        
        {hasMappings && (
          <button
            onClick={() => {
              const mappingsText = volumeMappings
                .map(m => `${m.hostPath} → ${m.containerPath} (${m.status})`)
                .join('\n');
              alert(`${name} Volume Mappings:\n\n${mappingsText}`);
            }}
            className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-2 rounded text-sm font-medium transition-colors duration-200"
            title="View Volume Mappings"
          >
            📁
          </button>
        )}
        
        <button
          onClick={() => {
            const info = `
${name}
Status: ${getStatusText(status)}
Category: ${category}
Port: ${port}
Description: ${description}
${hasMappings ? `\nVolume Mappings:\n${volumeMappings.map(m => `  ${m.hostPath} → ${m.containerPath} (${m.status})`).join('\n')}` : ''}`;
            alert(info);
          }}
          className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-2 rounded text-sm font-medium transition-colors duration-200"
          title="Service Information"
        >
          ℹ️
        </button>
      </div>
    </div>
  );
};

export default EnhancedServiceCard;