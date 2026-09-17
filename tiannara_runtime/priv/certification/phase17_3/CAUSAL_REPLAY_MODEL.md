# CAUSAL_REPLAY_MODEL.md

## Phase 17.3 — Causal Discovery Replay Model

---

## 1. Replay Principles

Causal discovery replay guarantees that any causal graph can be reconstructed from:

1. The original evidence set (fingerprinted)
2. The pipeline configuration (recorded)
3. The deterministic seed (content-addressed)
4. The stage roots (independence, skeleton, orientation, scoring)

No runtime state, no hidden randomness, no external dependencies.

---

## 2. Replay Keys

Every stage of the causal pipeline produces a replay root:

| Stage | Root | Composition |
|-------|------|-------------|
| Independence | `independence_root` | SHA-256 of sorted test results |
| Skeleton | `skeleton_root` | SHA-256 of sorted adjacency list |
| Orientation | `orientation_root` | SHA-256 of sorted oriented edges |
| Score Refinement | `refinement_root` | SHA-256 of sorted edge scores |
| Hybrid Discovery | `hybrid_root` | SHA-256 of candidate graph fingerprints |
| Edge Scoring | `scoring_root` | SHA-256 of sorted edge scores |
| Latent Detection | `latent_root` | SHA-256 of sorted latent proposals |
| Validation | `validation_root` | SHA-256 of sorted check results |
| Intervention | `intervention_root` | SHA-256 of sorted intervention plans |
| Archaeology | `archaeology_root` | SHA-256 of sorted archaeology entries |

### Combined Root

```elixir
causal_root = SHA-256(
  independence_root ||
  skeleton_root ||
  orientation_root ||
  refinement_root ||
  scoring_root ||
  latent_root ||
  validation_root ||
  intervention_root ||
  archaeology_root
)
```

This becomes the `structure_root` in the Phase 17.2 pipeline, replacing the placeholder value.

---

## 3. Replay Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                     CAUSAL REPLAY FLOW                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Evidence Set + Config + Seed                                     │
│         │                                                         │
│         ▼                                                         │
│  ┌──────────────┐                                                 │
│  │  Replay Pipe  │──── independence_root ──── verify              │
│  └──────┬───────┘                                                 │
│         │                                                         │
│         ▼                                                         │
│  ┌──────────────┐                                                 │
│  │ Replay Skeleton│──── skeleton_root ──────── verify             │
│  └──────┬───────┘                                                 │
│         │                ┌─────────────────┐                      │
│         ├───────────────►│  Verify against   │                     │
│         │                │  stored roots     │                     │
│         │                └─────────────────┘                      │
│         ▼                                                         │
│  ... continue through all 10 stages ...                            │
│         │                                                         │
│         ▼                                                         │
│  ┌──────────────┐                                                 │
│  │Replay Archaeology│─── archaeology_root ──── verify             │
│  └──────┬───────┘                                                 │
│         │                                                         │
│         ▼                                                         │
│  Reconstructed CausalGraph with full provenance                    │
│                                                                  │
│  Result: {:ok, graph} | {:error, "root mismatch at stage N"}     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Replay API

```elixir
@callback replay_stage(stage :: atom(), config :: map(), evidence_set :: map()) ::
  {:ok, stage_output :: map()} | {:error, String.t()}

@callback replay_discovery(evidence_set :: map(), config :: map()) ::
  {:ok, %{causal_graph: CausalGraph.t(), causal_root: String.t()}} | {:error, String.t()}

@callback verify_replay(model_id :: String.t(), version :: non_neg_integer()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}} | {:error, String.t()}
```

---

## 5. Stage Replay Specifications

### 5.1 Independence Stage Replay

```elixir
def replay_stage(:independence, config, evidence_set) do
  # 1. Load config: {test_type, threshold, max_conditioning_size}
  # 2. Get variable list from evidence_set
  # 3. Generate sorted variable pairs
  # 4. For each pair, compute independence test deterministically
  # 5. Sort results by canonical ID
  # 6. Compute independence_root
  # 7. Return {:ok, %{results: [...], root: independence_root}}
end
```

### 5.2 Skeleton Stage Replay

```elixir
def replay_stage(:skeleton, config, %{independence_results: results}) do
  # 1. Build fully connected graph
  # 2. For each independence result where independent, remove edge
  # 3. Record separating set
  # 4. Compute skeleton_root
  # 5. Return {:ok, %{skeleton: ..., root: skeleton_root}}
end
```

### 5.3 Orientation Stage Replay

```elixir
def replay_stage(:orientation, config, %{skeleton: skeleton, independence_results: results}) do
  # 1. Detect v-structures using independence results
  # 2. Apply Meek rules in deterministic order
  # 3. Compute orientation_root
  # 4. Return {:ok, %{graph: ..., root: orientation_root}}
end
```

---

## 6. Replay Verification

```elixir
def verify_replay(model_id, version) do
  with {:ok, model} <- ModelRegistry.get_model(model_id, version),
       {:ok, evidence} <- fetch_evidence(model.evidence_roots),
       {:ok, discovery} <- replay_discovery(evidence, model.metadata.causal_config) do
    if discovery.causal_root == model.metadata.causal_root do
      {:ok, %{verified: true, mismatches: []}}
    else
      {:error, "Causal root mismatch"}
    end
  end
end
```

---

## 7. Determinism Guarantees

| Replay Component | Guarantee |
|-----------------|-----------|
| Independence tests | Deterministic given sorted variable pairs and canonical data |
| Skeleton construction | Deterministic given sorted independence results |
| Edge orientation | Deterministic given sorted v-structures and fixed rule ordering |
| Score computation | Deterministic given canonical data ordering |
| Latent detection | Deterministic given fixed thresholds (constitutional parameters) |
| Validation | Deterministic given purely structural checks |
| Intervention planning | Deterministic given do-calculus is an algorithm |
| Archaeology | Deterministic given full input trace |

---

## 8. Failure Recovery During Replay

| Failure | Recovery Action |
|---------|-----------------|
| Evidence root missing | Return `{:error, :evidence_unavailable}` |
| Independence root mismatch | Return mismatch with expected vs actual root |
| Skeleton root mismatch | Return mismatch with candidate edge differences |
| Orientation root mismatch | Return mismatch with oriented edge differences |
| Scoring root mismatch | Return mismatch with score differences |
| Graph contains cycle during replay | Return `{:error, :cycle_detected}` — constitutional violation |
| Archaeology root mismatch | Rebuild archaeology from replayed stages |

---

*This document is Phase 17.3.0 deliverable. Replay model subject to constitutional review before freeze.*
