# 📊 Prometheus Session Analysis Queries

**Prometheus URL**: [http://localhost:9098](http://localhost:9098)

## 🔍 Key Session Metrics Available

### Current Active Targets
Based on your Prometheus setup, these metrics are available:

```promql
# Check all available metrics
{__name__=~".*"}

# Active Prometheus targets
up

# Node exporter system metrics
node_load1
node_load5  
node_load15
node_memory_MemAvailable_bytes
node_filesystem_avail_bytes

# PostgreSQL connection metrics
pg_stat_database_numbackends
pg_stat_activity_count
pg_locks_count
```

## 🖥️ System Session Queries

### SSH Connection Monitoring
```promql
# SSH daemon status
node_systemd_unit_state{name="ssh.service", state="active"}

# Network connections on SSH port
node_netstat_Tcp_CurrEstab{port="22"}

# System load (session impact)
node_load1
node_load5
node_load15
```

### Process Session Tracking
```promql
# Running processes
node_processes_running

# Process start time (session duration)
node_boot_time_seconds

# Memory usage by processes
node_memory_MemAvailable_bytes / 1024 / 1024
```

## 💾 Database Session Queries

### PostgreSQL Connections
```promql
# Active database connections
pg_stat_database_numbackends

# Connection states
pg_stat_activity_count by (state)

# Database locks
pg_locks_count by (mode)

# Query duration
pg_stat_activity_max_tx_duration_seconds
```

### Redis Connection Monitoring
```promql
# Redis connected clients (if redis_exporter available)
redis_connected_clients

# Redis memory usage
redis_memory_used_bytes

# Redis commands processed
redis_commands_processed_total
```

## 🚀 n8n Application Sessions

### Workflow Execution Tracking
```promql
# n8n execution metrics (if exposed)
n8n_executions_total
n8n_execution_duration_seconds
n8n_active_executions

# HTTP request metrics for n8n
http_requests_total{job="n8n"}
http_request_duration_seconds{job="n8n"}
```

## 📈 Custom Session Metrics

### Long Running Sessions
```promql
# Processes running longer than 1 hour
(time() - node_boot_time_seconds) > 3600

# High memory processes
topk(10, node_memory_MemAvailable_bytes)
```

### Session Anomaly Detection
```promql
# Rapid connection changes
delta(pg_stat_database_numbackends[5m]) > 5

# High CPU usage
rate(node_cpu_seconds_total{mode!="idle"}[5m]) > 0.8

# Memory pressure
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
```

## 🔧 Grafana Integration

### Data Source Configuration
- **URL**: `http://prometheus:9098`  
- **Access**: Server (default)
- **HTTP Method**: GET

### Example Dashboard Queries

#### Panel 1: Active Sessions
```promql
# System load
node_load1

# Database connections
pg_stat_database_numbackends

# Process count
node_processes_running
```

#### Panel 2: Session Duration Heatmap
```promql
# CPU usage by time
rate(node_cpu_seconds_total[5m])

# Memory usage timeline
node_memory_MemAvailable_bytes
```

## 🚨 Alert Rules for Sessions

### High Connection Count
```yaml
- alert: HighDatabaseConnections
  expr: pg_stat_database_numbackends > 50
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High database connection count"
    description: "{{ $value }} connections active"
```

### System Resource Alerts
```yaml
- alert: HighSystemLoad
  expr: node_load5 > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High system load detected"
    description: "Load average: {{ $value }}"
```

## 🔍 Available Metrics Discovery

### Check Your Prometheus Metrics
Visit: [http://localhost:9098/graph](http://localhost:9098/graph)

```promql
# List all available metrics
{__name__=~".*"}

# Check node_exporter metrics
{__name__=~"node_.*"}

# Check postgres_exporter metrics  
{__name__=~"pg_.*"}

# Check up status of all targets
up
```

### Query Builder Examples
```promql
# Find SSH-related metrics
{__name__=~".*ssh.*"}

# Find connection metrics
{__name__=~".*connect.*"}

# Find session metrics
{__name__=~".*session.*"}
```

## 📊 Session Analysis Workflow

1. **Check Available Metrics**:
   ```promql
   up
   ```

2. **Monitor Database Sessions**:
   ```promql
   pg_stat_database_numbackends
   ```

3. **Track System Load**:
   ```promql
   node_load1
   ```

4. **Analyze Process Activity**:
   ```promql
   node_processes_running
   ```

5. **Create Custom Alerts**:
   ```promql
   pg_stat_database_numbackends > 30
   ```

---

**Access Your Prometheus**: http://localhost:9098  
**Current Active Targets**: node_exporter:9100, postgres_exporter:9187  
**Last Updated**: 2026-01-07