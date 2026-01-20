# Grafana Session Analysis Configuration

## 🔧 Data Source Setup

### 1. Add Prometheus Data Source
1. **Access Grafana**: `http://192.168.1.118:3091`
2. **Login**: admin / 029466372
3. **Go to**: Configuration > Data Sources > Add data source
4. **Select**: Prometheus
5. **Configure**:
   ```
   Name: Prometheus
   URL: http://prometheus:9090
   Access: Server (default)
   ```
6. **Click**: Save & Test

### 2. Add PostgreSQL Data Source (for detailed logs)
1. **Add data source** > PostgreSQL
2. **Configure**:
   ```
   Name: PostgreSQL Sessions
   Host: postgres:5432
   Database: n8n
   User: root
   Password: 029466372
   SSL Mode: disable
   ```

## 📈 Session Metrics to Monitor

### A. System Sessions
- **Active SSH connections**: `node_network_up{device="ssh"}`
- **User login sessions**: Available in system logs
- **Process sessions**: `node_processes_running`

### B. Application Sessions  
- **n8n active sessions**: `n8n_active_executions`
- **Docker container sessions**: `container_last_seen`
- **Web server connections**: `apache_connections`

### C. Database Sessions
- **PostgreSQL connections**: `pg_stat_activity`
- **Redis connections**: `redis_connected_clients`
- **Active queries**: `pg_stat_database_numbackends`

## 🎯 Dashboard Creation

### Session Overview Dashboard
1. **Create Dashboard**: + > Dashboard
2. **Add Panels**:

#### Panel 1: Active System Sessions
```promql
# SSH Sessions
node_network_up{device~"ssh.*"}

# System Load (session impact)
node_load1
```

#### Panel 2: Application Sessions
```promql
# n8n Executions (active workflows)
n8n_executions_total

# Container Uptime
time() - container_start_time_seconds
```

#### Panel 3: Database Activity
```promql
# PostgreSQL connections
pg_stat_database_numbackends

# Redis connections  
redis_connected_clients
```

#### Panel 4: Web Traffic Analysis
```promql
# HTTP requests (if available)
http_requests_total

# Response times
http_request_duration_seconds
```

## 📊 Advanced Session Queries

### User Session Duration
```sql
-- PostgreSQL query for user sessions
SELECT 
  user_name,
  session_start,
  session_end,
  (session_end - session_start) AS duration
FROM user_sessions 
WHERE DATE(session_start) = CURRENT_DATE
ORDER BY duration DESC;
```

### n8n Workflow Sessions
```promql
# Active n8n workflows
sum(n8n_executions_total) by (status)

# Execution duration
histogram_quantile(0.95, n8n_execution_duration_seconds_bucket)
```

### System Resource Usage by Sessions
```promql
# Memory per process
process_resident_memory_bytes

# CPU usage
rate(process_cpu_seconds_total[5m])
```

## 🚨 Session Alerts

### High Session Count Alert
1. **Go to**: Alerting > Alert Rules
2. **Create Rule**:
   ```
   Query: sum(pg_stat_database_numbackends) > 50
   Condition: IS ABOVE 50
   Evaluation: Every 1m for 5m
   ```

### Session Duration Alert
```promql
# Long-running sessions
(time() - process_start_time_seconds) > 3600
```

## 📱 Dashboard Templates

### Template 1: System Sessions Overview
- Active SSH connections
- User login/logout events
- System load correlation
- Memory/CPU usage by session

### Template 2: Application Performance
- n8n workflow sessions
- Database connection pools
- API response times
- Error rates by session

### Template 3: Security Monitoring
- Failed login attempts
- Unusual session patterns
- Geographic session analysis
- Session duration anomalies

## 🔍 Log Sources for Session Analysis

### 1. System Logs (via Loki - optional)
```bash
# Install Loki for log aggregation
docker run -d --name loki \
  -p 3100:3100 \
  grafana/loki:latest
```

### 2. Application Logs
- **n8n logs**: Docker container logs
- **Apache logs**: `/var/log/apache2/access.log`
- **Mail logs**: `/var/log/mail.log`

### 3. Database Query Logs
```sql
-- Enable PostgreSQL logging
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

## 🎨 Custom Visualizations

### Session Timeline
- **Panel Type**: Time series
- **Query**: Session start/end events
- **Visualization**: Line graph with annotations

### Session Heatmap  
- **Panel Type**: Heatmap
- **Query**: Sessions by hour/day
- **Color**: Session count intensity

### Geo Map (if available)
- **Panel Type**: Geomap
- **Query**: Session locations
- **Layer**: CircleLayer for session density

## 🔧 Advanced Configuration

### Variable Setup
1. **Dashboard Settings** > Variables
2. **Add Variable**:
   ```
   Name: time_range
   Type: Interval
   Values: 1h,6h,12h,24h,7d
   ```

### Refresh Settings
- **Auto-refresh**: 30s for real-time monitoring
- **Time range**: Last 24 hours default
- **Timezone**: Local (Asia/Jerusalem)

## 📈 Performance Optimization

### Query Optimization
- Use recording rules for complex queries
- Set appropriate time ranges
- Cache frequently used data

### Resource Management
- Limit concurrent queries
- Set memory limits for Grafana
- Use data source proxy caching