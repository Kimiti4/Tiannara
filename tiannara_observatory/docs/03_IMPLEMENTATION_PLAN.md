# Constitutional Observatory Core (COC) — Implementation Plan

## Development Order

The Observatory is built in 8 milestones of focused development.
Each milestone produces a working, testable, deployable increment.

---

## Milestone M1 — Umbrella Scaffold + Shared Types (Week 1)

**Goal:** Empty umbrella project compiles, apps can depend on each other, shared types exist.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 1.1 | Create umbrella mix project | root | `mix phx.new --umbrella` |
| 1.2 | Create `observatory_core` app | core | `mix phx.new` with Ecto |
| 1.3 | Create `shared` dep-free lib | shared | `TelemetryEvent` struct, constants |
| 1.4 | Create `observatory_api` app (no routes yet) | api | Phoenix skeleton, Endpoint, CORS |
| 1.5 | Create `rbac` app (no runtime deps yet) | rbac | `mix phx.new` with Ecto |
| 1.6 | Create `event_store` app (no routes) | event | Ecto repo, Event schema |
| 1.7 | Create `metrics_engine` app | metrics | Ecto repo, MetricPoint schema |
| 1.8 | Create `replay_store` app | replay | Ecto repo, Snapshot schema |
| 1.9 | Create `observatory_state` app | state | GenServer skeleton, ETS specs |
| 1.10 | Create `telemetry_gateway` app | gateway | Broadway pipeline skeleton |
| 1.11 | Create React scaffold | ui | `create-next-app`, Tailwind, shadcn |
| 1.12 | Wire app deps in umbrella | root | All apps depend correctly |
| 1.13 | Verify `mix compile --warnings-as-errors` | root | 0 warnings, 0 errors |
| 1.14 | Write umbrella integration test scaffold | root | Tests load all apps |

**Acceptance:** `mix test` passes at umbrella root. All 8 apps start.

**Estimated files:** ~60 files, ~3,000 lines

---

## Milestone M2 — RBAC + Configuration + Boot (Week 2)

**Goal:** Observatory starts, authenticates, configures itself.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 2.1 | Implement Configuration loader | core | Reads config.exs + env overrides |
| 2.2 | Implement Application + Supervisor | core | Starts all app supervisors |
| 2.3 | Implement Lifecycle module | core | `start/1`, `stop/0`, `status/0` |
| 2.4 | Implement User schema + migration | rbac | PG users table |
| 2.5 | Implement Role schema + assignment | rbac | PG roles table, role hierarchy |
| 2.6 | Implement Permission checker | rbac | `allowed?(user, resource, action)` |
| 2.7 | Implement JWT generation/validation | rbac | HS256 tokens, configurable TTL |
| 2.8 | Implement AuditLog | rbac | Append-only query audit table |
| 2.9 | Implement Auth plug | api | JWT verification on Phoenix routes |
| 2.10 | Implement RateLimit plug | api | Per-role rate limiter |
| 2.11 | Implement Audit plug | api | Logs all API queries |
| 2.12 | Dev-mode no-auth bypass | api | `config :rbac, enabled: false` |
| 2.13 | Seed script for dev users | rbac | Admin + demo users |
| 2.14 | Write tests | all | Unit tests for RBAC, lifecycle |

**Acceptance:** `Startup.start()` boots all apps. Auth plug returns 401 for invalid tokens, passes for valid. Dev mode bypasses auth.

**Estimated files:** ~40 files, ~2,500 lines

---

## Milestone M3 — Telemetry Gateway + Event Store (Week 3)

**Goal:** Runtime telemetry events are received, validated, stored, and queryable.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 3.1 | Implement Receiver | gateway | Attaches to `:telemetry` handlers |
| 3.2 | Implement NATS subscriber | gateway | Listens on `observatory.>` subjects |
| 3.3 | Implement Validator | gateway | Schema validation per domain |
| 3.4 | Implement Router | gateway | Routes to correct handler module |
| 3.5 | Implement per-domain handlers | gateway | 8 handler modules |
| 3.6 | Implement Buffer | gateway | Configurable in-memory buffer |
| 3.7 | Implement MetricsProxy | gateway | Forwards to metrics pipeline |
| 3.8 | Implement EventStore Writer | event | Append-only write with idempotency |
| 3.9 | Implement EventStore Reader | event | Query by ID, domain, time range |
| 3.10 | Implement Deduplicator | event | UUID-based dedup |
| 3.11 | Implement Orderer | event | Global ordering by timestamp |
| 3.12 | Implement Publisher | event | Broadcasts to WebSocket after write |
| 3.13 | Event table migration | event | PG: events (uuid, domain, type, payload, timestamp, runtime_gen...) |
| 3.14 | Write tests | all | Receiver, Validator, Writer, Reader |

