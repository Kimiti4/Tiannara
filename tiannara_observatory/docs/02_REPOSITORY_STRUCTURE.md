# Constitutional Observatory Core (COC) — Repository Structure

## Umbrella Layout

```
tiannara_observatory/
│
├── mix.exs                          # Umbrella project definition
├── mix.lock
├── README.md
├── docs/
│   ├── 01_SYSTEM_DESIGN_SPECIFICATION.md
│   ├── 02_REPOSITORY_STRUCTURE.md
│   └── 03_IMPLEMENTATION_PLAN.md
│
├── config/
│   ├── config.exs                   # Shared configuration
│   ├── dev.exs                      # Dev overrides (localhost PG, no auth)
│   ├── test.exs                     # Test overrides (in-memory stores)
│   └── prod.exs                     # Production overrides (auth, clustering)
│
├── apps/
│   │
│   ├── observatory_core/            # OTP app: boot, lifecycle, supervision
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── observatory_core/
│   │   │       ├── application.ex           # Application start
│   │   │       ├── supervisor.ex            # Top-level supervisor
│   │   │       ├── config.ex                # Configuration loader
│   │   │       ├── lifecycle.ex             # Start/stop/restart orchestration
│   │   │       ├── node_discovery.ex        # Cluster node discovery
│   │   │       └── types/
│   │   │           ├── telemetry_event.ex   # TelemetryEvent struct
│   │   │           ├── widget.ex            # WidgetConfig struct
│   │   │           └── layout.ex            # LayoutConfig struct
│   │   ├── test/
│   │   │   ├── test_helper.exs
│   │   │   ├── observatory_core_test.exs
│   │   │   ├── lifecycle_test.exs
│   │   │   └── support/
│   │   │       └── event_factory.ex
│   │   └── priv/
│   │       └── migrations/          # Ecto migrations
│   │           └── 001_create_events.exs
│   │
│   ├── telemetry_gateway/           # OTP app: event ingestion
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── telemetry_gateway/
│   │   │       ├── supervisor.ex
│   │   │       ├── receiver.ex              # Listens for telemetry events
│   │   │       ├── validator.ex             # Schema validation
│   │   │       ├── router.ex                # Routes to correct pipeline
│   │   │       ├── handler/
│   │   │       │   ├── runtime_handler.ex   # Routes runtime events
│   │   │       │   ├── science_handler.ex   # Routes science events
│   │   │       │   ├── engineering_handler.ex
│   │   │       │   ├── discovery_handler.ex
│   │   │       │   ├── planetary_handler.ex
│   │   │       │   ├── certification_handler.ex
│   │   │       │   └── evolution_handler.ex
│   │   │       ├── buffer.ex                # In-memory buffer for backpressure
│   │   │       └── metrics_proxy.ex         # Forward to metrics pipeline
│   │   └── test/
│   │       ├── telemetry_gateway_test.exs
│   │       ├── receiver_test.exs
│   │       └── validator_test.exs
│   │
│   ├── event_store/                 # OTP app: immutable event storage
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── event_store/
│   │   │       ├── supervisor.ex
│   │   │       ├── writer.ex                # Append-only event writer
│   │   │       ├── reader.ex                # Event query interface
│   │   │       ├── deduplicator.ex          # Idempotency on replay
│   │   │       ├── orderer.ex               # Global event ordering
│   │   │       ├── publisher.ex             # Publish to WebSocket channels
│   │   │       ├── schema/
│   │   │       │   ├── event.ex             # Ecto schema
│   │   │       │   └── migration.ex
│   │   │       └── repo.ex                  # Ecto repo
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/
│   │   │           └── 001_create_events_table.exs
│   │   ├── test/
│   │   │   ├── event_store_test.exs
│   │   │   ├── writer_test.exs
│   │   │   └── reader_test.exs
│   │   └── mix.exs
│   │
│   ├── metrics_engine/              # OTP app: metrics aggregation
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── metrics_engine/
│   │   │       ├── supervisor.ex
│   │   │       ├── counter.ex              # Counter aggregation
│   │   │       ├── gauge.ex                # Gauge tracking
│   │   │       ├── histogram.ex            # Histogram with percentiles
│   │   │       ├── time_window.ex          # Time-windowed aggregation
│   │   │       ├── persistence.ex          # Write to PG
│   │   │       ├── query.ex                # Query interface
│   │   │       ├── schema/
│   │   │       │   ├── metric_point.ex
│   │   │       │   └── metric_window.ex
│   │   │       └── repo.ex
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/
│   │   │           ├── 001_create_metric_points.exs
│   │   │           └── 002_create_metric_windows.exs
│   │   └── test/
│   │       ├── metrics_engine_test.exs
│   │       ├── counter_test.exs
│   │       └── query_test.exs
│   │
│   ├── replay_store/                # OTP app: checkpoint snapshots & replay
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── replay_store/
│   │   │       ├── supervisor.ex
│   │   │       ├── snapshot.ex            # Snapshot creation
│   │   │       ├── timeline.ex            # Timeline index
│   │   │       ├── replay.ex              # Replay reconstruction
│   │   │       ├── lineage.ex             # Causal lineage tracking
│   │   │       ├── schema/
│   │   │       │   ├── snapshot.ex
│   │   │       │   ├── checkpoint.ex
│   │   │       │   └── replay_event.ex
│   │   │       └── repo.ex
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/
│   │   └── test/
│   │       ├── replay_store_test.exs
│   │       ├── snapshot_test.exs
│   │       └── replay_test.exs
│   │
│   ├── observatory_state/           # OTP app: in-memory state engine
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── observatory_state/
│   │   │       ├── supervisor.ex
│   │   │       ├── runtime.ex             # ETS: runtime state
│   │   │       ├── scientific.ex          # ETS: scientific state
│   │   │       ├── engineering.ex         # ETS: engineering state
│   │   │       ├── knowledge.ex           # ETS: knowledge state
│   │   │       ├── planetary.ex           # ETS: planetary state
│   │   │       ├── civilization.ex        # ETS: civilization state
│   │   │       ├── evolution.ex           # ETS: evolution state
│   │   │       ├── governance.ex          # ETS: governance state
│   │   │       ├── certification.ex       # ETS: certification state
│   │   │       └── snapshot_scheduler.ex  # Periodic snapshot to PG
│   │   └── test/
│   │       ├── observatory_state_test.exs
│   │       └── runtime_test.exs
│   │
│   ├── observatory_api/             # OTP app: Phoenix API + WebSocket
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── observatory_api/
│   │   │       ├── application.ex
│   │   │       ├── endpoint.ex            # Phoenix Endpoint
│   │   │       ├── router.ex              # REST routes
│   │   │       ├── channels/
│   │   │       │   ├── runtime_channel.ex
│   │   │       │   ├── metrics_channel.ex
│   │   │       │   ├── science_channel.ex
│   │   │       │   ├── engineering_channel.ex
│   │   │       │   ├── discovery_channel.ex
│   │   │       │   ├── replay_channel.ex
│   │   │       │   ├── alerts_channel.ex
│   │   │       │   └── certification_channel.ex
│   │   │       ├── controllers/
│   │   │       │   ├── runtime_controller.ex
│   │   │       │   ├── science_controller.ex
│   │   │       │   ├── engineering_controller.ex
│   │   │       │   ├── discovery_controller.ex
│   │   │       │   ├── planet_controller.ex
│   │   │       │   ├── civilization_controller.ex
│   │   │       │   ├── replay_controller.ex
│   │   │       │   ├── certification_controller.ex
│   │   │       │   ├── metrics_controller.ex
│   │   │       │   ├── events_controller.ex
│   │   │       │   └── status_controller.ex
│   │   │       ├── plugs/
│   │   │       │   ├── auth.ex
│   │   │       │   ├── rate_limit.ex
│   │   │       │   └── audit_log.ex
│   │   │       ├── views/
│   │   │       │   └── error_view.ex
│   │   │       └── telemetry_exporter.ex  # Export OTEL traces for self-obs
│   │   ├── test/
│   │   │   ├── support/
│   │   │   │   └── channel_case.ex
│   │   │   ├── router_test.exs
│   │   │   ├── runtime_controller_test.exs
│   │   │   └── channels/
│   │   │       ├── runtime_channel_test.exs
│   │   │       └── metrics_channel_test.exs
│   │   └── priv/
│   │       └── static/                    # React build output
│   │
│   ├── rbac/                         # OTP app: auth, roles, permissions
│   │   ├── mix.exs
│   │   ├── README.md
│   │   ├── lib/
│   │   │   └── rbac/
│   │   │       ├── supervisor.ex
│   │   │       ├── role.ex               # Role enum and hierarchy
│   │   │       ├── permission.ex          # Permission checks
│   │   │       ├── user.ex               # User schema
│   │   │       ├── token.ex              # JWT generation/validation
│   │   │       ├── audit_log.ex          # Query audit log
│   │   │       ├── schema/
│   │   │       │   ├── user.ex
│   │   │       │   ├── role_assignment.ex
│   │   │       │   └── audit_entry.ex
│   │   │       └── repo.ex
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/
│   │   │           ├── 001_create_users.exs
│   │   │           ├── 002_create_roles.exs
│   │   │           └── 003_create_audit_log.exs
│   │   └── test/
│   │       ├── rbac_test.exs
│   │       ├── permission_test.exs
│   │       └── token_test.exs
│   │
│   └── observatory_ui/              # React app: Mission Control UI
│       ├── package.json
│       ├── tsconfig.json
│       ├── tailwind.config.ts
│       ├── next.config.js
│       ├── src/
│       │   ├── app/
│       │   │   ├── layout.tsx            # Root shell
│       │   │   ├── page.tsx              # Dashboard redirect
│       │   │   ├── login/
│       │   │   │   └── page.tsx
│       │   │   ├── mission-control/
│       │   │   │   └── page.tsx          # Main widget grid
│       │   │   ├── runtime/
│       │   │   ├── science/
│       │   │   ├── engineering/
│       │   │   ├── knowledge/
│       │   │   ├── planet/
│       │   │   ├── civilization/
│       │   │   ├── replay/
│       │   │   ├── archaeology/
│       │   │   ├── certification/
│       │   │   └── settings/
│       │   ├── components/
│       │   │   ├── layout/
│       │   │   │   ├── Navigation.tsx     # Sidebar nav
│       │   │   │   ├── StatusBar.tsx      # Bottom status bar
│       │   │   │   ├── Header.tsx         # Top bar
│       │   │   │   └── WidgetGrid.tsx     # Grid container
│       │   │   ├── widgets/
│       │   │   │   ├── Widget.tsx         # Base widget wrapper
│       │   │   │   ├── WidgetHeader.tsx
│       │   │   │   └── WidgetPlaceholder.tsx
│       │   │   ├── auth/
│       │   │   │   └── AuthGuard.tsx
│       │   │   └── theme/
│       │   │       └── ThemeProvider.tsx
│       │   ├── lib/
│       │   │   ├── api.ts                 # API client
│       │   │   └── websocket.ts           # WebSocket client
│       │   └── types/
│       │       ├── telemetry.ts
│       │       ├── widget.ts
│       │       └── layout.ts
│       └── public/
│
├── shared/                           # Shared Elixir types/config (dep-free)
│   └── lib/
│       └── shared/
│           ├── types.ex                  # Shared type definitions
│           └── constants.ex              # Shared constants
│
├── test/                             # Top-level integration tests
│   ├── test_helper.exs
│   ├── telemetry_pipeline_test.exs
│   ├── auth_integration_test.exs
│   └── support/
│       └── integration_case.ex
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── test.yml
│       └── deploy.yml
│
└── scripts/
    ├── setup.sh                      # Create databases, run migrations
    ├── seed.exs                      # Seed demo data
    └── start_dev.sh                  # Launch all services
```

