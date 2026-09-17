# EFDI D1 — Signal Intelligence Implementation Plan

## Scope

Implement **D1: Signal Intelligence** as the foundational contract layer for the eventual
D1–D6 Epistemic Forecasting & Decision Intelligence (EFDI) subsystem.

D1 does NOT implement forecasting, calibration, decision evaluation, counterfactuals,
noise measurement, or forecast memory. It establishes the **stable interfaces and core
data model** that those later packages will consume.

---

## 1. What D1 Delivers

| Deliverable | Purpose |
|---|---|
| `EFDI` root module | Namespace, public API facade, lifecycle |
| `Signal` struct | Canonical signal representation |
| `SignalRegistry` | Durable registration/retrieval with provenance |
| `SignalQuality` | Multi-dimensional quality evaluation |
| `SignalInfoValue` | Predictive value / information gain measurement |
| `ResearchDirectorAdapter` | Interface for D2→Research Director integration |
| `CISAdapter` | Interface for D2→CIS integration |
| `EFDI architectural doc` | Integration map, invariants, failure modes |
| Tests | Unit, contract, provenance, determinism, adversarial, stale/duplicate |
| Certification | Machine-verifiable D1 gates |

---

## 2. What D1 Reuses (Not Duplicates)

| Existing module | What it provides | How D1 uses it |
|---|---|---|
| `Tiannara.Numerics` | `error_mode()`, `with_uncertainty/2`, `qnorm/1` | Signal measurement uncertainty, error modes |
| `Tiannara.Foundations.InformationTheory` | `shannon_entropy/1`, `kl_divergence/2` | Signal information-theoretic metrics |
| `Tiannara.Math.Probability` | `bayes_update/3` | Belief updating when signals update priors |
| `Tiannara.Constraints` | `normalize_to/2`, `normalize_probabilities/1`, `evidence_report/1` | Normalizing weights, generating evidence reports |
| `Tiannara.Executive.ExecutiveMemory` | `put/3`, `get/1`, `keys/0` | Signal persistence |
| `Tiannara.Executive.EventStore` | `append/1`, `stream/1` | Signal event lineage |
| `Tiannara.Core.WorldModel.Uncertainty` | `record_ambiguity/3`, `record_contradiction/4` | Contradiction detection between signals |
| `Tiannara.Discovery.Domain` structs | `HypothesisSpec`, `PredictionSpec` with `expected_information_gain` | Research Director contract shape |
| `Tiannara.Discovery.Optimization.ActiveLearner` | `compute_eig/2`, `ucb/3` | Information gain computation for signals |
| `Tiannara.World.ConflictDetector` | Conflict-map contract (`entity_ids, severity, evidence`) | Contradiction detection between competing signals |
| `Tiannara.Research.ResearchDirector` | `ingest_priorities/1` | Future D2 integration point |

---

## 3. Constitutional Rules for D1

1. **A signal is not a prediction, and a prediction is not a fact.** Every object
   preserves its epistemic status.

2. **No duplicate evidence ontology.** Signals link to existing
   `Tiannara.Discovery.Domain` evidence and provenance through
   `Tiannara.Executive.EventStore` lineage, not a parallel system.

3. **Mathematics remains a foundational substrate**, not a new canonical domain.
   EFDI consumes mathematical services; it does not become one.

4. **UNKNOWN is a valid result.** When evidence is insufficient to evaluate signal
   quality or predictive value, say so explicitly.

5. **Historical signal records are never overwritten.** Corrections create new versions.

6. **Every signal preserves:** probability, uncertainty, evidence provenance,
   assumptions, model lineage, timestamp, and domain context.

7. **D1 is not complete merely because tests pass.** Certification requires machine-
   verifiable evidence for every gate.

---

## 4. Module Design

### 4a. `Tiannara.EFDI` (Root Module)

**File:** `lib/tiannara/efdi.ex`

Namespace module providing:
- `start_link/1` — starts the EFDI supervisor (for future D2-D6 child processes)
- `register_signal/1` — delegates to `SignalRegistry.register/1`
- `get_signal/1` — delegates to `SignalRegistry.get/1`
- `quality/1` — delegates to `SignalQuality.evaluate/1`
- `info_value/1` — delegates to `SignalInfoValue.measure/1`
- `status/0`, `health/0` — aggregate subsystem status

### 4b. `Tiannara.EFDI.Signal` (Struct)

**File:** `lib/tiannara/efdi/signal.ex`

