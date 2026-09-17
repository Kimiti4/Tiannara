defmodule TiannaraRuntime.Cognitive.Decision.DecisionEvaluator do
  @moduledoc "Phase 18.6 — Scores and ranks decision candidates"

  def score(candidate) do
    plan = Map.get(candidate, :plan, %{})
    mission_value = clamp(calc_dimension(plan, :mission_value, 0.7))
    scientific_value = clamp(calc_dimension(plan, :scientific_value, 0.5))
    mathematical_value = clamp(calc_dimension(plan, :mathematical_value, 0.4))
    risk = clamp(1.0 - calc_dimension(plan, :risk_factor, 0.3))
    cost = clamp(1.0 - calc_dimension(plan, :cost_factor, 0.3))
    memory = clamp(calc_dimension(plan, :memory_efficiency, 0.6))
    simulation_budget = clamp(calc_dimension(plan, :simulation_budget, 0.5))
    resource_util = clamp(calc_dimension(plan, :resource_utilization, 0.5))
    constitutional_simplicity = clamp(calc_dimension(plan, :constitutional_simplicity, 0.8))
    optionality = clamp(calc_dimension(plan, :optionality, 0.4))
    total = (mission_value + scientific_value + mathematical_value + risk + cost + memory + simulation_budget + resource_util + constitutional_simplicity + optionality) / 10.0
    fingerprint = :crypto.hash(:sha256, "#{Map.get(candidate, :id)}_#{total}") |> Base.encode16(case: :lower)
    {:ok, %{candidate_id: Map.get(candidate, :id), mission_value: mission_value, scientific_value: scientific_value, mathematical_value: mathematical_value, risk: risk, cost: cost, memory: memory, simulation_budget: simulation_budget, resource_util: resource_util, constitutional_simplicity: constitutional_simplicity, optionality: optionality, total: total, fingerprint: fingerprint}}
  end

  def compare(scores_a, scores_b) do
    dims = [:mission_value, :scientific_value, :mathematical_value, :risk, :cost, :memory, :simulation_budget, :resource_util, :constitutional_simplicity, :optionality]
    {a_wins, rest} = Enum.split_with(dims, fn d -> Map.get(scores_a, d, 0) > Map.get(scores_b, d, 0) end)
    {b_wins, tie_in} = Enum.split_with(rest, fn d -> Map.get(scores_a, d, 0) < Map.get(scores_b, d, 0) end)
    {:ok, %{a_wins_in: a_wins, b_wins_in: b_wins, tie_in: tie_in}}
  end

  def rank(candidates) do
    scored = Enum.map(candidates, fn c ->
      {:ok, s} = score(c)
      s
    end)
    {:ok, Enum.sort_by(scored, fn s -> Map.get(s, :total, 0) end, :desc)}
  end

  defp calc_dimension(plan, key, default) do
    Map.get(plan, key, default)
  end

  defp clamp(val) when val < 0.0, do: 0.0
  defp clamp(val) when val > 1.0, do: 1.0
  defp clamp(val), do: val
end
