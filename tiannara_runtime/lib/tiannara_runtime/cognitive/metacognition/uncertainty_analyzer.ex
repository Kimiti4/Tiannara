defmodule TiannaraRuntime.Cognitive.Metacognition.UncertaintyAnalyzer do
  @moduledoc "Phase 18.8 — Aleatoric and epistemic uncertainty analysis"

  def analyze(decision, plan, outcomes) do
    {:ok, aleatoric_val} = aleatoric(outcomes)
    {:ok, epistemic_val} = epistemic(decision, plan)
    {:ok, total_val} = total(aleatoric_val, epistemic_val)
    {:ok, %{aleatoric: aleatoric_val, epistemic: epistemic_val, total: total_val, sources: [%{type: :aleatoric, value: aleatoric_val, source: "outcome_variance"}, %{type: :epistemic, value: epistemic_val, source: "incomplete_knowledge"}], computed_at: :erlang.unique_integer([:positive])}}
  end

  def aleatoric(outcomes) do
    count = length(outcomes)
    result = if count < 2 do
      0.0
    else
      mean = Enum.sum(outcomes) / count
      Enum.reduce(outcomes, 0.0, fn x, acc -> acc + (x - mean) ** 2 end) / count
    end
    {:ok, min(result, 1.0)}
  end

  def epistemic(decision, plan) do
    plan_fields = if is_map(plan), do: map_size(plan), else: 0
    total_fields = plan_fields + (if is_map(decision), do: map_size(decision), else: 0)
    missing = if is_map(plan), do: Enum.count(plan, fn {_, v} -> is_nil(v) end), else: 0
    ratio = if total_fields > 0, do: missing / total_fields, else: 1.0
    {:ok, min(ratio, 1.0)}
  end

  def total(aleatoric, epistemic) do
    {:ok, min(:math.sqrt((aleatoric ** 2 + epistemic ** 2) / 2.0), 1.0)}
  end
end
