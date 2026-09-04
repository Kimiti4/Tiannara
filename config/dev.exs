import Config

# Configure your database
config :tiannara, Tiannara.Repo,
  username: "postgres",
  password: "postgres",
  database: "tiannara_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we don't enforce a production password and allow
# " insecure access from any hostname".
config :tiannara, TiannaraWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  server: true,
  check_origin: false,
  code_reloader: true,
  debug: true,
  secret_key_base: "tiannara_dev_secret_key_base_change_in_production"

# Storage context: the soak server boots with STORAGE_CONTEXT=soak so its
# checkpoints/reports/logs land under data/soak/ — never the production tree.
# Default is "production" for interactive development.
config :tiannara, :storage_context, System.get_env("STORAGE_CONTEXT", "production")

# Configure NATS for development
config :tiannara, :nats,
  connection: [
    host: "nats://localhost:4222",
    name: "tiannara_nats_dev",
    reconnect_time: 1_000,
    max_reconnect_attempts: 5
  ]

# Development specific metrics
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
    ]
  ]

# Enable faster development cycles
config :tiannara, :development,
  fast_compilation: true,
  hot_reload_modules: true,
  debug_logging: true

# Configure persistent storage for development
config :tiannara, :storage,
  # 5 minutes
  ontology_cache_ttl: 300_000,
  # 5 seconds
  compute_metrics_interval: 5_000,
  audit_log_enabled: true
