# Phase 17.6 — World Composition Replay Model

## 1. Replay Determinism

A composition is replayable if and only if:

1. Every constituent world model is content-addressed and certified
2. All domain interfaces are frozen (content-addressed)
3. Shared variable resolution is deterministic (consistent priority rules)
4. Synchronization rules are explicit, complete, and frozen
5. The world graph is constructed by deterministic topological ordering
6. All random seeds are explicitly recorded in metadata
7. The replay fingerprint is SHA-256 over canonical form

## 2. Fingerprint Computation

```elixir
def fingerprint(composition) do
  excluded = [:composition_id, :archaeology_root, :created_at, :metadata, 
              :replay_fingerprint, :certificate]

  canonical =
    composition
    |> Map.from_struct()
    |> Map.drop(excluded)
    |> canonicalize_map()

  "fp_" <> (:crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower))
end
```

## 3. Replay Protocol

```
1. Load composition from registry
2. Compute fingerprint from canonical form
3. Compare with stored replay_fingerprint
4. Re-execute composition from constituent models + interfaces
5. Compare re-executed world graph with stored world graph
6. Report: verified | fingerprint_mismatch | graph_divergence
```

## 4. Replay Record

```elixir
%ReplayRecord{
  composition_id: "cw_...",
  replayed_at: "ISO 8601",
  original_fingerprint: "fp_abc123",
  computed_fingerprint: "fp_abc123",
  graph_match: true,
  nodes_match: 150,
  edges_match: 300,
  verified: true
}
```

## 5. Archaeology Integration

```elixir
CompositionArchaeology.record_replay(
  composition_id,
  original_fingerprint,
  computed_fingerprint,
  verified
)
```

## 6. Replay Lifecycle

```
composed → fingerprinted → stored → replayed → verified → archived
```

After first verification, a composition may be replayed any number of times. Each replay produces an identical world graph or the composition is marked as broken.
