# MODEL_PIPELINE.md

## Phase 17 — World Model Construction and Lifecycle Pipeline

---

## 1. Overview

The model pipeline transforms raw evidence into constitutionally certified world models. Every stage is deterministic, replayable, and archaeologically logged.

```
Evidence → Feature Extraction → Structure Learning → Parameter Estimation
    → Validation → Certification → Operational Deployment → Evolution
```

---

## 2. Pipeline Stages

### Stage 1 — Evidence Ingestion

**Input**: Observations from Phase 16.1 Observation Registry, experiments from Phase 14.2, external data.

**Process**:
1. Evidence is fetched from the Observation Registry by domain + time window
2. Each observation is fingerprinted (SHA-256 of canonical JSON)
3. Evidence roots are computed (Merkle tree of observation fingerprints)
4. Evidence is classified by type (controlled experiment, natural observation, simulation output)

**Output**: `EvidenceSet.t` with fingerprint root

**Replay key**: `evidence_root = hash(all_observation_fingerprints)`

---

### Stage 2 — Variable Specification

**Input**: Evidence set, optional domain expert guidance

**Process**:
1. Variables are extracted from evidence schema
2. Each variable gets: name, type (continuous, categorical, ordinal), domain bounds, unit
3. Variables are classified as endogenous (modeled) or exogenous (input)
4. Latent variables are proposed where evidence suggests unobserved confounders

**Output**: `VariableSet.t` with typed variable list

**Replay key**: `variable_root = hash(sorted variable specifications)`

---

### Stage 3 — Structure Learning

**Input**: Variable set, evidence set

**Process**:
1. Causal graph structure is learned from evidence using:
   - Constraint-based methods (PC, FCI) for conditional independence tests
   - Score-based methods (BGe, BIC) for graph search
   - Hybrid methods combining both
2. Domain expert may provide prior edges (must be flagged)
3. Every edge gets a confidence score
4. Cycles are rejected by GCK gate

**Output**: `CausalGraph.t` with nodes (variables) and directed edges

**Replay key**: `structure_root = hash(sorted edge list + confidence scores)`

---

### Stage 4 — Equation Learning

**Input**: Causal graph, evidence set

**Process**:
1. Governing equations are learned or assigned per variable:
   - Symbolic regression (discover equations from data)
   - Differential equation inference
   - Known physical laws (from Phase 16.X Mathematical Knowledge Graph)
   - Linear/nonlinear approximations
2. Equations are represented in the Phase 16.X symbolic form
3. Mathematical consistency is verified by ProofEngine

**Output**: `EquationSystem.t` with symbolic expressions per variable

**Replay key**: `equation_root = hash(sorted equations)`

---

### Stage 5 — Parameter Estimation

**Input**: Equation system, evidence set

**Process**:
1. Parameters are estimated using the Phase 16.X Optimization Engine
2. Uncertainty is computed (confidence intervals, posterior distributions)
3. Identifiability is checked (are parameters uniquely determined by evidence?)
4. Sensitivity analysis identifies which parameters most affect predictions

**Output**: `ParameterSet.t` with values and uncertainty distributions

**Replay key**: `parameter_root = hash(sorted parameters + uncertainty)`

---

### Stage 6 — Model Assembly

**Input**: Variable set, causal graph, equation system, parameter set

**Process**:
1. All components are assembled into a `WorldModel.t` struct
2. The model is fingerprinted (replay root computed)
3. Model is registered in the ModelRegistry with status `:draft`

**Output**: `WorldModel.t` with unique model_id

**Replay key**: `model_root = hash(variable_root || structure_root || equation_root || parameter_root)`

---

### Stage 7 — Validation

**Input**: World model, held-out evidence

**Process**:
1. Predictions are generated from the model
2. Predictions are compared against held-out observations
3. Metrics: RMSE, log-likelihood, coverage of confidence intervals, calibration
4. Causal validation: intervention predictions vs actual interventions
5. Cross-validation across different evidence subsets

**Output**: `ValidationEvidence.t` with metrics and pass/fail

**Status update**: Model transitions to `:validated` if all checks pass

---

### Stage 8 — Constitutional Certification

**Input**: Validated world model

**Process**:
1. Mathematical consistency verified (ProofEngine)
2. Causal soundness verified (CausalEngine)
3. Evidence lineage verified (ObservationRegistry)
4. Uncertainty correctness verified
5. Replay determinism verified
6. Certificate issued by CertificateIssuer

**Output**: `ModelCertificate.t` with certificate root

**Status update**: Model transitions to `:operational`

---

### Stage 9 — Deployment

**Input**: Certified world model

**Process**:
1. Model is published to the PredictionEngine
2. Model is available for queries from all downstream phases
3. Replay root is published to the constitutional ledger

**Output**: Operational status confirmed

**Status update**: Model transitions to `:operational`

---

### Stage 10 — Evolution

**Input**: Operational model + new evidence

**Process**:
1. New evidence triggers re-estimation
2. If parameter change only: update parameters (new version)
3. If structural change needed: rebuild affected stages
4. If complete revision needed: new model (new model_id)
5. Previous versions remain replayable

**Output**: New model version or new model_id

**Status update**: Previous version → `:deprecated`, new version → `:draft`

---

## 3. Lifecycle State Machine

```
                 ┌─────────┐
                 │  Draft  │
                 └────┬────┘
                      │ validation
                 ┌────▼────┐
                 │Validated│
                 └────┬────┘
                      │ certification
                 ┌────▼──────┐
                 │Operational│
                 └────┬──────┘
                      │
              ┌───────┴───────┐
              │               │
         ┌────▼────┐    ┌────▼──────┐
         │Deprecated│   │ Archived  │
         └─────────┘    └───────────┘
```

### State Transitions

| From | To | Trigger |
|------|----|---------|
| Draft | Validated | Validation passes |
| Validated | Operational | Certification issued |
| Operational | Deprecated | New version supersedes |
| Any | Archived | Inactivity threshold exceeded |
| Deprecated | Draft | New evidence triggers rebuild |
| Archived | Draft | Constitutional migration reactivation |

---

## 4. Pipeline Replay

Every stage of the pipeline is independently replayable.

```elixir
@callback replay_stage(model_id :: String.t(), stage :: atom(), config :: map()) ::
  {:ok, stage_output :: map()} | {:error, String.t()}

@callback replay_pipeline(model_id :: String.t()) ::
  {:ok, [stage_output]} | {:error, String.t()}
```

---

## 5. Failure Recovery

| Failure | Recovery |
|---------|----------|
| Evidence unavailable | Pipeline blocks with missing evidence report |
| Structure learning fails | Falls back to simpler structural model |
| Equations inconsistent | Reports contradiction to domain expert |
| Parameters unidentifiable | Reduces model complexity |
| Validation fails | Returns to draft with failure report |
| Certification fails | Blocks deployment with violation report |

---

*This document is Phase 17.0 deliverable. Pipeline subject to constitutional review before freeze.*
