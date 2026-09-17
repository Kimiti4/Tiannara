# CAUSAL_RUNTIME_FREEZE.md

## Phase 17.3.05 — Constitutional Freeze: Causal Discovery Runtime

---

## 1. Scope

This document freezes the contracts (schemas, APIs, behaviours) for the Phase 17.3 Causal Structure Learning subsystem.

**Already frozen in Phase 17.05** (not redefined here):
- `CausalNode`, `CausalEdge`, `CausalGraph` — `ontology/causal_graph.ex`
- `Intervention`, `CounterfactualModel` — `ontology/intervention.ex`
- `ProbabilityDistribution`, `Interval` — `ontology/probability_distribution.ex`
- `Variable` — `ontology/variable.ex`

**New freeze scope (Phase 17.3.05):**
- Schemas: IndependenceResult, Skeleton, StructureCandidate, EdgeScore, DiscoveryEvidence, LatentVariable, CausalArchaeology, ArchaeologyEntry, CausalValidationResult, ValidationCheck, IndependentAuditReport
- APIs: IndependenceEngine, StructureLearner, EdgeScorer, GraphValidator, InterventionEngine, CausalReplay, CausalArchaeology
- Behaviours: StructureLearning, IndependenceTesting, CausalReplay, CausalValidation

---

## 2. Schema Definitions

### 2.1 IndependenceResult

```elixir
@enforce_keys [:variable_a, :variable_b, :test_type]
defstruct [
  :result_id,           # content-addressed: ir_ + SHA-256(var_a || var_b || conditioning)
  :variable_a,          # variable_id
  :variable_b,          # variable_id
  :conditioning_set,    # [variable_id] — empty for marginal
  :test_type,           # :conditional | :marginal
  :statistic,           # float
  :p_value,             # float
  :confidence,          # float 0..1
  :dof,                 # non_neg_integer
  :sample_size,         # non_neg_integer
  :evidence_root,       # String.t()
  :metadata             # map()
]
```

**Validation rules:**
- `variable_a` and `variable_b` must be non-empty and different
- `test_type` must be `:conditional` or `:marginal`
- `p_value` must be in `[0.0, 1.0]`
- `confidence` must be in `[0.0, 1.0]`
- `evidence_root` must be a valid SHA-256 hex string

---

### 2.2 Skeleton

```elixir
@enforce_keys [:nodes]
defstruct [
  :skeleton_id,         # content-addressed: sk_ + SHA-256(sorted adjacency)
  :nodes,               # [variable_id]
  :adjacency,           # %{variable_id => [variable_id]} — undirected, sorted
  :separating_sets,     # %{{a, b} => [variable_id]}
  :fingerprint          # String.t() | nil
]
```

**Validation rules:**
- All `nodes` entries are non-empty strings
- `adjacency` keys are a subset of `nodes`
- Each adjacency value list is sorted
- `separating_sets` keys are `{a, b}` with `a < b` (canonical order)

---

### 2.3 StructureCandidate

```elixir
@enforce_keys [:edges, :score]
defstruct [
  :candidate_id,        # content-addressed: sc_ + SHA-256(canonical edges || score)
  :edges,               # [{source, target, type, confidence}]
  :score,               # float
  :score_type,          # :bge | :bic | :custom
  :derivation,          # :constraint_based | :score_based | :hybrid | :expert
  :parent_graph,        # candidate_id | nil
  :mutations,           # [map()] — changes from parent
  :confidence,          # float 0..1
  :metadata             # map()
]
```

**Validation rules:**
- `edges` must form a DAG (validated at construction)
- `score_type` must be one of `:bge`, `:bic`, `:custom`
- `derivation` must be one of `:constraint_based`, `:score_based`, `:hybrid`, `:expert`
- `parent_graph` when non-nil must reference an existing candidate

---

### 2.4 EdgeScore

```elixir
@enforce_keys [:source, :target]
defstruct [
  :edge_id,              # content-addressed: es_ + SHA-256(source || target || context)
  :source,               # variable_id
  :target,               # variable_id
  :evidence_support,     # float 0..1
  :statistical_strength, # float 0..1
  :stability,            # float 0..1
  :replay_confidence,    # float 0..1
  :intervention_compat,  # float 0..1
  :overall,              # float 0..1
  :weight_vector,        # [float] — weights used for overall
  :metadata              # map()
]
```

