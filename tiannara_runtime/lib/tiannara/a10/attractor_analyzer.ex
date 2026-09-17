defmodule Tiannara.A10.AttractorAnalyzer do
  @moduledoc """
  Classifies Stability Phases (A through E).
  Relies on Drift Magnitude, Acceleration, and Recovery Elasticity.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{current_phase: :phase_a}}
  end

  def handle_cast({:analyze, tensor_state}, state) do
    %{
      magnitude: mag,
      acceleration: acc,
      elasticity: elasticity,
      covariance: cov
    } = tensor_state

    # Covariance trace sum as a proxy for structural drift correlation
    trace = calc_trace(cov)

    phase = cond do
      # Monoculture convergence: extremely low magnitude, negative elasticity (cannot bounce back to diversity)
      mag < 0.01 and elasticity < 0.0 -> :phase_e
      
      # Drift-divergent: high magnitude, high acceleration, negative elasticity (runaway)
      mag > 5.0 and acc > 0.5 and elasticity < 0.0 -> :phase_d
      
      # Metastable: high magnitude, but positive elasticity (fragile but recovering)
      mag > 3.0 and elasticity >= 0.0 -> :phase_c
      
      # Oscillatory but bounded: moderate magnitude, bouncing back and forth
      mag > 1.0 -> :phase_b
      
      # Stable attractor
      true -> :phase_a
    end

    if phase != state.current_phase do
      # Record in history
      GenServer.cast(Tiannara.A10.AttractorMemory, {:record_phase, phase})
      
      # If unsafe, emit Advisory to CIS
      if phase in [:phase_c, :phase_d, :phase_e] do
        GenServer.cast(Tiannara.A10.AdvisoryEmitter, {:emit_advisory, phase, trace})
      end
      
      # Emit native telemetry for MEK observation
      :telemetry.execute(
        [:tiannara, :a10, :phase_change],
        %{magnitude: mag, elasticity: elasticity},
        %{phase: phase, trace: trace}
      )
    end

    {:noreply, %{state | current_phase: phase}}
  end
  
  def handle_call(:get_phase, _from, state) do
    {:reply, state.current_phase, state}
  end

  defp calc_trace(nil), do: 0.0
  defp calc_trace(cov) do
    # sum of diagonal elements
    Enum.reduce(0..(length(cov)-1), 0.0, fn i, acc ->
      acc + Enum.at(Enum.at(cov, i), i)
    end)
  end
end
