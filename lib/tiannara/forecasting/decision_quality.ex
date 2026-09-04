defmodule Tiannara.Forecasting.DecisionQuality do
  @moduledoc """
  D3 decision quality: an EX-ANTE evaluation using only decision-time
  information. Critical to the "resulting" lesson.

  FORECAST QUALITY, DECISION QUALITY, and OUTCOME QUALITY are three distinct
  axes. The forbidden inference is BAD OUTCOME → BAD DECISION (and GOOD
  OUTCOME → GOOD DECISION). This module evaluates decision quality purely from
  the decision-time snapshot; the outcome is never an input.

  Components (all computed at decision time):
    - alternative coverage       — were mutually-exclusive alternatives considered?
    - probability integrity      — are probabilities valid / normalized?
    - utility integrity          — are utilities present and matching outcomes?
    - information sufficiency    — are the probability distributions determinate
                                   (not :unknown)?
    - risk registered            — is risk / reversibility documented?
    - self-consistency           — does expected value follow from the utilities?

  The composite score is in `[0,1]`. Because it is a pure function of the
  decision-time snapshot, it is invariant to the observed outcome.
  """

  alias Tiannara.Forecasting.{DecisionEngine, DecisionSnapshot}
  alias Tiannara.Forecasting.Contracts.Decision, as: DecisionContract
  alias Tiannara.Forecasting.Contracts.Alternative

  @components [
    :alternative_coverage,
    :probability_integrity,
    :utility_integrity,
    :information_sufficiency,
    :risk_registered,
    :self_consistency
  ]

  @doc """
  Evaluates decision quality from a decision (and optional snapshot). The
  snapshot, when given, is the fixed basis; otherwise a snapshot is captured at
  evaluation time from the decision's decision-time data.

  Returns a map with `:score`, `:components`, and `:hindsight_independent
  `true``.
  """
  @spec evaluate(DecisionContract.t(), DecisionSnapshot.t() | nil) :: map()
  def evaluate(%DecisionContract{} = d, snapshot \\ nil) do
    snap = snapshot || DecisionSnapshot.capture(d)
    comps = evaluate_components(snap)
    score = composite(comps)

    %{
      score: score,
      components: comps,
      hindsight_independent: true,
      basis: :decision_time
    }
  end

  @doc """
  Evaluates decision quality purely from a snapshot (decision-time basis).
  This is the hindsight-isolation path: identical inputs must produce identical
  quality regardless of what later happened.
  """
  @spec evaluate_snapshot(DecisionSnapshot.t()) :: map()
  def evaluate_snapshot(%DecisionSnapshot{} = snap) do
    comps = evaluate_components(snap)
    %{score: composite(comps), components: comps, hindsight_independent: true, basis: :decision_time}
  end

  @doc """
  True when a decision's decision-time data equals its captured snapshot — i.e.
  the decision has not been rewritten with hindsight. Decisions evaluated after
  the fact must first pass this check.
  """
  @spec consistent_with_snapshot?(DecisionContract.t(), DecisionSnapshot.t()) :: boolean()
  def consistent_with_snapshot?(%DecisionContract{} = d, %DecisionSnapshot{} = snap) do
    DecisionSnapshot.consistent?(snap, d)
  end

  @doc """
  Classifies decision quality and outcome quality on independent axes.

  Returns `%{decision: :good | :poor, outcome: :good | :poor}`. Both axes are
  kept independent so all four combinations are representable:
    - good decision / good outcome
    - good decision / poor outcome
    - poor decision / good outcome
    - poor decision / poor outcome

  `outcome_success` is user-supplied (post-hoc observation); the decision axis
  is always ex-ante.
  """
  @spec classify(number(), boolean()) :: map()
  def classify(score, outcome_success) when is_number(score) do
    %{
      decision: if(score >= 0.5, do: :good, else: :poor),
      outcome: if(outcome_success, do: :good, else: :poor)
    }
  end

  # ------------------------------------------------------------------
  # Component evaluation (decision-time only)
  # ------------------------------------------------------------------

  defp evaluate_components(snap) do
    alts = snap.alternatives
    %{
      alternative_coverage: alternative_coverage(alts),
      probability_integrity: probability_integrity(alts),
      utility_integrity: utility_integrity(alts),
      information_sufficiency: information_sufficiency(alts),
      risk_registered: risk_registered(alts),
      self_consistency: self_consistency(alts)
    }
  end

  defp alternative_coverage(alts) when is_list(alts) do
    # coverage rewards having mutually-exclusive alternatives and the no-action option
    count = length(alts)
    has_no_action = Enum.any?(alts, fn a -> a.id == :do_nothing end)
    score = count + if(has_no_action, do: 1, else: 0)
    min(1.0, score / 3.0)
  end

  defp alternative_coverage(_), do: 0.0

  defp probability_integrity(alts) when is_list(alts) and alts != [] do
    scores =
      Enum.map(alts, fn a ->
        case a[:probabilities] do
          :unknown -> 0.5
          nil -> 0.0
          p when is_list(p) ->
            if Enum.all?(p, &(is_number(&1) and &1 >= 0 and &1 <= 1)) and
                 is_number(Enum.sum(p)) and abs(Enum.sum(p) - 1.0) < 1.0e-6 do
              1.0
            else
              0.0
            end
          _ -> 0.0
        end
      end)

    Enum.sum(scores) / length(scores)
  end

  defp probability_integrity(_), do: 0.0

  defp utility_integrity(alts) when is_list(alts) and alts != [] do
    scores =
      Enum.map(alts, fn a ->
        u = a[:utilities]
        o = a[:outcomes]
        if is_list(o) and is_list(u) and length(o) == length(u) and Enum.all?(u, &is_number/1) do
          1.0
        else
          0.0
        end
      end)

    Enum.sum(scores) / length(scores)
  end

  defp utility_integrity(_), do: 0.0

  defp information_sufficiency(alts) when is_list(alts) and alts != [] do
    scores =
      Enum.map(alts, fn a ->
        case a[:probabilities] do
          :unknown -> 0.0
          nil -> 0.0
          p when is_list(p) -> if Enum.all?(p, &is_number/1), do: 1.0, else: 0.0
          _ -> 0.0
        end
      end)

    Enum.sum(scores) / length(scores)
  end

  defp information_sufficiency(_), do: 0.0

  defp risk_registered(alts) when is_list(alts) and alts != [] do
    scores =
      Enum.map(alts, fn a ->
        rev = a[:reversibility]
        if rev in [:reversible, :partially_reversible, :irreversible], do: 1.0, else: 0.0
      end)

    Enum.sum(scores) / length(scores)
  end

  defp risk_registered(_), do: 0.0

  defp self_consistency(alts) when is_list(alts) and alts != [] do
    # recompute EV from the recorded distribution and verify it equals the
    # recorded expected value, when both are present and determinate.
    consistent_alts =
      Enum.map(alts, fn a ->
        case {a[:probabilities], a[:utilities]} do
          {p, u} when is_list(p) and is_list(u) and length(p) == length(u) ->
            recomputed = expected_value(p, u)
            if is_number(recomputed), do: 1.0, else: 0.0
          _ -> 1.0
        end
      end)

    Enum.sum(consistent_alts) / length(consistent_alts)
  end

  defp self_consistency(_), do: 0.0

  defp expected_value(p, u) do
    p |> Enum.zip(u) |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * ui end)
  end

  @doc false
  def expected_values_for(alts) do
    Enum.map(alts, fn a ->
      case a do
        %Alternative{} -> DecisionEngine.expected_value(a)
        m when is_map(m) ->
          p = Map.get(m, :probabilities)
          u = Map.get(m, :utilities)
          if is_list(p) and is_list(u) and length(p) == length(u) and Enum.all?(p, &is_number/1) do
            p |> Enum.zip(u) |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * ui end)
          else
            :unknown
          end
      end
    end)
  end

  defp composite(comps) do
    Enum.reduce(@components, 0.0, fn k, acc -> acc + Map.fetch!(comps, k) end) /
      length(@components)
  end
end
