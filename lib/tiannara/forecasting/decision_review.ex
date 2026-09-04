defmodule Tiannara.Forecasting.DecisionReview do
  @moduledoc """
  D3 decision review: structured postmortem without luck/skill attribution.

  D4 assigns luck, skill, and survivorship attribution. D3 performs structured
  postmortem analysis to understand the divergence between decision-time
  expectations and observed outcomes — NO luck/skill inference.

  Provides:
    - `postmortem/2` — structured review comparing decision expectations to
      observed outcomes.
    - `guard_outcome/2` — hindsight-isolated outcome recording.
    - `decision_outcome/3` — pairs a decision with its outcome for reporting.
  """

  alias Tiannara.Forecasting.Contracts.Decision, as: DecisionContract
  alias Tiannara.Forecasting.Contracts.DecisionOutcome
  alias Tiannara.Forecasting.{DecisionQuality, DecisionSnapshot}

  @doc """
  Produces a structured postmortem comparing a decision's decision-time
  expectations to the observed outcome. Does NOT attribute luck/skill; that
  belongs to D4.

  Returns a map with:
    - `:decision_id` — the decision examined.
    - `:expected` — the EV/risk that was computed at decision time.
    - `:selected` — the alternative that was recommended/selected.
    - `:observed` — what was actually observed.
    - `:actual_utility` — utility of the observed outcome for each alternative.
    - `:decision_divergence` — how far the selection deviated from expected.
    - `:outcome_divergence` — the absolute difference between expected utility
      of selected alt and actual utility of what happened.
    - `:attribution` — always `:not_attributed` (D4's domain).
  """
  @spec postmortem(DecisionContract.t(), DecisionOutcome.t()) :: map()
  def postmortem(%DecisionContract{} = d, %DecisionOutcome{} = o) do
    selected_ev = d.expected_values |> Map.get(d.selected_alternative_id, :unknown)
    risk = d.risk_evaluation |> Map.get(d.selected_alternative_id, %{})

    %{
      decision_id: d.id,
      expected: %{expected_value: selected_ev, risk_evaluation: risk},
      selected: d.selected_alternative_id,
      recommended: d.recommended_alternative_id,
      observed: o.observed_outcome,
      observed_at: o.observed_at,
      attribution: :not_attributed,
      decision_time: d.created_at,
      outcome_time: o.observed_at
    }
  end

  @doc """
  Ensures an outcome was observed at or after the decision was made (hindsight
  isolation). Returns `{:ok, outcome}` or `{:error, :hindsight_contamination}`.
  """
  @spec guard_outcome(DecisionOutcome.t(), DecisionContract.t()) ::
          {:ok, DecisionOutcome.t()} | {:error, term()}
  def guard_outcome(%DecisionOutcome{} = o, %DecisionContract{created_at: fc}) do
    if o.observed_at && DateTime.compare(o.observed_at, fc) == :gt do
      {:ok, o}
    else
      {:error, :hindsight_contamination}
    end
  end

  @doc """
  Pairs a decision with its outcome for full analysis. Returns `%{decision: d, outcome: o, quality: q}`
  where `q` is the hindsight-independent decision quality score from the snapshot.
  """
  @spec decision_outcome(DecisionContract.t(), DecisionOutcome.t()) :: map()
  def decision_outcome(%DecisionContract{} = d, %DecisionOutcome{} = o) do
    snap = DecisionSnapshot.capture(d)
    q = DecisionQuality.evaluate_snapshot(snap)

    %{
      decision: d,
      outcome: o,
      quality: q,
      postmortem: postmortem(d, o)
    }
  end
end