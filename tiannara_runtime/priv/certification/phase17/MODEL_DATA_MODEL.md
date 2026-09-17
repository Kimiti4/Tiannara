# MODEL_DATA_MODEL.md

## Phase 17 — World Model Data Model

---

## 1. Core Structs

### WorldModel

```elixir
defmodule TiannaraRuntime.WorldModel do
  defstruct [
    :model_id,           # SHA-256 of genesis content
    :version,            # monotonic integer
    :name,               # human-readable
    :domain,             # research domain (Engineering, Physics, ...)
    :state_space,        # StateSpace.t
    :variables,          # [Variable.t]
    :parameters,         # [Parameter.t]
    :equations,          # EquationSystem.t
    :causal_graph,       # CausalGraph.t
    :observation_model,  # ObservationModel.t
    :constraints,        # [Constraint.t]
    :metadata,           # map (provenance, tags, etc.)
    :evidence_roots,     # [String.t()]
    :certificate,        # ModelCertificate.t | nil
    :status,             # :draft | :validated | :operational | :deprecated | :archived
    :fingerprint,        # replay root hash
    :created_at          # ISO-8601
  ]
end
```

### StateSpace

```elixir
defmodule TiannaraRuntime.WorldModel.StateSpace do
  defstruct [
    :dimensions,          # non_neg_integer
    :variable_order,      # [variable_id]
    :bounds,              # %{variable_id => {lower, upper}}
    :default_initial,     # %{variable_id => value}
    :support_type         # :continuous | :discrete | :mixed
  ]
end
```

### Variable

```elixir
defmodule TiannaraRuntime.WorldModel.Variable do
  defstruct [
    :variable_id,         # unique within model
    :name,                # human-readable
    :type,                # :continuous | :discrete | :categorical | :ordinal | :latent
    :domain,              # [allowed values] or {min, max}
    :unit,                # SI unit string or nil
    :is_endogenous,       # boolean — modeled vs exogenous input
    :observation_source,  # evidence reference
    :description,         # natural language
    :metadata             # map
  ]
end
```

### Parameter

```elixir
defmodule TiannaraRuntime.WorldModel.Parameter do
  defstruct [
    :parameter_id,
    :name,
    :value,              # estimated value
    :distribution,       # ProbabilityDistribution.t
    :bounds,             # {lower, upper} or nil
    :is_identifiable,    # boolean
    :sensitivity,        # float | nil
    :estimated_from      # evidence reference
  ]
end
```

### EquationSystem

```elixir
defmodule TiannaraRuntime.WorldModel.EquationSystem do
  defstruct [
    :equations,          # [Equation.t]
    :algebraic_loops,    # [loop_id] — detected algebraic constraints
    :differential_index, # non_neg_integer | nil
    :consistency_proof   # proof reference or nil
  ]
end
```

### Equation

```elixir
defmodule TiannaraRuntime.WorldModel.Equation do
  defstruct [
    :equation_id,
    :target_variable,    # variable_id this equation defines
    :expression,         # SymbolicExpression.t (from Phase 16.X)
    :type,               # :algebraic | :differential | :integral | :difference
    :derivation,         # :learned | :first_principles | :expert_provided | :approximated
    :assumptions,        # [String.t()]
    :confidence,         # float 0..1
    :mathematical_proof  # proof reference from ProofEngine
  ]
end
```

### CausalGraph

```elixir
defmodule TiannaraRuntime.WorldModel.CausalGraph do
  defstruct [
    :nodes,              # [CausalNode.t]
    :edges,              # [CausalEdge.t]
    :latent_variables,   # [variable_id]
    :confounders,        # [Confounder.t]
    :do_calculus_level,  # 1 | 2 | 3
    :graph_fingerprint   # SHA-256 of canonical edge list
  ]
end
```

### CausalNode

```elixir
defmodule TiannaraRuntime.WorldModel.CausalNode do
  defstruct [
    :node_id,            # variable_id
    :type,               # :endogenous | :exogenous | :latent | :intervention
    :metadata
  ]
end
```

### CausalEdge

