defmodule Tiannara.Bridge.EntropyBalancer do
  @moduledoc """
  Phase 5F.12: Entropy Balancer - Final Normalization Layer
  
  Prevents Ω-Φ drift by gently pulling both values toward their mean.
  
  This creates a damping effect that prevents runaway divergence while
  allowing natural oscillation around the equilibrium point.
  
  Formula: x_new = x + (target - x) × damping_factor
  
  Where damping_factor = 0.1 (10% correction per cycle)
  """

  @damping_factor 0.1

  @doc """
  Balance Ω and Φ by moving them toward their mean.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  
  ## Returns
  {balanced_omega, balanced_phi} tuple with adjusted values
  """
  def balance(omega, phi) when is_number(omega) and is_number(phi) do
    mean = (omega + phi) / 2.0
    
    {
      clamp(omega, mean),
      clamp(phi, mean)
    }
  end

  @doc """
  Apply damping to move value toward target.
  
  ## Parameters
  - current: Current value
  - target: Target value to approach
  
  ## Returns
  Adjusted value moved 10% closer to target
  """
  defp clamp(current, target) do
    current + (target - current) * @damping_factor
  end

  @doc """
  Balance with adaptive damping based on divergence severity.
  
  When divergence is large, apply stronger damping to prevent instability.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  - divergence: Absolute difference |Ω - Φ|
  
  ## Returns
  {balanced_omega, balanced_phi} with adaptive correction applied
  """
  def balance_adaptive(omega, phi, divergence) do
    mean = (omega + phi) / 2.0
    
    # Increase damping factor for larger divergences
    adaptive_damping = calculate_adaptive_damping(divergence)
    
    {
      clamp_with_factor(omega, mean, adaptive_damping),
      clamp_with_factor(phi, mean, adaptive_damping)
    }
  end

  defp calculate_adaptive_damping(divergence) do
    cond do
      divergence > 0.8 -> 0.3   # Strong correction for severe divergence
      divergence > 0.5 -> 0.2   # Moderate correction
      divergence > 0.2 -> 0.15  # Light correction
      true -> @damping_factor   # Standard gentle correction
    end
  end

  defp clamp_with_factor(current, target, factor) do
    current + (target - current) * factor
  end

  @doc """
  Calculate entropy metric representing system disorder.
  
  Higher entropy indicates greater Ω-Φ misalignment.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  
  ## Returns
  Entropy value (0.0 = perfect alignment, higher = more disorder)
  """
  def calculate_entropy(omega, phi) do
    # Use squared divergence to penalize large mismatches more heavily
    divergence = omega - phi
    divergence * divergence
  end

  @doc """
  Check if entropy is within acceptable bounds.
  
  ## Parameters
  - entropy: Current entropy value
  - threshold: Maximum acceptable entropy (default: 0.1)
  
  ## Returns
  true if entropy is acceptable, false if corrective action needed
  """
  def acceptable_entropy?(entropy, threshold \\ 0.1) do
    entropy <= threshold
  end
end
