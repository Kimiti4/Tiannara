defmodule Tiannara.Sentinel.Validation.AnomalyInjector do
  @moduledoc """
  Generates deterministic anomalies where the optimal action and outcome are known in advance.
  """
  
  def generate(count \\ 1) do
    Enum.map(1..count, fn i -> 
      type = random_type()
      %{
        id: "anom_#{i}_#{:os.system_time(:millisecond)}",
        type: type,
        expected_best_action: optimal_action(type),
        worst_possible_action: worst_action(type),
        severity: :rand.uniform() * 0.5 + 0.5
      }
    end)
  end

  defp random_type do
    Enum.random([
      :type_a_runtime_pressure,
      :type_b_entropy_growth,
      :type_c_semantic_fragmentation,
      :type_d_forecast_divergence,
      :type_e_causal_branch_instability
    ])
  end

  def optimal_action(:type_a_runtime_pressure), do: :constraint_tightening
  def optimal_action(:type_b_entropy_growth), do: :entropy_rebalancing
  def optimal_action(:type_c_semantic_fragmentation), do: :ontology_reconciliation
  def optimal_action(:type_d_forecast_divergence), do: :observation_only
  def optimal_action(:type_e_causal_branch_instability), do: :quarantine

  def worst_action(:type_a_runtime_pressure), do: :entropy_rebalancing
  def worst_action(:type_b_entropy_growth), do: :constraint_tightening
  def worst_action(:type_c_semantic_fragmentation), do: :quarantine
  def worst_action(:type_d_forecast_divergence), do: :constraint_tightening
  def worst_action(:type_e_causal_branch_instability), do: :observation_only
end
