defmodule TiannaraRuntime.IRD.BudgetController do
  @moduledoc """
  Phase 5F.12 — IRD Budget Controller

  Manages compute budget allocation for competing IRD proposals.
  """

  use GenServer
  require Logger

  @max_budget 1_000
  @per_observer_budget 250

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{used_budget: %{}, total_reserved: 0}}
  end

  @doc "Reserve budget for a new proposal if there is remaining compute capacity."
  def reserve(proposal) when is_map(proposal) do
    GenServer.call(__MODULE__, {:reserve, proposal})
  end

  @doc "Release budget for a completed or deferred proposal."
  def release(observer_id, amount \\ @per_observer_budget) do
    GenServer.cast(__MODULE__, {:release, observer_id, amount})
  end

  @impl true
  def handle_call({:reserve, proposal}, _from, state) do
    observer_id = Map.get(proposal, :observer_id, "unknown_observer")
    current_usage = Map.get(state.used_budget, observer_id, 0)
    remaining = @max_budget - state.total_reserved

    cond do
      remaining <= 0 ->
        {:reply, {:deferred, :budget_exhausted}, state}

      current_usage + @per_observer_budget > @per_observer_budget * 4 ->
        {:reply, {:deferred, :observer_budget_overrun}, state}

      true ->
        new_used_budget = Map.put(state.used_budget, observer_id, current_usage + @per_observer_budget)
        new_state = %{state | used_budget: new_used_budget, total_reserved: state.total_reserved + @per_observer_budget}
        Logger.debug("[IRD] Reserved budget for #{observer_id}, remaining=#{remaining - @per_observer_budget}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_cast({:release, observer_id, amount}, state) do
    usage = Map.get(state.used_budget, observer_id, 0)
    new_usage = max(usage - amount, 0)
    new_used_budget = Map.put(state.used_budget, observer_id, new_usage)
    new_state = %{state | used_budget: new_used_budget, total_reserved: max(state.total_reserved - amount, 0)}
    {:noreply, new_state}
  end
end
