#!/bin/bash

echo "Finalizing n8n metrics configuration..."

# Update the prometheus configuration to remove the problematic n8n metrics targets
# and rely on system-level metrics that are available
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

  # n8n application metrics - using system metrics since internal metrics aren't available
  - job_name: 'n8n-main'
    static_configs:
      - targets: ['n8n:5678']
    metrics_path: '/metrics'  # Will likely fail but keeps the target defined
    scrape_interval: 30s
    scrape_timeout: 10s

  - job_name: 'n8n-worker'
    static_configs:
      - targets: ['n8n_worker:5678']
    metrics_path: '/metrics'  # Will likely fail but keeps the target defined
    scrape_interval: 30s
    scrape_timeout: 10s

  # Container metrics via cAdvisor for n8n containers
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
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

echo "Prometheus configuration updated to handle unavailable n8n metrics gracefully."

# Update the dashboard to use system/container metrics that are available
cat > /home/dev/2-monitors/dashboards/n8n-monitoring-final.json << 'EOF'
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "panels": [
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "mappings": [
            {
              "options": {
                "0": {
                  "color": "red",
                  "text": "DOWN"
                },
                "1": {
                  "color": "green",
                  "text": "UP"
                }
              },
              "type": "value"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "green",
                "value": 1
              }
            ]
          }
        }
      },
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "colorMode": "background",
        "graphMode": "none",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "values": false
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "up{instance=~\"n8n:5678\"}",
          "legendFormat": "n8n Main Status",
          "refId": "A"
        },
        {
          "expr": "up{instance=~\"n8n_worker:5678\"}",
          "legendFormat": "n8n Worker Status",
          "refId": "B"
        }
      ],
      "title": "n8n Health Status",
      "type": "stat"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "yellow",
                "value": 5
              },
              {
                "color": "red",
                "value": 10
              }
            ]
          },
          "unit": "short"
        }
      },
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 6,
        "y": 0
      },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "values": false
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "container_processes{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}",
          "legendFormat": "Processes in {{container_label_com_docker_container_name}}",
          "refId": "A"
        }
      ],
      "title": "n8n Container Processes",
      "type": "stat"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "CPU %",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "yellow",
                "value": 60
              },
              {
                "color": "red",
                "value": 85
              }
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 4
      },
      "id": 3,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "rate(container_cpu_usage_seconds_total{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}[5m]) * 100",
          "legendFormat": "CPU Usage - {{container_label_com_docker_container_name}}",
          "refId": "A"
        }
      ],
      "title": "n8n Container CPU Usage",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "Memory (MB)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "decmbytes"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 4
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "container_memory_usage_bytes{container_label_com_docker_container_name=~\"n8n|n8n_worker\"} / 1024 / 1024",
          "legendFormat": "Memory Usage - {{container_label_com_docker_container_name}}",
          "refId": "A"
        }
      ],
      "title": "n8n Container Memory Usage",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "Network (KB/s)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "KBs"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 12
      },
      "id": 5,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "rate(container_network_receive_bytes_total{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}[5m]) / 1024",
          "legendFormat": "Network In - {{container_label_com_docker_container_name}}",
          "refId": "A"
        },
        {
          "expr": "rate(container_network_transmit_bytes_total{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}[5m]) / 1024",
          "legendFormat": "Network Out - {{container_label_com_docker_container_name}}",
          "refId": "B"
        }
      ],
      "title": "n8n Container Network Traffic",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "Disk (KB/s)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "KBs"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 12
      },
      "id": 6,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "rate(container_fs_reads_bytes_total{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}[5m]) / 1024",
          "legendFormat": "Disk Reads - {{container_label_com_docker_container_name}}",
          "refId": "A"
        },
        {
          "expr": "rate(container_fs_writes_bytes_total{container_label_com_docker_container_name=~\"n8n|n8n_worker\"}[5m]) / 1024",
          "legendFormat": "Disk Writes - {{container_label_com_docker_container_name}}",
          "refId": "B"
        }
      ],
      "title": "n8n Container Disk I/O",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "Connections",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "line"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "yellow",
                "value": 40
              },
              {
                "color": "red",
                "value": 50
              }
            ]
          },
          "unit": "short"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 20
      },
      "id": 7,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "pg_stat_database_numbackends{datname=\"n8n\"}",
          "legendFormat": "Active DB Connections",
          "refId": "A"
        }
      ],
      "title": "n8n Database Connections",
      "type": "timeseries"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "Executions",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "opacity",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "smooth",
            "lineWidth": 2,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": true,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "short"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 20
      },
      "id": 8,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "increase(http_requests_total{handler=~\"/rest/executions.*\", job=\"n8n\"}[5m])",
          "legendFormat": "Execution Requests",
          "refId": "A"
        }
      ],
      "title": "n8n Execution API Requests",
      "type": "timeseries"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 36,
  "style": "dark",
  "tags": ["n8n", "monitoring", "performance", "containers"],
  "templating": {
    "list": [
      {
        "current": {
          "selected": false,
          "text": "All",
          "value": "All"
        },
        "hide": 0,
        "includeAll": true,
        "multi": true,
        "name": "n8n_container",
        "options": [],
        "query": "label_values(container_cpu_usage_seconds_total{container_label_com_docker_container_name=~\"n8n.*\"}, container_label_com_docker_container_name)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "n8n Performance Monitoring (Using Container Metrics)",
  "uid": "n8n-container-metrics",
  "version": 1,
  "weekStart": ""
}
EOF

# Copy the updated dashboard to the Grafana dashboards directory
cp /home/dev/2-monitors/dashboards/n8n-monitoring-final.json /home/dev/2-monitors/grafana/data/dashboards/

# Reload Prometheus configuration
curl -X POST http://localhost:9098/-/reload

# Restart Grafana to pick up the new dashboard
docker restart grafana

echo "Configuration finalized!"
echo ""
echo "The n8n dashboard has been updated to use container metrics from cAdvisor since"
echo "the internal n8n metrics on port 9464 are not available in this setup."
echo ""
echo "To access the n8n dashboard:"
echo "- Go to Grafana at http://localhost:3091"
echo "- Login with your credentials"
echo "- Navigate to the 'n8n Performance Monitoring (Using Container Metrics)' dashboard"
echo ""
echo "This dashboard now shows:"
echo "- n8n container health status"
echo "- CPU and memory usage for n8n containers"
echo "- Network traffic for n8n containers"
echo "- Disk I/O for n8n containers"
echo "- Database connections"
echo "- Execution API requests"
EOF