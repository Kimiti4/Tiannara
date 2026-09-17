defmodule ObservationBus.CIL.Ops.ResourceCommander do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_allocation, do: GenServer.call(__MODULE__, :allocation)
  def rebalance(resource, delta), do: GenServer.cast(__MODULE__, {:rebalance, resource, delta})

  @impl true
  def init(_opts) do
    state = %{
      cpu: %{total: 1024, allocated: 780, available: 244, unit: "cores"},
      gpu: %{total: 256, allocated: 210, available: 46, unit: "GPUs"},
      memory: %{total: 50_000, allocated: 38_000, available: 12_000, unit: "GB"},
      storage: %{total: 10_000, allocated: 7_200, available: 2_800, unit: "TB"},
      human_operators: %{total: 50, allocated: 38, available: 12, unit: "FTE"},
      budget: %{total: 50_000_000, allocated: 32_000_000, available: 18_000_000, unit: "USD"},
      energy: %{total: 5_000, allocated: 3_800, available: 1_200, unit: "MWh"},
      last_rebalanced: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:allocation, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:rebalance, resource, delta}, state) do
    if Map.has_key?(state, resource) do
      current = state[resource]
      new_allocated = max(0, min(current.total, current.allocated + delta))
      updated = %{current | allocated: new_allocated, available: current.total - new_allocated}
      {:noreply, %{state | resource => updated, last_rebalanced: DateTime.utc_now()}}
    else
      {:noreply, state}
    end
  end
end
