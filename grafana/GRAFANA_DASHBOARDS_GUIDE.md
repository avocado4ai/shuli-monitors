# Grafana Dashboards Setup Guide

**Created**: November 9, 2025
**Last Updated**: November 10, 2025 (Added Scrapy & PostgresML dashboard)
**Purpose**: Monitor Dozzle logs, system metrics, web scraping, and ML services in Grafana
**Status**: Ready for import and configuration

---

## 📊 Available Dashboards

### 1. **Docker Logs & Containers Dashboard**
**File**: `grafana-docker-logs-dashboard.json`

**Contents**:
- Container CPU usage (real-time graph)
- Container memory usage (real-time graph)
- Running containers count (gauge)
- Container restart count (gauge)
- Container list with status
- Direct link to Dozzle (http://localhost:8801)

**Data Source**: Prometheus
**Refresh Rate**: 30 seconds
**Time Range**: Last 6 hours

**Use Cases**:
- Monitor Docker container performance
- Track container restarts
- Quick access to detailed logs via Dozzle link
- Identify problematic containers

---

### 2. **System Metrics Dashboard**
**File**: `grafana-system-metrics-dashboard.json`

**Contents**:
- CPU usage % (real-time graph with thresholds)
- Memory usage % (real-time graph with thresholds)
- Disk usage % (real-time graph)
- System load average (1m, 5m, 15m)
- CPU cores count
- Total memory (stat)
- Total disk space (stat)
- Available disk space (stat)

**Data Source**: Prometheus
**Refresh Rate**: 30 seconds
**Time Range**: Last 6 hours

**Use Cases**:
- Monitor overall system health
- Identify resource bottlenecks
- Track trends over time
- Alert on high resource usage

---

### 3. **Scrapy & PostgresML Monitoring Dashboard** (NEW)
**File**: `grafana-scrapy-postgresml-dashboard.json`

**Contents**:
- Service status indicators (Scrapy & PostgresML)
- Scrapy spider activity (pages scraped, requests/sec)
- Container memory usage (Scrapyd, PostgresML)
- Container CPU usage (Scrapyd, PostgresML)
- Scrapy job statistics (pending, received, dropped requests)
- PostgresML database activity (queries/sec, function calls)
- PostgresML models and training information
- Container status indicators for both services
- PostgresML disk I/O monitoring
- PostgresML database connections
- Quick links and documentation section

**Data Source**: Prometheus
**Refresh Rate**: Dynamic (adaptable)
**Time Range**: Last 24 hours

**Use Cases**:
- Monitor web scraping performance and job status
- Track PostgresML ML model training and execution
- Monitor database activity and connections
- Identify resource bottlenecks in both services
- Quick access to service UIs (Scrapyd-UI, PostgresML Dashboard)
- View integration documentation

**Service-Specific Links**:
- Scrapy Web Interface: http://localhost:3007 (when running)
- Scrapy API: http://localhost:6800
- PostgresML Dashboard: http://localhost:8100
- PostgresML Database: localhost:5433

---

## 🚀 Quick Start

### Step 1: Access Grafana
```
http://localhost:3091
```

Default login: `admin` / `admin`
(Change password on first login)

### Step 2: Import Dashboards

#### Option A: Via Web UI (Recommended)

1. Click **"+"** menu (top left)
2. Select **"Import"**
3. In "Import via panel json" section, paste JSON content from files:
   - `grafana-docker-logs-dashboard.json`
   - `grafana-system-metrics-dashboard.json`
   - `grafana-scrapy-postgresml-dashboard.json` (NEW)
4. Select **"Prometheus"** as data source
5. Click **"Import"**

#### Option B: Via API

```bash
# Import Docker Logs Dashboard
curl -X POST http://localhost:3091/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @/home/dev/grafana-docker-logs-dashboard.json

# Import System Metrics Dashboard
curl -X POST http://localhost:3091/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @/home/dev/grafana-system-metrics-dashboard.json

# Import Scrapy & PostgresML Dashboard (NEW)
curl -X POST http://localhost:3091/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @/home/dev/grafana-scrapy-postgresml-dashboard.json
```

### Step 3: Verify Data Source

Ensure Prometheus is configured as data source:

1. Go to **Configuration** → **Data Sources**
2. Verify **"Prometheus"** exists and is marked as default
3. Test connection (should say "Data source is working")

If not configured:
```bash
# Check if Prometheus is accessible
curl -s http://localhost:9098/api/v1/targets | jq .
```

---

## 📈 Dashboard Panels Explained

### Docker Logs Dashboard

#### Panel: Container CPU Usage
- **Query**: `rate(container_cpu_usage_seconds_total[5m]) * 100`
- **Metric**: CPU percentage per container
- **Color**: Green → Red (increasing load)
- **Shows**: Which containers are using most CPU

#### Panel: Container Memory Usage
- **Query**: `container_memory_usage_bytes / 1024 / 1024`
- **Metric**: Memory in MB per container
- **Shows**: Which containers are memory-heavy

#### Panel: Running Containers
- **Query**: `count(container_last_seen)`
- **Type**: Gauge showing number of running containers
- **Threshold**: Red if count = 0 (alert!)

#### Panel: Container Restarts
- **Query**: `increase(container_last_seen[1h])`
- **Shows**: How many container restarts in last hour
- **Threshold**: Yellow at 5+, Red at 10+

#### Panel: Container List
- **Query**: Table view of all running containers
- **Shows**: Container names and counts

#### Panel: Dozzle Link
- **Purpose**: Quick link to detailed Docker logs
- **URL**: http://localhost:8801
- **Use**: Click to view real-time logs for any container

---

### System Metrics Dashboard

#### Panel: CPU Usage
- **Query**: `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Shows**: CPU percentage (0-100%)
- **Thresholds**: Yellow at 60%, Red at 85%
- **Stats**: Mean, Max, Min shown

#### Panel: Memory Usage
- **Query**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- **Shows**: Memory percentage (0-100%)
- **Thresholds**: Yellow at 70%, Red at 85%

#### Panel: Disk Usage
- **Query**: `100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)`
- **Shows**: Disk usage percentage for /
- **Thresholds**: Yellow at 70%, Red at 85%

#### Panel: System Load
- **Queries**:
  - `node_load1` (1 minute average)
  - `node_load5` (5 minute average)
  - `node_load15` (15 minute average)
- **Shows**: System load trends
- **Thresholds**: Yellow at 2, Red at 4

#### Panel: CPU Cores
- **Query**: `count(node_cpu_seconds_total{mode="system"})`
- **Shows**: Total number of CPU cores available

#### Panel: Total Memory
- **Query**: `node_memory_MemTotal_bytes`
- **Shows**: Total system memory in bytes

#### Panel: Total Disk Space
- **Query**: `node_filesystem_size_bytes{mountpoint="/"}`
- **Shows**: Total disk space for root partition

#### Panel: Available Disk Space
- **Query**: `node_filesystem_avail_bytes{mountpoint="/"}`
- **Shows**: Free disk space available

---

## 🔧 Configuration

### Data Source Setup

Prometheus is already running at `http://localhost:9098`

