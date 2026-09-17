import Config

config :observatory_core,
  env: :dev,
  database_url: "postgres://localhost:5432/observatory_core",
  cluster_mode: :standalone

config :observatory_api,
  cors_origins: "*"

config :observatory_api, ObservatoryApiWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 4000],
  secret_key_base: "dev-secret-key-base-change-in-production",
  pubsub_server: :observatory_pubsub

config :observatory_api, ObservatoryApi.WebSocket,
  pubsub: [name: :observatory_pubsub, adapter: Phoenix.PubSub.PG2]

config :event_store, EventStore.Repo,
  database: "observatory_event_store",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :metrics_engine, MetricsEngine.Repo,
  database: "observatory_metrics",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :replay_store, ReplayStore.Repo,
  database: "observatory_replay",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :rbac, Rbac.Repo,
  database: "observatory_rbac",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :rbac, jwt_secret: "dev-secret-change-in-production"

config :observatory_core, ObservatoryCore.Repo,
  database: "observatory_core",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :telemetry_gateway, TelemetryGateway.Repo,
  database: "telemetry_gateway",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :observation_bus, :tiannara_bridge,
  mode: :auto,
  url: System.get_env("TIANNARA_RUNTIME_URL", "http://localhost:4000"),
  node: (System.get_env("TIANNARA_RUNTIME_NODE") || "") |> then(&if(&1 == "", do: nil, else: String.to_atom(&1)))
