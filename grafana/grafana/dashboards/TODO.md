# TODO

- [x] Create the Docling & Docling MCP Grafana dashboard JSON (panels, templating, instructions) and save it as `grafana-docling-dashboard.json`, swapping in the real Prometheus/Loki datasource UIDs.
- [x] Fix `n8n-monitoring.json` by removing the outer `{"dashboard": {...}}` wrapper so the top-level object contains the `title`, panels, etc., allowing Grafana provisioning to read it.
- [ ] Confirm Grafana's provisioning config points at `/home/dev/n8n-pstg/grafana/dashboards` and reload/restart Grafana so it picks up the corrected dashboards.
- [ ] Ensure Prometheus is scraping Docling Serve and Docling MCP metrics (e.g., `http_requests_total`, `docling_job_queue_length`) from the node exporter and Docling exporters so the new dashboard panels resolve.
