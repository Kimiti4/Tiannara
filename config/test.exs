import Config

# NOTE: the former `config :tiannara, Tiannara.Repo` block (incl. the Ecto
# SQL.Sandbox pool) was removed (2026-10-13 audit) — no Tiannara.Repo module
# exists and ecto is not a dependency of this app; the config was dead.

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tiannara, TiannaraWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Phase 3.5: Enable synchronous CEL boot so World services are available
config :tiannara, :test_mode, true

# LLMGateway: fixture responses in tests (no network). See llm_gateway.ex.
config :tiannara, :llm_mock, true

# Phase 3.5: Each test run gets its own DETS directory to isolate state.
# D-A5: System.unique_integer([:positive]) is process-local and repeats across
# fresh BEAM VMs — never use it alone as a cross-run isolation key. Combine
# OS-independent wall time, OS pid, and monotonic unique integer so sequential
# and concurrent fresh VMs cannot share a persistence root. TEST_PARTITION
# (same env var as the DB name) optionally pins an explicit partition.
test_run_id =
  case System.get_env("TEST_PARTITION") do
    nil ->
      "#{System.system_time(:nanosecond)}_pid#{:os.getpid()}_#{:erlang.unique_integer([:positive, :monotonic])}"

    "" ->
      "#{System.system_time(:nanosecond)}_pid#{:os.getpid()}_#{:erlang.unique_integer([:positive, :monotonic])}"

    partition when is_binary(partition) ->
      partition
  end

config :tiannara, :dets_base_path, "./test_data/dets/#{test_run_id}"
config :tiannara, :test_run_id, test_run_id

# Storage context: every artifact resolved through Tiannara.Storage.Paths
# lands under data/test/ during tests — never under the production or soak trees.
config :tiannara, :storage_context, "test"

# D-A5: non-DETS artifacts (checkpoints, reports, logs) also need a per-run root.
# Keeping storage_base under test_data means a concurrent/sequential run cannot
# mutate another run's mutable test tree; paths_test still pins the :test context
# segment via Paths.context().
config :tiannara, :storage_base, "./test_data/storage/#{test_run_id}"

# Phase 3.5: Disable telemetry handlers that slow down tests
config :tiannara, :telemetry_disabled, true

# Configure NATS for testing
config :tiannara, :nats,
  connection: [
    host: "nats://localhost:4222",
    name: "tiannara_nats_test",
    reconnect_time: 500,
    max_reconnect_attempts: 3
  ]

# Test specific configurations
config :tiannara, :test,
  mock_ird: true,
  mock_topology: true,
  fast_folding: true,
  chaos_injection: true

# Configure test metrics
config :tiannara, :telemetry,
  metrics: [
    [
      name: "tiannara.ontology.density",
      type: :gauge,
      unit: {1, :ontology_density},
      description: "Test ontology density metric"
    ]
  ]

# Test-specific topology settings
config :tiannara, :topology,
  # Lower threshold for faster testing
  persistence_threshold: 0.3,
  # Reduced dimension for performance
  max_dimension: 1,
  filtration_threshold: 0.05

# Test-specific conservation settings
config :tiannara, :conservation,
  causal_floor: 0.0,
  # Lower for testing
  semantic_floor: 0.85,
  complexity_ceiling: 0.9,
  information_threshold: 0.01

# Configure test timeouts
config :tiannara, :test_timeouts,
  stabilization_timeout: 5_000,
  compilation_timeout: 10_000,
  folding_timeout: 15_000
