#!/bin/bash

echo "Installing Enhanced Disk and Memory Monitoring Dashboard..."

# Create dashboards directory if it doesn't exist
mkdir -p /home/dev/2-monitors/grafana/data/dashboards

# Copy the enhanced dashboard to the Grafana dashboards directory
cp /home/dev/2-monitors/enhanced-disk-memory-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/enhanced-disk-memory-dashboard.json

# Also copy to the dashboards folder in the main directory for consistency
cp /home/dev/2-monitors/enhanced-disk-memory-dashboard.json /home/dev/2-monitors/dashboards/enhanced-disk-memory-dashboard.json

# Create a system monitoring folder and copy the dashboard there too
mkdir -p /home/dev/2-monitors/grafana/data/dashboards/system
cp /home/dev/2-monitors/enhanced-disk-memory-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/system/enhanced-disk-memory-dashboard.json

# Update the Grafana provisioning to ensure dashboards are loaded
cat > /home/dev/2-monitors/grafana/dashboards-provisioning.yaml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    folderUid: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
  - name: 'system-monitoring'
    orgId: 1
    folder: 'System Monitoring'
    folderUid: 'system-monitoring'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/system
      foldersFromFilesStructure: false
EOF

# Restart Grafana to pick up the new dashboard
echo "Restarting Grafana to apply changes..."
docker restart grafana

echo "Enhanced dashboard installation complete!"
echo ""
echo "To access the Enhanced Disk and Memory Monitoring Dashboard:"
echo "- Go to Grafana at http://localhost:3091"
echo "- Login with your credentials"
echo "- Look for 'Enhanced Disk and Memory Monitoring Dashboard' in the dashboard list"
echo ""
echo "The enhanced dashboard includes:"
echo "- Physical disks space usage (bar gauge view)"
echo "- Virtual disks (LVM/VG) space usage (bar gauge view)"
echo "- Physical disks capacity and available space"
echo "- Virtual disks capacity and available space"
echo "- Physical disks used space over time"
echo "- Virtual disks used space over time"
echo "- Disk I/O operations and throughput"
echo ""
echo "Physical disks are identified by device names that don't match the LVM pattern (*mapper*)"
echo "Virtual disks (LVM) are identified by device names containing 'mapper'"
EOF