```elixir
defmodule Tiannara.EFDI.Signal do
  @moduledoc """
  A canonical signal: a structured observation with explicit epistemic status.

  A signal is NOT a prediction, NOT evidence, NOT a fact.
  It is a structured observation with quality metadata.

  Epistemic lifecycle:
    observation → signal → [evidence] → [hypothesis] → [forecast] → [decision]

  Every field is explicit. UNKNOWN is a valid value.
  """

  @enforce_keys [:id, :source, :observation, :timestamp]
  defstruct [
    # Identity
    :id,                    # "sig_<nanoid>" — immutable, unique
    :version,               # integer — monotonically increasing (never overwrite)

    # Source
    :source,                # atom() | String.t() — originating system
    :source_reliability,    # float 0..1 | nil — historical source reliability
    :domain,                # atom() — one of 20 canonical domains | :cross_domain
    :regime,                # atom() | nil — environmental regime context

    # Observation
    :observation,           # term() — the raw observation value
    :observation_type,      # atom() — :numeric | :categorical | :temporal | :textual | :derived
    :measurement_uncertainty, # Tiannara.Numerics.error_mode() | nil

    # Timestamps
    :timestamp,             # DateTime.t() — when the observation occurred
    :received_at,           # DateTime.t() — when the signal was registered
    :expires_at,            # DateTime.t() | nil — optional staleness boundary

    # Quality metadata
    :reliability,           # float 0..1 | nil — assessed reliability
    :relevance,             # float 0..1 | nil — assessed relevance
    :independence,          # float 0..1 | nil — assessed independence from other signals
    :persistence,           # float 0..1 | nil — assessed temporal persistence
    :recency,               # float 0..1 | nil — assessed recency (decays with time)

    # Information value
    :predictive_value,      # float 0..1 | nil — historical predictive performance
    :information_gain,      # float >= 0 | nil — marginal information gain over existing signals
    :redundancy,            # float 0..1 | nil — redundancy with existing signals

    # Provenance & lineage
    :provenance,            # %{kind: atom(), evidence_hash: String.t()} | nil
    :lineage,               # [String.t()] — parent signal IDs (for derived signals)
    :transformations,       # [atom()] — transformations applied to raw observation

    # Versioning
    :supersedes,            # String.t() | nil — ID of signal this version replaces

    # Metadata
    :assumptions,           # [String.t()] — assumptions underlying this signal
    :tags,                  # [atom()] — arbitrary tags for filtering/selection
    :metadata,              # map() — extensible metadata
  ]

  @type t :: %__MODULE__{}

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) or is_keyword(attrs) do
    attrs = Map.new(attrs)
    now = DateTime.utc_now()

    id = attrs[:id] || generate_id()
    struct = struct!(__MODULE__, Map.drop(attrs, [:id]))
    %{struct |
      id: id,
      version: attrs[:version] || 1,
      received_at: attrs[:received_at] || now,
      timestamp: attrs[:timestamp] || now
    }
  end

  @spec version(t(), map()) :: t()
  def version(signal, updates) do
    new(Map.put(Map.from_struct(signal), :supersedes, signal.id)
        |> Map.merge(Map.new(updates))
        |> Map.update!(:version, &(&1 + 1)))
  end

  defp generate_id do
    raw = :crypto.strong_rand_bytes(16) |> Base.encode64(padding: false)
    "sig_#{raw}"
  end
end
```

### 4c. `Tiannara.EFDI.SignalRegistry` (GenServer + ETS)

**File:** `lib/tiannara/efdi/signal_registry.ex`

Responsibilities:
- Register signals with immutable IDs
- ETS indexes: by id, by source, by domain, by timestamp range
- Append to EventStore for lineage
- Persist to ExecutiveMemory for durability
- Deduplication by source+observation hash
- Temporal ordering
- Version tracking (superseded signals)

Public API:
```elixir
@spec register(Signal.t()) :: {:ok, Signal.t()} | {:error, term()}
@spec get(String.t()) :: {:ok, Signal.t()} | :error
@spec list_by_source(atom()) :: [Signal.t()]
@spec list_by_domain(atom()) :: [Signal.t()]
@spec list_recent(DateTime.t(), DateTime.t()) :: [Signal.t()]
@spec list_active(DateTime.t()) :: [Signal.t()]  # not expired
@spec supersede(String.t(), map()) :: {:ok, Signal.t()}
@spec stats() :: map()
```

### 4d. `Tiannara.EFDI.SignalQuality` (Pure Functions)

**File:** `lib/tiannara/efdi/signal_quality.ex`

Multi-dimensional quality evaluation of a signal. Returns a quality assessment
struct with per-dimension scores and an aggregate.

