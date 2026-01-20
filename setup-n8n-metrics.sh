#!/bin/bash

echo "Setting up proper n8n metrics configuration..."

# Create a backup of the current prometheus config
cp /home/dev/2-monitors/.prometheus/prometheus_cfg.yml /home/dev/2-monitors/.prometheus/prometheus_cfg.yml.backup.$(date +%s)

# Update the prometheus configuration to ensure n8n metrics are properly scraped
echo "Updating Prometheus configuration for n8n metrics..."

# Create the updated prometheus config with n8n metrics
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

  # n8n application metrics (main)
  - job_name: 'n8n-main'
    static_configs:
      - targets: ['n8n:9464']
    scrape_interval: 30s
    scrape_timeout: 10s

  # n8n application metrics (worker)
  - job_name: 'n8n-worker'
    static_configs:
      - targets: ['n8n_worker:9464']
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

# Create the updated dashboard
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
          "expr": "up{job=\"n8n-main\"}",
          "legendFormat": "n8n Main Status",
          "refId": "A"
        },
        {
          "expr": "up{job=\"n8n-worker\"}",
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
          "expr": "count(count by (workflow_id) (n8n_workflow_active))",
          "legendFormat": "Active Workflows",
          "refId": "A"
        }
      ],
      "title": "Active Workflows",
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
            "axisLabel": "Jobs",
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
        "y": 0
      },
      "id": 3,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull", "max"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "multi",
          "sort": "desc"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "n8n_scaling_mode_queue_jobs_waiting",
          "legendFormat": "Waiting Jobs",
          "refId": "A"
        },
        {
          "expr": "n8n_scaling_mode_queue_jobs_active",
          "legendFormat": "Active Jobs",
          "refId": "B"
        }
      ],
      "title": "Queue Status",
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
            "axisLabel": "Jobs/sec",
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
              "mode": "normal"
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
          "unit": "ops"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Failed"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "red",
                  "mode": "fixed"
                }
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
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
          "mode": "multi",
          "sort": "desc"
        }
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "expr": "rate(n8n_scaling_mode_queue_jobs_completed[5m])",
          "legendFormat": "Completed",
          "refId": "A"
        },
        {
          "expr": "rate(n8n_scaling_mode_queue_jobs_failed[5m])",
          "legendFormat": "Failed",
          "refId": "B"
        }
      ],
      "title": "Job Completion Rate",
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
          "expr": "rate(process_cpu_seconds_total{job=~\"n8n.*\"}[5m]) * 100",
          "legendFormat": "n8n CPU Usage",
          "refId": "A"
        }
      ],
      "title": "n8n Process CPU Usage",
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
          "expr": "process_resident_memory_bytes{job=~\"n8n.*\"} / 1024 / 1024",
          "legendFormat": "Memory Usage",
          "refId": "A"
        }
      ],
      "title": "n8n Memory Usage",
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
          "expr": "n8n_executions_total",
          "legendFormat": "Total Executions",
          "refId": "A"
        },
        {
          "expr": "n8n_executions_running",
          "legendFormat": "Running Executions",
          "refId": "B"
        }
      ],
      "title": "Execution Metrics",
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
          "expr": "pg_stat_database_numbackends{datname=\"n8n\"}",
          "legendFormat": "Active Connections",
          "refId": "A"
        }
      ],
      "title": "Database Connections",
      "type": "timeseries"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 36,
  "style": "dark",
  "tags": ["n8n", "monitoring", "performance"],
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
        "name": "n8n_instance",
        "options": [],
        "query": "label_values(up{job=~\"n8n.*\"}, instance)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "current": {
          "selected": false,
          "text": "All",
          "value": "All"
        },
        "hide": 0,
        "includeAll": true,
        "multi": true,
        "name": "n8n_job",
        "options": [],
        "query": "label_values(up{job=~\"n8n.*\"}, job)",
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
  "title": "n8n Performance Monitoring (Updated)",
  "uid": "n8n-performance-updated",
  "version": 1,
  "weekStart": ""
}
EOF

# Copy the updated dashboard to the Grafana dashboards directory
cp /home/dev/2-monitors/dashboards/n8n-monitoring-final.json /home/dev/2-monitors/grafana/data/dashboards/

# Restart Prometheus to apply the configuration changes
echo "Restarting Prometheus to apply configuration changes..."
docker restart monitors_prometheus

# Restart Grafana to pick up the new dashboard
echo "Restarting Grafana to apply dashboard changes..."
docker restart grafana

echo "Setup complete!"
echo ""
echo "To access the n8n dashboard:"
echo "- Go to Grafana at http://localhost:3091"
echo "- Login with your credentials"
echo "- Navigate to the 'n8n Performance Monitoring (Updated)' dashboard"
echo ""
echo "Note: Prometheus has been updated with proper n8n metrics scraping configuration."
echo "If metrics are still not showing, the n8n containers may need to be restarted to expose metrics on port 9464."
EOF