defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.AdaptiveController do
  @moduledoc """
  The Self-Tuning MSCL (Control Brain).
  
  Runs a continuous feedback loop that adjusts the gain matrix K(t)
  based on the divergence gradient ∇V(x).
  """
  use GenServer
  require Logger
  
  alias Tiannara.MSCL.A10Native
  alias Tiannara.MSCL.Supervisor, as: MSCLSupervisor

  @tick_interval_ms 100
  @learning_rate 0.01

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🧠 AdaptiveController initialized. Booting control loop...")
    schedule_tick()
    
    state = %{
      k_scalar: 1.0,
      previous_v: 0.0,
      learning_rate: @learning_rate,
      tick_count: 0
    }
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    # 1. Compute V(x)_t
    gain_matrix = List.duplicate(state.k_scalar, 100)
    
    case A10Native.compute_snapshot(gain_matrix) do
      {:ok, current_v} ->
        # 2. Compute ∇V(x)
        gradient = current_v - state.previous_v
        
        # 3. K(t+1) = K(t) + η∇V(x)
        new_k = state.k_scalar + (state.learning_rate * gradient)
        # Bound K to avoid exploding gradients for now
        new_k = clamp(new_k, 0.1, 10.0)
        
        # 4. Update thresholds dynamically
        update_thresholds(new_k)
        
        if rem(state.tick_count, 10) == 0 do
          Logger.debug("🧠 AdaptiveController [Tick #{state.tick_count}] - V(x): #{Float.round(current_v, 4)}, ∇V: #{Float.round(gradient, 4)}, K(t+1): #{Float.round(new_k, 4)}")
        end
        
        schedule_tick()
        {:noreply, %{state | k_scalar: new_k, previous_v: current_v, tick_count: state.tick_count + 1}}
        
      _ ->
        schedule_tick()
        {:noreply, state}
    end
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval_ms)
  end

  defp clamp(val, min_val, max_val) do
    max(min_val, min(val, max_val))
  end

  defp update_thresholds(k_scalar) do
    # Map the scalar gain to pressure thresholds.
    base_max = 10_000.0
    max_pressure = max(1000.0, base_max / k_scalar)
    
    # Adjust collapse risks (stricter if K is high)
    crit_risk = max(0.5, 0.85 - ((k_scalar - 1.0) * 0.1))
    warn_risk = max(0.3, 0.70 - ((k_scalar - 1.0) * 0.1))
    
    MSCLSupervisor.update_thresholds(max_pressure, crit_risk, warn_risk)
  end
end