```elixir
defmodule Tiannara.EFDI.SignalQuality do
  @moduledoc """
  Evaluates signal quality across multiple dimensions.
  All dimensions are explicit. UNKNOWN is a valid assessment.
  """

  defstruct [
    :signal_id,
    :reliability,       # source reliability assessment
    :recency,           # time-decayed freshness
    :completeness,      # field fill ratio
    :consistency,       # consistency with existing signals
    :independence,      # independence from correlated signals
    :persistence,       # temporal persistence across observations
    :measurement_quality, # uncertainty mode assessment
    :domain_validity,   # whether signal is valid in its domain/regime
    :aggregate_score,   # weighted aggregate
    :assessed_at,       # DateTime.t()
    :dimensions_assessed, # count of dimensions with non-nil scores
    :dimensions_unknown,  # count of dimensions that could not be assessed
  ]

  @spec evaluate(Signal.t(), Keyword.t()) :: t()
  def evaluate(signal, opts \\ [])

  @spec evaluate_reliability(Signal.t()) :: float() | :unknown
  @spec evaluate_recency(Signal.t()) :: float() | :unknown
  @spec evaluate_completeness(Signal.t()) :: float() | :unknown
  @spec evaluate_persistence(Signal.t(), [Signal.t()]) :: float() | :unknown
  @spec evaluate_measurement_quality(Signal.t()) :: float() | :unknown
end
```

Key implementation details:
- Recency uses exponential decay with configurable half-life
- Completeness = count of non-nil key fields / total key fields
- Persistence = ratio of historical signals from same source with similar observations
- Measurement quality maps Numerics error_mode to a 0..1 score
- Aggregate uses configurable weights (default: reliability 0.3, recency 0.15,
  completeness 0.1, consistency 0.15, independence 0.15, persistence 0.15)

### 4e. `Tiannara.EFDI.SignalInfoValue` (Pure Functions)

**File:** `lib/tiannara/efdi/signal_info_value.ex`

Measures the information value of a signal given the existing signal set.

```elixir
defmodule Tiannara.EFDI.SignalInfoValue do
  @moduledoc """
  Measures the information value of a signal.
  Predictive value requires outcome data — without it, the result is :unknown.
  """

  defstruct [
    :signal_id,
    :predictive_value,      # float 0..1 | :unknown
    :information_gain,      # float >= 0 | :unknown
    :redundancy,            # float 0..1 | :unknown
    :marginal_value,        # float 0..1 | :unknown — value over best existing signal
    :assessed_at,
    :assessment_basis,      # :historical_outcomes | :structural_analysis | :insufficient_data
  ]

  @spec measure(Signal.t(), [Signal.t()], Keyword.t()) :: t()
  def measure(signal, existing_signals \\ [], opts \\ [])

  @spec compute_predictive_value(String.t(), [(outcome :: term())]) :: float() | :unknown
  @spec compute_information_gain(Signal.t(), [Signal.t()]) :: float() | :unknown
  @spec compute_redundancy(Signal.t(), [Signal.t()]) :: float() | :unknown
end
```

Key implementation details:
- `compute_predictive_value` requires historical outcome data; returns `:unknown` without it
- `compute_information_gain` uses KL divergence from `InformationTheory` (signal shifts
  belief from prior to posterior)
- `compute_redundancy` measures correlation/overlap with existing signals using cosine
  similarity on observation vectors
- `compute_marginal_value` = information_gain minus best existing signal's information_gain
- All functions return `:unknown` when evidence is insufficient (constitutional rule)

### 4f. `Tiannara.EFDI.ResearchDirectorAdapter`

**File:** `lib/tiannara/efdi/adapters/research_director_adapter.ex`

Defines the contract through which D2 will feed signal information into the Research Director.

```elixir
defmodule Tiannara.EFDI.ResearchDirectorAdapter do
  @moduledoc """
  Contract for integrating EFDI signals with the Research Director.

  D1 defines the interface. D2 implements the integration.
  """

  @callback signal_to_priority(Signal.t()) :: {:ok, map()} | {:error, term()}
  # Converts a high-value signal into a Research Director priority:
  #   %{source: :efdi, signal_id: ..., domain: ..., urgency: ..., information_gain: ...}

  @callback signals_to_priorities([Signal.t()]) :: {:ok, [map()]}
  # Batch conversion for ResearchDirector.ingest_priorities/1

  @callback forecast_to_hypothesis(map(), Signal.t()) :: {:ok, map()} | {:error, term()}
  # Converts a D2 forecast into a Discovery.Domain.HypothesisSpec
  #   for ResearchDirector pipeline consumption

  @callback information_gain_estimate(Signal.t(), [map()]) :: {:ok, float()} | {:error, :insufficient_data}
  # Estimates information gain for Research Director's experiment selection
end
```

