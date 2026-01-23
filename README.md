## Infra · Self-Hosted

This repository is my personal playground for self-hosting.

It’s where I experiment, break things, fix them, and slowly build intuition
about how real systems behave - networking, isolation, observability, reproducibility, and
resource constraints included.

---

This repository is a space for infrastructure tinkering - opinionated, imperfect, and evolving - built primarily to learn by doing.
<br>Nothing here is “enterprise-grade”. Most decisions here come from curiosity, constraints, and iteration.

---

> [!NOTE]
> Specifics about services live in <a href="https://github.com/Manaswa-S/Infra-SelfHosted/blob/main/SERVICES.md">SERVICES.md</a>.

### Mental Model

The entire setup revolves around ***isolation first***, then ***explicit connectivity***.

Services live in clearly separated network groups, communicate only when needed,
and are brought up gently - one at a time - to respect limited system resources.

- One service = one folder
- Each service is self-contained
- No shared compose files
- No bind-mounted `./` volumes - only named Docker volumes

This keeps services portable, replaceable, and mentally simple.

```text
├── <service-name>/     # One folder per service
    ├── docker-compose.yaml
    ├── .env
    └── prepare.sh      # optional pre-flight script
```

---

### Network Groups

| Network | Purpose | Who lives here |
|-------|------|----------------|
| `edge_net` | Public-facing edge, reverse proxy | Caddy |
| `metrics_net` | Visibility, metrics & monitoring | Prometheus, Grafana, exporters |
| `db_net` | State, databases | Postgres, Redis, etc |
| `apps_net` | App mesh, core application network | n8n, gitea, etc |

Each service explicitly joins only the networks it actually needs.

---

### Startup Flow

Services are not started all at once.
Startup is **ordered, paced, and resource-aware**.

#### High-level flow
1. System boots
2. Wait for CPU & memory to stabilize
3. Initialize required Docker networks
4. Start services sequentially
    - Iterates through service folders
    - Runs `prepare.sh` if present
5. Pause between services to avoid resource starvation

#### Ordering
Services are started based on a simple, explicit list:
- Edge & routing
- Databases
- Monitoring
- Application services (one at a time)

The startup order is defined by a manually ordered list of service groups - just deliberate sequencing.

---

### Automation Scripts

| Script | Responsibility |
|------|----------------|
| `install.docker.sh` | Docker installation, if required |
| `networks.docker.sh` | Initialize all network groups |
| `startup.sh` | Ordered, resource-aware startup |
| `shutdown.sh` | Graceful shutdown of all services |

---

### What’s missing (future plans)

- No formal secrets management
- No automated failure handling or self-healing
- No database lifecycle automation (yet)
- No config templating or abstraction layers
- No automated update or rollout mechanisms
- No scaling automation
- No “one command to rule them all”
- No CI/CD or deployment pipelines

These are areas I haven’t reached yet. They come later or may stay manual while the fundamentals sink in.

