import Config

# Test environment configuration
config :tiannara_runtime, TiannaraRuntimeWeb.Endpoint,
  http: [port: 4001],
  server: false

# Logger configuration for tests - reduce noise
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning

# NATS configuration for tests (use same as dev but tests handle connection failures gracefully)
config :tiannara_runtime, TiannaraRuntime.NATS.ConnectionManager,
  server_url: System.get_env("NATS_URL", "nats://localhost:4222"),
  reconnect_delay_ms: 500,
  max_reconnect_attempts: 3

# CIS entropy monitoring - disable during tests
config :tiannara_runtime, TiannaraRuntime.CIS.EntropyMonitor,
  monitoring_interval_ms: :infinity,
  target_entropy_min: 0.60,
  target_entropy_max: 0.75,
  critical_threshold: 0.35,
  at_risk_threshold: 0.55

# GRCC ecology - minimal configuration for tests
config :tiannara_runtime, TiannaraRuntime.GRCC.EcologySupervisor,
  max_identities: 10,
  initial_identity_count: 1

# Phoenix PubSub configuration
config :tiannara_runtime, TiannaraRuntime.PubSub,
  adapter: Phoenix.PubSub.PG2

# ExUnit configuration
config :ex_unit,
  timeout: 30_000,  # 30 seconds timeout for integration tests
  capture_log: true

# Disable application startup for tests - modules are tested independently
config :tiannara_runtime, TiannaraRuntime.Application,
  start_app: false
