#!/bin/bash

echo "Fixing n8n metrics configuration..."

# Check if n8n containers have the metrics configuration properly set
echo "Current n8n environment variables related to metrics:"
docker exec n8n env | grep -i metric

echo ""
echo "Current n8n_worker environment variables related to metrics:"
docker exec n8n_worker env | grep -i metric

echo ""
echo "Attempting to fix n8n metrics configuration..."

# The issue is that while metrics are enabled in the n8n containers, they might not be exposed properly
# Let's check if the n8n services are running with the correct metrics settings

echo "Checking n8n main service configuration..."
docker exec n8n printenv | grep N8N_METRICS

echo ""
echo "Checking n8n worker service configuration..."
docker exec n8n_worker printenv | grep N8N_METRICS

echo ""
echo "Both services should have metrics enabled. Let's verify the ports are exposed correctly..."

# Check if port 9464 is actually listening inside the container
echo "Checking if port 9464 is listening in n8n container..."
docker exec n8n ss -tuln | grep 9464 || echo "Port 9464 not found in n8n container"

echo ""
echo "Checking if port 9464 is listening in n8n_worker container..."
docker exec n8n_worker ss -tuln | grep 9464 || echo "Port 9464 not found in n8n_worker container"

echo ""
echo "The issue is that n8n metrics are enabled but not exposed on port 9464."
echo "They might be exposed on the same port as the main service (5678) under /metrics endpoint."
echo ""
echo "Testing metrics availability on main n8n port with /metrics endpoint..."

# Test if metrics are available on the main port with /metrics endpoint
echo "Testing n8n main service metrics on port 5678 /metrics endpoint..."
docker exec monitors_prometheus sh -c 'echo -e "GET /metrics HTTP/1.0\r\nHost: n8n:5678\r\n\r\n" | nc n8n 5678' | head -10

echo ""
echo "Testing n8n worker service metrics on port 5678 /metrics endpoint..."
docker exec monitors_prometheus sh -c 'echo -e "GET /metrics HTTP/1.0\r\nHost: n8n_worker:5678\r\n\r\n" | nc n8n_worker 5678' | head -10

echo ""
echo "If metrics are available on port 5678, we need to update the Prometheus configuration."
echo "Updating Prometheus configuration to use port 5678 with /metrics endpoint..."

# Update the prometheus configuration to use the correct port and path
cat > /home/dev/2-monitors/.prometheus/prometheus_cfg.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/disk_alerts.yml"
  - "rules/n8n_alerts.yml"

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # PostgreSQL database metrics
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres_exporter:9187']
    scrape_interval: 30s

  # System metrics via node_exporter
  - job_name: 'node'
    static_configs:
      - targets: ['node_exporter:9100']
    scrape_interval: 30s

  # NVIDIA GPU metrics
  - job_name: 'nvidia-gpu'
    static_configs:
      - targets: ['172.17.0.1:9835']
    scrape_interval: 30s

  # Ollama server metrics
  - job_name: 'ollama-servers'
    static_configs:
      - targets: ['ollama:11434']
    metrics_path: '/api/ps'
    scrape_interval: 30s

  # MinIO metrics
  - job_name: 'minio'
    bearer_token: eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJwcm9tZXRoZXVzIiwic3ViIjoiZGV2IiwiZXhwIjo0OTExNjc4NjkyfQ.VYB84XC3FI_G0tEqJcJEQ6su3avnm83qaRVCDB2CFK1qWXUSjKyTF78p_rYZoQZjhNSVhofQg5psIOmX6UZqoA
    metrics_path: '/minio/v2/metrics/cluster'
    scheme: http
    static_configs:
      - targets: ['minio:9000']
    scrape_interval: 30s

  # Traefik metrics
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # n8n application metrics (main) - using main port with /metrics endpoint
  - job_name: 'n8n-main'
    static_configs:
      - targets: ['n8n:5678']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s

  # n8n application metrics (worker) - using main port with /metrics endpoint
  - job_name: 'n8n-worker'
    static_configs:
      - targets: ['n8n_worker:5678']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s

  # Ollama Metrics Exporter
  - job_name: 'ollama-metrics'
    static_configs:
      - targets: ['172.17.0.1:1313']
    scrape_interval: 15s
    scrape_timeout: 10s

  # Services without Prometheus metrics endpoints (disabled):
  # - Redis: Redis Stack UI at port 8001 returns HTML, not Prometheus metrics
  # - LiteLLM: No metrics endpoint available
  # - Neo4j: No metrics endpoint in community edition
  # - OpenWebUI: /metrics returns HTML instead of Prometheus format
  # - MCP Server: Service not currently running
EOF

echo "Prometheus configuration updated. Reloading..."
curl -X POST http://localhost:9098/-/reload

echo ""
echo "Configuration updated. Please check the Prometheus targets page to see if n8n services are now UP."
echo "Access http://localhost:9098/targets to verify."
EOF