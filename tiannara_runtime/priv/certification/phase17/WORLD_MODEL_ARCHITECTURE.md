# WORLD_MODEL_ARCHITECTURE.md

## Phase 17 — Constitutional World Modeling System Architecture

---

## 1. System Overview

The Constitutional World Modeling System (CWMS) transforms Tiannara from a discoverer of isolated knowledge into a builder of **executable models of reality**. Every model is deterministic, replayable, archaeologically explainable, mathematically verifiable, and constitutionally governed.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                 Downstream Consumers                     │
│   (Phase 18 Learning · Phase 19 Reasoning · Phase 20 COS) │
└────────────────────┬────────────────────────────────────┘
                     │ queries predictions counterfactuals
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Constitutional World Modeling System        │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐      │
│  │ Registry │  │ Builder  │  │ Prediction Engine │      │
│  │          │  │          │  │                  │      │
│  │ lifecycle│  │ symbolic │  │ forecasts        │      │
│  │ domain   │  │ prob.    │  │ confidence       │      │
│  │ lineage  │  │ diff eq  │  │ explanation      │      │
│  └────┬─────┘  └────┬─────┘  └───────┬──────────┘      │
│       │              │                │                  │
│  ┌────▼──────────────▼────────────────▼──────────┐      │
│  │           Causal Engine                       │      │
│  │  graphs · interventions · counterfactuals     │      │
│  └─────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐      │
│  │ Replay   │  │Archaeology│  │ Certificate      │      │
│  │ Engine   │  │ Engine    │  │ Issuer           │      │
│  └──────────┘  └──────────┘  └──────────────────┘      │
└────────────────────┬────────────────────────────────────┘
                     │ models · evidence · fingerprints
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Constitutional Foundations                  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Mathematics  │  │   Logic      │  │ Information  │  │
│  │ (Phase 16.X) │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Ownership

### Constitutional Ownership

The World Modeling System is owned by the **Constitutional Operating System** (Phase 20). No individual domain owns a model. Models are shared infrastructure.

**Ownership rules:**

| Aspect | Owner |
|--------|-------|
| Schema | Constitutional freeze (Phase 17.05) |
| Registry | CWMS runtime (Phase 17.9) |
| Builder | CWMS + Domain experts |
| Predictions | CWMS runtime |
| Evidence lineage | Phase 16.1 Observation Registry |
| Mathematical verification | Phase 16.X Mathematics Substrate |
| Certification | Phase 17.999 |

### Model Ownership

Each model has a **domain sponsor** but no domain **owns** it. Any domain may query any model. Models are public infrastructure.

---

## 3. Replay Architecture

Every world model operation must be replayable.

### Replay Scope

| Operation | Replay mechanism |
|-----------|-----------------|
| Model construction | Builder replay with identical evidence + config |
| Prediction | Prediction replay with model version + evidence |
| Intervention | Causal replay with do-operator inputs |
| Counterfactual | Branch replay with alternative history |
| Model merge | Merge replay with identical input models |
| Model evolution | Evolution replay with change log |

### Replay Root

Each model version has a **replay root** — the SHA-256 hash of:

```
model_id || version || state_space_fingerprint || evidence_root || builder_config || mathematical_proof_root
```

The replay root is the constitutional identifier for any model.

### Replay Contract

```elixir
@callback replay_model(model_id :: String.t(), version :: non_neg_integer()) ::
  {:ok, model_map()} | {:error, String.t()}

@callback replay_prediction(prediction_id :: String.t()) ::
  {:ok, prediction_map()} | {:error, String.t()}

@callback replay_intervention(model_id :: String.t(), intervention :: map()) ::
  {:ok, counterfactual_map()} | {:error, String.t()}
```

---

## 4. Provenance

Every model maintains a complete provenance chain.

### Provenance Fields

| Field | Description |
|-------|-------------|
| `model_id` | Content-addressed from genesis |
| `version` | Monotonic integer |
| `parent_id` | Previous version (nil for genesis) |
| `evidence_roots` | SHA-256 of all evidence used |
| `builder_log` | Deterministic log of builder operations |
| `mathematical_proof` | Proof of mathematical consistency |
| `certificate_root` | Validation certificate hash |
| `created_at` | ISO-8601 timestamp |
| `owner` | Domain sponsor |

### Evidence Lineage

Every variable in a model must trace back to specific observations or experiments in the Phase 16.1 Observation Registry.

No variable may exist without evidence ancestry. This is enforced constitutionally.

---

## 5. Mathematics Integration

The Phase 16.X Mathematics Substrate is the formal backbone of every world model.

### Integration Points

