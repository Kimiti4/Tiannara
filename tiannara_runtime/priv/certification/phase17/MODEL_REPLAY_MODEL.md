# MODEL_REPLAY_MODEL.md

## Phase 17 — World Model Replay Architecture

---

## 1. Replay Principle

Every world model operation must be **deterministically reproducible** from immutable artifacts alone.

Replay is not debugging. Replay is the constitutional guarantee that any prediction, intervention, or counterfactual can be independently reconstructed without trusting the runtime that originally produced it.

---

## 2. Replay Roots

Every model artifact has a **replay root** — a SHA-256 hash that uniquely identifies the artifact's complete provenance.

### Root Hierarchy

```
Evidence Root
    ├── observation_1_fingerprint
    ├── observation_2_fingerprint
    └── ...

Variable Root
    ├── variable_spec_1_hash
    ├── variable_spec_2_hash
    └── ...

Structure Root
    ├── edge_1_hash (source, target, type, confidence)
    ├── edge_2_hash
    └── ...

Equation Root
    ├── equation_1_hash (symbolic expression)
    ├── equation_2_hash
    └── ...

Parameter Root
    ├── parameter_1_hash (value, distribution)
    ├── parameter_2_hash
    └── ...

Model Root = hash(
    evidence_root || variable_root || structure_root ||
    equation_root || parameter_root || builder_config_hash
)

Prediction Root = hash(
    model_root || model_version || input_state_hash || prediction_config_hash
)

Intervention Root = hash(
    model_root || model_version || intervention_hash
)

Counterfactual Root = hash(
    model_root || model_version || intervention_hash || base_prediction_root
)
```

---

## 3. Replay Engine

### Core Functions

```elixir
@callback replay_model(model_id :: String.t(), version :: non_neg_integer()) ::
  {:ok, WorldModel.t()} | {:error, String.t()}

@callback replay_prediction(prediction_id :: String.t()) ::
  {:ok, Prediction.t()} | {:error, String.t()}

@callback replay_intervention(intervention_id :: String.t()) ::
  {:ok, CounterfactualModel.t()} | {:error, String.t()}

@callback replay_counterfactual(counterfactual_id :: String.t()) ::
  {:ok, CounterfactualModel.t()} | {:error, String.t()}

@callback replay_evolution(model_id :: String.t(), from_version :: non_neg_integer(), to_version :: non_neg_integer()) ::
  {:ok, [EvolutionStep.t()]} | {:error, String.t()}

@callback replay_pipeline(model_id :: String.t()) ::
  {:ok, [PipelineStage.t()]} | {:error, String.t()}
```

### Storage

Replay data is stored in three tiers:

| Tier | Storage | Content | Latency |
|------|---------|---------|---------|
| Hot | ETS named tables | Active model versions, recent predictions | <1ms |
| Warm | Term files on disk | All model versions, all predictions | <10ms |
| Cold | Compressed archive | Archived models, historical predictions | <1s |

### Replay Registry

A dedicated ETS table maps:

```
prediction_id -> {model_id, version, input_state_fingerprint, output_fingerprint, created_at}
model_id -> {current_version, status, fingerprint}
```

---

## 4. Replay Determinism Guarantees

### What is guaranteed deterministic:

| Operation | Determinism source |
|-----------|-------------------|
| Model construction | Fixed evidence + fixed builder config → identical model |
| Prediction | Fixed model + fixed input → identical forecast |
| Intervention | Fixed model + fixed intervention → identical counterfactual |
| Model merge | Fixed input models + fixed merge config → identical merged model |
| Evolution step | Fixed model + fixed evidence → identical new version |
| Fingerprint | Fixed content → identical hash |

### What is NOT guaranteed deterministic:

| Operation | Non-determinism source | Mitigation |
|-----------|----------------------|------------|
| Structure learning | Randomized search | Seed recorded in builder config |
| Parameter estimation | MCMC sampling | Seed recorded, full trace stored |
| Optimization | Stochastic algorithms | Seed recorded, all candidates stored |

---

## 5. Replay Verification

### Automated Verification

The replay engine periodically verifies:

1. **Model replay**: Reconstruct every operational model from evidence
2. **Prediction replay**: Reconstruct every recent prediction
3. **Cross-validation**: Replay with independent auditor
4. **Fingerprint consistency**: Verify all replay roots

### Constitutional Check

```elixir
def verify_replay_determinism(model_id, version) do
  original = load_model(model_id, version)
  replayed = replay_model(model_id, version)

  case replayed do
    {:ok, ^original} -> :pass
    {:ok, different} -> {:fail, fingerprint_mismatch(different)}
    {:error, reason} -> {:error, reason}
  end
end
```

Only models that pass `verify_replay_determinism/2` may remain `:operational`.

---

## 6. Independent Replay

The independent auditor (Phase 17.96 counterpart to Phase 16.X.96) consumes only:

- Model ledgers (serialized replay roots)
- Evidence archives
- Builder configuration logs

It reconstructs every model from these artifacts alone, without importing the CWMS runtime. This guarantees that replay determinism is not an artifact of runtime state.

---

## 7. Archaeology Integration

Every replay operation is also an archaeology operation. The Replay Engine and Archaeology Engine share a unified interface:

```elixir
@callback replay_with_archaeology(model_id :: String.t(), version :: non_neg_integer()) ::
  {:ok, {%WorldModel{} = model, ArchaeologyReport.t()}} | {:error, String.t()}
```

The archaeology report contains:

- Evidence lineage for every variable
- Derivation path for every equation
- Estimation history for every parameter
- Certification chain for every version

---

*This document is Phase 17.0 deliverable. Replay model subject to constitutional freeze in Phase 17.05.*
