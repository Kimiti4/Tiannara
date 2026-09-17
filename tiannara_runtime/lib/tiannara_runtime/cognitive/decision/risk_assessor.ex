defmodule TiannaraRuntime.Cognitive.Decision.RiskAssessor do
  @moduledoc "Phase 18.6 — Assesses risk dimensions for decision candidates"

  def assess(candidate) do
    plan = Map.get(candidate, :plan, %{})
    execution_risk = clamp(calc_risk(plan, :execution_risk, 0.3))
    scientific_risk = clamp(calc_risk(plan, :scientific_risk, 0.2))
    governance_risk = clamp(calc_risk(plan, :governance_risk, 0.1))
    resource_risk = clamp(calc_risk(plan, :resource_risk, 0.3))
    uncertainty = clamp(calc_risk(plan, :uncertainty, 0.4))
    constitutional_complexity = clamp(calc_risk(plan, :constitutional_complexity, 0.2))
    overall = (execution_risk + scientific_risk + governance_risk + resource_risk + uncertainty + constitutional_complexity) / 6.0
    {:ok, %{candidate_id: Map.get(candidate, :id), execution_risk: execution_risk, scientific_risk: scientific_risk, governance_risk: governance_risk, resource_risk: resource_risk, uncertainty: uncertainty, constitutional_complexity: constitutional_complexity, overall: overall, assessed_at: :erlang.unique_integer([:positive])}}
  end

  def compare(risk_a, risk_b) do
    dims = [:execution_risk, :scientific_risk, :governance_risk, :resource_risk, :uncertainty, :constitutional_complexity]
    {a_higher, rest} = Enum.split_with(dims, fn d -> Map.get(risk_a, d, 0) > Map.get(risk_b, d, 0) end)
    {b_higher, equal} = Enum.split_with(rest, fn d -> Map.get(risk_a, d, 0) < Map.get(risk_b, d, 0) end)
    {:ok, %{a_higher_in: a_higher, b_higher_in: b_higher, equal_in: equal}}
  end

  defp calc_risk(plan, key, default) do
    Map.get(plan, key, default)
  end

  defp clamp(val) when val < 0.0, do: 0.0
  defp clamp(val) when val > 1.0, do: 1.0
  defp clamp(val), do: val
end
