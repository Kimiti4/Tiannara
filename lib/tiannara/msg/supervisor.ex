defmodule Tiannara.MSG.Supervisor do
  @moduledoc """
  Meta-Stability Governor (MSG) - Prevents stabilizer overregulation
  """
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      stabilizer_log: [],
      overregulation_score: 0.0,
      immune_intensity: 0.0,
      adaptive_activity: 0.0,
      config: %{
        max_frequency_per_second: 50,
        overregulation_threshold: 0.75,
        critical_curvature: 12.0
      }
    }}
  end

  def propose_intervention(module, action, intensity) do
    GenServer.cast(__MODULE__, {:propose, module, action, intensity})
  end

  def get_stabilization_pressure, do: GenServer.call(__MODULE__, :get_pressure)
  def get_overregulation_score, do: GenServer.call(__MODULE__, :get_overregulation)
  def get_health_metrics, do: GenServer.call(__MODULE__, :get_metrics)

  def handle_cast({:propose, module, action, intensity}, state) do
    now = System.monotonic_time(:millisecond)
    window_ms = 1000
    recent = Enum.filter(state.stabilizer_log, fn {_, _, _, ts} -> now - ts < window_ms end)
    updated_log = [{module, action, intensity, now} | recent]
    frequency = length(updated_log)
    total_intensity = Enum.sum(Enum.map(updated_log, fn {_, _, i, _} -> i end))
    avg_intensity = if frequency > 0, do: total_intensity / frequency, else: 0.0
    
    unique_modules = updated_log |> Enum.map(fn {m, _, _, _} -> m end) |> Enum.uniq() |> length()
    unique_actions = updated_log |> Enum.map(fn {_, a, _, _} -> a end) |> Enum.uniq() |> length()
    adaptive_activity = (unique_modules + unique_actions) / 2.0
    
    m_pressure = if adaptive_activity > 0.1, do: total_intensity / adaptive_activity, else: total_intensity / 0.1
    overreg_score = min(1.0, m_pressure / state.config.critical_curvature)
    
    new_state = %{state | stabilizer_log: updated_log, overregulation_score: overreg_score, immune_intensity: avg_intensity, adaptive_activity: adaptive_activity}
    
    if overreg_score > state.config.overregulation_threshold do
      Logger.warning("MSG: Overregulation detected (#{Float.round(overreg_score, 3)})")
    end
    
    {:noreply, new_state}
  end

  def handle_call(:get_pressure, _from, state) do
    m = if state.adaptive_activity > 0.1, do: state.immune_intensity / state.adaptive_activity, else: state.immune_intensity / 0.1
    {:reply, m, state}
  end

  def handle_call(:get_overregulation, _from, state), do: {:reply, state.overregulation_score, state}
  
  def handle_call(:get_metrics, _from, state) do
    metrics = %{overregulation_score: state.overregulation_score, immune_intensity: state.immune_intensity, adaptive_activity: state.adaptive_activity, frequency: length(state.stabilizer_log)}
    {:reply, metrics, state}
  end
end
