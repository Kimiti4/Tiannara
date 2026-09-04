defmodule Tiannara.CEL.Services.Priority.OutcomeSignal do
  defstruct [
    :workflow_id,
    :completed_at,
    :outcome,
    step_types: [],
    durations: [],
    confidence: 0.5,
    evidence_count: 0,
    quality_metrics: %{},
    resource_usage: %{},
    feature_vector: [],
    target_score: 0.0
  ]

  alias Tiannara.CEL.Workflow.Workflow

  def from_workflow_telemetry(%Workflow{} = wf, outcome) do
    evidence = wf.outcome_evidence || []

    %__MODULE__{
      workflow_id: wf.id,
      step_types: Enum.map(evidence, & &1.step_type),
      durations: Enum.map(evidence, &get_in(&1, [:result, :duration_ms]) || 0),
      confidence: avg_confidence(evidence),
      evidence_count: length(evidence),
      quality_metrics: aggregate_metrics(evidence, :quality_metrics),
      resource_usage: aggregate_metrics(evidence, :resource_usage),
      outcome: outcome,
      completed_at: wf.completed_at || DateTime.utc_now(),
      feature_vector: extract_features(wf, evidence, outcome),
      target_score: composite_score(wf, evidence, outcome)
    }
  end

  def composite_score(_workflow, evidence, outcome) do
    c = avg_confidence(evidence)
    n_evidence = length(evidence)
    n_total = n_evidence + 1
    evidence_ratio = n_evidence / max(1, n_total)
    outcome_score = if outcome == :success, do: 1.0, else: 0.2

    0.30 * c + 0.25 * evidence_ratio + 0.25 * outcome_score + 0.20 * 0.5
  end

  defp avg_confidence([]), do: 0.5
  defp avg_confidence(evidence) do
    scores = Enum.map(evidence, &get_in(&1, [:result, :confidence]) || 0.5)
    Enum.sum(scores) / length(scores)
  end

  defp aggregate_metrics(evidence, key) do
    evidence
    |> Enum.map(&get_in(&1, [:result, key]) || %{})
    |> Enum.reduce(%{}, fn m, acc ->
      Map.merge(acc, m, fn _k, v1, v2 -> v1 + v2 end)
    end)
  end

  defp extract_features(_workflow, evidence, outcome) do
    c = avg_confidence(evidence)
    n_ev = length(evidence)
    evidence_density = n_ev / max(1, n_ev + 1)
    avg_dur = if n_ev > 0 do
      Enum.map(evidence, &(get_in(&1, [:result, :duration_ms]) || 0)) |> Enum.sum() |> Kernel./(n_ev)
    else 0 end
    duration_eff = 1.0 / (1.0 + avg_dur / 1000.0)
    outcome_bit = if outcome == :success, do: 1.0, else: 0.0
    diversity = evidence |> Enum.map(& &1.step_type) |> Enum.uniq() |> length()
    step_div = diversity / max(1, length(evidence) + 1)

    [c, evidence_density, duration_eff, outcome_bit, step_div]
  end
end
