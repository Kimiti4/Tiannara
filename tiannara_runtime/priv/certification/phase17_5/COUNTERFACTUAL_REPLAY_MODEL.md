# Phase 17.5 — Counterfactual Replay Model

## 1. Replay Determinism

A counterfactual is replayable if and only if:

1. The parent world model is content-addressed and certified
2. The intervention is fully specified (type, target, operation, value, constraints)
3. The divergence point is deterministic (specific step + state)
4. All random seeds are explicitly recorded in metadata
5. The replay fingerprint is SHA-256 over canonical form
6. No external state (clock, network, filesystem) influences the branch

## 2. Fingerprint Computation

```elixir
def fingerprint(counterfactual) do
  excluded = [:counterfactual_id, :archaeology_root, :created_at, :metadata, :replay_fingerprint]

  canonical =
    counterfactual
    |> Map.from_struct()
    |> Map.drop(excluded)
    |> canonicalize_map()

  "fp_" <> (:crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower))
end
```

## 3. Replay Protocol

```
1. Load counterfactual from registry (or evidence)
2. Compute fingerprint from canonical form
3. Compare with stored replay_fingerprint
4. Re-execute branch generation from parent model + intervention
5. Compare re-executed timeline with stored timeline
6. Report: verified | fingerprint_mismatch | timeline_divergence
```

## 4. Replay Record

```elixir
%ReplayRecord{
  counterfactual_id: "cf_...",
  replayed_at: "ISO 8601",
  original_fingerprint: "fp_abc123",
  computed_fingerprint: "fp_abc123",
  timeline_match: true,
  steps_match: 100,
  steps_total: 100,
  verified: true
}
```

## 5. Archaeology Integration

Every replay attempt is recorded in CounterfactualArchaeology:

```elixir
CounterfactualArchaeology.record_replay(
  counterfactual_id,
  original_fingerprint,
  computed_fingerprint,
  verified
)
```

## 6. Replay Lifecycle

```
created → fingerprinted → stored → replayed → verified → archived
```

After first verification, a counterfactual may be replayed any number of times. Each replay produces an identical result or the counterfactual is marked as broken.
