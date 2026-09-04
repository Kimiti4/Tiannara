defmodule Tiannara.ASC.CivilizationMemory do
  @moduledoc """
  Maintains civilization-scale memory through archaeological preservation.
  Failures become civilizational archaeology, not deletion.
  Integrates with Reality Graph, Archaeology System, and OMCE.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def preserve(pid, record), do: GenServer.cast(pid, {:preserve, record})
  def retrieve(pid, query), do: GenServer.call(pid, {:retrieve, query})

  @impl true
  def init(_), do: {:ok, %{discoveries: %{}, failures: %{}, principles: %{}}}

  @impl true
  def handle_cast({:preserve, %{type: :discovery} = record}, state) do
    state = put_in(state, [:discoveries, record.id], record)
    Tiannara.RealityGraph.add_node(:discovery, record)
    {:noreply, state}
  end

  def handle_cast({:preserve, %{type: :failure} = record}, state) do
    state = put_in(state, [:failures, record.id], record)
    Tiannara.RealityGraph.add_node(:archaeology_failure, record)
    {:noreply, state}
  end

  def handle_cast({:preserve, %{type: :principle} = record}, state) do
    state = put_in(state, [:principles, record.id], record)
    Tiannara.RealityGraph.add_node(:principle, record)
    {:noreply, state}
  end

  @impl true
  def handle_call({:retrieve, query}, _from, state) do
    results = case query.type do
      :discovery -> Map.values(state.discoveries)
      :failure -> Map.values(state.failures)
      :principle -> Map.values(state.principles)
      :all -> Map.values(state.discoveries) ++ Map.values(state.failures) ++ Map.values(state.principles)
    end
    filtered = Enum.filter(results, fn r -> r.domain == query.domain end)
    {:reply, filtered, state}
  end
end
