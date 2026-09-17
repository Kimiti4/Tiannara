defmodule ObservationBus.CIL.Strategy.ResourcePlanner do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_allocation, do: GenServer.call(__MODULE__, :get_allocation)
  def get_optimization, do: GenServer.call(__MODULE__, :get_optimization)
  def allocate(resource, domain, amount) do
    GenServer.cast(__MODULE__, {:allocate, resource, domain, amount})
  end

  @impl true
  def init(_opts) do
    state = %{
      resources: %{
        compute: %{total: 1000, allocated: 720, unit: "TFLOPS"},
        researchers: %{total: 100, allocated: 68, unit: "FTE"},
        simulations: %{total: 500, allocated: 310, unit: "runs/day"},
        storage: %{total: 10_000, allocated: 4200, unit: "TB"},
        energy: %{total: 5000, allocated: 2800, unit: "MWh"},
        budget: %{total: 50_000_000, allocated: 28_000_000, unit: "USD"},
        time: %{total: 8760, allocated: 5200, unit: "hours"}
      },
      allocation: %{
        mathematics: %{compute: 0.15, researchers: 0.12, budget: 0.10},
        physics: %{compute: 0.25, researchers: 0.22, budget: 0.20},
        biology: %{compute: 0.15, researchers: 0.18, budget: 0.20},
        computing: %{compute: 0.25, researchers: 0.28, budget: 0.25},
        engineering: %{compute: 0.20, researchers: 0.20, budget: 0.25}
      }
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get_allocation, _from, state), do: {:reply, state.allocation, state}
  def handle_call(:get_optimization, _from, state) do
    optimization = state.resources
    |> Enum.map(fn {k, v} -> {k, %{total: v.total, allocated: v.allocated, utilization: safe_div(v.allocated, v.total), available: v.total - v.allocated}} end)
    |> Enum.into(%{})
    {:reply, optimization, state}
  end

  @impl true
  def handle_cast({:allocate, resource, domain, amount}, state) do
    res = Map.get(state.resources, resource)
    alloc = state.allocation
    if res && res.allocated + amount <= res.total do
      resources = update_in(state.resources, [resource, :allocated], &(&1 + amount))
      allocation = put_in(alloc, [domain, resource], amount)
      {:noreply, %{state | resources: resources, allocation: allocation}}
    else
      {:noreply, state}
    end
  end

  defp safe_div(_, 0), do: 0.0
  defp safe_div(a, b), do: a / b
end
