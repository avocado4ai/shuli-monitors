#!/bin/bash

echo "Installing Alerts-Enabled Disk and Memory Monitoring Dashboard..."

# Create dashboards directory if it doesn't exist
mkdir -p /home/dev/2-monitors/grafana/data/dashboards

# Copy the alerts-enabled dashboard to the Grafana dashboards directory
cp /home/dev/2-monitors/alerts-enabled-disk-memory-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/alerts-enabled-disk-memory-dashboard.json

# Also copy to the dashboards folder in the main directory for consistency
cp /home/dev/2-monitors/alerts-enabled-disk-memory-dashboard.json /home/dev/2-monitors/dashboards/alerts-enabled-disk-memory-dashboard.json

# Create a system monitoring folder and copy the dashboard there too
mkdir -p /home/dev/2-monitors/grafana/data/dashboards/system
cp /home/dev/2-monitors/alerts-enabled-disk-memory-dashboard.json /home/dev/2-monitors/grafana/data/dashboards/system/alerts-enabled-disk-memory-dashboard.json

# Create alert rules configuration directory
mkdir -p /home/dev/2-monitors/grafana/data/provisioning/alerting

# Create alert rules file for memory and disk monitoring
cat > /home/dev/2-monitors/grafana/data/provisioning/alerting/memory-disk-alerts.yaml << 'EOF'
apiVersion: 1

groups:
  - name: memory_and_disk_alerts
    rules:
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% for more than 2 minutes on {{ $labels.instance }}"
      
      - alert: LowAvailableMemory
        expr: node_memory_MemAvailable_bytes / 1024 / 1024 / 1024 < 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Low available memory"
          description: "Available memory is below 5GB on {{ $labels.instance }}"
          
      - alert: HighPhysicalDiskUsage
        expr: (node_filesystem_size_bytes{device!~'tmpfs|rootfs|selinuxfs|autofs|rpc_pipefs|rpc_pipefs|none|devpts|sysfs|debugfs|lo'} - node_filesystem_avail_bytes{device!~'tmpfs|rootfs|selinuxfs|autofs|rpc_pipefs|rpc_pipefs|none|devpts|sysfs|debugfs|lo'}) / node_filesystem_size_bytes{device!~'tmpfs|rootfs|selinuxfs|autofs|rpc_pipefs|rpc_pipefs|none|devpts|sysfs|debugfs|lo'} * 100 > 85
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High physical disk usage"
          description: "Physical disk usage is above 85% on device {{ $labels.device }} mounted at {{ $labels.mountpoint }}"
          
      - alert: HighVirtualDiskUsage
        expr: (node_filesystem_size_bytes{device=~'.*mapper.*'} - node_filesystem_avail_bytes{device=~'.*mapper.*'}) / node_filesystem_size_bytes{device=~'.*mapper.*'} * 100 > 85
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High virtual disk usage"
          description: "Virtual disk (LVM) usage is above 85% on device {{ $labels.device }} mounted at {{ $labels.mountpoint }}"
          
      - alert: LowPhysicalDiskSpace
        expr: node_filesystem_avail_bytes{device!~'tmpfs|rootfs|selinuxfs|autofs|rpc_pipefs|rpc_pipefs|none|devpts|sysfs|debugfs|lo'} / 1024 / 1024 / 1024 < 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Low physical disk space"
          description: "Less than 5GB available on physical disk {{ $labels.device }} mounted at {{ $labels.mountpoint }}"
          
      - alert: LowVirtualDiskSpace
        expr: node_filesystem_avail_bytes{device=~'.*mapper.*'} / 1024 / 1024 / 1024 < 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Low virtual disk space"
          description: "Less than 5GB available on virtual disk (LVM) {{ $labels.device }} mounted at {{ $labels.mountpoint }}"
EOF

# Update the Grafana alerting provisioning configuration
cat > /home/dev/2-monitors/grafana/data/provisioning/alerting/alerting.yaml << 'EOF'
apiVersion: 1
groups:
  - orgId: 1
    name: memory_and_disk_alerts
    folder: 'System Monitoring'
    interval: 10s
    rules:
      - uid: high_memory_usage_rule
        title: High Memory Usage
        condition: A
        data:
          - refId: A
            relativeTimeRange:
              from: 300
              to: 0
            datasourceUid: prometheus
            model:
              expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
              instant: true
              intervalMs: 1000
              maxDataPoints: 43200
              refId: A
        noDataState: NoData
        execErrState: Error
        for: 2m
        annotations:
          __dashboardUid__: alerts-enabled-disk-memory-monitoring
          __panelId__: 4
          summary: Memory usage is above 85%
        labels:
          severity: critical
EOF

# Update the Grafana provisioning to ensure dashboards and alerts are loaded
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

# Create/update Grafana alerting provisioning directory configuration
mkdir -p /home/dev/2-monitors/grafana/data/provisioning
cat > /home/dev/2-monitors/grafana/data/provisioning/alerting.yaml << 'EOF'
apiVersion: 1

# Alerting configuration
# This enables the alerting engine
alertmanager:
  enabled: true
  provisioning:
    rules:
      - name: 'default'
        interval: 30s
        files:
          - '/etc/grafana/provisioning/alerting/memory-disk-alerts.yaml'
    contactpoints:
      - org_id: 1
        name: default-email
        email_configs:
          - to: 'admin@example.com'
            send_resolved: true
EOF

# Restart Grafana to apply all changes
echo "Restarting Grafana to apply dashboard and alerting changes..."
docker restart grafana

echo "Alerts-enabled dashboard installation complete!"
echo ""
echo "To access the Alerts-Enabled Disk and Memory Monitoring Dashboard:"
echo "- Go to Grafana at http://localhost:3091"
echo "- Login with your credentials"
echo "- Look for 'Alerts-Enabled Disk and Memory Monitoring Dashboard' in the dashboard list"
echo ""
echo "The dashboard includes all previous features plus:"
echo "- Memory usage alerts (critical at >85%)"
echo "- Available memory alerts (critical when <5GB)"
echo "- Physical disk usage alerts (critical at >85%)"
echo "- Virtual disk usage alerts (critical at >85%)"
echo "- Physical disk space alerts (critical when <5GB available)"
echo "- Virtual disk space alerts (critical when <5GB available)"
echo ""
echo "Alerts are configured with:"
echo "- 2-minute evaluation period before triggering"
echo "- Critical severity level"
echo "- Descriptive alert messages"
echo ""
echo "To view and manage alerts:"
echo "- Go to 'Alerting' in the left sidebar"
echo "- Select 'Alert rules' to see configured rules"
echo "- Select 'Silences' to temporarily disable alerts"
echo "- Select 'Alert groups' to see active alerts"
EOF