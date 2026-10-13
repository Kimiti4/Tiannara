import Config

# Production configuration.
#
# This file MUST exist: config/config.exs ends with
#   import_config "#{config_env()}.exs"
# so MIX_ENV=prod previously failed to even load configuration.

# Endpoint: bind all interfaces; PORT follows the common PaaS convention.
# SECRET_KEY_BASE is required — generate with: mix phx.gen.secret
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise "environment variable SECRET_KEY_BASE is missing " <>
            "(generate one with: mix phx.gen.secret)"

check_origin =
  case System.get_env("PHX_HOST") do
    nil -> true
    host -> ["//#{host}", "https://#{host}"]
  end

config :tiannara, TiannaraWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  server: true,
  secret_key_base: secret_key_base,
  code_reloader: false,
  debug: false,
  check_origin: check_origin

log_level =
  case System.get_env("LOG_LEVEL", "info") do
    "debug" -> :debug
    "info" -> :info
    "warn" -> :warning
    "error" -> :error
    _ -> :info
  end

config :logger, level: log_level

# Durable storage root (config.exs already defaults non-dev/test to ./data/dets;
# this makes the context explicit and env-overridable).
config :tiannara, :storage_context, System.get_env("STORAGE_CONTEXT", "production")
