defmodule Tiannara.ASC.Civilization.KnowledgePreservationEngine do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def preserve(cycle_data) do
    GenServer.cast(__MODULE__, {:preserve, cycle_data})
  end

  def retrieve(domain), do: GenServer.call(__MODULE__, {:retrieve, domain})
  def archive, do: GenServer.call(__MODULE__, :archive)

  @impl true
  def init(_opts) do
    {:ok, %{preserved: [], principles: [], lessons: [], total_preserved: 0, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:preserve, cycle_data}, state) do
    entry = %{
      id: "preserve_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}",
      cycle: Map.get(cycle_data, :cycle),
      decisions: Map.get(cycle_data, :decisions, []),
      risk_level: get_in(cycle_data, [:risk, :overall_risk]),
      sustainability_score: get_in(cycle_data, [:sustainability, :score]),
      preserved_at: DateTime.utc_now()
    }

    new_principles = extract_principles(cycle_data)

    {:noreply, %{state |
      preserved: [entry | state.preserved] |> Enum.take(1000),
      principles: new_principles ++ state.principles |> Enum.take(500),
      total_preserved: state.total_preserved + 1
    }}
  end

  @impl true
  def handle_call({:retrieve, _domain}, _from, state), do: {:reply, state.preserved, state}

  def handle_call(:archive, _from, state) do
    {:reply, %{total_preserved: state.total_preserved, principles: length(state.principles), lessons: length(state.lessons)}, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp extract_principles(cycle_data) do
    Map.get(cycle_data, :decisions, [])
    |> Enum.filter(fn d -> Map.get(d, :confidence, 0) > 0.8 end)
    |> Enum.map(fn d ->
      %{principle: Map.get(d, :action, "unnamed"), confidence: Map.get(d, :confidence, 0.8),
        evidence: Map.get(d, :evidence, ""), extracted_at: DateTime.utc_now()}
    end)
  end
end
