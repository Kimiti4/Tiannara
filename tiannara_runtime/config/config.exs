import Config

# General application configuration
config :tiannara_runtime,
  namespace: TiannaraRuntime,
  version: "0.1.0",
  boot_profile: :stable,
  enable_nde: false,
  enable_twp: false,
  enable_osl: false

# NATS connection configuration
config :tiannara_runtime, TiannaraRuntime.NATS.ConnectionManager,
  server_url: System.get_env("NATS_URL", "nats://localhost:4222"),
  reconnect_delay_ms: 1000,
  max_reconnect_delay_ms: 60000

# CIS entropy monitoring configuration
config :tiannara_runtime, TiannaraRuntime.CIS.EntropyMonitor,
  monitoring_interval_ms: 5000,
  target_entropy_min: 0.60,
  target_entropy_max: 0.75,
  critical_threshold: 0.35,
  at_risk_threshold: 0.55

# GRCC ecology configuration
config :tiannara_runtime, TiannaraRuntime.GRCC.EcologySupervisor,
  max_identities: 100,
  initial_identity_count: 3

# Phoenix PubSub configuration
config :tiannara_runtime, TiannaraRuntime.PubSub,
  adapter: Phoenix.PubSub.PG2

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

# Environment-specific configurations
config :tiannara_runtime, TiannaraRuntimeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: TiannaraRuntimeWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: TiannaraRuntime.PubSub

import_config "opc.ex"

# Import environment specific config. Expected structure:
#
#     config/dev.exs
#     config/test.exs
#     config/prod.exs
#
import_config "#{Mix.env()}.exs"
