// Upgrade API Integration - Backend for Version Checking + Upgrades
// No UI changes - provides upgrade functionality

import React, { useState, useEffect } from 'react';

const UpgradeAPI = () => {
  const [upgradeStatus, setUpgradeStatus] = useState({});
  const [isUpgradingGlobal, setIsUpgradingGlobal] = useState(false);

  // Check for updates on component mount
  useEffect(() => {
    checkForUpdates();
    const interval = setInterval(checkForUpdates, 60000); // Check every minute
    return () => clearInterval(interval);
  }, []);

  // Check for service updates
  const checkForUpdates = async () => {
    try {
      const response = await fetch('/api/services/versions');
      const data = await response.json();
      setUpgradeStatus(data);
    } catch (error) {
      console.error('Failed to check versions:', error);
    }
  };

  // Upgrade individual service
  const upgradeService = async (containerName, action = 'pull_image') => {
    try {
      // Update status to upgrading
      setUpgradeStatus(prev => ({
        ...prev,
        [containerName]: { ...prev[containerName], isUpgrading: true }
      }));

      // Call upgrade API
      const response = await fetch('/api/services/upgrade', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          containerName, 
          action 
        })
      });

      const result = await response.json();

      if (result.success) {
        // Update service info
        setTimeout(() => {
          checkForUpdates();
        }, 3000);
      } else {
        throw new Error(result.error || 'Upgrade failed');
      }
    } catch (error) {
      console.error('Service upgrade failed:', error);
      // Reset upgrade status
      setUpgradeStatus(prev => ({
        ...prev,
        [containerName]: { ...prev[containerName], isUpgrading: false }
      }));
      alert(`Failed to upgrade ${containerName}: ${error.message}`);
    }
  };

  // Global upgrade (Arrmematey + all services)
  const globalUpgrade = async () => {
    try {
      setIsUpgradingGlobal(true);

      // Step 1: Pull latest Arrmematey code
      const response = await fetch('/api/arrmematey/upgrade', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'full_upgrade' })
      });

      const result = await response.json();

      if (result.success) {
        // Step 2: Upgrade all services
        await Promise.all(Object.keys(SERVICES_CONFIG).map(async (serviceKey) => {
          try {
            await upgradeService(serviceKey, 'pull_image');
          } catch (error) {
            console.warn(`Failed to upgrade ${serviceKey}:`, error);
          }
        }));

        // Step 3: Restart services
        await fetch('/api/services/restart', { method: 'POST' });

        // Step 4: Verify upgrade
        setTimeout(() => {
          checkForUpdates();
          setIsUpgradingGlobal(false);
        }, 5000);
      } else {
        throw new Error(result.error || 'Global upgrade failed');
      }
    } catch (error) {
      console.error('Global upgrade failed:', error);
      setIsUpgradingGlobal(false);
      alert(`Global upgrade failed: ${error.message}`);
    }
  };

  // Check if any service needs update
  const hasServiceUpdates = Object.values(upgradeStatus).some(
    service => service.needsUpdate && !service.isUpgrading
  );

  // Check if Arrmematey needs update
  const arrmemateyNeedsUpdate = upgradeStatus.arrmematey?.needsUpdate;

  // Overall has updates
  const hasAnyUpdates = hasServiceUpdates || arrmemateyNeedsUpdate;

  return {
    upgradeStatus,
    hasAnyUpdates,
    hasServiceUpdates,
    arrmemateyNeedsUpdate,
    isUpgradingGlobal,
    checkForUpdates,
    upgradeService,
    globalUpgrade
  };
};

export default UpgradeAPI;