**Validation rules:**
- All score fields must be in `[0.0, 1.0]`
- `weight_vector` must have length 5 (one per component metric)
- `source` and `target` must be different

---

### 2.5 DiscoveryEvidence

```elixir
@enforce_keys [:stage]
defstruct [
  :discovery_id,        # content-addressed: de_ + SHA-256(canonical context)
  :stage,               # :independence | :skeleton | :orientation | :scoring | :latent | :validation | :intervention
  :input_roots,         # [String.t()]
  :output_root,         # String.t()
  :config,              # map()
  :created_at           # ISO-8601
]
```

**Validation rules:**
- `stage` must match one of the defined stage atoms
- `input_roots` must be non-empty for all stages except the first
- `output_root` must be a valid SHA-256 hex string

---

### 2.6 LatentVariable

```elixir
@enforce_keys [:manifest_variables]
defstruct [
  :latent_id,            # content-addressed: lv_ + SHA-256(canonical config)
  :name,                 # String.t()
  :manifest_variables,   # [variable_id] — at least 2
  :confidence,           # float 0..1
  :detection_method,     # :residual_correlation | :mediation_gap | :expert
  :competing_explanations, # [[variable_id]]
  :supporting_observations, # [String.t()] — evidence roots
  :metadata              # map()
]
```

**Validation rules:**
- `manifest_variables` must have length >= 2
- `detection_method` must be one of `:residual_correlation`, `:mediation_gap`, `:expert`

---

### 2.7 CausalArchaeology

```elixir
@enforce_keys [:model_id, :entries]
defstruct [
  :archaeology_id,       # content-addressed: ca_ + SHA-256(sorted entry fingerprints)
  :model_id,             # String.t() — references ModelRegistry
  :entries,              # [ArchaeologyEntry.t]
  :fingerprint           # String.t() | nil
]
```

### 2.8 ArchaeologyEntry

```elixir
@enforce_keys [:stage, :description]
defstruct [
  :entry_id,             # content-addressed: ae_ + SHA-256(canonical entry)
  :stage,                # atom — which pipeline stage
  :description,          # String.t()
  :input_fingerprints,   # [String.t()]
  :output_fingerprints,  # [String.t()]
  :alternatives,         # [String.t()] — rejected alternative fingerprints
  :evidence_roots,       # [String.t()]
  :confidence,           # float 0..1 | nil
  :metadata              # map()
]
```

**Validation rules:**
- `stage` must be a valid pipeline stage atom
- All fingerprint fields must be valid SHA-256 hex strings when non-nil

---

### 2.9 CausalValidationResult

```elixir
@enforce_keys [:graph_fingerprint, :checks]
defstruct [
  :validation_id,        # content-addressed
  :graph_fingerprint,    # String.t()
  :checks,              # [ValidationCheck.t]
  :overall,             # :pass | :fail | :inconclusive
  :created_at           # ISO-8601
]
```

### 2.10 ValidationCheck

```elixir
@enforce_keys [:check_name, :status]
defstruct [
  :check_name,           # String.t()
  :status,               # :pass | :fail | :skipped
  :details,              # String.t() | nil
  :fingerprint           # String.t() | nil
]
```

---

### 2.11 IndependentAuditReport

```elixir
@enforce_keys [:graph_fingerprint, :overall]
defstruct [
  :audit_id,             # content-addressed
  :graph_fingerprint,    # String.t()
  :overall,              # :pass | :fail | :inconclusive
  :findings,             # [map()]
  :replay_result,        # :match | :mismatch | :unavailable
  :evidence_coverage,    # float 0..1
  :violations,           # [String.t()]
  :issued_at,            # ISO-8601
  :issued_by             # :auditor
]
```

---

## 3. API Contracts

### 3.1 IndependenceEngine

