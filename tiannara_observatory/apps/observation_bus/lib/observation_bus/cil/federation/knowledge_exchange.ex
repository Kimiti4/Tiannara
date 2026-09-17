defmodule ObservationBus.CIL.Federation.KnowledgeExchange do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_exchanges, do: GenServer.call(__MODULE__, :list)
  def get_stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    exchanges = [
      %{id: "ke_1", from: "obs_alpha", to: "obs_beta", type: :discovery, content: "High-temperature superconductor candidate", verified: true, verified_at: DateTime.utc_now()},
      %{id: "ke_2", from: "obs_beta", to: "obs_gamma", type: :theory, content: "Plasma confinement model v3.2", verified: true, verified_at: DateTime.utc_now()},
      %{id: "ke_3", from: "obs_delta", to: "obs_alpha", type: :simulation, content: "Fusion ignition simulation results", verified: false, verified_at: nil},
      %{id: "ke_4", from: "obs_alpha", to: "obs_epsilon", type: :evidence, content: "Climate feedback loop observation", verified: true, verified_at: DateTime.utc_now()},
      %{id: "ke_5", from: "obs_gamma", to: "obs_delta", type: :engineering_design, content: "Reactor wall material specification", verified: false, verified_at: nil},
    ]
    {:ok, %{exchanges: exchanges, total_exchanged: 247, sync_rate: 0.88}}
  end

  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.exchanges, state}
  def handle_call(:stats, _from, state) do
    {:reply, %{total: state.total_exchanged, sync_rate: state.sync_rate, pending_verification: Enum.count(state.exchanges, &(!&1.verified))}, state}
  end
end
