// Enhanced Service Card - Same Design, Add Version + Upgrade Features
// No layout changes - only adds version display and upgrade button

import React, { useState } from 'react';
import { SERVICES_CONFIG, VERSION_STATUS, UPGRADE_ACTIONS } from './enhanced-services-with-versions';

// Service Card Component (design preserved, new features added)
const EnhancedServiceCardWithVersion = ({ service, onUpgrade }) => {
  const [isUpgrading, setIsUpgrading] = useState(false);
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);

  const { 
    name, 
    icon, 
    port, 
    category, 
    description,
    volumeMappings,
    healthCheck,
    status,
    currentVersion,
    latestVersion,
    needsUpdate,
    containerName
  } = service;

  // Status styling (preserved from existing design)
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

  // Version status styling (addition, no design changes)
  const getVersionColor = (needsUpdate) => {
    return needsUpdate ? 'text-yellow-400' : 'text-green-400';
  };

  const handleUpgrade = async () => {
    setIsUpgrading(true);
    try {
      await onUpgrade(containerName, UPGRADE_ACTIONS.PULL_IMAGE);
      setTimeout(() => setIsUpgrading(false), 2000);
    } catch (error) {
      console.error('Upgrade failed:', error);
      setIsUpgrading(false);
    }
  };

  const hasMappings = volumeMappings && volumeMappings.length > 0;

  // EXACT same card design with added version row
  return (
    <div className="bg-gray-900 rounded-lg p-5 border border-gray-700 hover:border-gray-600 transition-all duration-200 shadow-lg">
      {/* Existing Service Header - NO DESIGN CHANGES */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          {/* Service Icon - same as existing */}
          <div className="relative">
            <img 
              src={icon} 
              alt={name}
              className="w-10 h-10 rounded-lg bg-gray-800 p-1"
              onError={(e) => {
                e.target.src = 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/generic.svg';
                e.target.className = 'w-10 h-10 rounded-lg bg-gray-800 p-2 opacity-75';
              }}
              loading="lazy"
            />
            {/* Status Indicator - same as existing */}
            <div className={`absolute -top-1 -right-1 w-3 h-3 rounded-full ${getStatusColor(status)}`} />
          </div>
          <div>
            <h3 className="text-white font-semibold text-lg">{name}</h3>
            <div className="flex items-center space-x-2">
              <span className="text-blue-400 text-xs uppercase">{category}</span>
              <span className="text-gray-500 text-xs">Port: {port}</span>
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

      {/* Description - same as existing */}
      <p className="text-gray-400 text-sm mb-4">{description}</p>

      {/* NEW: Version Row - ADDITION ONLY */}
      <div className="flex items-center justify-between p-2 bg-gray-800 rounded text-sm mb-3">
        <div className="flex items-center space-x-3">
          <span className="text-gray-400">Version:</span>
          <span className={`font-mono ${getVersionColor(needsUpdate)}`}>
            v{currentVersion}
          </span>
          {needsUpdate && (
            <span className="text-yellow-400 text-xs">
              → v{latestVersion}
            </span>
          )}
        </div>
        <div className="flex items-center space-x-2">
          {needsUpdate && !isUpgrading && (
            <button
              onClick={() => setShowUpgradeModal(true)}
              className="text-blue-400 hover:text-blue-300 text-xs font-medium"
              title="Upgrade available"
            >
              🔄 Upgrade
            </button>
          )}
          {isUpgrading && (
            <div className="text-yellow-400 text-xs">
              ⏳ Upgrading...
            </div>
          )}
        </div>
      </div>

      {/* Volume Mappings - same as existing */}
      {hasMappings && (
        <div className="mb-4 p-3 bg-gray-800 rounded border border-gray-600">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <span className="text-gray-400">📁</span>
              <span className="text-gray-300 text-sm font-medium">Volume Mappings</span>
              <span className="text-green-400 text-xs">
                ({service.volumeMappings.filter(m => m.status === 'mapped').length}/{service.volumeMappings.length})
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

      {/* Existing Action Buttons - SAME DESIGN */}
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
            onClick={() => alert(`Volume mappings for ${name}:\n\n${volumeMappings.map(m => `${m.hostPath} → ${m.containerPath}`).join('\n')}`)}
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
Current Version: v${currentVersion}
${needsUpdate ? `Latest Version: v${latestVersion} (UPDATE AVAILABLE)` : 'Up to date'}
Description: ${description}
${hasMappings ? `\nVolume Mappings:\n${volumeMappings.map(m => `  ${m.hostPath} → ${m.containerPath}`).join('\n')}` : ''}`;
            alert(info);
          }}
          className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-2 rounded text-sm font-medium transition-colors duration-200"
          title="Service Information"
        >
          ℹ️
        </button>
      </div>

      {/* NEW: Upgrade Modal - OVERLAY, NO DESIGN CHANGES */}
      {showUpgradeModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-gray-900 rounded-lg p-6 border border-gray-700 max-w-md w-full">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-white text-lg font-semibold">Upgrade {name}</h3>
              <button
                onClick={() => setShowUpgradeModal(false)}
                className="text-gray-400 hover:text-white text-xl"
              >
                ×
              </button>
            </div>
            
            <div className="space-y-3 mb-6">
              <div className="flex justify-between">
                <span className="text-gray-400">Current:</span>
                <span className="text-white font-mono">v{currentVersion}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Latest:</span>
                <span className="text-green-400 font-mono">v{latestVersion}</span>
              </div>
            </div>
            
            <div className="flex space-x-3">
              <button
                onClick={() => setShowUpgradeModal(false)}
                className="flex-1 bg-gray-700 hover:bg-gray-600 text-white px-4 py-2 rounded text-sm font-medium"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  handleUpgrade();
                  setShowUpgradeModal(false);
                }}
                className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm font-medium"
              >
                Upgrade Now
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EnhancedServiceCardWithVersion;