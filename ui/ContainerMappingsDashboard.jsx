import React from 'react';
import { SERVICES_CONFIG, VOLUME_STATUS } from './enhanced-services';

// Volume Mapping Component
const VolumeMapping = ({ mapping, index }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case VOLUME_STATUS.MAPPED: return 'text-green-500';
      case VOLUME_STATUS.WARNING: return 'text-yellow-500';
      case VOLUME_STATUS.ERROR: return 'text-red-500';
      default: return 'text-gray-500';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case VOLUME_STATUS.MAPPED: return '✅';
      case VOLUME_STATUS.WARNING: return '⚠️';
      case VOLUME_STATUS.ERROR: return '❌';
      default: return '❓';
    }
  };

  return (
    <div key={index} className="flex items-center justify-between p-2 bg-gray-800 rounded text-sm">
      <div className="flex items-center space-x-2">
        <span className={getStatusColor(mapping.status)}>
          {getStatusIcon(mapping.status)}
        </span>
        <span className="text-gray-300">Container:</span>
        <span className="text-white font-mono">{mapping.containerPath}</span>
      </div>
      <div className="flex items-center space-x-2">
        <span className="text-gray-400">↕️</span>
        <span className="text-gray-300">Host:</span>
        <span className="text-white font-mono text-xs">{mapping.hostPath}</span>
      </div>
    </div>
  );
};

// Service Card Component with Mappings
const ServiceCard = ({ service, key }) => {
  const statusColor = service.status === 'running' ? 'text-green-400' : 'text-red-400';
  const hasMappings = service.volumeMappings && service.volumeMappings.length > 0;

  return (
    <div key={key} className="bg-gray-900 rounded-lg p-4 border border-gray-700 hover:border-gray-600 transition-colors">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-3">
          {/* Service Icon */}
          <img 
            src={service.icon} 
            alt={service.name}
            className="w-8 h-8 rounded"
            onError={(e) => {
              e.target.src = 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/generic.svg';
            }}
          />
          <div>
            <h3 className="text-white font-semibold">{service.name}</h3>
            <p className="text-gray-400 text-sm">{service.description}</p>
          </div>
        </div>
        <div className="text-right">
          <span className={`text-sm ${statusColor}`}>
            {service.status === 'running' ? '● Online' : '● Offline'}
          </span>
          <div className="text-gray-500 text-xs">
            Port: {service.port}
          </div>
        </div>
      </div>

      {/* Volume Mappings Section */}
      {hasMappings && (
        <div className="mt-3 border-t border-gray-700 pt-3">
          <div className="flex items-center space-x-2 mb-2">
            <span className="text-gray-400">📁</span>
            <span className="text-gray-300 text-sm font-semibold">Volume Mappings:</span>
            <span className="text-green-400 text-xs">
              ({service.volumeMappings.filter(m => m.status === VOLUME_STATUS.MAPPED).length}/{service.volumeMappings.length})
            </span>
          </div>
          <div className="space-y-1">
            {service.volumeMappings.map((mapping, index) => (
              <VolumeMapping key={index} mapping={mapping} index={index} />
            ))}
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="mt-3 flex space-x-2">
        <button
          onClick={() => window.open(`http://192.168.6.137:${service.port}`, '_blank')}
          className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded text-sm transition-colors"
        >
          Open Service
        </button>
        {hasMappings && (
          <button
            onClick={() => alert(`Volume mappings for ${service.name}:\n\n${service.volumeMappings.map(m => `${m.hostPath} → ${m.containerPath}`).join('\n')}`)}
            className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-2 rounded text-sm transition-colors"
          >
            📁 Volumes
          </button>
        )}
      </div>
    </div>
  );
};

// Container Mappings Dashboard Component
const ContainerMappingsDashboard = () => {
  // Get services with volume mappings
  const servicesWithMappings = Object.entries(SERVICES_CONFIG)
    .filter(([key, service]) => service.volumeMappings && service.volumeMappings.length > 0)
    .map(([key, service]) => ({
      ...service,
      key,
      status: 'running' // This would come from actual service status API
    }));

  const totalMappings = servicesWithMappings.reduce((acc, service) => 
    acc + (service.volumeMappings?.length || 0), 0
  );
  const mappedVolumes = servicesWithMappings.reduce((acc, service) => 
    acc + (service.volumeMappings?.filter(m => m.status === VOLUME_STATUS.MAPPED)?.length || 0), 0
  );

  return (
    <div className="container mx-auto p-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-white mb-2">Container Volume Mappings</h2>
        <p className="text-gray-400">
          Monitor host ↔ container volume mappings for all Arrmematey services
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <span className="text-gray-400">Total Mappings</span>
            <span className="text-2xl font-bold text-white">{totalMappings}</span>
          </div>
        </div>
        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <span className="text-gray-400">Mapped Volumes</span>
            <span className="text-2xl font-bold text-green-400">{mappedVolumes}</span>
          </div>
        </div>
        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <span className="text-gray-400">Services</span>
            <span className="text-2xl font-bold text-blue-400">{servicesWithMappings.length}</span>
          </div>
        </div>
      </div>

      {/* Services Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {servicesWithMappings.map((service) => (
          <ServiceCard service={service} key={service.key} />
        ))}
      </div>
    </div>
  );
};

export default ContainerMappingsDashboard;