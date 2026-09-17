defmodule TiannaraRuntime.Evolution.FitnessEngine do
  @moduledoc """
  PHASE 5B: World Fitness Engine
  
  Computes survival probability of each world based on multi-factor scoring.
  
  Fitness Formula:
    fitness = α(coherence_stability) + β(recovery_speed) + γ(coalition_success_rate)
              - δ(entropy_instability) - ε(collapse_frequency)
  
  Weights (default):
    α = 0.35 (coherence stability - most important)
    β = 0.20 (recovery speed after perturbations)
    γ = 0.25 (coalition success rate)
    δ = 0.10 (entropy instability penalty)
    ε = 0.10 (collapse frequency penalty)
  
  Returns fitness score in range [0.0, 1.0]
  """
  
  # Default weights
  @weight_coherence 0.35
  @weight_recovery 0.20
  @weight_coalition 0.25
  @weight_entropy 0.10
  @weight_collapse 0.10
  
  @doc """
  Compute fitness score for a world based on its metrics.
  
  Parameters:
    metrics - Map containing:
      - coherence_stability: float [0.0, 1.0]
      - recovery_speed: float [0.0, 1.0]
      - coalition_success_rate: float [0.0, 1.0]
      - entropy_instability: float [0.0, 1.0]
      - collapse_frequency: float [0.0, 1.0]
  
  Returns:
    fitness score [0.0, 1.0]
  """
  def compute(metrics) do
    coherence = Map.get(metrics, :coherence_stability, 0.5)
    recovery = Map.get(metrics, :recovery_speed, 0.5)
    coalition = Map.get(metrics, :coalition_success_rate, 0.5)
    entropy = Map.get(metrics, :entropy_instability, 0.5)
    collapse = Map.get(metrics, :collapse_frequency, 0.5)
    
    raw_fitness = (
      @weight_coherence * coherence +
      @weight_recovery * recovery +
      @weight_coalition * coalition -
      @weight_entropy * entropy -
      @weight_collapse * collapse
    )
    
    # Clamp to [0.0, 1.0]
    clamp(raw_fitness, 0.0, 1.0)
  end
  
  @doc """
  Compute fitness with custom weights.
  
  Allows dynamic adjustment of selection pressure.
  """
  def compute_with_weights(metrics, weights) do
    coherence = Map.get(metrics, :coherence_stability, 0.5)
    recovery = Map.get(metrics, :recovery_speed, 0.5)
    coalition = Map.get(metrics, :coalition_success_rate, 0.5)
    entropy = Map.get(metrics, :entropy_instability, 0.5)
    collapse = Map.get(metrics, :collapse_frequency, 0.5)
    
    w_coherence = Map.get(weights, :coherence, @weight_coherence)
    w_recovery = Map.get(weights, :recovery, @weight_recovery)
    w_coalition = Map.get(weights, :coalition, @weight_coalition)
    w_entropy = Map.get(weights, :entropy, @weight_entropy)
    w_collapse = Map.get(weights, :collapse, @weight_collapse)
    
    raw_fitness = (
      w_coherence * coherence +
      w_recovery * recovery +
      w_coalition * coalition -
      w_entropy * entropy -
      w_collapse * collapse
    )
    
    clamp(raw_fitness, 0.0, 1.0)
  end
  
  @doc """
  Calculate risk level (inverse of fitness).
  
  Returns risk score [0.0, 1.0] where higher = more dangerous
  """
  def calculate_risk(fitness) do
    1.0 - fitness
  end
  
  @doc """
  Classify world based on fitness level.
  
  Returns:
    :thriving - fitness > 0.7
    :stable - fitness 0.5-0.7
    :struggling - fitness 0.3-0.5
    :critical - fitness < 0.3
  """
  def classify(fitness) do
    cond do
      fitness > 0.7 -> :thriving
      fitness > 0.5 -> :stable
      fitness > 0.3 -> :struggling
      true -> :critical
    end
  end
  
  @doc """
  Compute survival pressure index.
  
  Combines multiple stress factors into single pressure metric.
  """
  def compute_pressure(metrics) do
    entropy_growth = Map.get(metrics, :entropy_growth_rate, 0.0)
    cis_density = Map.get(metrics, :cis_intervention_density, 0.0)
    cal_instability = Map.get(metrics, :cal_instability_index, 0.0)
    
    pressure = entropy_growth + cis_density + cal_instability
    
    clamp(pressure / 3.0, 0.0, 1.0)  # Normalize to [0, 1]
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp clamp(value, min_val, max_val) do
    max(min_val, min(value, max_val))
  end
end
