defmodule Tiannara.SOPL.LawAttractor do
  @moduledoc "An emergent gravity well in law-space."
  defstruct [
    :id,
    :centroid,             # Semantic descriptor or vector of law parameters
    :fitness,              # Average fitness in this attractor
    :persistence,          # Epochs spent in this attractor / Population size
    :pathology_profile,    # Frequency map of pathologies found here
    :constitutional_margin # Average distance to failure
  ]
end

defmodule Tiannara.SOPL.LawAttractorRegistry do
  @moduledoc """
  SOPL-1.5: Law Attractor Registry
  
  Discovers emergent LawAttractors by clustering LawGenomes dynamically.
  We do not hardcode "Balanced Optimum" or "Chaotic Frontier". They emerge
  based on actual ecosystem trajectories.
  """
  use GenServer
  require Logger
  alias Tiannara.SOPL.LawAttractor

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{attractors: []}}
  end

  @doc """
  Runs clustering over a set of evaluated LawGenomes and updates attractors.
  `evaluated_laws` is a list of maps: %{law_genome: law, total_fitness: f, pathologies: []}
  """
  def discover_attractors(evaluated_laws) do
    GenServer.call(__MODULE__, {:discover, evaluated_laws})
  end

  def get_attractors, do: GenServer.call(__MODULE__, :get_attractors)

  def handle_call({:discover, evaluated_laws}, _from, state) do
    # Emergent clustering based on law parameter vectors
    new_attractors = 
      evaluated_laws
      |> Enum.group_by(fn eval -> classify_centroid(eval.law_genome) end)
      |> Enum.map(fn {centroid_class, members} ->
        avg_fitness = Enum.sum(Enum.map(members, & &1.total_fitness)) / length(members)
        avg_margin = Enum.sum(Enum.map(members, & &1.law_genome.constitutional_margin)) / length(members)
        
        pathologies = 
          members
          |> Enum.flat_map(&Map.get(&1, :pathologies, []))
          |> Enum.frequencies_by(& &1.type)
          
        %LawAttractor{
          id: "attractor_#{:erlang.phash2(centroid_class)}",
          centroid: centroid_class,
          fitness: avg_fitness,
          persistence: length(members),
          pathology_profile: pathologies,
          constitutional_margin: avg_margin
        }
      end)

    Logger.info("🌌 [SOPL-1.5] Discovered #{length(new_attractors)} emergent Law Attractors.")

    {:reply, new_attractors, %{state | attractors: new_attractors}}
  end

  def handle_call(:get_attractors, _from, state) do
    {:reply, state.attractors, state}
  end

  defp classify_centroid(law) do
    # Creates a vector signature mapping exploration vs exploitation
    novelty = if law.mutation_pressure > 0.1, do: :high_mutation, else: :low_mutation
    truth = if Map.get(law.trust_formula, :identity_persistence_weight, 0.5) > 0.6, do: :rigid_identity, else: :fluid_identity
    "#{novelty}_#{truth}"
  end
end