### 4g. `Tiannara.EFDI.CISAdapter`

**File:** `lib/tiannara/efdi/adapters/cis_adapter.ex`

Defines the contract through which D2 forecasts will be consumed by CIS.

```elixir
defmodule Tiannara.EFDI.CISAdapter do
  @moduledoc """
  Contract for integrating EFDI forecasts with the Cognitive Immune System.

  D1 defines the interface. D2 implements the integration.
  CIS retains authority over safety/stability regulation.
  EFDI provides epistemic prediction, not unrestricted control.
  """

  @callback signal_to_telemetry(Signal.t()) :: {:ok, map()} | {:error, term()}
  # Converts a signal into CIS-compatible telemetry format:
  #   %{signal_type: atom(), severity: float(), confidence: float(), source: atom()}

  @callback forecast_to_collapse_probability(map()) :: {:ok, float()} | {:error, term()}
  # Converts a D2 forecast distribution into a CIS-compatible collapse probability.
  # CIS.CollapsePredictor retains authority; EFDI provides input only.

  @callback signal_conflict_to_pathogen([Signal.t()]) :: {:ok, map()} | {:error, term()}
  # Converts a set of conflicting signals into a CIS pathogen detection event.
end
```

---

## 5. File Plan

### New files to create

| Path | Purpose |
|---|---|
| `lib/tiannara/efdi.ex` | Root module, public API, namespace |
| `lib/tiannara/efdi/signal.ex` | Signal struct definition |
| `lib/tiannara/efdi/signal_registry.ex` | Signal persistence and retrieval (GenServer + ETS) |
| `lib/tiannara/efdi/signal_quality.ex` | Multi-dimensional quality evaluation |
| `lib/tiannara/efdi/signal_info_value.ex` | Predictive value / information gain |
| `lib/tiannara/efdi/adapters/research_director_adapter.ex` | Research Director contract |
| `lib/tiannara/efdi/adapters/cis_adapter.ex` | CIS contract |
| `test/tiannara/efdi/signal_test.exs` | Signal struct tests |
| `test/tiannara/efdi/signal_registry_test.exs` | Registry persistence/retrieval tests |
| `test/tiannara/efdi/signal_quality_test.exs` | Quality evaluation tests |
| `test/tiannara/efdi/signal_info_value_test.exs` | Information value tests |
| `test/tiannara/efdi/integration_test.exs` | Integration tests with existing systems |
| `docs/architecture/EFDI_ARCHITECTURE.md` | Full architecture document |
| `docs/architecture/EFDI_SIGNAL_MODEL.md` | Signal model specification |
| `certification/efdi/D1_CERTIFICATION.md` | D1 certification record |
| `priv/tiannara/efdi/D1_result.json` | Machine result JSON |

### Files to modify

| Path | Change |
|---|---|
| `config/config.exs` | Add EFDI config section (registry ETS name, EventStore path) |
| `config/test.exs` | Add EFDI test config (isolated ETS, test paths) |

### Files NOT modified

All existing canonical ontologies, constitutional contracts, certified components, and
domain registrations remain untouched. EFDI is additive.

---

## 6. Implementation Order

1. **Signal struct** (`signal.ex`) — pure data, no dependencies
2. **SignalRegistry** (`signal_registry.ex`) — depends on ExecutiveMemory, EventStore
3. **SignalQuality** (`signal_quality.ex`) — pure functions on Signal struct
4. **SignalInfoValue** (`signal_info_value.ex`) — pure functions, depends on InformationTheory
5. **Root module** (`efdi.ex`) — namespace and API facade
6. **Adapters** (`research_director_adapter.ex`, `cis_adapter.ex`) — behaviour definitions only
7. **Config** — add EFDI config to `config.exs` and `config/test.exs`
8. **Tests** — one test file per module, plus integration test
9. **Architecture doc** — `EFDI_ARCHITECTURE.md`, `EFDI_SIGNAL_MODEL.md`
10. **Certification** — run tests, verify gates, write `D1_CERTIFICATION.md` + `D1_result.json`

---

## 7. Testing Strategy

### Unit tests (`signal_test.exs`)
- `new/1` with all fields
- `new/1` with minimal required fields (defaults applied)
- `version/2` creates new version with incremented version number
- `supersedes` link is correct
- ID generation produces unique IDs
- Struct enforces required keys

### Registry tests (`signal_registry_test.exs`)
- Register and retrieve a signal
- Register multiple signals, query by source
- Register multiple signals, query by domain
- Register signals at different timestamps, query by time range
- Query active signals (not expired)
- Supersede a signal, verify old is marked and new is retrievable
- Deduplication: same source+observation hash returns existing signal
- Stats reflect correct counts
- EventStore lineage is created on registration