```elixir
defmodule TiannaraRuntime.WorldModel.CausalEdge do
  defstruct [
    :edge_id,
    :source,             # node_id
    :target,             # node_id
    :type,               # :direct | :inferred | :known | :speculative
    :confidence,         # float 0..1
    :strength,           # float | nil (effect size)
    :metadata
  ]
end
```

### ObservationModel

```elixir
defmodule TiannaraRuntime.WorldModel.ObservationModel do
  defstruct [
    :mapping,            # %{variable_id => observable_id}
    :noise_distribution, # ProbabilityDistribution.t per observable
    :missing_data,       # :ignore | :impute | :marginalize
    :measurement_error   # float | nil (std dev)
  ]
end
```

### Prediction

```elixir
defmodule TiannaraRuntime.WorldModel.Prediction do
  defstruct [
    :prediction_id,
    :model_id,
    :model_version,
    :input_state,         # StateSpace initial values
    :output_variables,    # [variable_id]
    :time_horizon,        # number of steps | continuous time
    :forecast,            # [TimeSeriesPoint.t]
    :confidence_intervals,# [Interval.t]
    :extrapolation,       # boolean — outside training evidence?
    :fingerprint,         # SHA-256 of prediction content
    :created_at
  ]
end
```

### TimeSeriesPoint

```elixir
defmodule TiannaraRuntime.WorldModel.TimeSeriesPoint do
  defstruct [
    :t,                   # time step or timestamp
    :values,              # %{variable_id => value}
    :uncertainty          # %{variable_id => distribution} or nil
  ]
end
```

### Intervention

```elixir
defmodule TiannaraRuntime.WorldModel.Intervention do
  defstruct [
    :intervention_id,
    :target_variable,     # variable_id
    :set_value,           # :remove | :fix(value) | :set_distribution(dist)
    :do_operator,         # :atomic | :conditional | :stochastic
    :description
  ]
end
```

### CounterfactualModel

```elixir
defmodule TiannaraRuntime.WorldModel.CounterfactualModel do
  defstruct [
    :counterfactual_id,
    :base_model_id,
    :intervention,        # Intervention.t
    :resulting_state,     # StateSpace at specified time
    :fingerprint,
    :created_at
  ]
end
```

### ModelCertificate

```elixir
defmodule TiannaraRuntime.WorldModel.ModelCertificate do
  defstruct [
    :certificate_id,
    :model_id,
    :model_version,
    :certification_type,  # :mathematical | :validation | :operational
    :checks,              # [CertificationCheck.t]
    :overall_status,       # :pass | :fail
    :fingerprint,
    :issued_at,
    :issued_by
  ]
end
```

### CertificationCheck

```elixir
defmodule TiannaraRuntime.WorldModel.CertificationCheck do
  defstruct [
    :check_name,
    :status,              # :pass | :fail | :skipped
    :description,
    :evidence             # proof hash or fingerprint reference
  ]
end
```

### ProbabilityDistribution

```elixir
defmodule TiannaraRuntime.WorldModel.ProbabilityDistribution do
  defstruct [
    :type,                # :normal | :uniform | :beta | :gamma | :lognormal | :categorical | :empirical
    :parameters,          # %{name => value} — varies by type
    :fingerprint          # SHA-256 of canonical form
  ]
end
```

---

## 2. Validation Evidence

```elixir
defmodule TiannaraRuntime.WorldModel.ValidationEvidence do
  defstruct [
    :validation_id,
    :model_id,
    :model_version,
    :metric,              # :rmse | :log_likelihood | :coverage | :calibration | :custom
    :value,               # float
    :threshold,           # float (pass if value <= threshold for error, >= for accuracy)
    :passed,              # boolean
    :evidence_fingerprint,# held-out evidence root
    :created_at
  ]
end
```

---

## 3. Canonicalization

All structs support canonical JSON serialization for fingerprint computation:

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

---

## 4. Serialization

Models are serialized to term files for storage and replay:

```elixir
def serialize(model), do: :erlang.term_to_binary(model)
def deserialize(binary), do: :erlang.binary_to_term(binary)
```

---

*This document is Phase 17.0 deliverable. All structs subject to constitutional freeze in Phase 17.05.*