```
Module: TiannaraRuntime.CausalDiscovery.IndependenceEngine

Purpose: Compute conditional and marginal independence tests
         deterministically from evidence.

Functions:

  compute_all_pairs(variables, evidence_set, opts)
    -> {:ok, [IndependenceResult.t]}
    opts: [:test_type, :max_conditioning_size, :alpha, :correction]
    Deterministic: variable pairs sorted canonically, test order fixed.

  compute_conditional(a, b, conditioning, evidence_set)
    -> {:ok, IndependenceResult.t} | {:error, String.t()}
    Deterministic: canonical data ordering, fixed random seed from content.

  compute_marginal(a, b, evidence_set)
    -> {:ok, IndependenceResult.t} | {:error, String.t()}

  compute_given_skeleton(skeleton, evidence_set, opts)
    -> {:ok, [IndependenceResult.t]}
    Tests only pairs adjacent in skeleton (PC algorithm optimization).

  result_fingerprint(result)
    -> String.t() — content-addressed SHA-256

  replay_results(independence_root)
    -> {:ok, [IndependenceResult.t]} | {:error, :not_found}
```

### 3.2 StructureLearner

```
Module: TiannaraRuntime.CausalDiscovery.StructureLearner

Purpose: Learn causal graph structure from independence results.

Functions:

  discover_skeleton(independence_results, variables, opts)
    -> {:ok, Skeleton.t}
    opts: [:alpha, :max_conditioning_size, :adjacency_priority]
    PC algorithm skeleton phase.

  orient_edges(skeleton, independence_results, opts)
    -> {:ok, CausalGraph.t}
    V-structure detection + Meek rule application.

  score_refine(graph, evidence_set, opts)
    -> {:ok, StructureCandidate.t}
    BGe/BIC scoring + greedy hill-climbing.

  hybrid_discover(independence_results, evidence_set, opts)
    -> {:ok, StructureCandidate.t}
    PC skeleton + score-based refinement + constraint-locked edges.

  generate_candidates(graph, evidence_set, opts)
    -> {:ok, [StructureCandidate.t]}
    Generate alternative graphs by single-edge mutations.
```

### 3.3 EdgeScorer

```
Module: TiannaraRuntime.CausalDiscovery.EdgeScorer

Purpose: Score and rank causal edges with multi-metric evaluation.

Functions:

  score_edge(source, target, independence_results, evidence_set, opts)
    -> {:ok, EdgeScore.t}
    Computes evidence_support, statistical_strength, stability,
    replay_confidence, intervention_compat.

  score_graph(graph, independence_results, evidence_set, opts)
    -> {:ok, [EdgeScore.t]}
    Score all edges in a graph.

  rank_by_metric(edge_scores, metric)
    -> [EdgeScore.t] — sorted descending

  edge_fingerprint(edge_score)
    -> String.t() — content-addressed SHA-256
```

### 3.4 GraphValidator

```
Module: TiannaraRuntime.CausalDiscovery.GraphValidator

Purpose: Validate causal graph structure and constitutional compliance.

Functions:

  validate_acyclic(graph)
    -> :ok | {:error, [String.t()]}
    DFS-based cycle detection.

  validate_reachability(graph)
    -> :ok | {:error, [String.t()]}
    Every node reachable from at least one exogenous variable.

  validate_do_calculus(graph)
    -> {:ok, 1 | 2 | 3}
    Compute do-calculus level from graph structure.

  validate_intervention_safety(graph, intervention)
    -> :ok | {:error, String.t()}
    Verify intervention is valid for the graph.

  validate_replay(graph, evidence_set, config)
    -> :ok | {:error, String.t()}
    Re-run discovery and verify stage roots match.

  validate_all(graph, opts)
    -> {:ok, CausalValidationResult.t}
    Run all validation checks and return combined result.
```

### 3.5 InterventionEngine

```
Module: TiannaraRuntime.CausalDiscovery.InterventionEngine

Purpose: Plan and analyze interventions given a causal graph.

Functions:

  plan_intervention(graph, target_variable, set_value, opts)
    -> {:ok, InterventionPlan.t} | {:error, String.t()}
    opts: [:do_operator, :conditional_values]

  identify_controllable(graph)
    -> [variable_id]
    Variables that can be directly intervened upon.

  trace_pathway(graph, source, target)
    -> {:ok, [variable_id]} | {:error, :no_path}

  predict_effect(graph, intervention, target)
    -> {:ok, %{expected: float, confidence_interval: Interval.t}} | {:error, String.t()}

  verify_identifiability(graph, intervention, target)
    -> :identified | :partial | :non_identifiable
```

