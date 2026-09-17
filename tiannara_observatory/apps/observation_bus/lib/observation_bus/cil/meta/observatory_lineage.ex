defmodule ObservationBus.CIL.Meta.ObservatoryLineage do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_lineage, do: GenServer.call(__MODULE__, :lineage)
  def get_version(version), do: GenServer.call(__MODULE__, {:version, version})

  @impl true
  def init(_opts) do
    versions = [
      %{version: "1.0.0", name: "Initial Observatory", deployed_at: ~U[2026-01-15 00:00:00Z], certification: :certified, changes: ["Initial deployment"], components: 12},
      %{version: "1.1.0", name: "CIL Integration", deployed_at: ~U[2026-03-01 00:00:00Z], certification: :certified, changes: ["Added Constitutional Intelligence Layer (M10)"], components: 24},
      %{version: "1.2.0", name: "Predictive & Epistemic", deployed_at: ~U[2026-04-15 00:00:00Z], certification: :certified, changes: ["Added CPO (M11)", "Added CEO (M12)"], components: 39},
      %{version: "1.3.0", name: "Mission Control", deployed_at: ~U[2026-05-20 00:00:00Z], certification: :certified, changes: ["Added CSMC (M13)"], components: 49},
      %{version: "1.4.0", name: "Strategic Intelligence", deployed_at: ~U[2026-06-10 00:00:00Z], certification: :certified, changes: ["Added CSIC (M14)"], components: 56},
      %{version: "1.5.0", name: "Civilization Observatory", deployed_at: ~U[2026-07-01 00:00:00Z], certification: :certified, changes: ["Added CCO (M15)"], components: 63},
      %{version: "1.6.0", name: "Futures Laboratory", deployed_at: nil, certification: :provisional, changes: ["Added CFL (M16)"], components: 70},
    ]
    {:ok, %{versions: versions, current_version: "1.6.0"}}
  end

  @impl true
  def handle_call(:lineage, _from, state) do
    {:reply, %{versions: state.versions, current: state.current_version}, state}
  end
  def handle_call({:version, version}, _from, state) do
    {:reply, Enum.find(state.versions, &(&1.version == version)), state}
  end
end
