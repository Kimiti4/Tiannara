defmodule Tiannara.EPC.SmoothedJacobian do
  @moduledoc """
  Evolution Pressure Control: Smoothed Jacobian Estimator.
  
  Computes the interaction matrix A(S_t) using exponential smoothing
  to prevent noisy Jacobians from destabilizing the control feedback loop.
  A_hat_t = (1 - alpha) * A_hat_{t-1} + alpha * A_obs_t
  """
  
  @alpha 0.1 # Smoothing factor

  @doc """
  Estimates the smoothed Jacobian based on observed changes.
  Uses finite differences of state variables to compute the observed Jacobian,
  then applies exponential smoothing to prevent noisy feedback.
  """
  def estimate(prev_a_hat, s_t, prev_s, u_t_minus_1) do
    # Compute observed Jacobian via finite differences
    a_obs = compute_observed_jacobian(s_t, prev_s, u_t_minus_1)
    
    # Apply Exponential Smoothing
    apply_smoothing(prev_a_hat, a_obs)
  end
  
  defp apply_smoothing(prev_a_hat, a_obs) do
    (1.0 - @alpha) * prev_a_hat + (@alpha * a_obs)
  end
  
  defp compute_observed_jacobian(s_t, prev_s, u_t_minus_1) do
    # Finite difference approximation: dS/dU
    delta_entropy = s_t.entropy - prev_s.entropy
    delta_coherence = s_t.coherence - prev_s.coherence
    delta_ose = (u_t_minus_1.ose || 0.0) + 0.001 # prevent div by zero
    
    # Jacobian element: sensitivity of state change to control input
    entropy_sensitivity = abs(delta_entropy / delta_ose)
    coherence_sensitivity = abs(delta_coherence / delta_ose)
    
    # Weighted combination representing overall system sensitivity
    (entropy_sensitivity + coherence_sensitivity) / 2.0
  end
end