## App Dependencies

```
observatory_core    → (standalone — foundation)
telemetry_gateway   → observatory_core (types)
event_store         → observatory_core (types), telemetry_gateway (events)
metrics_engine     → observatory_core (types), telemetry_gateway (metrics)
replay_store       → observatory_core (types), event_store (query)
observatory_state  → observatory_core (types), event_store (replay)
observatory_api    → all apps (queries each)
rbac               → observatory_core (types) — no runtime dependency
observatory_ui     → observatory_api (REST + WS)
```

No circular dependencies. Each app depends only on apps lower in the dependency chain.

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| OTP app | snake_case | `observatory_core` |
| Elixir module | PascalCase, app-prefixed | `ObservatoryCore.Supervisor` |
| ETS table | atom, `:obs_` prefix | `:obs_runtime_state` |
| Telemetry event | dotted notation | `[:observatory, :event, :ingested]` |
| NATS subject | dotted path | `observatory.runtime.checkpoint` |
| PostgreSQL table | snake_case, domain prefix | `runtime_checkpoints` |
| Phoenix route | kebab-case | `/api/v1/runtime/health` |
| WebSocket channel | `"obs:"` prefix | `"obs:metrics"` |
| React component | PascalCase | `WidgetGrid` |
| CSS class | kebab-case | `mission-control-grid` |
| Migration | sequential | `001_create_events_table.exs` |

## Configuration Hierarchy

```
1. config/config.exs          — defaults
2. config/{dev,test,prod}.exs — environment overrides
3. System.get_env / runtime   — runtime overrides
4. Application.get_env        — code fallbacks
```
