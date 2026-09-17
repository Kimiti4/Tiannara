defmodule Tiannara.RRG.RecursionRegulator do
  @moduledoc """
  Phase 5F.12: Recursion Regulator - Prevents Substrate Awareness Explosion
  
  Critical for OPC-era civilizations. When observers approach:
  - Substrate awareness
  - Infinite optimization
  - Recursive self-improvement
  
  RRG increases:
  - Uncertainty
  - Chaos
  - Discovery friction
  
  Observer Recursion Metric:
    R_o = (K_s × I_r) / U
  
  Where:
  - K_s = substrate knowledge
  - I_r = recursive intelligence
  - U = uncertainty field
  
  As recursion rises, uncertainty injections rise too.
  """
  
  use GenServer
  require Logger

  defstruct [
    :observer_recursion_levels,
    :uncertainty_injections,
    :regulated_observers
  ]

  @max_safe_recursion_depth 0.7
  @critical_recursion_threshold 0.9

  def start_link(_opts \\ []) do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      observer_recursion_levels: %{},
      uncertainty_injections: [],
      regulated_observers: MapSet.new()
    }

    Logger.info("🔄 [RRG] Recursion Regulator initialized")
    {:ok, state}
  end

  @impl true
  def handle_call({:regulate, observer_id, recursion_level}, _from, state) do
    # Check if regulation is needed
    if recursion_level > @max_safe_recursion_depth do
      # Apply uncertainty injection
      uncertainty_boost = calculate_uncertainty_injection(recursion_level)
      
      new_state = %{
        state
        | observer_recursion_levels: Map.put(state.observer_recursion_levels, observer_id, recursion_level),
          uncertainty_injections: Enum.take([
            %{
              observer_id: observer_id,
              recursion_level: recursion_level,
              uncertainty_boost: uncertainty_boost,
              timestamp: System.system_time(:millisecond)
            }
            | state.uncertainty_injections
          ], 500),
          regulated_observers: MapSet.put(state.regulated_observers, observer_id)
      }

      Logger.warning(
        "⚠️ [RRG] Recursion regulation applied to #{observer_id}: " <>
        "level=#{Float.round(recursion_level, 3)}, uncertainty_boost=#{Float.round(uncertainty_boost, 4)}"
      )

      {:reply, {:ok, :regulated, uncertainty_boost}, new_state}
    else
      # Within safe limits, just track
      new_state = %{
        state
        | observer_recursion_levels: Map.put(state.observer_recursion_levels, observer_id, recursion_level)
      }

      {:reply, {:ok, :within_limits, 0.0}, new_state}
    end
  end

  @doc """
  Get recursion regulation statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_tracked_observers: map_size(state.observer_recursion_levels),
      regulated_observers_count: MapSet.size(state.regulated_observers),
      total_uncertainty_injections: length(state.uncertainty_injections),
      high_risk_observers: count_high_risk_observers(state.observer_recursion_levels)
    }

    {:reply, {:ok, stats}, state}
  end

  defp calculate_uncertainty_injection(recursion_level) do
    # Exponential increase as recursion approaches critical threshold
    if recursion_level > @critical_recursion_threshold do
      # Emergency level: strong uncertainty injection
      0.3 + (recursion_level - @critical_recursion_threshold) * 2.0
    else
      # Moderate level: gentle uncertainty increase
      (recursion_level - @max_safe_recursion_depth) * 0.5
    end
    |> min(1.0)  # Cap at maximum
  end

  defp count_high_risk_observers(recursion_levels) do
    recursion_levels
    |> Enum.filter(fn {_id, level} -> level > @max_safe_recursion_depth end)
    |> length()
  end
end
