defmodule ObservationBus.CIL.Federation.ObservatoryFederation do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_nodes, do: GenServer.call(__MODULE__, :list)
  def get_node(id), do: GenServer.call(__MODULE__, {:node, id})

  @impl true
  def init(_opts) do
    nodes = [
      %{id: "obs_alpha", name: "Alpha Observatory", location: :local, status: :online, latency_ms: 2, version: "1.6.0", last_sync: DateTime.utc_now(), discoveries_shared: 128, uptime_hours: 720},
      %{id: "obs_beta", name: "Beta Research Cluster", location: :regional, status: :online, latency_ms: 45, version: "1.5.0", last_sync: DateTime.add(DateTime.utc_now(), -300, :second), discoveries_shared: 85, uptime_hours: 480},
      %{id: "obs_gamma", name: "Gamma Engineering Center", location: :regional, status: :degraded, latency_ms: 120, version: "1.4.0", last_sync: DateTime.add(DateTime.utc_now(), -1800, :second), discoveries_shared: 42, uptime_hours: 240},
      %{id: "obs_delta", name: "Delta Simulation Hub", location: :continental, status: :online, latency_ms: 150, version: "1.5.0", last_sync: DateTime.add(DateTime.utc_now(), -600, :second), discoveries_shared: 210, uptime_hours: 360},
      %{id: "obs_epsilon", name: "Epsilon Planetary Twin", location: :continental, status: :online, latency_ms: 200, version: "1.3.0", last_sync: DateTime.add(DateTime.utc_now(), -900, :second), discoveries_shared: 67, uptime_hours: 168},
    ]
    {:ok, %{nodes: nodes, federation_health: :operational, sync_interval_seconds: 60}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.nodes, state}
  def handle_call({:node, id}, _from, state), do: {:reply, Enum.find(state.nodes, &(&1.id == id)), state}
end
