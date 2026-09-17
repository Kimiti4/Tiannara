defmodule ObservationBus.CIL.Federation.ScientificFederation do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_members, do: GenServer.call(__MODULE__, :members)
  def get_stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    members = [
      %{id: "lab_1", name: "Fusion Research Lab", type: :laboratory, node: "obs_alpha", active_projects: 12, certification: :certified},
      %{id: "lab_2", name: "Materials Discovery Center", type: :laboratory, node: "obs_beta", active_projects: 8, certification: :certified},
      %{id: "lab_3", name: "AI Research Group", type: :research_group, node: "obs_alpha", active_projects: 15, certification: :certified},
      %{id: "lab_4", name: "Quantum Computing Center", type: :engineering_center, node: "obs_delta", active_projects: 6, certification: :provisional},
      %{id: "lab_5", name: "Planetary Sciences Division", type: :laboratory, node: "obs_epsilon", active_projects: 10, certification: :certified},
      %{id: "lab_6", name: "Nanotechnology Institute", type: :university, node: "obs_gamma", active_projects: 4, certification: :provisional},
    ]
    {:ok, %{members: members, total_discovery_challenges: 18, active_collaborations: 7}}
  end

  @impl true
  def handle_call(:members, _from, state), do: {:reply, state.members, state}
  def handle_call(:stats, _from, state), do: {:reply, Map.take(state, [:total_discovery_challenges, :active_collaborations]), state}
end
