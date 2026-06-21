defmodule Tiannara.REL.EconomyManager do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      resource_budget: 1000.0,
      resource_spent: 0.0,
      generation_costs: %{branch_spawn: 10.0, observer_creation: 5.0, ontology_generation: 15.0, stabilizer_intervention: 1.0},
      config: %{budget_refill_ms: 10000, budget_refill_amount: 1000.0}
    }}
  end

  def allocate_resource(operation_type, count \\ 1) do
    GenServer.call(__MODULE__, {:allocate, operation_type, count})
  end

  def get_resource_balance do
    GenServer.call(__MODULE__, :get_balance)
  end

  def handle_call({:allocate, operation_type, count}, _from, state) do
    cost = Map.get(state.generation_costs, operation_type, 1.0) * count
    if state.resource_spent + cost > state.resource_budget do
      Logger.warning("REL: Insufficient resources for #{operation_type}")
      {:reply, {:denied, cost}, state}
    else
      new_state = %{state | resource_spent: state.resource_spent + cost}
      Logger.debug("REL: Allocated #{Float.round(cost, 2)} for #{operation_type}")
      {:reply, {:approved, cost}, new_state}
    end
  end

  def handle_call(:get_balance, _from, state) do
    balance = %{available: state.resource_budget - state.resource_spent, total_budget: state.resource_budget, spent: state.resource_spent}
    {:reply, balance, state}
  end
end
