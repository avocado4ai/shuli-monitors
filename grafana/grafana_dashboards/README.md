# Grafana Dashboards

This directory contains JSON exports for the pre-built Grafana dashboards used across the infrastructure stack:

- `grafana-system-metrics-dashboard.json` – system + NVIDIA GPU monitoring (Prometheus based).
- `grafana-docker-logs-dashboard.json` – container log overview.
- `grafana-scrapy-postgresml-dashboard.json` – service-specific metrics for Scrapy + PostgresML.

## How to Import a Dashboard
1. Log into Grafana (`http://localhost:3091`, default `admin`/`admin123` unless changed).
2. Navigate to **Dashboards → New → Import**.
3. Upload the desired JSON file from this folder or paste its raw content.
4. When prompted, choose the correct data source:
   - `Prometheus` (http://prometheus:9090 or the proxied 9098 mapping) for metrics panels.
   - `Loki` or `Promtail` (if configured) for log panels.
5. Click **Import**; the dashboard appears under “General” unless you specify another folder.

## Connecting Data Sources
All dashboards assume the existing infra components are running via Docker (see `/home/dev/setup-grafana-dashboards.sh` and `README_OPERATIONS.md`):

- **Prometheus** – container `prometheus` exposed on `9098->9090`. Confirm it is healthy with `docker ps` and verify the service in Grafana under **Connections → Data sources → Prometheus**.
- **Node Exporter / NVIDIA GPU Exporter** – already scraped by Prometheus using `node-exporter:9100` and `nvidia-gpu-exporter:9835`.
- **Postgres Exporter** – container `postgres_exporter` exposes metrics on `9187`. Prometheus job definitions already scrape it, so any dashboards referencing PostgreSQL panels (e.g., `grafana-scrapy-postgresml-dashboard.json`) will work once the Prometheus data source is selected.
- **Loki / Logging** – if you are using Loki, ensure the Grafana data source points to the Loki endpoint defined in your compose stack; the docker logs dashboard expects labels `container`, `service`, etc.

### Suggested Dashboards for Detected Containers
| Container | Dashboard JSON | Notes |
|-----------|----------------|-------|
| `node_exporter` | `grafana-system-metrics-dashboard.json` | Shows CPU, RAM, disk, plus GPU metrics (Prometheus). |
| `nvidia-gpu-exporter` | `grafana-system-metrics-dashboard.json` | GPU utilization, temp, power panels. |
| `postgres_exporter` | `grafana-scrapy-postgresml-dashboard.json` | Postgres connection, cache, query timing panels. |
| `prometheus` | Any of the above | Must remain healthy to serve metrics. |
| Logging stack (e.g., Loki/Promtail) | `grafana-docker-logs-dashboard.json` | Displays container logs with label filters. |

## Transformer Board for App Services
Build individual Grafana dashboards (one per service) under **Dashboards → New → New dashboard** to cover application-level health. Each board should have at least: request/queue metrics, error counts, resource usage, and logs.

1. **Scriberr** (`scriberr`, port 3006)  
   - Metrics: `http_requests_total`, latency histogram, GPU job queue depth, success vs error counts.  
   - Panels: throughput, p95 latency, queue length, GPU usage per job, error rate sparkline.  
   - Logs: Loki query `{container="scriberr"} |= "ERROR"`.

2. **Ivrit API** (`ivrit-api-container`, port 3008)  
   - Metrics: translation throughput, pending job queue, external API latency, model inference GPU memory usage.  
   - Panels: p99 translation latency, success/error ratio, GPU VRAM timeline.  
   - Logs: `{container="ivrit-api-container"}`.

3. **Docling Serve + Docling MCP** (`docling-serve`, `docling-mcp`)  
   - Metrics: conversion request rate, job duration histogram, OCR error codes, GPU utilization, CPU load.  
   - Panels: workload by document type, conversion success vs failure, GPU temperature.  
   - Logs: separate Loki panels for each container with filters on “ERROR” or specific exception strings.

4. **FileWizard** (`test-filewizard-fixed`)  
   - Metrics: job queue depth, processing latency, file size distribution, API error rate.  
   - Panels: queue backlog gauge, average processing time, error rate.  
   - Logs: `{container="test-filewizard-fixed"}`.

5. **PDF Extraction API** (`pdf-extraction-api`)  
   - Metrics: `uvicorn_request_duration_seconds`, job queue size, conversion success %, GPU usage if OCR leverages CUDA.  
   - Panels: documents/minute, p95 latency, OCR error count, GPU mem usage.  
   - Logs: `{container="pdf-extraction-api"}` focusing on PDF parsing failures.

6. **PostgresML** (`postgresml`)  
   - Metrics: QPS, query latency, inference job counts, GPU utilization (if PostgresML uses CUDA).  
   - Panels: inference queue depth, GPU memory, database connections, custom Postgres exporter metrics filtered by `job="postgres_exporter"` and `db="postgresml"`.  
   - Logs: Loki query by container to catch extension errors or slow query warnings.

### Dashboard Creation Flow (per service)
1. Ensure Prometheus scrapes the service (add `/metrics` endpoint in `prometheus.yml` or attach Docker labels).  
2. In Grafana, create a new dashboard, add rows per metric type (Traffic, Latency, Errors, Resources, Logs).  
3. Use PromQL queries filtered by `job` or `container` labels, e.g.:  
   ```promql
   sum(rate(http_requests_total{job="scriberr"}[5m]))
   Histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="scriberr"}[5m])) by (le))
   ```
4. Add a Loki panel with query `{container="scriberr"} |= "ERROR"` (adjust container names accordingly).  
5. Save the dashboard with a clear title, e.g., “Scriberr Transformer Board,” and optionally export it into this directory for reuse.

### How to Wire Metrics
1. Ensure each service exposes Prometheus-formatted metrics (`/metrics`) or emits custom metrics via Pushgateway.  
2. Add scrape configs in `prometheus.yml` (or via Docker labels) for the service containers.  
3. In Grafana, add panels referencing the new metric names. Example query for Scriberr latency percentile:  
   ```promql
   histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="scriberr"}[5m])) by (le))
   ```
4. Add a Loki data source panel per service to show recent errors with a query such as:  
   ```
   {container="scriberr"} |= "ERROR"
   ```
5. Group the panels in rows (“Scriberr”, “Ivrit”, “Docling”, “FileWizard”) to form a transformer board covering queue depth, error counts, model utilization, and logs for rapid diagnosis.

### Quick Validation Commands
```bash
# List relevant containers to ensure they are running
docker ps --filter name=grafana --filter name=prometheus --filter name=nvidia-gpu-exporter

# Test Prometheus reachability
curl http://localhost:9098/api/v1/label/job/values
```

Once the data sources respond, importing any JSON file from this directory will recreate the matching dashboard in Grafana with all panels wired to the running infrastructure.
