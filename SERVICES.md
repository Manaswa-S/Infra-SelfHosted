### Services & Internals

This document lists how things are actually wired together: networks, storage, and URLs'.

---
> Simple by design.
---
> Note: All endpoints are secured via basic caddy authentication to mitigate bot scraping.
---

### Service Matrix

| Service     | Category     | Internal Port(s) | Exposed Port(s)     | URL / Endpoint            | Networks Joined              | Storage |
|------------|--------------|------------------|----------------------|---------------------------|------------------------------|---------|
| Caddy      | Edge         | 80, 443          | 80 → 80<br>443 → 443 | -                         | edge_net                     | None    |
| Prometheus | Monitoring   | 9090             | -                    | -                         | metrics_net                  | prometheus_data  |
| Grafana    | Monitoring   | 3000             | -                    | https://grafana.mnswa.me  | metrics_net, edge_net        | grafana_data  |
| Node Exporter | Monitoring | 9100            | -                    | -                         | metrics_net                  | None
| Postgres   | Database     | 5432             | -                    | -                         | db_net                       | postgres  |
| n8n        | Apps   | 5678             | -                    | https://n8n.mnswa.me      | apps_net, edge_net           | n8n_data |
| Gitea      | Apps       | 3090, 22         | 22 → 2222            | https://gitea.mnswa.me    | edge_net, apps_net, db_net   | gitea_data  |

---

### Closing note

This setup grows organically.
Things change when they stop making sense.
Nothing here is sacred.