**Acceptance:** Emitting a `[:observatory, :event, :test]` telemetry event results in a persisted row in `events` table within 50ms.

**Estimated files:** ~30 files, ~3,000 lines

---

## Milestone M4 — Metrics Engine + Observatory State (Week 4)

**Goal:** Metrics are aggregated from events, state is maintained in ETS, both are queryable.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 4.1 | Implement Counter | metrics | Increment/decrement/count |
| 4.2 | Implement Gauge | metrics | Set/get/trend |
| 4.3 | Implement Histogram | metrics | Configurable buckets, p50/p95/p99 |
| 4.4 | Implement TimeWindow | metrics | Windows: 1s, 5s, 30s, 5m, 1h, 24h |
| 4.5 | Implement Persistence | metrics | Write to PG MetricPoint table |
| 4.6 | Implement Query | metrics | Time-range queries with aggregation |
| 4.7 | MetricPoint table migration | metrics | TimescaleDB hypertable |
| 4.8 | MetricWindow table migration | metrics | Pre-aggregated windows |
| 4.9 | Implement Runtime state (ETS) | state | Runtime health, uptime, checkpoints |
| 4.10 | Implement Scientific state (ETS) | state | Discoveries, hypotheses, experiments |
| 4.11 | Implement Engineering state (ETS) | state | Designs, optimizations, TRL |
| 4.12 | Implement Knowledge state (ETS) | state | Concepts, theories, relationships |
| 4.13 | Implement Planetary state (ETS) | state | Earth-model metrics |
| 4.14 | Implement Civilization state (ETS) | state | Innovation index, Kardashev |
| 4.15 | Implement Evolution state (ETS) | state | Self-improvement, generations |
| 4.16 | Implement Governance state (ETS) | state | Drift, policies, violations |
| 4.17 | Implement Certification state (ETS) | state | Certification status per layer |
| 4.18 | Implement SnapshotScheduler | state | Periodic ETS → PG snapshots |
| 4.19 | Wire state update handlers | state | Subscribe to event_store updates |
| 4.20 | Write tests | all | All metrics and state modules |

**Acceptance:** 10,000 events ingested → all corresponding ETS state tables populated within 1 second. Metrics counters show correct values.

**Estimated files:** ~50 files, ~4,000 lines

---

## Milestone M5 — Replay Store + Phoenix API (Week 5)

**Goal:** Historical replay works, REST API exposes all observatory data.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 5.1 | Implement Snapshot creator | replay | Create ETS snapshot at checkpoint |
| 5.2 | Implement Timeline index | replay | Ordered checkpoint timeline |
| 5.3 | Implement Replay engine | replay | Reconstruct state at timestamp T |
| 5.4 | Implement Lineage tracker | replay | Causal parent → child tracking |
| 5.5 | Snapshot table migration | replay | PG snapshots table |
| 5.6 | Checkpoint table migration | replay | PG checkpoints table |
| 5.7 | Implement all REST controllers | api | 10 controllers, read-only |
| 5.8 | Implement StatusController | api | Health, subsystem status, versions |
| 5.9 | Implement EventsController | api | Query event history |
| 5.10 | Implement MetricsController | api | Query time-series metrics |
| 5.11 | Implement ReplayController | api | Query historical snapshots |
| 5.12 | Router — full route table | api | All routes + OpenAPI schema |
| 5.13 | Rate limit configuration | api | Per-endpoint rate limits |
| 5.14 | Write tests | all | Controller integration tests |

**Acceptance:** `GET /api/v1/runtime/health` returns 200 with valid JSON. `GET /api/v1/replay?timestamp=T` returns reconstructed state.

**Estimated files:** ~40 files, ~3,500 lines

---

## Milestone M6 — WebSocket Channels (Week 6)

**Goal:** Real-time streaming works for all observatory domains.

### Tasks

| # | Task | App | Deliverable |
|---|------|-----|-------------|
| 6.1 | Implement RuntimeChannel | api | Real-time runtime metrics stream |
| 6.2 | Implement MetricsChannel | api | Real-time metric counters |
| 6.3 | Implement ScienceChannel | api | Discovery/hypothesis/experiment feed |
| 6.4 | Implement EngineeringChannel | api | Design/optimization stream |
| 6.5 | Implement DiscoveryChannel | api | Discovery pipeline live feed |
| 6.6 | Implement ReplayChannel | api | Historical replay playback |
| 6.7 | Implement AlertsChannel | api | Critical event notifications |
| 6.8 | Implement CertificationChannel | api | Certification status changes |
| 6.9 | Channel auth middleware | api | WS auth via JWT handshake |
| 6.10 | Rate limiting on WS | api | Per-channel subscriber limits |
| 6.11 | Write tests | api | Channel integration tests |

