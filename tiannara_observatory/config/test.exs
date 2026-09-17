import Config

# Test environment — no database connections

config :observatory_core,
  env: :test

config :rbac,
  jwt_secret: "test-secret"