**To manually add (if not already configured)**:

1. **Configuration** → **Data Sources**
2. Click **"Add data source"**
3. Select **"Prometheus"**
4. Set URL: `http://prometheus:9090` (internal) or `http://localhost:9098` (external)
5. Click **"Save & test"**

---

## 📊 Accessing Dashboards

After import, dashboards are available at:

**Docker Logs Dashboard**:
```
http://localhost:3091/d/docker-logs/docker-logs-containers
```

**System Metrics Dashboard**:
```
http://localhost:3091/d/system-metrics/system-metrics
```

Or use the dashboard search:
1. Click **"Search"** (top left)
2. Type dashboard name
3. Click to open

---

## 🎨 Customizing Dashboards

### Change Refresh Rate
1. Click **"Dashboard Settings"** (gear icon, top right)
2. Set **"Refresh interval"** (e.g., 10s, 30s, 1m)

### Change Time Range
- Use time picker at top right
- Options: Last 6 hours, 24 hours, 7 days, 30 days, custom

### Add New Panels
1. Click **"Add panel"** (top right)
2. Select metric query
3. Choose visualization type (graph, gauge, stat, etc.)
4. Customize colors, thresholds, legend

### Edit Existing Panels
1. Hover over panel title
2. Click edit icon (pencil)
3. Modify query or visualization
4. Click **"Apply"**

---

## 🚨 Setting Up Alerts (Optional)

### Alert Rule: High CPU Usage

1. Go to **Alerting** → **Alert rules**
2. Click **"Create new alert rule"**
3. Set up query:
   ```
   100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
   ```
4. Set duration: **5 minutes**
5. Add notification channel
6. Click **"Create alert"**

### Alert Rule: High Memory Usage

```
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
For: 5m
```

### Alert Rule: Disk Space Low

```
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 85
For: 5m
```

### Alert Rule: Container Crash

```
rate(container_last_seen[5m]) > 0
For: 1m
```

---

## 🔗 Integration with Dozzle

### What is Dozzle?
Dozzle is a real-time Docker log viewer running on port **8801**

**URL**: `http://localhost:8801`

**Features**:
- Real-time log streaming
- Search and filter logs
- Multiple container view
- Clean, simple interface

### How to Use in Grafana
1. Click the **"Dozzle Link"** panel in Docker Logs dashboard
2. Opens Dozzle in new tab
3. View detailed logs for any container
4. Search for errors, warnings, specific text
5. Filter by container, log level

### Recommended Workflow
1. See high CPU/memory in Grafana dashboard
2. Identify problematic container
3. Click Dozzle link
4. View container logs for errors
5. Take corrective action

---

## 📝 Prometheus Queries Reference

### Docker Container Metrics
```
# Container CPU
rate(container_cpu_usage_seconds_total[5m])

# Container Memory
container_memory_usage_bytes

# Running containers
count(container_last_seen)

# Container restarts
increase(container_last_seen[1h])
```

