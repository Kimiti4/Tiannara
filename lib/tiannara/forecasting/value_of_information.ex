defmodule Tiannara.Forecasting.ValueOfInformation do
  @moduledoc """
  D3 Value of Information: expected value of perfect information (EVPI) and
  expected value of sample information (EVSI) bridges between decisions and
  research prioritization.

  EVPI computation operationalizes the prompt: "where additional information
  could change the preferred action" — this is the bridge to Research Director
  → Experiment → Evidence → D2 Forecast Update → D3 re-evaluation.

  Definitions:
    - EVPI = Σ_o p(o) · max_a u_a(o) − max_a Σ_o p(o) · u_a(o)
      — the value of knowing the outcome before deciding.
    - EVSI ≈ uncertainty × impact × feasibility (the OpportunityCost format,
      adapted for decision context).

  The module provides:
    - `expected_value_of_perfect_information/1` — EVPI for a decision.
    - `expected_value_of_information/2` — quick heuristic for research direction.
    - `information_gap/1` — where decision certainty is low, flags for research.
  """

  alias Tiannara.Forecasting.Contracts.Decision, as: DecisionContract
  alias Tiannara.Forecasting.Contracts.Alternative
  alias Tiannara.Forecasting.{Decision, DecisionEngine}

  @doc """
  Expected Value of Perfect Information (EVPI).

  Uses a reference belief distribution derived from the recommended alternative
  (the decision's best estimate of the world) if its probabilities are determinate,
  otherwise falls back to uniform distribution over outcomes.

  EVPI = Σ_o p(o) · max_a u_a(o)  −  max_a EV(a)

  The first term assumes perfect knowledge (optimal action per outcome). The
  second term is the current best expected value.
  """
  @spec expected_value_of_perfect_information(DecisionContract.t()) ::
          float() | :unknown
  def expected_value_of_perfect_information(%DecisionContract{} = d) do
    belief = default_belief(d)

    if belief == :unknown do
      :unknown
    else
      case max_expected_value(d) do
        :unknown -> :unknown
        ev_of_best -> best_per_outcome(belief, d.alternatives) - ev_of_best
      end
    end
  end

  @doc """
  Expected Value of Sample Information (quick heuristic).

  Computes: uncertainty × impact × feasibility.
  Similar to `Discovery.Adaptive.OpportunityCostEstimator.expected_value_of_information/1`
  but adapted to decision context with utilities and risk.

  `uncertainty` — from forecast or decision uncertainty field (0.0–1.0).
  `impact` — estimated swing in utility if the information changes the decision.
  `feasibility` — cost/risk-adjusted ability to gather this info (0.0–1.0).
  """
  @spec expected_value_of_information(
          uncertainty :: number(),
          impact :: number(),
          feasibility :: number()
        ) :: float()
  def expected_value_of_information(uncertainty, impact, feasibility)
      when is_number(uncertainty) and is_number(impact) and is_number(feasibility) do
    uncertainty * impact * feasibility
  end

  @doc """
  Returns the gap between best and second-best expected value among alternatives
  with determinate values. A small gap (near 0) means additional information
  could flip the decision. This is the primary signal for research prioritization.
  """
  @spec decision_sensitivity([map()]) :: float() | :unknown
  def decision_sensitivity(alternatives) when is_list(alternatives) do
    evs =
      alternatives
      |> Enum.map(fn a ->
        p = Map.get(a, :probabilities)
        u = Map.get(a, :utilities)

        if is_list(p) and is_list(u) and length(p) == length(u) and Enum.all?(p, &is_number/1) do
          ev = Enum.reduce(Enum.zip(p, u), 0.0, fn {pi, ui}, acc -> acc + pi * ui end)
          {a.id, ev}
        else
          {a.id, :unknown}
        end
      end)

    determinate = Enum.filter(evs, fn {_, ev} -> is_number(ev) end)

    case determinate do
      [] ->
        :unknown

      [_] ->
        0.0

      _ ->
        values = Enum.map(evs, fn {_, ev} -> ev end) |> Enum.sort(:desc)
        [best, second | _] = values
        best - second
    end
  end

  @doc """
  Indicates which alternatives would benefit most from additional information,
  for the Research Director to prioritize experiments.
  Returns a list of %{alternative_id, ev_gap, reason}.
  """
  @spec information_gap(DecisionContract.t()) :: [map()]
  def information_gap(%DecisionContract{} = d) do
    sensitivity = decision_sensitivity(d.alternatives)

    if sensitivity == :unknown do
      Enum.map(d.alternatives, fn a ->
        %{alternative_id: a.id, ev_gap: :unknown, reason: :insufficient_data}
      end)
    else
      sorted = get_expected_values_sorted(d.alternatives)
      [best | _rest] = sorted
      gap = decision_sensitivity(d.alternatives)

      Enum.map(d.alternatives, fn a ->
        current_ev = DecisionEngine.expected_value(a)
        ev_gap = if is_number(current_ev) and is_number(best.ev), do: abs(current_ev - best.ev), else: :unknown
        %{
          alternative_id: a.id,
          ev_gap: ev_gap,
          reason: analyze_gap(a, gap)
        }
      end)
    end
  end

  @doc """
  Bridge to Research Director: produces priorities for experiments that would
  reduce decision uncertainty. Returns a list of priority maps compatible with
  `Tiannara.Research.ResearchDirector.ingest_priorities/1`.
  """
  @spec to_research_priorities(DecisionContract.t(), opts :: Keyword.t()) :: [map()]
  def to_research_priorities(%DecisionContract{} = d, opts \\ []) do
    threshold = Keyword.get(opts, :sensitivity_threshold, 0.1)

    info_gaps = information_gap(d)

    info_gaps
    |> Enum.filter(fn g -> g.ev_gap > threshold end)
    |> Enum.map(fn %{alternative_id: aid, ev_gap: gap, reason: reason} ->
      %{
        id: "voi_#{aid}",
        level: if(gap > 0.5, do: :immediate, else: :urgent),
        score: min(gap, 1.0),
        source_type: :information_value,
        source_id: d.id,
        domain: d.context[:domain] || :general,
        signal: nil,
        title: "Value-of-Information gathering for alternative #{aid}",
        rationale: reason,
        recommended_action: "Obtain information to reduce uncertainty on alternative #{aid}",
        created_at: DateTime.utc_now(),
        expires_at: nil
      }
    end)
  end

  # ------------------------------------------------------------------
  # Internal helpers
  # ------------------------------------------------------------------

  defp default_belief(%DecisionContract{recommended_alternative_id: rec_id, alternatives: alts}) do
    rec = Enum.find(alts, fn a -> a.id == rec_id end)
    case rec do
      nil -> :unknown
      %Alternative{probabilities: :unknown} -> :unknown
      %Alternative{probabilities: p} when is_list(p) -> p
      _ -> :unknown
    end
  end

  defp max_expected_value(%DecisionContract{alternatives: alts}) do
    alts
    |> Enum.map(fn a -> DecisionEngine.expected_value(a) end)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> :unknown
      values -> Enum.max(values)
    end
  end

  defp best_per_outcome(belief, alts) do
    utilities = collect_utilities(alts)

    belief
    |> Enum.with_index()
    |> Enum.reduce(0.0, fn {p, idx}, acc ->
      max_u = max_utility_for_outcome(utilities, idx)
      acc + p * max_u
    end)
  end

  defp collect_utilities(alts) do
    Enum.map(alts, fn a -> {a.id, a.utilities} end)
  end

  defp max_utility_for_outcome(utilities, idx) do
    utilities
    |> Enum.map(fn {_id, us} -> us |> Enum.at(idx, 0) end)
    |> Enum.max(fn -> 0.0 end)
  end

  defp get_expected_values_sorted(alts) do
    alts
    |> Enum.map(fn a ->
      ev = DecisionEngine.expected_value(a)
      %{id: a.id, ev: ev}
    end)
    |> Enum.filter(fn m -> is_number(m.ev) end)
    |> Enum.sort_by(& &1.ev, :desc)
  end

  defp analyze_gap(_a, gap) when gap > 0.5, do: "high_decision_sensitivity"
  defp analyze_gap(_a, gap) when gap > 0.2, do: "medium_decision_sensitivity"
  defp analyze_gap(_a, _gap), do: "low_decision_sensitivity"
end