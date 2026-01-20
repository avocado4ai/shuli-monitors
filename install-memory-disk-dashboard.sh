#!/bin/bash

echo "Installing Memory and Disk Monitoring Dashboard..."

# Create dashboards directory if it doesn't exist
mkdir -p /home/dev/2-monitors/grafana/data/dashboards

# Copy the dashboard to the Grafana dashboards directory
cp /home/dev/2-monitors/memory-disk-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/memory-disk-dashboard.json

# Also copy to the dashboards folder in the main directory for consistency
cp /home/dev/2-monitors/memory-disk-dashboard.json /home/dev/2-monitors/dashboards/memory-disk-dashboard.json

# Update the Grafana provisioning to include this dashboard
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

# Create the system dashboards directory
mkdir -p /home/dev/2-monitors/grafana/data/dashboards/system

# Copy the dashboard to the system monitoring folder as well
cp /home/dev/2-monitors/memory-disk-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/system/memory-disk-dashboard.json

# Restart Grafana to pick up the new dashboard
echo "Restarting Grafana to apply changes..."
docker restart grafana

echo "Dashboard installation complete!"
echo ""
echo "To access the Memory and Disk Monitoring Dashboard:"
echo "- Go to Grafana at http://localhost:3091"
echo "- Login with your credentials"
echo "- Look for 'Memory and Disk Monitoring Dashboard' in the dashboard list"
echo ""
echo "The dashboard includes:"
echo "- System memory overview (total, used, available)"
echo "- Memory usage percentage gauge"
echo "- Memory usage trends over time"
echo "- Filesystem usage for all mount points"
echo "- Disk I/O operations and throughput"
echo "- Top containers by memory usage"
EOF