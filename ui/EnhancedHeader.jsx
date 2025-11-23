// Enhanced Header - Same Design, Add Arrmematey Version + Upgrade
// No layout changes - only adds version display and global upgrade button

import React, { useState } from 'react';
import { ARRMEMATEY_CONFIG } from './enhanced-services-with-versions';

const EnhancedHeader = ({ onGlobalUpgrade, hasUpdates }) => {
  const [isUpgrading, setIsUpgrading] = useState(false);

  const handleGlobalUpgrade = async () => {
    setIsUpgrading(true);
    try {
      await onGlobalUpgrade();
      setTimeout(() => setIsUpgrading(false), 3000);
    } catch (error) {
      console.error('Global upgrade failed:', error);
      setIsUpgrading(false);
    }
  };

  return (
    <header className="bg-gray-900 border-b border-gray-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between py-6">
          {/* EXISTING Logo and Title - NO DESIGN CHANGES */}
          <div className="flex items-center space-x-3">
            {/* Logo - same as existing */}
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xl">🏴</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold text-white">Arrmematey</h1>
              <p className="text-gray-400 text-sm">Media Automation Stack</p>
            </div>
          </div>
          
          {/* NEW: Version Display + Upgrade - ADDITION ONLY */}
          <div className="flex items-center space-x-4">
            {/* Version Display */}
            <div className="flex items-center space-x-2">
              <span className="text-gray-400 text-sm">Version:</span>
              <span className="text-white font-mono text-sm">
                v{ARRMEMATEY_CONFIG.currentVersion}
              </span>
              {hasUpdates && (
                <span className="text-yellow-400 text-xs animate-pulse">
                  🔄 Update
                </span>
              )}
            </div>
            
            {/* Global Upgrade Button */}
            <div className="flex items-center space-x-2">
              <button
                onClick={handleGlobalUpgrade}
                disabled={isUpgrading || !hasUpdates}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors duration-200 flex items-center space-x-2 ${
                  isUpgrading || !hasUpdates
                    ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                    : 'bg-blue-600 hover:bg-blue-700 text-white'
                }`}
                title={hasUpdates ? "Upgrade All Services + Arrmematey" : "Up to Date"}
              >
                {isUpgrading ? (
                  <>
                    <span>⏳</span>
                    <span>Upgrading...</span>
                  </>
                ) : hasUpdates ? (
                  <>
                    <span>🚀</span>
                    <span>Upgrade All</span>
                  </>
                ) : (
                  <>
                    <span>✅</span>
                    <span>Up to Date</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default EnhancedHeader;