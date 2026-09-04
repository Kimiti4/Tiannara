defmodule Tiannara.Forecasting.Attribution do
  @moduledoc """
  D4 bounded luck/skill attribution.

  Attribution is boundary-guarded: single outcomes are NOT attributed, and a
  flip off `:not_attributed` happens only above configured evidence thresholds
  which themselves carry provenance (`thresholds_provenance`). The module never
  infers BAD OUTCOME → BAD DECISION or GOOD OUTCOME → GOOD DECISION.

  Inputs are a D3 `Decision` (read-only) plus a list of D3 `DecisionOutcome`
  records. Expected utility per outcome is recomputed from the decision-time
  distribution; actual utility is looked up from the observed outcome in the
  executed alternative's decision-time utility list — so both sides use
  decision-time information only.
  """

  alias Tiannara.Forecasting.Decision
  alias Tiannara.Forecasting.Contracts.{AttributionReport, Decision, DecisionOutcome}

  @default_n_min 3
  @default_skill_margin 0.1
  @default_skill_consistency 0.6

  @statuses [:not_attributed, :likely_luck, :likely_skill, :mixed, :insufficient_evidence]

  @doc false
  def statuses, do: @statuses

  @type t :: AttributionReport.t()

  @doc """
  Analyzes a decision against repeated observed outcomes.

  opts:
    - `:n_min`               minimum evidence repetitions before attribution may
                             leave `:not_attributed` (default 3).
    - `:skill_margin`        mean delta required (default 0.1).
    - `:skill_consistency`   min fraction of same-signed deltas (default 0.6).
    - `:prior`               reference-class prior probability of skill.
    - `:reference_class_ref` reference to the D2 base-rate reference class.
    - `:alternative_bundle_ref`, `:selection_report_ref`, `:rtm_report_ref`
  """
  @spec analyze(Decision.t(), [DecisionOutcome.t()], map() | Keyword.t()) :: AttributionReport.t()
  def analyze(%Decision{} = d, outcomes, opts \\ []) when is_map(opts) or is_list(opts) do
    o = Map.new(opts)
    n_min = Map.get(o, :n_min, @default_n_min)
    margin = Map.get(o, :skill_margin, @default_skill_margin)
    consistency_min = Map.get(o, :skill_consistency, @default_skill_consistency)

    deltas = deltas(d, outcomes)
    n = length(deltas)
    mean_delta = mean_delta(deltas)
    consistency = signed_consistency(deltas, mean_delta, margin)

    status = classify(n, n_min, mean_delta, consistency, margin, consistency_min)

    %AttributionReport{
      report_id: "attr_" <> Tiannara.Executive.Types.new_id(),
      decision_id: d.id,
      status: status,
      repeat_count: n,
      threshold: n_min,
      prior: Map.get(o, :prior),
      reference_class_ref: Map.get(o, :reference_class_ref),
      mean_delta: mean_delta,
      skill_consistency: consistency,
      evidence_summary: %{
        expected_utilities: Enum.map(deltas, & &1.expected),
        actual_utilities: Enum.map(deltas, & &1.actual),
        known_outcomes: n,
        unknown_outcomes: length(outcomes) - n
      },
      thresholds_provenance: %{
        n_min: [n_min, :repeat_count_evidence_threshold],
        skill_margin: [margin, :mean_delta_gate],
        skill_consistency: [consistency_min, :signed_consistency_gate]
      },
      alternative_bundle_ref: Map.get(o, :alternative_bundle_ref),
      selection_report_ref: Map.get(o, :selection_report_ref),
      rtm_report_ref: Map.get(o, :rtm_report_ref),
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Reflects a compute-only evaluation that could not see real outcomes: status is
  always `:not_attributed`, unsupportable by design.
  """
  @spec reify_attribution_guardance(Decision.t()) :: AttributionReport.t()
  def reify_attribution_guardance(%Decision{} = d) do
    %AttributionReport{
      report_id: "attr_guard_" <> Tiannara.Executive.Types.new_id(),
      decision_id: d.id,
      status: :not_attributed,
      repeat_count: 0,
      threshold: @default_n_min,
      thresholds_provenance: %{},
      created_at: DateTime.utc_now()
    }
  end

  @doc false
  def default_n_min, do: @default_n_min

  # ------------------------------------------------------------------
  # Evidence computation (decision-time only)
  # ------------------------------------------------------------------

  defp deltas(_d, outcomes) when not is_list(outcomes), do: []

  defp deltas(d, outcomes) do
    Enum.filter_map(outcomes, fn o ->
      match?({:ok, _, _}, outcome_delta(d, o))
    end, fn o ->
      {:ok, expected, actual} = outcome_delta(d, o)
      %{expected: expected, actual: actual, outcome: o.observed_outcome}
    end)
  end

  # expected == actual contribution only when the alternative is unknown/no-evidence;
  # never double-counts, and unknown outcomes are recorded separately.
  defp outcome_delta(d, %DecisionOutcome{} = o) do
    alt = Enum.find(d.alternatives, fn a -> a.id == o.alternative_id end)

    with %{probabilities: p, utilities: u, outcomes: os}
           when is_list(p) and is_list(u) and is_list(os) <- alt,
         expected when is_number(expected) <- expected(p, u),
         idx when is_integer(idx) <- Enum.find_index(os, &(&1 == o.observed_outcome)),
         actual when is_number(actual) <- Enum.at(u, idx) do
      {:ok, expected, actual}
    else
      _ -> :error
    end
  end

  defp outcome_delta(_d, _), do: :error

  defp expected(p, u) when is_list(p) and is_list(u) and length(p) == length(u) do
    p |> Enum.zip(u) |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * ui end)
  end

  defp expected(_p, _u), do: :error

  defp mean_delta([]), do: nil

  defp mean_delta(deltas) do
    diffs = Enum.map(deltas, fn d -> d.actual - d.expected end)
    Enum.sum(diffs) / length(diffs)
  end

  defp signed_consistency([], _mean, _margin), do: nil

  defp signed_consistency(deltas, mean, margin) do
    denom =
      Enum.count(deltas, fn d ->
        is_number(d.expected) and is_number(d.actual)
      end)

    if denom == 0 do
      nil
    else
      matches =
        Enum.count(deltas, fn d ->
          diff = d.actual - d.expected
          (mean >= margin and diff >= 0) or (mean <= -margin and diff <= 0) or
            (abs(mean) < margin and abs(diff) < margin)
        end)

      matches / denom
    end
  end

  # ------------------------------------------------------------------
  # Classification
  # ------------------------------------------------------------------

  defp classify(_n, n_min, _mean, _consistency, _margin, _consistency_min) when n_min < 1,
    do: :not_attributed

  defp classify(n, _n_min, _mean, _consistency, _margin, _consistency_min) when n < 1,
    do: :not_attributed

  defp classify(n, n_min, _mean, _consistency, _margin, _consistency_min) when n < n_min,
    do: :not_attributed

  defp classify(_n, _n_min, mean, consistency, margin, consistency_min)
       when is_number(mean) and is_number(consistency) do
    cond do
      consistency >= consistency_min and mean >= margin -> :likely_skill
      consistency >= consistency_min and mean <= -margin -> :likely_luck
      true -> :mixed
    end
  end

  defp classify(n, _n_min, _mean, _consistency, _margin, _consistency_min) when n >= 1, do: :mixed
end