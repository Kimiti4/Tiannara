import Config

config :tiannara_runtime, Tiannara.OPC,
  compile_interval_ms: 5_000,
  max_batch_events: 200,
  invariant_threshold: 3
