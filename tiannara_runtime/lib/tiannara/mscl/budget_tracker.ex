defmodule Tiannara.MSCL.BudgetTracker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{cpu: 0, memory: 0, entropy_budget: 1.0, observer_budgets: %{}, resource_totals: %{}}}
  end

  def handle_call(:consume, _from, state) do
    new_state = %{state | entropy_budget: state.entropy_budget - 0.01}
    {:reply, new_state, new_state}
  end

  def check_budget(observer_id, resource_type, amount) do
    GenServer.call(__MODULE__, {:check_budget, observer_id, resource_type, amount})
  end

  def allocate_budget(observer_id, resource_type, amount) do
    GenServer.cast(__MODULE__, {:allocate_budget, observer_id, resource_type, amount})
  end

  def release_budget(observer_id, resource_type, amount) do
    GenServer.cast(__MODULE__, {:release_budget, observer_id, resource_type, amount})
  end

  def get_observer_budget(observer_id) do
    GenServer.call(__MODULE__, {:get_observer_budget, observer_id})
  end

  def get_global_metrics do
    GenServer.call(__MODULE__, :get_global_metrics)
  end

  def handle_call({:check_budget, _observer_id, resource_type, amount}, _from, state) do
    current = Map.get(state.resource_totals, resource_type, 0.0)
    if current + amount <= 100.0 do
      {:reply, {:ok}, state}
    else
      {:reply, {:error, :insufficient_budget}, state}
    end
  end

  def handle_call({:get_observer_budget, observer_id}, _from, state) do
    budget = Map.get(state.observer_budgets, observer_id, %{allocations: %{}, total_allocated: 0.0})
    {:reply, {:ok, budget}, state}
  end

  def handle_call(:get_global_metrics, _from, state) do
    metrics = %{
      global_allocations: Map.values(state.observer_budgets) |> Enum.map(& &1.total_allocated) |> Enum.sum(),
      active_observers: map_size(state.observer_budgets)
    }
    {:reply, {:ok, metrics}, state}
  end

  def handle_cast({:allocate_budget, observer_id, resource_type, amount}, state) do
    budget = Map.get(state.observer_budgets, observer_id, %{allocations: %{}, total_allocated: 0.0})
    new_allocations = Map.put(budget.allocations, resource_type, amount)
    new_budget = %{budget | allocations: new_allocations, total_allocated: budget.total_allocated + amount}
    new_resource_totals = Map.update(state.resource_totals, resource_type, amount, &(&1 + amount))
    {:noreply, %{state | observer_budgets: Map.put(state.observer_budgets, observer_id, new_budget), resource_totals: new_resource_totals}}
  end

  def handle_cast({:release_budget, observer_id, resource_type, amount}, state) do
    budget = Map.get(state.observer_budgets, observer_id, %{allocations: %{}, total_allocated: 0.0})
    current = Map.get(budget.allocations, resource_type, 0.0)
    new_allocations = Map.put(budget.allocations, resource_type, max(0.0, current - amount))
    new_budget = %{budget | allocations: new_allocations, total_allocated: max(0.0, budget.total_allocated - amount)}
    new_resource_totals = Map.update(state.resource_totals, resource_type, 0.0, &max(0.0, &1 - amount))
    {:noreply, %{state | observer_budgets: Map.put(state.observer_budgets, observer_id, new_budget), resource_totals: new_resource_totals}}
  end

  def handle_cast(:reset, state) do
    {:noreply, %{state | observer_budgets: %{}, resource_totals: %{}}}
  end
end