### System Metrics
```
# CPU (0-100%)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory (0-100%)
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk (0-100%)
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Load average
node_load1
node_load5
node_load15
```

### Service Health
```
# All services up/down
up

# PostgreSQL connections
pg_stat_activity_count

# Database size
pg_database_size_bytes
```

---

## 🐛 Troubleshooting

### Dashboard Shows "No data"
1. Verify Prometheus is running: `docker ps | grep prometheus`
2. Check Prometheus targets: `curl -s http://localhost:9098/api/v1/targets | jq .`
3. Verify data source is selected in dashboard
4. Check time range (try "Last 1 hour" instead of "Last 6 hours")

### Metrics Aren't Updating
1. Check Prometheus health: `curl -s http://localhost:9098/-/healthy`
2. Verify exporters are running: `docker ps | grep exporter`
3. Check Prometheus scrape config: `curl -s http://localhost:9098/service-discovery`

### Can't Access Grafana
1. Check Grafana is running: `docker ps | grep grafana`
2. Check port 3091: `netstat -tlnp | grep 3091`
3. Try: `curl -s http://localhost:3091/api/health`

### Dozzle Link Doesn't Work
1. Verify Dozzle running: `docker ps | grep dozzle`
2. Check port 8801: `netstat -tlnp | grep 8801`
3. Try direct access: `http://localhost:8801`

---

## 📋 Import Checklist

- [ ] Access Grafana at http://localhost:3091
- [ ] Login with admin/admin
- [ ] Change default password
- [ ] Verify Prometheus data source exists
- [ ] Import Docker Logs Dashboard
- [ ] Import System Metrics Dashboard
- [ ] View dashboards and verify data is showing
- [ ] Test Dozzle link from Docker Logs dashboard
- [ ] Customize refresh rates as needed
- [ ] Set up alerts (optional)
- [ ] Share dashboards with team

---

## 🎓 Next Steps

1. **Import dashboards** (see Quick Start above)
2. **Explore metrics** in Grafana
3. **Create custom dashboards** for your specific needs
4. **Set up alerts** for critical metrics
5. **Monitor regularly** during operations
6. **Adjust thresholds** based on your system

---

## 📞 Support

### If Dashboards Don't Load Data

**Step 1**: Check Prometheus
```bash
# Verify Prometheus is running
docker ps | grep prometheus

# Test connectivity
curl -s http://localhost:9098/api/v1/targets | jq .targets[0:2]
```

**Step 2**: Check Metrics Available
```bash
# List available metrics
curl -s 'http://localhost:9098/api/v1/label/__name__/values' | jq . | head -20

# Query specific metric
curl -s 'http://localhost:9098/api/v1/query?query=up' | jq .
```

**Step 3**: Review Grafana Logs
```bash
# Check Grafana container logs
docker logs grafana

# Check for errors
docker logs grafana | grep -i error
```

---

## 📚 Additional Resources

**Grafana Docs**: https://grafana.com/docs/grafana/latest/
**Prometheus Docs**: https://prometheus.io/docs/
**Dozzle**: https://dozzle.dev/

---

## 📋 File Locations

```
/home/dev/
├── setup-grafana-dashboards.sh          (Setup guide script)
├── grafana-docker-logs-dashboard.json   (Docker dashboard)
├── grafana-system-metrics-dashboard.json (System dashboard)
└── GRAFANA_DASHBOARDS_GUIDE.md         (This file)
```

---

## ✅ Verification

After importing dashboards, verify:

1. **Docker Logs Dashboard**
   - Shows running container count
   - CPU and memory graphs have data
   - Dozzle link works
   - See service-specific links (Scrapy, PostgresML)

2. **System Metrics Dashboard**
   - Shows CPU, Memory, Disk usage
   - Load average graph updates
   - Hardware stats show correct values
   - Includes tags for Scrapy and PostgresML

3. **Scrapy & PostgresML Dashboard** (NEW)
   - Service status indicators show up/down status
   - Spider activity graphs show data (if Scrapy running)
   - Container memory and CPU usage displays correctly
   - PostgresML database metrics appear
   - Quick links work (Dozzle, Scrapy UI, PostgresML UI)

4. **Data Updates**
   - Graphs update every 30 seconds (configurable)
   - No "No data" errors
   - Timestamps are current

---

## 📋 Dashboard Summary

| Dashboard | File | Panels | Focus |
|-----------|------|--------|-------|
| Docker Logs | `grafana-docker-logs-dashboard.json` | 6 | Container monitoring, Dozzle integration |
| System Metrics | `grafana-system-metrics-dashboard.json` | 8 | System resources, load, disk usage |
| Scrapy & PostgresML | `grafana-scrapy-postgresml-dashboard.json` | 13 | Web scraping and ML service monitoring |

---

**Created**: November 9, 2025
**Last Updated**: November 10, 2025
**Status**: Ready for import and use
**Total Dashboards**: 3
**Total Panels**: 27
**Data Source**: Prometheus (http://localhost:9098)
**Monitoring Services**: Docker, Dozzle, Scrapy, PostgresML
