import Config

# Configure the Elixir runtime system
config :tiannara, Tiannara,
  namespace: Tiannara

# Phase 3.5: Lazy DETS initialization
# Tables open on first access, not at supervisor startup
config :tiannara, :dets_lazy_init, true

# Phase 3.5: DETS file locations (isolated per environment)
if config_env() == :test do
  config :tiannara, :dets_base_path, "./test_data/dets"
else
  if config_env() == :dev do
    config :tiannara, :dets_base_path, "./dev_data/dets"
  else
    config :tiannara, :dets_base_path, "./data/dets"
  end
end

# Configure the Phoenix Endpoint and PubSub
config :tiannara, TiannaraWeb.Endpoint,
  pubsub_server: Tiannara.PubSub,
  render_errors: [
    formats: [html: TiannaraWeb.ErrorHTML, json: TiannaraWeb.ErrorJSON],
    layout: false
  ],
  live_view: [signing_salt: "GLgWBAqY04D6QQfC"]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure NATS/JetStream
config :tiannara, :nats,
  connection: [
    host: "nats://localhost:4222",
    name: "tiannara_nats",
    reconnect_time: 2_000,
    max_reconnect_attempts: 10
  ]

# Configure JetStream streams
config :tiannara, :jetstream,
  streams: %{
    "ird_proposals" => %{
      subjects: ["tiannara.ird.interventions"],
      retention: :limits,
      max_msgs: 10_000,
      max_bytes: 100_000_000
    },
    "stabilizer_outcomes" => %{
      subjects: ["tiannara.ird.outcomes.*"],
      retention: :limits,
      max_msgs: 5_000
    },
    "physics_compilation" => %{
      subjects: ["tiannara.opc.compile_request"],
      retention: :limits,
      max_msgs: 1_000
    }
  }

# Configure metrics collection
config :tiannara, :telemetry,
  metrics: [
    [
      name: "tiannara.ontology.density",
      type: :gauge,
      unit: {1, :ontology_density},
      description: "Global ontology density metric"
    ],
    [
      name: "tiannara.compute.pressure",
      type: :gauge,
      unit: {1, :compute_pressure},
      description: "Global compute pressure metric"
    ],
    [
      name: "tiannara.stability.equilibrium",
      type: :gauge,
      unit: {1, :stability_score},
      description: "Harmonic equilibrium score"
    ],
    [
      name: "tiannara.interference.variance",
      type: :gauge,
      unit: {1, :interference_variance},
      description: "Stabilizer interference variance"
    ]
  ]

# Configure persistent homology thresholds
config :tiannara, :topology,
  persistence_threshold: 0.5,
  max_dimension: 2,
  filtration_threshold: 0.01

# Configure conservation laws
config :tiannara, :conservation,
  causal_floor: 0.0,
  semantic_floor: 0.92,
  complexity_ceiling: 0.85,
  information_threshold: 0.001

# Configure folding parameters
config :tiannara, :folding,
  stability_plateau: 500,
  required_stability: 0.85,
  max_interference: 0.12,
  compression_ratio: 0.01

# Configure recursion governance
config :tiannara, :recursion,
  max_recursion_depth: 1000,
  stabilization_budget: 100.0,
  rate_limit_ms: 1000

# Configure sandbox layer
config :tiannara, :sandbox,
  observer_tiers: [:tier1, :tier2, :tier3, :tier4],
  kernel_isolation: true,
  substrate_abstraction: true

# ============================================================
# EFDI D1 (Signal Intelligence)
# Foundational contract layer for Epistemic Forecasting, Signal &
# Decision Intelligence. D1 models signals only — it does NOT forecast,
# calibrate, decide, or reason counterfactually (those are D2-D6).
# ============================================================
config :tiannara,
  # Persist signal registrations to ExecutiveMemory/EventStore (D1 uses ETS +
  # EventStore lineage; durable in-memory persistence lands in D6).
  efdi_persist_signals: true,
  # EFDI registry ETS table (also referenced by SignalRegistry).
  efdi_registry_table: :efdi_signal_registry

# SignalQuality dimension weights (must conceptually sum to 1.0) and recency
# half-life. Read by SignalQuality.config/0 as a flat map merged over defaults;
# D5 (Noise) may recalibrate these.
config :tiannara, :efdi_quality_weights,
  reliability: 0.30,
  recency: 0.15,
  completeness: 0.10,
  measurement: 0.10,
  independence: 0.15,
  persistence: 0.10,
  validity: 0.10,
  recency_half_life_hours: 24

# ============================================================
# Autonomous Software Civilization (ASC)
# Feature flag: set to true to start the ASC supervision tree.
# Keep false during REA simulation runs to isolate fault domains.
# ============================================================
config :tiannara, :asc,
  enabled: true,  # Enabled for Phase 5C.6 validation
  # Persistent project storage root (Q2 answer: Option C)
  project_data_dir: "data/asc_projects",
  # Deployment posture (Q3 answer: artifact generation only)
  deployment_mode: :artifact_only,
  # KnowledgeGraph write rate limit from ResearchBridge (nodes/sec)
  kg_write_rate_limit: 1,
  # Max KG nodes promoted per project
  kg_max_nodes_per_project: 10,
  # Crucible: max iterations before escalation
  crucible_max_iterations: 10,
  # API Evolution: minimum stability window before deprecation (ms)
  api_min_stability_window_ms: 259_200_000,
  # Observatory flush interval
  observatory_flush_ms: 60_000,
  # RepairLibrary: bounded ETS active working set (oldest-first eviction)
  repair_library_max_patterns: 20_000

config :tiannara,
  asc_required_workers: [
    %{
      role: :metrics,
      handler: Tiannara.ASC.Workers.Metrics,
      capabilities: [:metrics, :observation]
    },
    %{
      role: :research,
      handler: Tiannara.ASC.Workers.Research,
      capabilities: [:research, :retrieval]
    },
    %{
      role: :self_evaluation,
      handler: Tiannara.ASC.Workers.SelfEvaluation,
      capabilities: [:self_evaluation]
    },
    %{
      role: :evolution,
      handler: Tiannara.ASC.Workers.Evolution,
      capabilities: [:evolution]
    }
  ]

# Keep the 2 most recent archives per store (so the rollback source survives)
# and age out anything older than 30 minutes. Rotation caps each live store at
# `:dets_rotate_bytes`; together these bound total on-disk footprint so a 72h
# soak cannot die of ENOSPC. TTL 30 (not 60) keeps the live archive window
# small enough to leave comfortable headroom under the 20 GB-class disks the
# soak targets.
config :tiannara, :dets_retention_max_archives, 2
config :tiannara, :dets_archive_ttl_minutes, 30

# Import environment specific config
import_config "#{config_env()}.exs"