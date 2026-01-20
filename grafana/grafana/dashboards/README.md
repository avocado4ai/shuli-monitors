# Grafana dashboards

This directory is bind mounted into the Grafana container at `/var/lib/grafana/dashboards` so the dashboard JSON snapshots live in the repository and survive volume recreation.

- Drop any new dashboard JSON here and restart Grafana to have it provisioned automatically.
- Use this folder as the backup source you can copy or export whenever you need to restore dashboards.
- The Docker Compose file already mounts `./grafana/dashboards` with `:ro`, so keep files under version control before reloading Grafana.
