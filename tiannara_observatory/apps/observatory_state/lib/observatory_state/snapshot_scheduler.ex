defmodule ObservatoryState.SnapshotScheduler do
  use GenServer

  @interval :timer.minutes(5)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:snapshot, state) do
    take_snapshot()
    schedule()
    {:noreply, state}
  end

  defp schedule do
    Process.send_after(self(), :snapshot, @interval)
  end

  defp take_snapshot do
    domains = %{
      runtime: :obs_runtime_state,
      scientific: :obs_scientific_state,
      engineering: :obs_engineering_state,
      knowledge: :obs_knowledge_state,
      planetary: :obs_planetary_state,
      civilization: :obs_civilization_state,
      evolution: :obs_evolution_state,
      governance: :obs_governance_state,
      certification: :obs_certification_state
    }

    Enum.each(domains, fn {name, table} ->
      data = :ets.tab2list(table)
      ReplayStore.Snapshot.create("state/#{name}", data)
    end)
  end
end