| Mathematical Service | World Model Usage |
|---|---|
| Symbolic representation (Service 1) | All model variables, parameters, equations |
| Symbolic reasoning (Service 2) | Equation simplification, formula rearrangement |
| Proof infrastructure (Service 3) | Verification of model consistency |
| Constraint solving (Service 5) | Model parameter bounds, structural constraints |
| Optimization (Service 6) | Model fitting, parameter estimation |
| Verification (Service 7) | Pre-acceptance mathematical consistency check |
| Knowledge Graph (Service 9) | Model dependencies, theorem references |
| Cross-domain translation (Service 10) | Model transfer between domains |

### Verification Pipeline

```
Domain expert proposes model
    ↓
Mathematical consistency check (ProofEngine)
    ↓
Causal soundness check (CausalEngine)
    ↓
Evidence lineage verification (ObservationRegistry)
    ↓
Prediction validation on held-out data
    ↓
Constitutional certification (CertificateIssuer)
```

---

## 6. Uncertainty Propagation

Every model must explicitly represent uncertainty.

### Uncertainty Types

| Type | Representation |
|------|---------------|
| Parameter uncertainty | Probability distributions over parameters |
| Structural uncertainty | Model averaging over candidate structures |
| Observational noise | Error models for each observable |
| Missing data | Sensitivity intervals |
| Model mismatch | Bounds on prediction error |

### Propagation Rule

Uncertainty must propagate through every transformation:

```
Input uncertainty
    ↓
Model computation (with uncertainty propagation)
    ↓
Output uncertainty (wider or equal to input)
    ↓
Prediction with confidence bounds
```

If uncertainty collapses without justification, the model is constitutionally invalid.

---

## 7. Causal Inference

Every world model must contain an explicit causal graph.

### Causal Requirements

| Requirement | Enforcement |
|-------------|-------------|
| Directed acyclic | GCK gate prohibits cycles |
| Intervention-addressable | do-calculus supported |
| Latent variable support | Unobserved confounders modeled |
| Counterfactual readiness | Structural causal model format |
| Replayable | Complete causal lineage |

### Causal Contract

```elixir
@callback causal_graph(model_id :: String.t()) ::
  {:ok, CausalGraph.t()} | {:error, String.t()}

@callback intervene(model_id :: String.t(), intervention :: Intervention.t()) ::
  {:ok, CounterfactualModel.t()} | {:error, String.t()}

@callback counterfactual(model_id :: String.t(), condition :: map()) ::
  {:ok, CounterfactualModel.t()} | {:error, String.t()}
```

---

## 8. Model Evolution

Models improve over time. Every evolution must be replayable.

### Evolution Types

| Type | Description |
|------|-------------|
| Parameter update | Re-estimate parameters with new evidence |
| Structural update | Add/remove variables or edges |
| Equation replacement | Replace governing equations |
| Hypothesis incorporation | Merge theory-derived constraints |
| Domain merger | Combine two domain models |

### Evolution Contract

```elixir
@callback evolve_model(model_id :: String.t(), update :: ModelUpdate.t()) ::
  {:ok, new_version :: non_neg_integer()} | {:error, String.t()}

@callback merge_models(model_id_a :: String.t(), model_id_b :: String.t()) ::
  {:ok, merged_model_id :: String.t()} | {:error, String.t()}
```

### Evolution Replay

Each evolution step is recorded in the model's change log. The full evolution chain is replayable from genesis to current version.

---

## 9. Scalability

### Computational Scaling

| Scale | Approach |
|-------|----------|
| Small (≤10 variables) | Full symbolic solution |
| Medium (10–10³ variables) | Hybrid symbolic-numeric |
| Large (10³–10⁶ variables) | Sparse numerical + approximation |
| Extreme (10⁶+) | Hierarchical decomposition |

### Storage Scaling

Models are content-addressed and stored in ETS (hot) + disk (warm) + archive (cold).

| Tier | Storage | Access |
|------|---------|--------|
| Hot | ETS named table | Sub-millisecond |
| Warm | Term file on disk | Milliseconds |
| Cold | Compressed archive | Seconds |

---

## 10. Validation Boundaries

### Boundary Rules

1. **No model may predict outside its evidence domain** without explicit extrapolation flags
2. **No model may claim certainty without quantified uncertainty**
3. **No model may conceal evidence gaps**
4. **No model may be used for decisions without constitutional certification**
5. **No model may operate outside its certified state space**

### Extrapolation Warning

When a model is queried outside its training evidence, it must return an `extrapolation_warning` flag alongside the prediction. Predictions without this flag are constitutionally invalid outside their evidence bounds.

---

*This document is Phase 17.0 deliverable. No implementation. Architecture subject to constitutional review before freeze.*
