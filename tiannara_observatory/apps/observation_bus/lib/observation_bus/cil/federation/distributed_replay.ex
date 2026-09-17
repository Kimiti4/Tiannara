defmodule ObservationBus.CIL.Federation.DistributedReplay do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_state, do: GenServer.call(__MODULE__, :state)
  def replay_node(node_id), do: GenServer.call(__MODULE__, {:replay_node, node_id})
  def replay_global, do: GenServer.call(__MODULE__, :replay_global)

  @impl true
  def init(_opts) do
    state = %{
      snapshots: %{
        obs_alpha: %{id: "snap_a1", timestamp: DateTime.add(DateTime.utc_now(), -3600, :second), events: 15200, integrity: :verified},
        obs_beta: %{id: "snap_b1", timestamp: DateTime.add(DateTime.utc_now(), -1800, :second), events: 8900, integrity: :verified},
        obs_gamma: %{id: "snap_g1", timestamp: DateTime.add(DateTime.utc_now(), -7200, :second), events: 4200, integrity: :verified},
        obs_delta: %{id: "snap_d1", timestamp: DateTime.add(DateTime.utc_now(), -900, :second), events: 23100, integrity: :verified},
      },
      global_replay_capability: true,
      cross_node_consistency: 0.96,
      last_global_sync: DateTime.utc_now()
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}
  def handle_call({:replay_node, node_id}, _from, state) do
    snap = Map.get(state.snapshots, String.to_atom(node_id)) || Map.get(state.snapshots, node_id)
    {:reply, snap, state}
  end
  def handle_call(:replay_global, _from, state) do
    {:reply, %{capability: state.global_replay_capability, consistency: state.cross_node_consistency, nodes: Map.keys(state.snapshots)}, state}
  end
end
