Code.require_file("support/cold_ignition_helpers.exs", __DIR__)
Code.require_file("support/telemetry_assertions.exs", __DIR__)

# Fixed seed (matches root project): ExUnit's per-run random test order made
# shared-global-state tests order-dependent (observed at baseline
# e7f81b97: extra failures on some seeds, pass on others).
ExUnit.start(seed: 0)
