# Generate 110 replay cycles with realistic simulation data
# Usage: mix run scripts/simulate_110_replay_cycles.exs

Code.require_file("lib/tiannara/sentinel/operational_observatory.ex")
alias Tiannara.Sentinel.OperationalObservatory

# Clear existing file
File.rm("data/simulation_events.ndjson")

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🚀 GENERATING 110 REPLAY CYCLES TO SIMULATION EVENT LOG")
IO.puts(String.duplicate("=", 80))

Enum.each(1..110, fn i ->
  id = "REA1-REPLAY-#{String.pad_leading("#{i}", 3, "0")}"
  is_novel = :rand.uniform() > 0.85 # ~15% novel discoveries
  
  expected_gain = 0.05 + (:rand.uniform() * 0.1)
  actual_gain = expected_gain + (:rand.uniform() * 0.1) - 0.05
  surprise = abs(actual_gain - expected_gain)

  # 1. Log proposed
  OperationalObservatory.log_state_transition(id, :proposed, %{
    type: :audit_tuning,
    description: "Replay simulation cycle #{i} testing adaptive threshold.",
    source: :replay,
    generated_by: :rea1,
    schema_version: 1
  }, :simulation)

  # 2. Log executed
  OperationalObservatory.log_state_transition(id, :executed, %{
    type: :audit_tuning,
    source: :replay,
    generated_by: :rea1,
    schema_version: 1
  }, :simulation)

  # 3. Log evaluated
  metrics = %{
    immediate_gain: actual_gain,
    long_term_gain: if(is_novel, do: 0.6 + (:rand.uniform() * 0.4), else: 0.1 + (:rand.uniform() * 0.3)),
    regression_cost: 0.02,
    reuse_count: if(is_novel, do: 3 + :rand.uniform(7), else: 0)
  }

  OperationalObservatory.log_state_transition(id, :evaluated, %{
    type: :audit_tuning,
    improvement: actual_gain,
    explanation: "Replay evaluation for cycle #{i}.",
    surprise_index: surprise,
    baseline: %{accuracy: 0.80},
    post: %{accuracy: 0.80 + actual_gain},
    source: :replay,
    generated_by: :rea1,
    is_novel_discovery: is_novel,
    prediction_accuracy: 0.80 + actual_gain,
    ghl: 100.0 + (:rand.uniform() * 50.0),
    result: :positive,
    metrics: metrics,
    schema_version: 1
  }, :simulation)
end)

# Retrieve counts to confirm
events = OperationalObservatory.load_events("data/simulation_events.ndjson")
evaluated_events = Enum.filter(events, fn ev -> ev[:status] in [:evaluated, "evaluated"] end)
novel_count = Enum.count(evaluated_events, & &1.is_novel_discovery)
IO.puts("✅ Successfully generated #{length(evaluated_events)} evaluated simulation events.")
IO.puts("✅ Detected #{novel_count} novel discoveries.")
IO.puts("📁 Event log saved to data/simulation_events.ndjson")
IO.puts(String.duplicate("=", 80) <> "\n")
