# Phase 17.7 — Digital Twin Replay Model

## 1. Replay Determinism

A Digital Twin simulation is replayable if and only if:

1. All constituent models are content-addressed and certified
2. The composition is content-addressed and certified
3. SimulationClock advances deterministically
4. Events are ordered by (tick, event_id)
5. Interventions are ordered by (tick, dependency, scheduled_id)
6. All random seeds are explicitly recorded in metadata
7. Every tick produces a replayable checkpoint
8. Archaeology records every state transition

## 2. Fingerprint Computation

```elixir
def fingerprint(twin) do
  excluded = [:twin_id, :archaeology_root, :created_at, :metadata,
              :replay_fingerprint, :certificate, :evidence_ledger]

  canonical =
    twin
    |> Map.from_struct()
    |> Map.drop(excluded)
    |> canonicalize_map()

  "fp_" <> (:crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower))
end
```

## 3. Tick-Level Checkpoint

```elixir
%ReplayCheckpoint{
  tick: 1000,
  twin_fingerprint: "fp_abc123",
  state_hash: "ts_def456",
  event_hashes: ["se_...", "se_..."],
  intervention_hashes: ["si_...", "si_..."],
  metrics_hash: "tm_ghi789",
  timestamp: "ISO 8601"
}
```

## 4. Replay Protocol

```
1. Load DigitalTwin from registry
2. Verify replay_fingerprint matches canonical form
3. Re-execute simulation from t=0 to t=N
4. Compare each tick's checkpoint with stored checkpoints
5. Report: verified | fingerprint_mismatch | tick_divergence(tick)
```

## 5. Replay Record

```elixir
%ReplayRecord{
  twin_id: "dt_...",
  replayed_at: "ISO 8601",
  original_fingerprint: "fp_abc123",
  computed_fingerprint: "fp_abc123",
  ticks_verified: 10000,
  divergent_tick: nil,
  verified: true
}
```

## 6. Replay Lifecycle

```
initialized → tick 0 fingerprint → tick 1 fingerprint → ...
→ tick N fingerprint → replayed → compared → verified
```
