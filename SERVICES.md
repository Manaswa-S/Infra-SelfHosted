# Self-Hosted Services

This is a list of all active self-hosted services, their ports, and URLs.

| Service      | Port | URL                       | Notes                     |
|-------------|------|---------------------------|---------------------------|
| Caddy       | 443, 80  | https://host.mnswa.me     | Reverse proxy / HTTPS     |
| Prometheus  | 9090 | https://prometheus.mnswa.me | Metrics monitoring       |
| Grafana     | 3000 | https://grafana.mnswa.me | Dashboard visualization  |
| Gitea       | 3000 | https://gitea.mnswa.me   | Git repositories / SCM    |
| Node Exporter | 9100 | N/A                       | System metrics (Prometheus) |
| PostgreSQL | 5432 | N/A                       | Common Database Instance |

---

## Notes

- All URLs are served via Caddy reverse proxy with HTTPS.
- Ports listed are either internal container ports or exposed host ports.
- Some services (like Node Exporter) are internal metrics exporters and not meant to be accessed directly.
