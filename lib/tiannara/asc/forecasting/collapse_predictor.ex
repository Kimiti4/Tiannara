defmodule Tiannara.ASC.Forecasting.CollapsePredictor do
  @moduledoc """
  Phase 18: The Actuary. Analyzes simulated future trajectories to calculate 
  the probability of terminal civilizational states.
  """
  require Logger

  def calculate_risk_of_ruin(trajectories) do
    final_states = Enum.map(trajectories, &List.last/1)
    total_sims = length(final_states)
    
    if total_sims == 0 do
      %{monoculture_risk: 1.0, asphyxiation_risk: 1.0, starvation_risk: 1.0}
    else
      %{
        monoculture_risk: calculate_monoculture_risk(final_states, total_sims),
        asphyxiation_risk: calculate_asphyxiation_risk(final_states, total_sims),
        starvation_risk: calculate_starvation_risk(final_states, total_sims)
      }
    end
  end

  # Risk: > 90% of utility controlled by LLM-synthesized organs
  defp calculate_monoculture_risk(states, total) do
    collapses = Enum.count(states, fn state ->
      llm_utility = Enum.filter(state.capabilities, & &1.lineage == :llm_synthesis) |> Enum.sum_by(& &1.fitness_impact)
      total_utility = Enum.sum_by(state.capabilities, & &1.fitness_impact)
      total_utility > 0 and (llm_utility / total_utility) > 0.90
    end)
    collapses / total
  end

  # Risk: Cognitive load exceeds 100% (Context Window Asphyxiation)
  defp calculate_asphyxiation_risk(states, total) do
    collapses = Enum.count(states, fn state -> state.cognitive_load >= 1.0 end)
    collapses / total
  end

  # Risk: Total utility drops below survival threshold
  defp calculate_starvation_risk(states, total) do
    collapses = Enum.count(states, fn state -> 
      Enum.sum_by(state.capabilities, & &1.fitness_impact) < 10.0 
    end)
    collapses / total
  end
end
