defmodule ObservationBus.CIL.Federation.CivilizationMemory do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_graph, do: GenServer.call(__MODULE__, :graph)
  def get_stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    state = %{
      total_nodes: 12400,
      total_edges: 87200,
      domains: %{physics: 3200, biology: 2100, computing: 1800, engineering: 1500, mathematics: 1200, energy: 800, materials: 600, other: 1200},
      last_updated: DateTime.utc_now(),
      sync_status: :synchronized,
      cross_references: 45600
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:graph, _from, state), do: {:reply, state, state}
  def handle_call(:stats, _from, state) do
    {:reply, Map.take(state, [:total_nodes, :total_edges, :domains, :sync_status, :cross_references]), state}
  end
end
