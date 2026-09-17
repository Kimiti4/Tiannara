# CAUSAL_DATA_MODEL.md

## Phase 17.3 — Causal Discovery Data Model

---

## 1. Core Structs

### IndependenceResult

```elixir
defmodule TiannaraRuntime.CausalDiscovery.IndependenceResult do
  defstruct [
    :result_id,            # SHA-256 of canonical content
    :variable_a,           # variable_id
    :variable_b,           # variable_id
    :conditioning_set,     # [variable_id] — may be empty for marginal
    :test_type,            # :conditional | :marginal
    :statistic,            # float — test statistic (chi-sq, correlation, etc.)
    :p_value,              # float
    :confidence,           # float 0..1
    :dof,                  # non_neg_integer — degrees of freedom
    :sample_size,          # non_neg_integer
    :evidence_root,        # evidence root used for this test
    :metadata
  ]
end
```

### Skeleton

```elixir
defmodule TiannaraRuntime.CausalDiscovery.Skeleton do
  defstruct [
    :skeleton_id,          # SHA-256 of canonical adjacency
    :adjacency,            # %{variable_id => [variable_id]} — undirected
    :separating_sets,      # %{{a, b} => [variable_id]} — evidence of independence
    :nodes,                # [variable_id] — all variable IDs in skeleton
    :fingerprint
  ]
end
```

### StructureCandidate

```elixir
defmodule TiannaraRuntime.CausalDiscovery.StructureCandidate do
  defstruct [
    :candidate_id,         # SHA-256 of canonical graph edge list
    :edges,                # [{source, target, type, confidence}]
    :score,                # BGe or BIC score
    :score_type,           # :bge | :bic | :custom
    :derivation,           # :constraint_based | :score_based | :hybrid | :expert
    :parent_graph,         # candidate_id of predecessor, or nil
    :mutations,            # list of changes from parent
    :confidence,           # float 0..1
    :metadata
  ]
end
```

### EdgeScore

```elixir
defmodule TiannaraRuntime.CausalDiscovery.EdgeScore do
  defstruct [
    :edge_id,              # SHA-256 of canonical edge + context
    :source,               # variable_id
    :target,               # variable_id
    :evidence_support,     # float 0..1 — proportion of evidence supporting
    :statistical_strength, # float 0..1 — transformed p-value
    :stability,            # float 0..1 — bootstrap retention rate
    :replay_confidence,    # float 0..1 — cross-replay consistency
    :intervention_compat,  # float 0..1 — consistency with known interventions
    :overall,              # float 0..1 — weighted combination
    :weight_vector,        # [float] — weights used for combination
    :metadata
  ]
end
```

### DiscoveryEvidence

```elixir
defmodule TiannaraRuntime.CausalDiscovery.DiscoveryEvidence do
  defstruct [
    :discovery_id,         # SHA-256 of canonical discovery context
    :stage,                # :independence | :skeleton | :orientation | :scoring | :latent
    :input_roots,          # [String.t()] — replay roots of inputs
    :output_root,          # String.t() — replay root of output
    :config,               # map — parameterization of this step
    :created_at
  ]
end
```

### LatentVariable (extending Phase 17 ontology)

```elixir
defmodule TiannaraRuntime.CausalDiscovery.LatentVariable do
  defstruct [
    :latent_id,
    :name,                 # human-readable label
    :manifest_variables,   # [variable_id] — observed variables it explains
    :confidence,           # float 0..1
    :detection_method,     # :residual_correlation | :mediation_gap | :expert
    :competing_explanations, # [[variable_id]] — alternative configurations
    :supporting_observations, # [evidence_root]
    :metadata
  ]
end
```

### InterventionPlan

```elixir
defmodule TiannaraRuntime.CausalDiscovery.InterventionPlan do
  defstruct [
    :plan_id,
    :target_variable,      # variable_id
    :intervention_type,    # :atomic | :conditional | :stochastic
    :set_value,            # :remove | :fix(value) | :set_distribution
    :expected_outcome,     # %{variable_id => {expected, confidence_interval}}
    :causal_pathway,       # [variable_id] — pathway from intervention to outcomes
    :identifiability,      # :identified | :partial | :non_identifiable
    :do_calculus_level,    # 1 | 2 | 3
    :confidence,           # float 0..1
    :metadata
  ]
end
```

### CounterfactualBranch

```elixir
defmodule TiannaraRuntime.CausalDiscovery.CounterfactualBranch do
  defstruct [
    :branch_id,
    :base_graph_id,        # causal graph fingerprint
    :intervention,         # InterventionPlan.t
    :resulting_state,      # %{variable_id => value}
    :probability,          # float 0..1
    :fingerprint
  ]
end
```

### CausalArchaeology

```elixir
defmodule TiannaraRuntime.CausalDiscovery.CausalArchaeology do
  defstruct [
    :archaeology_id,
    :model_id,             # from Phase 17.1 ModelRegistry
    :entries,              # [ArchaeologyEntry.t]
    :fingerprint
  ]
end

defmodule TiannaraRuntime.CausalDisccovery.ArchaeologyEntry do
  defstruct [
    :entry_id,
    :stage,                # which pipeline stage created this entry
    :timestamp,            # ISO-8601
    :description,          # what happened
    :input,                # input data fingerprints
    :output,               # output data fingerprints
    :alternatives,         # [fingerprint] — rejected alternatives
    :evidence_roots,       # evidence used in this decision
    :confidence,           # float 0..1
    :metadata
  ]
end
```

---

## 2. Validation Evidence (extending Phase 17)

### CausalValidationResult

```elixir
defmodule TiannaraRuntime.CausalDiscovery.CausalValidationResult do
  defstruct [
    :validation_id,
    :graph_fingerprint,
    :checks,               # [ValidationCheck.t]
    :overall,              # :pass | :fail | :inconclusive
    :created_at
  ]
end

defmodule TiannaraRuntime.CausalDiscovery.ValidationCheck do
  defstruct [
    :check_name,
    :status,               # :pass | :fail | :skipped
    :details,
    :fingerprint
  ]
end
```

---

## 3. Canonicalization

All structs support canonical JSON serialization (following Phase 17 convention):

```elixir
def canonicalize do
  __struct__
  |> Map.drop([:__struct__])
  |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
  |> Enum.sort_by(fn {k, _} -> k end)
  |> Enum.into(%{})
  |> Jason.encode!()
end

def fingerprint do
  canonicalize() |> :crypto.hash(:sha256) |> Base.encode16(case: :lower)
end
```

Tuples are converted to lists for JSON encoding: `{a, b}` → `[a, b]`.

---

## 4. Content-Addressed IDs

| Struct | ID Scheme |
|--------|-----------|
| IndependenceResult | `ir_` + SHA-256(var_a \|\| var_b \|\| conditioning) |
| Skeleton | `sk_` + SHA-256(sorted adjacency) |
| StructureCandidate | `sc_` + SHA-256(canonical edges + score) |
| EdgeScore | `es_` + SHA-256(source \|\| target \|\| context) |
| DiscoveryEvidence | `de_` + SHA-256(canonical discovery context) |
| LatentVariable | `lv_` + SHA-256(canonical latent config) |
| InterventionPlan | `ip_` + SHA-256(target \|\| intervention \|\| graph) |
| CausalArchaeology | `ca_` + SHA-256(sorted entry fingerprints) |

---

*This document is Phase 17.3.0 deliverable. All structs subject to constitutional freeze in Phase 17.3.05.*