### 3.6 CausalReplay

```
Module: TiannaraRuntime.CausalDiscovery.CausalReplay

Purpose: Deterministic replay of causal discovery pipeline.

Functions:

  replay_stage(stage, config, evidence_set)
    -> {:ok, map()} | {:error, String.t()}
    Replay a single pipeline stage. Stages:
    :independence, :skeleton, :orientation, :refinement, :hybrid,
    :scoring, :latent, :validation, :intervention

  replay_discovery(evidence_set, config)
    -> {:ok, %{causal_graph: CausalGraph.t(), causal_root: String.t()}}

  verify_replay(model_id, version)
    -> {:ok, %{verified: boolean(), mismatches: [String.t()]}}
       | {:error, String.t()}

  compare_stage_roots(actual, expected)
    -> {:ok, %{match: boolean(), differences: [String.t()]}}
```

### 3.7 CausalArchaeology

```
Module: TiannaraRuntime.CausalDiscovery.CausalArchaeology

Purpose: Full lineage tracking for every causal discovery decision.

Functions:

  record_entry(stage, input, output, alternatives, evidence_roots, opts)
    -> {:ok, ArchaeologyEntry.t}

  record_edge_origin(edge_id, independence_result, score, context)
    -> {:ok, ArchaeologyEntry.t}

  get_lineage(graph_fingerprint)
    -> {:ok, [ArchaeologyEntry.t]} | {:error, :not_found}

  get_edge_history(edge_id)
    -> {:ok, [ArchaeologyEntry.t]} | {:error, :not_found}

  get_rejected_alternatives(graph_fingerprint)
    -> {:ok, [String.t()]} — candidate IDs of rejected structures

  reconstruct_graph_history(graph_fingerprint, evidence_set, config)
    -> {:ok, CausalArchaeology.t}
    Deterministically rebuild full archaeology from replayed pipeline.

  archaeology_fingerprint(archaeology)
    -> String.t() — SHA-256 of sorted entry fingerprints
```

---

## 4. Behaviour Definitions

### 4.1 StructureLearningBehaviour

```elixir
@callback discover_structure(evidence_set :: map(), config :: map()) ::
  {:ok, %{causal_graph: CausalGraph.t(), candidates: [StructureCandidate.t()], structure_root: String.t()}}
  | {:error, String.t()}

@callback generate_alternatives(causal_graph :: CausalGraph.t(), evidence_set :: map(), config :: map()) ::
  {:ok, [StructureCandidate.t()]}
  | {:error, String.t()}

@callback score_structure(candidate :: StructureCandidate.t(), evidence_set :: map()) ::
  {:ok, StructureCandidate.t()}
  | {:error, String.t()}
```

### 4.2 IndependenceTestingBehaviour

```elixir
@callback test_conditional(variable_a :: String.t(), variable_b :: String.t(),
                           conditioning_set :: [String.t()], evidence_set :: map()) ::
  {:ok, IndependenceResult.t()}
  | {:error, String.t()}

@callback test_marginal(variable_a :: String.t(), variable_b :: String.t(),
                        evidence_set :: map()) ::
  {:ok, IndependenceResult.t()}
  | {:error, String.t()}

@callback batch_test(variables :: [String.t()], evidence_set :: map(), config :: map()) ::
  {:ok, [IndependenceResult.t()]}
  | {:error, String.t()}
```

### 4.3 CausalReplayBehaviour

```elixir
@callback replay_stage(stage :: atom(), config :: map(), evidence_set :: map()) ::
  {:ok, map()}
  | {:error, String.t()}

@callback replay_discovery(evidence_set :: map(), config :: map()) ::
  {:ok, %{causal_graph: CausalGraph.t(), causal_root: String.t()}}
  | {:error, String.t()}

@callback verify_replay(model_id :: String.t(), version :: non_neg_integer()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}
  | {:error, String.t()}
```

### 4.4 CausalValidationBehaviour

