import Config

test_tmp =
  Path.expand("../_build/test/tmp/#{System.system_time(:millisecond)}", __DIR__)

# Test isolation: never write CPL events/checkpoints or Mnesia logs into the
# repository tree. These paths are absolute and live under the ignored
# _build/test directory.
config :tiannara_runtime, :test_tmp, test_tmp
config :tiannara_runtime, :cpl_storage_path, Path.join(test_tmp, "cpl")
config :tiannara_runtime, :omega_storage_path, Path.join(test_tmp, "omega")
config :mnesia, :dir, String.to_charlist(Path.join(test_tmp, "mnesia"))

config :forward_provenance,
       :identity_authority_ledger_path,
       Path.join(test_tmp, "identity_authority_ledger.jsonl")

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

# Removed 2026-10-20 (PHASE_5F_WIRING_AUDIT §4 item 5): the
# `start_app: false` key under TiannaraRuntime.Application was dead —
# grep of lib/ showed no consumer, so tests never disabled app boot;
# they booted the app implicitly (setup callbacks call
# Application.ensure_all_started/1). The key's comment claimed the
# opposite of what happened.