**Acceptance:** Connecting to `ws://localhost:4000/ws/runtime` with valid token streams live runtime events. `ws://localhost:4000/ws/replay?timestamp=T` replays historical events.

**Estimated files:** ~15 files, ~2,000 lines

---

## Milestone M7 — React Mission Control UI (Week 7)

**Goal:** Navigation shell, widget grid, theme system, auth screen, status bar.

### Tasks

| # | Task | Deliverable |
|---|------|-------------|
| 7.1 | Next.js scaffold with TypeScript | Project compiles |
| 7.2 | Tailwind + shadcn/ui setup | Design system tokens |
| 7.3 | ThemeProvider | Dark-first, high contrast |
| 7.4 | Navigation sidebar | Collapsible, 10 sections |
| 7.5 | Top header bar | Breadcrumb, search, user menu |
| 7.6 | Status bar | Bottom bar, live from WS |
| 7.7 | WidgetGrid | Resizable, movable grid |
| 7.8 | Widget base component | Wrapper with title, refresh, close |
| 7.9 | AuthGuard + LoginScreen | JWT login flow |
| 7.10 | Layout persistence | Save/load layouts |
| 7.11 | API client library | Fetch + WebSocket wrappers |
| 7.12 | WebSocket hook | `useWebSocket(channel)` |
| 7.13 | WidgetPlaceholder | Skeleton loading state |
| 7.14 | Route page shells (10 pages) | Empty pages for each observatory |
| 7.15 | Build config | next.config.js for proxy |
| 7.16 | Tests | Component + integration tests |

**Acceptance:** Navigating to `/mission-control` shows a grid with placeholder widgets. Sidebar navigates to all 10 pages. Status bar shows live data. Layout is persisted on refresh.

**Estimated files:** ~80 files, ~8,000 lines

---

## Milestone M8 — Integration + Production Hardening (Week 8)

**Goal:** End-to-end working, tested, documented.

### Tasks

| # | Task | Deliverable |
|---|------|-------------|
| 8.1 | Wire Runtime telemetry → Event Store | End-to-end event flow |
| 8.2 | Wire Event Store → Metrics Engine | Metric aggregation |
| 8.3 | Wire Metrics Engine → State Engine | State population |
| 8.4 | Wire State Engine → Phoenix API | Query endpoints |
| 8.5 | Wire Phoenix API → React UI | Live dashboard |
| 8.6 | Load test: 10,000 events/sec | Performance report |
| 8.7 | Soak test: 24h continuous | Stability report |
| 8.8 | Failure recovery test | Kill/restart each component |
| 8.9 | Security audit | RBAC, auth, rate limits |
| 8.10 | Replay verification test | Deterministic replay across restarts |
| 8.11 | Documentation | README, API docs, architecture |
| 8.12 | CI/CD pipeline | GitHub Actions: test, build, deploy |

**Acceptance:** Full integration test suite passes. Observatory can ingest 10,000 events/sec, reconstruct any historical state from replay store, and survive component failures without data loss.

**Estimated files:** ~20 files, ~2,000 lines (tests + config)

---

## Summary

| Milestone | Focus | Files | Lines | Weeks |
|-----------|-------|-------|-------|-------|
| M1 | Umbrella scaffold | 60 | 3,000 | 1 |
| M2 | RBAC + Boot | 40 | 2,500 | 1 |
| M3 | Telemetry + Event Store | 30 | 3,000 | 1 |
| M4 | Metrics + State Engine | 50 | 4,000 | 1 |
| M5 | Replay + REST API | 40 | 3,500 | 1 |
| M6 | WebSocket Channels | 15 | 2,000 | 1 |
| M7 | React UI | 80 | 8,000 | 1 |
| M8 | Integration + Hardening | 20 | 2,000 | 1 |
| **Total** | | **~335** | **~28,000** | **8 weeks** |

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Telemetry volume overwhelms Event Store | Medium | High | Buffer + backpressure + auto-scaling PG |
| WebSocket auth bypass | Low | Critical | JWT verification in channel connect |
| ETS state diverges from PG | Medium | Medium | Periodic reconciliation + snapshot comparison |
| Runtime changes break telemetry schema | Medium | High | Validate at TelemetryGateway; reject unknown fields |
| Replay takes too long for large histories | Low | Medium | Incremental snapshots + parallel replay |
