defmodule Tiannara.Sentinel.D2.EpistemologyGraph do
  @moduledoc """
  D.2: Tracks Epistemologies (combinations of reasoning operators) as first-class entities.
  Maps Operator Sets -> Outcomes.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records the active epistemology of a civilization and its current outcomes."
  def record_epistemology(civ_id, operators, outcomes) do
    GenServer.cast(__MODULE__, {:record, civ_id, operators, outcomes})
  end

  @doc "Retrieves the entire graph."
  def get_graph do
    GenServer.call(__MODULE__, :get_graph)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting D.2 EpistemologyGraph")
    {:ok, %{
      epistemologies: %{}, # operator_set -> stats
      pair_relationships: %{} # {op_a, op_b} -> %{synergy: float, antagonism: float}
    }}
  end

  @impl true
  def handle_cast({:record, _civ_id, operators, outcomes}, state) do
    # Sort operators so that the combination acts as a unique signature
    signature = Enum.sort(operators)
    
    current = Map.get(state.epistemologies, signature, %{
      adoption_count: 0,
      total_discoveries: 0,
      disease_resistance: 0.0,
      truth_retention: 0.0,
      fitness_snapshots: []
    })

    updated = %{current |
      adoption_count: current.adoption_count + 1,
      total_discoveries: current.total_discoveries + Map.get(outcomes, :discoveries_produced, 0),
      disease_resistance: Map.get(outcomes, :disease_resistance, current.disease_resistance),
      truth_retention: Map.get(outcomes, :truth_retention, current.truth_retention),
      fitness_snapshots: [Map.get(outcomes, :fitness, 0.0) | current.fitness_snapshots]
    }

    # Update Pair Relationships
    fitness = Map.get(outcomes, :fitness, 0.0)
    is_positive = fitness > 0.5 or Map.get(outcomes, :discoveries_produced, 0) > 0
    is_negative = Map.get(outcomes, :collapsed, false) or fitness < 0.2

    new_pairs = update_pairs(signature, state.pair_relationships, is_positive, is_negative)

    {:noreply, %{state | epistemologies: Map.put(state.epistemologies, signature, updated), pair_relationships: new_pairs}}
  end

  @impl true
  def handle_call(:get_graph, _from, state) do
    {:reply, state.epistemologies, state}
  end

  @doc "Retrieves the pairwise synergies and antagonisms."
  def get_ecology_map do
    GenServer.call(__MODULE__, :get_ecology_map, :infinity)
  end

  @impl true
  def handle_call(:get_ecology_map, _from, state) do
    {:reply, state.pair_relationships, state}
  end

  defp update_pairs(signature, pair_map, is_positive, is_negative) do
    pairs = for a <- signature, b <- signature, a < b, do: {a, b}
    
    Enum.reduce(pairs, pair_map, fn pair, acc ->
      current = Map.get(acc, pair, %{synergy: 0.0, antagonism: 0.0})
      
      syn_inc = if is_positive, do: 1.0, else: 0.0
      ant_inc = if is_negative, do: 1.0, else: 0.0
      
      Map.put(acc, pair, %{
        synergy: current.synergy + syn_inc,
        antagonism: current.antagonism + ant_inc
      })
    end)
  end
end
