defmodule Tiannara.ASC.Research.Economics do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def allocate(program_id, budget) do
    GenServer.call(__MODULE__, {:allocate, program_id, budget})
  end

  def spend(program_id, amount, category) do
    GenServer.cast(__MODULE__, {:spend, program_id, amount, category})
  end

  def budget_status, do: GenServer.call(__MODULE__, :budget_status)

  def program_roi(program_id), do: GenServer.call(__MODULE__, {:roi, program_id})

  @impl true
  def init(_opts) do
    {:ok, %{
      total_budget: %{compute: 10_000, time_hours: 1_000, energy: 5_000},
      allocations: %{},
      expenditures: %{},
      returns: %{},
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:allocate, program_id, budget}, _from, state) do
    {:reply, :ok, put_in(state.allocations[program_id], budget)}
  end

  @impl true
  def handle_call(:budget_status, _from, state) do
    total_spent =
      state.expenditures
      |> Map.values()
      |> Enum.reduce(%{compute: 0, time_hours: 0, energy: 0}, fn exp, acc ->
        %{
          compute: acc.compute + Map.get(exp, :compute, 0),
          time_hours: acc.time_hours + Map.get(exp, :time_hours, 0),
          energy: acc.energy + Map.get(exp, :energy, 0)
        }
      end)

    remaining = %{
      compute: state.total_budget.compute - total_spent.compute,
      time_hours: state.total_budget.time_hours - total_spent.time_hours,
      energy: state.total_budget.energy - total_spent.energy
    }

    {:reply, %{total: state.total_budget, spent: total_spent, remaining: remaining}, state}
  end

  @impl true
  def handle_call({:roi, program_id}, _from, state) do
    spent = Map.get(state.expenditures, program_id, 0)
    returned = Map.get(state.returns, program_id, 0)

    roi = if spent > 0, do: returned / spent, else: 0.0
    {:reply, %{program_id: program_id, spent: spent, returned: returned, roi: roi}, state}
  end

  @impl true
  def handle_cast({:spend, program_id, amount, category}, state) do
    current = Map.get(state.expenditures, program_id, %{compute: 0, time_hours: 0, energy: 0})
    updated = Map.update(current, category, amount, &(&1 + amount))

    {:noreply, put_in(state.expenditures[program_id], updated)}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
