# 🎯 Ollama Metrics Dashboard - Grafana Import Guide

## 📋 Overview
This guide will help you import the Ollama Metrics Dashboard into your Grafana instance at `https://grafana.avocado4ai.com`.

## 🎨 Dashboard Features

The dashboard includes 8 comprehensive panels:

1. **Loaded Models Count** - Shows total number of loaded models
2. **Total Model RAM Usage** - Displays combined RAM usage of all models
3. **Prompt Tokens Rate by Model** - Time series of prompt token usage
4. **Generated Tokens Rate by Model** - Time series of generated token usage
5. **Average Request Duration** - Performance metrics by model and endpoint
6. **Average Time Per Token** - Efficiency metrics by model
7. **Active Models Count** - Number of currently active models
8. **RAM Usage by Model** - Memory consumption breakdown

## 🚀 Import Instructions

### Step 1: Access Grafana
- Open your browser and navigate to: `https://grafana.avocado4ai.com`
- Log in with your credentials

### Step 2: Create Prometheus Data Source (if not already configured)

1. **Navigate to**: Configuration (⚙️) → Data Sources
2. **Click**: "Add data source"
3. **Select**: "Prometheus"
4. **Configure**:
   - **Name**: `Prometheus` (or your preferred name)
   - **URL**: `http://prometheus:9090` (or your Prometheus server URL)
   - **Access**: "Server" (default)
5. **Click**: "Save & Test"

### Step 3: Import the Dashboard

#### Method A: Import via JSON File (Recommended)

1. **Navigate to**: Dashboards (📊) → Import
2. **Click**: "Upload JSON file"
3. **Select**: The `ollama-metrics-dashboard.json` file
4. **Configure**:
   - **Name**: `Ollama Metrics Dashboard` (or keep default)
   - **Folder**: Select appropriate folder (e.g., "AI Monitoring")
   - **Prometheus Data Source**: Select the Prometheus data source you created
5. **Click**: "Import"

#### Method B: Import via Dashboard ID (Alternative)

1. **Navigate to**: Dashboards (📊) → Import
2. **Enter Dashboard ID**: `ollama-metrics-dashboard`
3. **Paste JSON**: Copy the entire content of `ollama-metrics-dashboard.json` and paste it
4. **Configure**:
   - **Name**: `Ollama Metrics Dashboard`
   - **Folder**: Select appropriate folder
   - **Prometheus Data Source**: Select your Prometheus data source
5. **Click**: "Import"

### Step 4: Verify Dashboard

1. **Navigate to**: Dashboards → Manage → Find "Ollama Metrics Dashboard"
2. **Click** on the dashboard to open it
3. **Verify**: All panels should show data (may take a few minutes to populate)

## 🔧 Troubleshooting

### No Data Showing?
- **Check Prometheus Data Source**: Ensure it's correctly configured and can reach your Prometheus server
- **Verify Metrics**: Run this query in Prometheus: `ollama_loaded_models`
- **Check Time Range**: Ensure the time range includes data (try "Last 1 hour")
- **Verify Scraping**: Ensure Prometheus is scraping the ollama-metrics endpoint

### Dashboard Not Found After Import?
- Check the folder you selected during import
- Try searching for "Ollama" in the dashboard search
- Verify the import was successful in the Grafana logs

## 📊 Prometheus Configuration

Ensure your Prometheus configuration includes the ollama-metrics target:

```yaml
scrape_configs:
  - job_name: 'ollama-metrics'
    scrape_interval: 15s
    static_configs:
      - targets: ['ollama-metrics:1313']
```

## 🎯 Metrics Reference

### Key Metrics Collected

| Metric | Type | Description |
|--------|------|-------------|
| `ollama_loaded_models` | Gauge | Total number of loaded models |
| `ollama_model_loaded` | Gauge | Binary indicator if model is loaded |
| `ollama_model_ram_mb` | Gauge | RAM usage per model in MB |
| `ollama_prompt_tokens_total` | Counter | Total prompt tokens by model |
| `ollama_generated_tokens_total` | Counter | Total generated tokens by model |
| `ollama_request_duration_seconds` | Histogram | Request duration by endpoint and model |
| `ollama_time_per_token_seconds` | Histogram | Time per token by model |

## 🔄 Refresh & Maintenance

- **Dashboard Refresh**: Set to 30 seconds (configurable)
- **Data Retention**: Configure in Prometheus based on your needs
- **Alerts**: Consider adding alerts for high RAM usage or failed requests

## 📈 Example Queries

### Top 5 Models by Token Usage
```promql
topk(5, sum(rate(ollama_generated_tokens_total[1h])) by (model))
```

### Average Request Duration (Last 5m)
```promql
avg(rate(ollama_request_duration_seconds_sum[5m]) / rate(ollama_request_duration_seconds_count[5m]))
```

### Total RAM Usage
```promql
sum(ollama_model_ram_mb)
```

## 🎉 Success!

Your Ollama Metrics Dashboard is now fully integrated with Grafana. You can monitor:
- ✅ Model performance and usage
- ✅ Resource consumption (RAM)
- ✅ Token generation rates
- ✅ Request latency and efficiency
- ✅ Real-time monitoring of your AI infrastructure

Enjoy your new monitoring capabilities! 🚀