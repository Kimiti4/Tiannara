# Tiannara Constitutional Observatory Core

Real-time streaming observatory platform for Tiannara's Runtime — 9 Elixir/Phoenix apps + Next.js Mission Control UI.

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     Mission Control UI (Next.js)                │
│  apps/observatory_ui/  —  Glass-morphism dashboard, 10 panels  │
└────────────────────────────┬───────────────────────────────────┘
                             │ /api/* proxy → :4000, /ws → :4000
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                     Observatory API (Phoenix)                   │
│  apps/observatory_api/  —  REST + WebSocket (14 channels)      │
├────────────────────────────────────────────────────────────────┤
│  apps/telemetry_gateway/   —  Ingest, validate, dedup, route    │
│  apps/event_store/         —  Persistent event log              │
│  apps/metrics_engine/      —  Counters, gauges, trends, alerts  │
│  apps/observatory_state/   —  ETS state tables + snapshots      │
│  apps/replay_store/        —  Replay, archaeology, divergence   │
│  apps/rbac/                —  JWT auth, policies, audit         │
│  apps/shared/              —  Common types and constants        │
│  apps/observatory_core/    —  Core domain logic                 │
└────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Prerequisites: Elixir 1.18+, OTP 27+, Node 22+, PostgreSQL 16+

# Setup Elixir apps
mix deps.get
mix compile --warnings-as-errors

# Setup database (requires running PostgreSQL)
mix ecto.create
mix ecto.migrate

# Start Elixir API server (port 4000)
mix phx.server

# In another terminal, start the UI (port 3000)
cd apps/observatory_ui
npm install
npm run dev
```

Open http://localhost:3000/mission-control

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/status` | System health & uptime |
| GET | `/api/v1/runtime/health` | OTP & runtime health |
| GET | `/api/v1/runtime/metrics` | Runtime metrics |
| GET | `/api/v1/events` | Event list (filter by `?domain=`) |
| GET | `/api/v1/events/:id` | Single event |
| GET | `/api/v1/metrics` | All counters |
| GET | `/api/v1/metrics/:name` | Single metric |
| GET | `/api/v1/metrics/:name/trend` | Trend analysis |
| GET | `/api/v1/metrics/:name/forecast` | Forecast |
| GET | `/api/v1/metrics/query` | Time-range query |
| GET | `/api/v1/replay` | State reconstruction |
| GET | `/api/v1/replay/compare` | Comparative replay |
| GET | `/api/v1/replay/timeline` | Timeline jumps |
| GET | `/api/v1/replay/snapshots` | Snapshot list |
| GET | `/api/v1/replay/archaeology` | Event archaeology |
| GET | `/api/v1/replay/divergence` | Divergence report |
| GET | `/api/v1/science` | Scientific state |
| GET | `/api/v1/engineering` | Engineering state |
| GET | `/api/v1/knowledge` | Knowledge state |
| GET | `/api/v1/planetary` | Planetary state |
| GET | `/api/v1/civilization` | Civilization state |
| GET | `/api/v1/evolution` | Evolution state |
| GET | `/api/v1/governance` | Governance state |
| GET | `/api/v1/certification` | Certification state |

## WebSocket Channels

Connect to `ws://localhost:4000/ws` and join a topic:
- `obs:status` — System status updates
- `obs:runtime` — Runtime events
- `obs:science` — Scientific events
- `obs:engineering` — Engineering events
- `obs:knowledge` — Knowledge events
- `obs:theory` — Theory ecology events
- `obs:evolution` — Evolution events
- `obs:certification` — Certification events
- `obs:planetary` — Planetary events
- `obs:civilization` — Civilization events
- `obs:replay` — Replay events
- `obs:alerts` — Alert stream
- `obs:metrics` — Metric stream
- `obs:control` — General control stream

## Mission Control UI

The dashboard at `/mission-control` shows 10 + panels in a responive grid:

1. Constitutional Observatory
2. Runtime Observatory
3. Scientific Discovery
4. Engineering
5. Knowledge
6. Planetary (health bars)
7. Civilization (innovation index)
8. Evolution (timeline)
9. Certification
10. Archaeology & Replay

Sidebar navigation opens per-room focused views with draggable/resizable widgets.

## Deployment

### Docker

```bash
# Build images
docker build -f Dockerfile.api -t tiannara/observatory-api:latest .
docker build -f Dockerfile.ui -t tiannara/observatory-ui:latest .

# Run
docker run -d -p 4000:4000 --name obs-api tiannara/observatory-api:latest
docker run -d -p 3000:3000 --name obs-ui tiannara/observatory-ui:latest
```

### Production Config

Set environment variables:
- `PORT` — API port (default: 4000)
- `DATABASE_URL` — PostgreSQL connection string
- `SECRET_KEY_BASE` — Phoenix secret key
- `PHX_HOST` — Public hostname
- `PHX_SERVER=true` — Enable Phoenix server
- `NEXT_PUBLIC_API_URL` — API URL for the UI
- `NEXT_PUBLIC_WS_URL` — WebSocket URL for the UI

## Testing

```bash
# Elixir tests (from umbrella root)
MIX_ENV=test mix test

# UI tests
cd apps/observatory_ui && npm test
```

## CI/CD

GitHub Actions workflows in `.github/workflows/ci.yml`:
- **elixir_ci**: Compile (warnings as errors) + test + format check
- **node_ci**: Lint + TypeScript check + test + build
- **docker_build**: Build API + UI Docker images on main

## License

Constitutional OS — Prime Directive: Expand Knowledge. Preserve Life. Ensure Prosperity.
