defmodule Tiannara.Bridge.StabilityController do
  @moduledoc """
  Phase 5F.12: Stability Controller - Critical Safety Layer
  
  Monitors the Ω-Φ stability metric and triggers corrective actions
  when the system diverges from equilibrium.
  
  Stability Thresholds:
  - < 0.25 → UNSTABLE: Immediate rebalancing required
  - 0.25-0.6 → DEGRADED: Soft correction needed
  - ≥ 0.6 → STABLE: No action required
  """

  @unstable_threshold 0.25
  @degraded_threshold 0.6

  @doc """
  Evaluate system stability and recommend action.
  
  ## Parameters
  - stability: Current stability metric (0.0-1.0)
  
  ## Returns
  {:status, :action} where status is :unstable | :degraded | :stable
  """
  def evaluate(stability) when is_number(stability) do
    cond do
      stability < @unstable_threshold ->
        {:unstable, :rebalance_required}
      
      stability < @degraded_threshold ->
        {:degraded, :soft_correction}
      
      true ->
        {:stable, :no_action}
    end
  end

  @doc """
  Get recommended compression intensity based on stability level.
  
  When system is unstable, reduce compression aggressiveness to prevent
  further divergence.
  
  ## Parameters
  - stability: Current stability metric
  - base_intensity: Default compression intensity (:aggressive | :moderate | :light)
  
  ## Returns
  Adjusted compression intensity
  """
  def adjust_compression_for_stability(stability, base_intensity) do
    case evaluate(stability) do
      {:unstable, _} ->
        # During instability, use lightest compression to stabilize
        :light
      
      {:degraded, _} ->
        # During degradation, moderate compression
        if base_intensity == :aggressive, do: :moderate, else: base_intensity
      
      {:stable, _} ->
        # System stable, use requested intensity
        base_intensity
    end
  end

  @doc """
  Calculate emergency intervention level based on stability crisis.
  
  ## Parameters
  - stability: Current stability metric
  
  ## Returns
  Intervention level (0-3) where 3 is maximum emergency response
  """
  def intervention_level(stability) do
    cond do
      stability < 0.1 -> 3   # Critical: halt all compression
      stability < 0.25 -> 2  # Severe: aggressive load redistribution
      stability < 0.4 -> 1   # Moderate: soft corrections
      true -> 0              # Normal: no intervention
    end
  end

  @doc """
  Generate stability report with diagnostic information.
  
  ## Parameters
  - stability: Current stability metric
  - omega: Current ontology density
  - phi: Current load pressure
  
  ## Returns
  Map containing full stability assessment
  """
  def generate_report(stability, omega, phi) do
    {status, action} = evaluate(stability)
    divergence = abs(omega - phi)
    
    %{
      status: status,
      action: action,
      stability: stability,
      omega: omega,
      phi: phi,
      divergence: divergence,
      intervention_level: intervention_level(stability),
      timestamp: System.system_time(:millisecond),
      recommendation: generate_recommendation(status, divergence)
    }
  end

  defp generate_recommendation(:unstable, divergence) do
    "CRITICAL: Ω-Φ divergence of #{Float.round(divergence, 3)} detected. " <>
    "Initiate emergency rebalancing protocol. Suspend aggressive compression."
  end

  defp generate_recommendation(:degraded, divergence) do
    "WARNING: System degradation detected (divergence: #{Float.round(divergence, 3)}). " <>
    "Apply soft corrections and monitor closely."
  end

  defp generate_recommendation(:stable, _divergence) do
    "System operating within normal parameters. Continue current strategy."
  end
end
