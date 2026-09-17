defmodule Tiannara.MSCL.ConstraintEngine do
  @moduledoc """
  Core enforcement state for Meta-Stability Constraints.
  Holds constraints and emits 'constraint.updated' events via EventBus.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{constraints: %{}, pressure: 0.0}}
  end

  def handle_cast({:update_constraint, key, value}, state) do
    new_constraints = Map.put(state.constraints, key, value)
    new_state = %{state | constraints: new_constraints}
    
    # Broadcast to OLEF and other listeners
    EventBus.broadcast("constraint.updated", :constraint_changed, %{key: key, value: value})
    
    {:noreply, new_state}
  end

  def handle_info({:simulate_failure, :constraint_engine, :hard_fault}, _state) do
    # Simulates a process death and restart cascade without actually killing the PID
    EventBus.broadcast("constraint.updated", :constraint_reset, %{reason: :simulated_hard_fault})
    {:noreply, %{constraints: %{}, pressure: 0.0}}
  end

  def handle_info(:tick, state) do
    EventBus.broadcast("constraint.snapshot", :snapshot, state)
    {:noreply, state}
  end

  def evaluate_divergence(divergence) when divergence <= 1.0 do
    {:stable, divergence}
  end

  def evaluate_divergence(divergence) do
    {:compressed, divergence * 0.5}
  end

  def enforce_budget(amount, limit) when amount <= limit do
    {:ok}
  end

  def enforce_budget(_amount, _limit) do
    {:error, :budget_exceeded}
  end

  def calculate_constraint_pressure(factors) do
    values = Map.values(factors)
    total = if length(values) > 0, do: Enum.sum(values) / length(values), else: 0.0
    %{
      total_pressure: total,
      components: factors,
      status: if(total > 0.7, do: :critical, else: :nominal)
    }
  end

  def apply_emergency_constraints(state) do
    actions = [{:reduce_entropy, 0.5}, {:pause_observers, true}, {:increase_diffusion, 0.25}]
    Map.put(state, :actions_taken, actions)
  end
end
