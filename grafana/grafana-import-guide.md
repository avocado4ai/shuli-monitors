# 📊 Grafana Dashboard Import Guide

This guide provides step-by-step instructions to import the pre-configured session analysis dashboards into your Grafana instance.

## 🚀 Quick Import Steps

### 1. Access Grafana Dashboard
- Open: [http://192.168.1.118:3091](http://192.168.1.118:3091)
- Login: `admin` / `029466372`

### 2. Import Session Analysis Dashboard

1. **Navigate to Import**:
   - Click "+" (Create) in the left sidebar
   - Select "Import"

2. **Upload Dashboard**:
   - Click "Upload JSON file"
   - Select `/home/dev/firewall/grafana-session-dashboard.json`
   - OR copy/paste the content from the file

3. **Configure Import**:
   - Name: "n8n Platform Session Analysis"
   - Folder: Select or create "n8n Monitoring"
   - UID: Leave empty for auto-generation

4. **Data Source Mapping**:
   - Prometheus: Select your "Prometheus" data source
   - PostgreSQL: Select "PostgreSQL Sessions" (if configured)

5. **Import**: Click "Import"

### 3. Import Security Monitoring Dashboard

1. **Repeat Import Process**:
   - Use `/home/dev/firewall/grafana-security-dashboard.json`
   - Name: "n8n Platform Security Monitoring"

2. **Configure Alerts** (Optional):
   - Go to Alerting > Alert Rules
   - Enable notifications for security events

### 4. Configure Data Sources (If Not Already Done)

#### Option A: Manual Configuration
Follow the detailed steps in `/home/dev/firewall/grafana-session-config.md`

#### Option B: Provisioned Configuration (Advanced)
```bash
# Copy datasource configuration to Grafana container
docker cp /home/dev/firewall/grafana-datasources.yaml grafana:/etc/grafana/provisioning/datasources/

# Restart Grafana to load datasources
docker-compose restart grafana
```

## 📋 Dashboard Features

### Session Analysis Dashboard
- **Active System Sessions**: SSH connections and system load
- **Application Sessions**: n8n workflow executions and container uptime
- **Database Activity**: PostgreSQL and Redis connection monitoring
- **Session Heatmap**: CPU usage patterns by process
- **Alert Panels**: Long-running sessions and database connection alerts

### Security Monitoring Dashboard
- **Failed Login Attempts**: SSH and HTTP authentication failures
- **Unusual Session Patterns**: Anomaly detection for process creation
- **Geographic Analysis**: Client IP location mapping (requires log parsing)
- **Session Anomalies**: Duration-based anomaly detection
- **Security Logs**: n8n workflow security events

## 🔧 Customization Options

### Time Range Variables
Both dashboards include a time range selector:
- 1 hour (default)
- 6 hours
- 12 hours
- 24 hours
- 7 days

### Auto-refresh Settings
- **Session Dashboard**: 30 seconds
- **Security Dashboard**: 1 minute

### Alert Thresholds
Modify alert thresholds by editing panels:
1. Click panel title → Edit
2. Navigate to Alert tab
3. Adjust threshold values
4. Save changes

## 📊 Available Queries

### System Sessions
```promql
# SSH Sessions
node_network_up{device~"ssh.*"}

# System Load
node_load1, node_load5, node_load15
```

### Application Sessions
```promql
# n8n Active Executions
n8n_executions_total

# Container Uptime
time() - container_start_time_seconds
```

### Database Sessions
```promql
# PostgreSQL Connections
pg_stat_database_numbackends

# Redis Connections
redis_connected_clients
```

### Security Monitoring
```promql
# Failed SSH Logins
increase(node_systemd_unit_state{name="ssh.service",state="failed"}[5m])

# Long Running Sessions
(time() - process_start_time_seconds) > 3600
```

## 🚨 Alert Configuration

### High Connection Count Alert
```yaml
Alert Rule: High Database Connections
Query: sum(pg_stat_database_numbackends) > 50
Condition: IS ABOVE 50
Evaluation: Every 1m for 5m
Notification: Email/Slack
```

### Session Duration Alert
```yaml
Alert Rule: Long Running Sessions
Query: count((time() - process_start_time_seconds) > 3600) > 5
Condition: IS ABOVE 5
Evaluation: Every 5m for 10m
Notification: Email/Slack
```

## 🔍 Troubleshooting

### No Data Showing
1. **Check Data Sources**:
   - Go to Configuration → Data Sources
   - Test connection for Prometheus and PostgreSQL
   - Verify URLs: `http://prometheus:9090` and `postgres:5432`

2. **Verify Metrics Collection**:
   - Check Prometheus targets: [http://192.168.1.118:9098/targets](http://192.168.1.118:9098/targets)
   - Ensure exporters are running: node-exporter, postgres-exporter

3. **Time Range Issues**:
   - Adjust dashboard time range (top-right corner)
   - Check if metrics exist for the selected timeframe

### Import Errors
1. **JSON Format**: Ensure JSON files are valid
2. **Data Source Names**: Match exact names in configuration
3. **Permissions**: Verify admin access to import dashboards

### Performance Issues
1. **Query Optimization**: Reduce query complexity for large datasets
2. **Time Ranges**: Use appropriate time windows for data volume
3. **Refresh Rates**: Adjust auto-refresh intervals based on needs

## 📱 Dashboard URLs

After import, dashboards will be available at:
- **Session Analysis**: `http://192.168.1.118:3091/d/[dashboard-uid]/n8n-platform-session-analysis`
- **Security Monitoring**: `http://192.168.1.118:3091/d/[dashboard-uid]/n8n-platform-security-monitoring`

## 🔗 Related Files

- **Configuration Guide**: `/home/dev/firewall/grafana-session-config.md`
- **Session Dashboard JSON**: `/home/dev/firewall/grafana-session-dashboard.json`
- **Security Dashboard JSON**: `/home/dev/firewall/grafana-security-dashboard.json`
- **Data Source Provisioning**: `/home/dev/firewall/grafana-datasources.yaml`
- **Service Dashboard**: `/home/dev/firewall/services-dashboard.md`

---

**Last Updated**: 2025-09-03  
**Compatible with**: Grafana 8.0+, Prometheus 2.30+  
**Contact**: yaronel4.ai@gmail.com