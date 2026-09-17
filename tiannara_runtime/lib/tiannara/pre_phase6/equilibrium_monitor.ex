defmodule Tiannara.PrePhase6.EquilibriumMonitor do
  @moduledoc """
  Global stability tracker verifying Ψ stability, Ω/Φ divergence coupling,
  and attractor avoidance.
  """

  @psi_critical 0.30
  @omega_phi_max_divergence 0.4

  @spec validate_global_equilibrium(metrics :: map()) :: {:ok, map()} | {:error, String.t()}
  def validate_global_equilibrium(metrics) do
    with :ok <- verify_psi_stability(metrics),
         :ok <- check_omega_phi_coupling(metrics),
         :ok <- ensure_attractor_avoidance(metrics) do
      {:ok, %{status: :equilibrated, psi: metrics.psi, omega: metrics.omega, phi: metrics.phi}}
    end
  end

  defp verify_psi_stability(%{psi: psi}) do
    if psi >= @psi_critical do
      :ok
    else
      {:error, "Global stability Ψ below critical threshold (Ψ=#{psi} < #{@psi_critical})"}
    end
  end

  defp check_omega_phi_coupling(%{omega: o, phi: p}) do
    divergence = abs(o - p)
    if divergence <= @omega_phi_max_divergence do
      :ok
    else
      {:error, "Ω/Φ divergence too high (|#{o} - #{p}| = #{divergence} > #{@omega_phi_max_divergence})"}
    end
  end

  defp ensure_attractor_avoidance(metrics) do
    # Fallback default if custom Detector is not present
    cond do
      Process.whereis(Tiannara.RRG.AttractorDetector) ->
        case GenServer.call(Tiannara.RRG.AttractorDetector, {:detect, metrics}) do
          :stable -> :ok
          risk -> {:error, "Dangerous attractor state detected: #{risk}"}
        end

      true ->
        # Verify if metrics has an attractor indicator
        if Map.get(metrics, :attractor_detected, false) do
          {:error, "Dangerous attractor state detected: chaotic_attractor"}
        else
          :ok
        end
    end
  end
end
