import Config

# Development environment configuration
config :tiannara_runtime, TiannaraRuntimeWeb.Endpoint,
  http: [port: 8004],
  server: true,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Logger configuration for development
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug

# NATS configuration for development
config :tiannara_runtime, TiannaraRuntime.NATS.ConnectionManager,
  server_url: System.get_env("NATS_URL", "nats://localhost:4222")
