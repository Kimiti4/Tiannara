defmodule Tiannara.Forecasting.Contracts do
  @moduledoc """
  The EFDI D1 contract-layer for D2-D6.

  D1 defines the stable interfaces that the later EFDI packages will consume.
  D1 does NOT implement these — it documents the contracts so no parallel
  ontology or interface drift occurs when D2-D6 are built.

  Contracts defined here (all consumers of signals):

    - Forecast (D2)  — SignalSet + EvidenceSet + BaseRate + Context →
                       Forecast distribution
    - Calibration (D2) — Forecast → Outcome → Brier / LogLoss / reliability
    - Decision (D3)  — Forecast → Alternatives → Expected Value → Decision
    - Counterfactual (D4) — Outcome → Alternative Histories → luck/skill
    - Noise (D5)     — identical problem through multiple paths → disagreement
    - Memory (D6)    — Signal → Forecast → Decision → Outcome → Lesson (immutable)

  Constitutional rules surfaced here:
    - Forecast confidence ≠ authorization.
    - UNKNOWN is distinct from 0.0.
    - low confidence ≠ low probability.
    - model disagreement ≠ evidence contradiction.

  The types below are documented behavioural contracts. D2-D6 modules MUST
  implement `@behaviour Tiannara.Forecasting.Contracts` subsets as they land.
  """

  defmodule ForecastRequest do
    @moduledoc "Input contract for the D2 forecasting engine."
    defstruct [
      :signal_ids,
      :evidence_ids,
      :base_rate,
      :context,
      :model,
      :assumptions,
      :horizon,
      :question,
      # D2 fields
      :event,
      :outcomes,
      :regime
    ]

    @type t :: %__MODULE__{}
  end

  defmodule Forecast do
    @moduledoc """
    Output contract for the D2 forecasting engine (immutable).

    A Forecast is an immutable, evidence-linked, explicitly uncertain
    probability distribution over mutually exclusive outcomes. It is NOT a
    decision, a fact, or an authorization.

    D2 field notes:
      - `probabilities` preserves the full distribution; `confidence` is a
        separate, non-interchangeable quantity.
      - `UNKNOWN` probabilities are valid and distinct from `0.0`.
      - `lineage` records ancestor forecast ids; history is never overwritten.
    """
    defstruct [
      # D1 base identity/contract fields
      :id,
      :question,
      :probability,
      :distribution,
      :uncertainty,
      :evidence_id,
      :created_at,
      :models,
      :disagreement,
      :lineage,
      # D2 fields
      :event,
      :outcomes,
      :horizon,
      :forecast_version,
      :signal_refs,
      :evidence_refs,
      :base_rate_ref,
      :model_ref,
      :assumptions,
      :unknowns,
      :probabilities,
      :confidence,
      :context,
      :regime,
      :provenance
    ]

    @type t :: %__MODULE__{}
  end

  defmodule BaseRate do
    @moduledoc "Base-rate contract for the D2 base-rate engine."
    defstruct [
      :reference_class,
      :historical_frequency,
      :sample_size,
      :selection_conditions,
      :regime_conditions,
      :confidence,
      :source,
      # D2 fields
      :data_quality,
      :base_rate_uncertainty
    ]

    @type t :: %__MODULE__{}
  end

  defmodule Alternative do
    @moduledoc """
    D3: a single mutually-exclusive decision alternative.

    An `Alternative` bundles an action label with the decision-time probability
    distribution over outcomes and a utility assignment per outcome. Expected
    value is computed from these decision-time quantities — never from hindsight.

    Fields:
      - `id` — alternative identifier within the decision.
      - `label` — short descriptive name.
      - `probabilities` — decision-time distribution over `outcomes` (length must
        match `outcomes`; values in `[0,1]`, sum ≈ 1, or `:unknown`).
      - `outcomes` — ordered outcome labels.
      - `utilities` — utility per outcome (real number, same length as outcomes).
      - `risk` — optional quantitative risk assessment (map or scalar).
      - `reversibility` — `:reversible | :partially_reversible | :irreversible`
        (decision-time knowledge).
      - `assets_at_risk` — information about what could be lost (decision-time).

    A default no-action alternative `:do_nothing` is always available so a
    decision can compare against inaction.
    """
    defstruct [
      :id,
      :label,
      :probabilities,
      :outcomes,
      :utilities,
      :risk,
      :reversibility,
      :assets_at_risk
    ]

    @type reversibility :: :reversible | :partially_reversible | :irreversible
    @type t :: %__MODULE__{}
  end

  defmodule DecisionRequest do
    @moduledoc """
    D3: input contract for the decision engine.

    Carries the decision question plus an ordered list of `Alternative`
    structs. The engine computes expected value, risk, and selects a
    recommendation — it does NOT authorize.
    """
    defstruct [:decision_id, :question, :alternatives, :context, :horizon]

    @type t :: %__MODULE__{}
  end

  defmodule Decision do
    @moduledoc """
    D3: immutable decision record.

    Captures what was decided, on what information, and with what expected —
    value and risk — computed at decision time. It is deliberately NOT an
    authorization (a separate `Council.Authorization` governs permission).

    Constitutional rules:
      - The decision snapshots decision-time information only.
      - `recommended_alternative_id` is a recommendation, never a mandate.
      - `selected_by` records the actor; execution is a downstream, separately
        authorized step.
      - Where decision-time information is genuinely insufficient, alternatives
        carry `probabilities: :unknown` and the engine reports `:insufficient`
        rather than fabricating a recommendation.
    """
    defstruct [
      :id,
      :question,
      :alternatives,
      :recommended_alternative_id,
      :selected_alternative_id,
      :expected_values,
      :risk_evaluation,
      :context,
      :created_at,
      :decision_version,
      :lineage,
      :forecast_refs,
      :decisioner
    ]

    @type t :: %__MODULE__{}
  end

  defmodule DecisionOutcome do
    @moduledoc """
    D3: observed outcome of a decided action, hindsight-isolated.

    Links a `Decision` to the observed outcome and the alternative that was
    actually executed. `observed_at` must be after `decision.created_at`
    (hindsight isolation). D3 does not attribute luck/skill (that is D4); it
    records the mapping for structured postmortem.
    """
    defstruct [:decision_id, :alternative_id, :observed_outcome, :observed_at, :source]

    @type t :: %__MODULE__{}
  end

  defmodule InterventionSpec do
    @moduledoc """
    D4: explicit intervention specification.

    OBSERVE X is NOT SET X = x. The `kind` distinguishes observation-only
    analyses from interventions that posit a change; `target_variables` and
    `value` make the posited change explicit. A record built from an
    OBSERVE_ONLY spec is structurally incapable of claiming an intervention
    effect.
    """
    defstruct [
      :kind,              # :set | :observe_only | :policy | :information | :timing | :do_nothing | :defer
      :target_variables,  # [term()]
      :value,             # set value when kind == :set
      :do_semantics,      # text note making semantics explicit
      :description
    ]

    @type kind ::
            :set
            | :observe_only
            | :policy
            | :information
            | :timing
            | :do_nothing
            | :defer

    @type t :: %__MODULE__{}
  end

  defmodule CounterfactualRecord do
    @moduledoc """
    D4: a counterfactual record — a labeled analytical record, never a fact.

    Status ontology (never collapsed to boolean):
      OBSERVED            — real history; assignable ONLY via the D1 ingestion
                            path, never by D4 analysis.
      HYPOTHETICAL        — a plausible alternative not observed.
      COUNTERFACTUAL      — an alternative history branching from a baseline.
      SUPPORTED           — supported by evidence refs.
      WEAKLY_SUPPORTED    — partial evidence support.
      UNDERDETERMINED     — not resolvable with available information.
      INVALID             — rejected by validation.
      UNKNOWN             — genuinely unknown (distinct from 0.0/false).

    `reference.baseline_state_ref` is a content hash; records branch from a
    baseline and never mutate it. There is no merge operation and no promotion
    of a counterfactual node to OBSERVED.
    """
    defstruct [
      :counterfactual_id,
      :schema_version,
      :status,
      :intervention,
      :parent_ref,
      :assumptions,          # %{} with :causal_structure_ref, :independence, ... :assumption_evidence_map, :unsupported_assumptions
      :affected_variables,
      :expected_outcomes,    # %{distribution: ... | :unknown, point_estimate: ...}
      :uncertainty,          # %{aleatoric: ..., epistemic: ..., structural: ...}
      :provenance,           # %{created_by, model_version, seed, lineage_event_ref}
      :reference,            # %{observed_event_id, d3_decision_snapshot_id, baseline_state_ref}
      :created_at
    ]

    @type status ::
            :observed
            | :hypothetical
            | :counterfactual
            | :supported
            | :weakly_supported
            | :underdetermined
            | :invalid
            | :unknown

    @type t :: %__MODULE__{}
  end

  defmodule AlternativeHistoryBundle do
    @moduledoc """
    D4: a bounded distribution of alternative histories for one decision.

    A bundle holds a list of `CounterfactualRecord`s branching from a `Decision`
    snapshot baseline. It ALWAYS includes the no-action alternative
    (`:do_nothing`) so a consequential decision is never reduced to a
    cherry-picked single alternative. Bundles are bounded
    (`max_alternatives`, default 8) with deterministic exclusion records.
    """
    defstruct [
      :bundle_id,
      :decision_id,
      :baseline_state_ref,
      :alternatives,          # [CounterfactualRecord.t()]
      :includes_do_nothing,   # boolean()
      :excluded_alternatives, # [%{id, reason}]
      :max_alternatives,
      :created_at
    ]

    @type t :: %__MODULE__{}
  end

  defmodule AttributionReport do
    @moduledoc """
    D4: bounded luck/skill attribution report.

    Default status is `NOT_ATTRIBUTED`. Attribution flips only above configured
    evidence thresholds, and the thresholds themselves carry provenance
    (`thresholds_provenance`). Single outcomes cannot be attributed; D4 never
    infers BAD OUTCOME → BAD DECISION or GOOD OUTCOME → GOOD DECISION.
    """
    defstruct [
      :report_id,
      :decision_id,
      :status,               # :not_attributed | :likely_luck | :likely_skill | :mixed | :insufficient_evidence
      :repeat_count,
      :threshold,
      :prior,                # probabilistic prior carried from reference class
      :reference_class_ref,
      :mean_delta,
      :skill_consistency,
      :evidence_summary,
      :thresholds_provenance,
      :alternative_bundle_ref,
      :selection_report_ref,
      :rtm_report_ref,
      :created_at
    ]

    @type status ::
            :not_attributed
            | :likely_luck
            | :likely_skill
            | :mixed
            | :insufficient_evidence

    @type t :: %__MODULE__{}
  end

  defmodule SelectionEffectReport do
    @moduledoc """
    D4: survivorship / selection analysis report.

    Records the selection mechanism and the denominator status
    (`:known | :partial | :unknown`). When the denominator is unknown, the
    selection effect is first-class `UNKNOWN_SELECTION_EFFECT` and
    generalization scope is capped to the observed population.
    """
    defstruct [
      :report_id,
      :selection_mechanism,   # :random | :selected | :self_selected | :survivorship | :availability | :publication | :unknown
      :denominator_status,    # :known | :partial | :unknown
      :population_size,
      :sample_size,
      :generalization_scope,  # :observed_population | :flagged | :unknown
      :detection_flags,       # [term()]
      :created_at
    ]

    @type selection_mechanism ::
            :random
            | :selected
            | :self_selected
            | :survivorship
            | :availability
            | :publication
            | :unknown

    @type t :: %__MODULE__{}
  end

  defmodule RegressionToMeanReport do
    @moduledoc """
    D4: regression-to-the-mean analysis report.

    Measures extremity of an observation against a reference class and reports
    whether reversion is plausible. By construction this schema contains NO
    causal-claim field — RTM analysis is structurally incapable of attributing
    reversion to a cause.
    """
    defstruct [
      :report_id,
      :observations,          # [number()]
      :initial_value,
      :later_mean,
      :reference_class,       # %{mean: number(), std: number()} | nil
      :extremity_index,       # z-score or :unknown
      :rtm_plausibility,      # :likely | :possible | :unlikely | :unknown
      :created_at
    ]

    @type rtm_plausibility :: :likely | :possible | :unlikely | :unknown

    @type t :: %__MODULE__{}
  end
end
