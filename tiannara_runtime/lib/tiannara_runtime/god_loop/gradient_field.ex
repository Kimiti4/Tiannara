defmodule Tiannara.GodLoop.GradientField do
  @moduledoc """
  God-Loop: Immune-Cognitive Gradient Field.
  
  Produces pressure fields (collapse, mutation, stability, diversification)
  that act as forces shaping both MCAL cognition and OPC physics.
  """
  
  require Logger

  @doc """
  Evaluates the global state to produce pressure gradients.
  """
  def evaluate(mc_state, opc_state, cis_state) do
    Logger.debug("🌐 [God-Loop Gradient] Calculating thermodynamic forces...")
    
    # Analyze the synergy between current cognition, physics, and immunity
    collapse_pressure = calculate_collapse_risk(opc_state)
    mutation_pressure = calculate_entropy_stagnation(mc_state, cis_state)
    stability_pressure = calculate_causal_stress(opc_state, cis_state)
    diversification_pressure = calculate_monoculture_risk(mc_state)
    
    gradients = %{
      collapse: collapse_pressure,
      mutation: mutation_pressure,
      stability: stability_pressure,
      diversification: diversification_pressure
    }
    
    Logger.info("🌐 [God-Loop Gradient] Emitted: Collapse=#{Float.round(collapse_pressure, 2)}, Mutation=#{Float.round(mutation_pressure, 2)}, Stability=#{Float.round(stability_pressure, 2)}, Diversification=#{Float.round(diversification_pressure, 2)}")
    
    gradients
  end

  defp calculate_collapse_risk(opc_state) do
    # How close the causal compiler is to paradoxical singularity
    Map.get(opc_state, :paradox_density, 0.0)
  end

  defp calculate_entropy_stagnation(mc_state, cis_state) do
    # If cognition is too static but immune pressure is low, we need to force mutation
    static_time = Map.get(mc_state, :static_epochs, 0)
    immune_tension = Map.get(cis_state, :tension, 0.5)
    (static_time * 0.1) * (1.0 - immune_tension)
  end

  defp calculate_causal_stress(opc_state, cis_state) do
    # If physics changes too fast, stability pressure pushes back
    volatility = Map.get(opc_state, :rule_volatility, 0.0)
    immune_rigidity = Map.get(cis_state, :rigidity, 0.5)
    volatility * immune_rigidity
  end

  defp calculate_monoculture_risk(mc_state) do
    # Measures the diversity of the identity ecology
    1.0 - Map.get(mc_state, :identity_diversity, 1.0)
  end
end
