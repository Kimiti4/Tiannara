defmodule Tiannara.SOPL.LawUnknownRegistry do
  @moduledoc """
  SOPL-1.5: Law Unknown Registry
  
  Tracks unexplored territories in law-space to guide the SOPL-2 mutation engine.
  Identifies near-viable laws, constitutional edge zones, and unvisited regions
  so evolution explores deliberately rather than repeatedly searching dead ends.
  """
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      unvisited_regions: [
        %{desc: "High mutation with absolute identity persistence", parameters: %{mutation_pressure: 0.8, identity_weight: 0.9}},
        %{desc: "Zero novelty with low causal tolerance", parameters: %{novelty_reward: 0.0, causal_tolerance: 0.1}}
      ],
      edge_zones: [],
      near_viable: [],
      high_potential_unstable: []
    }}
  end

  @doc """
  Updates the registry with the latest live evaluations and historical ruins.
  """
  def update_topology_map(evaluations, ruins) do
    GenServer.cast(__MODULE__, {:update, evaluations, ruins})
  end

  def get_unknowns, do: GenServer.call(__MODULE__, :get_unknowns)

  def handle_cast({:update, evals, ruins}, state) do
    near_viable = extract_near_viable(evals)
    high_potential = extract_high_potential_unstable(ruins)
    edge_zones = extract_edge_zones(evals)

    Logger.info("🌌 [SOPL-1.5] Law Unknown Registry updated. Found #{length(near_viable)} near-viable and #{length(high_potential)} high-potential unstable targets for SOPL-2.")

    {:noreply, %{state | near_viable: near_viable, high_potential_unstable: high_potential, edge_zones: edge_zones}}
  end

  def handle_call(:get_unknowns, _from, state), do: {:reply, state, state}

  defp extract_near_viable(evals) do
    # Laws that scored well but just barely failed to become dominant attractors
    Enum.filter(evals, fn e -> e.total_fitness >= 0.6 and e.total_fitness < 0.8 end)
  end

  defp extract_high_potential_unstable(ruins) do
    # Collapsed laws (ruins) that had massive novelty but violated the constitution
    Enum.filter(ruins, fn r ->
      Map.has_key?(r.law_genome, :id) and length(r.produced_discoveries) > 0
    end)
  end

  defp extract_edge_zones(evals) do
    # Laws surviving with extreme constitutional pressure (danger close)
    Enum.filter(evals, fn e -> 
      Tiannara.SOPL.LandscapeAnalyzer.calculate_constitutional_pressure(e.law_genome) > 0.8 
    end)
  end
end