```elixir
@callback validate_graph(causal_graph :: CausalGraph.t()) ::
  {:ok, CausalValidationResult.t()}
  | {:error, String.t()}

@callback validate_evidence_grounding(causal_graph :: CausalGraph.t(), evidence_set :: map()) ::
  {:ok, %{grounded: boolean(), ungrounded_edges: [String.t()]}}
  | {:error, String.t()}

@callback validate_intervention(intervention :: Intervention.t(), causal_graph :: CausalGraph.t()) ::
  :ok
  | {:error, String.t()}
```

---

## 5. Content-Addressed ID Schemes

| Struct | Prefix | Canonical Content |
|--------|--------|-------------------|
| IndependenceResult | `ir_` | SHA-256(var_a \|\| var_b \|\| sorted conditioning \|\| test_type) |
| Skeleton | `sk_` | SHA-256(sorted adjacency list) |
| StructureCandidate | `sc_` | SHA-256(sorted edges \|\| score \|\| derivation) |
| EdgeScore | `es_` | SHA-256(source \|\| target \|\| context_fingerprint) |
| DiscoveryEvidence | `de_` | SHA-256(stage \|\| sorted input_roots \|\| output_root) |
| LatentVariable | `lv_` | SHA-256(sorted manifest \|\| detection_method) |
| CausalArchaeology | `ca_` | SHA-256(sorted entry fingerprints) |
| ArchaeologyEntry | `ae_` | SHA-256(stage \|\| description \|\| sorted input/output fingerprints) |
| CausalValidationResult | `vr_` | SHA-256(graph \|\| sorted check fingerprints) |
| ValidationCheck | `vc_` | SHA-256(check_name \|\| status \|\| details) |
| InterventionPlan | `ip_` | SHA-256(target \|\| intervention_type \|\| set_value \|\| graph) |
| IndependentAuditReport | `ar_` | SHA-256(graph \|\| sorted findings \|\| timestamp) |

---

## 6. Serialization Convention

All Phase 17.3 structs follow the Phase 17 serialization convention:

```elixir
def canonicalize do
  __struct__
  |> Map.drop([:__struct__])
  |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
  |> Enum.sort_by(fn {k, _} -> k end)
  |> Enum.into(%{})
end

defp canonical_value({a, b}), do: [a, b]
defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
defp canonical_value(v), do: v
```

---

## 7. Registration Conventions

All Phase 17.3 modules register their outputs in ETS tables following the ModelRegistry pattern:

| Artifact | Table | Key | Value |
|----------|-------|-----|-------|
| IndependenceResult | `:causal_independence` | result_id | result struct |
| Skeleton | `:causal_skeleton` | skeleton_id | skeleton struct |
| StructureCandidate | `:causal_candidates` | candidate_id | candidate struct |
| CausalArchaeology | `:causal_archaeology` | archaeology_id | archaeology struct |
| InterventionPlan | `:causal_interventions` | plan_id | plan struct |
| CausalValidationResult | `:causal_validation` | validation_id | result struct |

---

## 8. Freeze Scope

The following are frozen by this document:

| Item | Status |
|------|--------|
| IndependenceResult struct | FROZEN |
| Skeleton struct | FROZEN |
| StructureCandidate struct | FROZEN |
| EdgeScore struct | FROZEN |
| DiscoveryEvidence struct | FROZEN |
| LatentVariable struct | FROZEN |
| CausalArchaeology struct | FROZEN |
| ArchaeologyEntry struct | FROZEN |
| CausalValidationResult struct | FROZEN |
| ValidationCheck struct | FROZEN |
| IndependentAuditReport struct | FROZEN |
| IndependenceEngine API | FROZEN |
| StructureLearner API | FROZEN |
| EdgeScorer API | FROZEN |
| GraphValidator API | FROZEN |
| InterventionEngine API | FROZEN |
| CausalReplay API | FROZEN |
| CausalArchaeology API | FROZEN |
| StructureLearningBehaviour | FROZEN |
| IndependenceTestingBehaviour | FROZEN |
| CausalReplayBehaviour | FROZEN |
| CausalValidationBehaviour | FROZEN |
| ID schemes | FROZEN |
| Serialization rules | FROZEN |
| Registration conventions | FROZEN |

---

*This document is Phase 17.3.05 deliverable. Contracts are frozen. No implementation changes without constitutional review.*