### Quality tests (`signal_quality_test.exs`)
- Evaluate a fully-specified signal (all dimensions assessed)
- Evaluate a minimal signal (most dimensions :unknown)
- Recency decays with time (fresh signal > stale signal)
- Completeness: signal with all fields filled > signal with half filled
- Measurement quality: `:exact` mode > `:approximate` > `:unknown`
- Aggregate score: properly weighted
- Unknown is returned when evidence insufficient

### Information value tests (`signal_info_value_test.exs`)
- Predictive value with outcome data
- Predictive value without outcome data → `:unknown`
- Information gain: signal that shifts belief > signal that confirms existing belief
- Redundancy: two identical signals → high redundancy
- Redundancy: two orthogonal signals → low redundancy
- Marginal value: first signal > second signal with same content

### Integration tests (`integration_test.exs`)
- Signal → ResearchDirectorAdapter priority conversion (contract verification)
- Signal → CISAdapter telemetry conversion (contract verification)
- Signal contradiction detection via WorldModel.Uncertainty
- Signal normalization via Constraints.normalize_probabilities
- Signal stored in ExecutiveMemory and retrievable

### Determinism/reproducibility tests
- Same inputs → same signal quality assessment
- Same inputs → same information value assessment
- Signal IDs are unique across runs

### Adversarial tests
- Signal with nil source
- Signal with future timestamp
- Signal with expired expires_at
- Signal with all nil quality fields
- Signal with contradictory metadata (high reliability but nil source_reliability)
- Register 10,000 signals — no performance degradation

---

## 8. Certification Gates

| Gate | Criterion | Verification |
|---|---|---|
| D1-SIG-STRUCT | Signal struct has all required fields, enforces keys, new/1 works | Unit test |
| D1-SIG-VERSION | version/2 creates new version, supersedes link correct | Unit test |
| D1-REG-REGISTER | Register and retrieve signal | Registry test |
| D1-REG-INDEX | Query by source, domain, time range | Registry test |
| D1-REG-LINEAGE | EventStore lineage created on registration | Registry test |
| D1-REG-DEDUP | Deduplication by source+observation hash | Registry test |
| D1-REG-SUPERSEDE | Supersede creates new version, old marked | Registry test |
| D1-QUAL-EVAL | Quality evaluation returns valid struct with scores | Quality test |
| D1-QUAL-UNKNOWN | Insufficient data → :unknown (not fabricated score) | Quality test |
| D1-QUAL-DECAY | Recency decays with time | Quality test |
| D1-INFO-PRED | Predictive value with outcome data | InfoValue test |
| D1-INFO-UNKNOWN | Predictive value without outcome data → :unknown | InfoValue test |
| D1-INFO-GAIN | Information gain correctly measures belief shift | InfoValue test |
| D1-INFO-REDUND | Redundancy detection works | InfoValue test |
| D1-ADAPTER-RESEARCH | ResearchDirectorAdapter contract defined | Compilation |
| D1-ADAPTER-CIS | CISAdapter contract defined | Compilation |
| D1-NO-DUPLICATE | No evidence ontology duplication | Architecture review |
| D1-CONSTITUTIONAL | Epistemic status preserved (signal ≠ evidence ≠ forecast) | Code review |
| D1-TESTS-PASS | All tests pass | `mix test test/tiannara/efdi` |
| D1-COMPILE | Clean compilation, no warnings | `mix compile --warnings-as-errors` |

---

## 9. Architectural Risks

| Risk | Severity | Mitigation |
|---|---|---|
| ExecutiveMemory availability | High | SignalRegistry must handle DETS unavailable gracefully |
| EventStore serialization | Medium | Signal structs must implement `Event.to_binary/1` or use JSON |
| ETS memory pressure | Low | Signals are lightweight; 10K signals ≈ small memory footprint |
| Domain-neutral design too generic | Medium | Include concrete examples from ecology, engineering domains |
| Adapter contracts too abstract | Low | Include concrete function signatures, not just callbacks |

---

## 10. Deliberately NOT Implemented in D1

- Forecasting engine (D2)
- Calibration engine (D2)
- Base rate engine (D2)
- Ensemble engine (D2)
- Decision engine (D3)
- Counterfactual engine (D4)
- Noise engine (D5)
- Forecast memory (D6)
- Real predictive performance tracking (requires outcome data)
- Empirical signal value learning (requires historical outcomes)
- CIS integration logic (adapter only)
- Research Director integration logic (adapter only)
- AEO integration
- World Model integration beyond existing Uncertainty module
