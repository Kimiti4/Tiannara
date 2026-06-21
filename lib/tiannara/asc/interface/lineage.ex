defmodule Tiannara.ASC.Interface.Lineage do
  @moduledoc """
  Interface Lineage — tracks the evolutionary history of an interface genome family.

  A lineage represents a continuous chain of genomes connected by mutation and crossover,
  enabling longitudinal analysis of interface evolution patterns.

  This allows Tiannara to answer questions like:
  - "Which API family survived 50 generations?"
  - "What mutation patterns lead to lineage extinction?"
  - "How does contract complexity evolve within a lineage over time?"

  ## Example

      iex> lineage = %Tiannara.ASC.Interface.Lineage{
      ...>   id: "lineage_abc123",
      ...>   ancestor_genome: %Genome{...},
      ...>   current_genome: %Genome{...},
      ...>   generation: 42,
      ...>   mutations: [%Mutation{...}, %Mutation{...}],
      ...>   fitness_history: [0.65, 0.72, 0.78, 0.85],
      ...>   parent_lineages: ["lineage_xyz789"],
      ...>   children_lineages: [],
      ...>   extinct?: false,
      ...>   created_at: DateTime.utc_now()
      ...> }

  """

  alias Tiannara.ASC.Interface.{Genome, Mutation}

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique lineage identifier
    ancestor_genome: nil,       # Original genome that started this lineage
    current_genome: nil,        # Most recent genome in lineage

    # Temporal tracking
    generation: 0,              # Current generation number
    created_at: nil,            # When lineage was created
    last_updated_at: nil,       # When lineage was last modified

    # Evolutionary history
    mutations: [],              # List of all mutations applied to this lineage
    fitness_history: [],        # Fitness scores across generations
    genome_versions: [],        # Historical snapshots of genomes

    # Genealogical relationships
    parent_lineages: [],        # IDs of parent lineages (from crossover)
    children_lineages: [],      # IDs of child lineages (from speciation)

    # Status
    extinct?: false,            # Has lineage gone extinct?
    extinction_generation: nil, # Generation when lineage went extinct (if applicable)

    # Metadata
    species_id: nil,            # Species classification (from Speciation engine)
    dominant_protocol: nil,     # Primary protocol type used in this lineage
    total_mutations_applied: 0  # Count of mutations for efficiency
  ]

  @typedoc "Interface lineage record"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          ancestor_genome: Genome.t() | nil,
          current_genome: Genome.t() | nil,
          generation: non_neg_integer(),
          created_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil,
          mutations: [Mutation.t()],
          fitness_history: [float()],
          genome_versions: [Genome.t()],
          parent_lineages: [String.t()],
          children_lineages: [String.t()],
          extinct?: boolean(),
          extinction_generation: non_neg_integer() | nil,
          species_id: String.t() | nil,
          dominant_protocol: atom() | nil,
          total_mutations_applied: non_neg_integer()
        }

  @doc """
  Create a new lineage from an initial genome.

  Initializes lineage with the genome as both ancestor and current state.
  """
  def new(%Genome{} = genome) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: generate_id(),
      ancestor_genome: genome,
      current_genome: genome,
      generation: genome.generation,
      created_at: now,
      last_updated_at: now,
      mutations: [],
      fitness_history: [genome.fitness],
      genome_versions: [genome],
      parent_lineages: [],
      children_lineages: [],
      extinct?: false,
      extinction_generation: nil,
      species_id: nil,
      dominant_protocol: determine_dominant_protocol(genome),
      total_mutations_applied: 0
    }
  end

  @doc """
  Apply a mutation to the lineage, advancing it to a new generation.

  Updates current genome, records mutation, and appends fitness to history.

  ## Returns

  - Updated lineage with mutation applied

  """
  def apply_mutation(%__MODULE__{} = lineage, %Mutation{} = mutation, %Genome{} = new_genome) do
    now = DateTime.utc_now()

    %{
      lineage
      | current_genome: new_genome,
        generation: new_genome.generation,
        last_updated_at: now,
        mutations: lineage.mutations ++ [mutation],
        fitness_history: lineage.fitness_history ++ [new_genome.fitness],
        genome_versions: lineage.genome_versions ++ [new_genome],
        total_mutations_applied: lineage.total_mutations_applied + 1,
        dominant_protocol: determine_dominant_protocol(new_genome)
    }
  end

  @doc """
  Mark lineage as extinct.

  Records the generation when extinction occurred.
  """
  def mark_extinct(%__MODULE__{} = lineage, generation) do
    %{
      lineage
      | extinct?: true,
        extinction_generation: generation,
        last_updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Add parent lineage reference (from crossover).

  Links this lineage to its parental lineages.
  """
  def add_parent(%__MODULE__{} = lineage, parent_lineage_id) do
    %{
      lineage
      | parent_lineages: Enum.uniq(lineage.parent_lineages ++ [parent_lineage_id])
    }
  end

  @doc """
  Add child lineage reference (from speciation).

  Links this lineage to its offspring.
  """
  def add_child(%__MODULE__{} = lineage, child_lineage_id) do
    %{
      lineage
      | children_lineages: Enum.uniq(lineage.children_lineages ++ [child_lineage_id])
    }
  end

  @doc """
  Assign species classification.

  Categorizes lineage into a species based on protocol/interface characteristics.
  """
  def assign_species(%__MODULE__{} = lineage, species_id) do
    %{lineage | species_id: species_id}
  end

  @doc """
  Calculate lineage longevity (number of generations survived).

  Returns generation count if still alive, or extinction generation if extinct.
  """
  def longevity(%__MODULE__{extinct?: true, extinction_generation: gen}), do: gen
  def longevity(%__MODULE__{generation: gen}), do: gen

  @doc """
  Calculate average fitness improvement per generation.

  Positive values indicate improving lineage; negative indicates degradation.
  """
  def avg_fitness_improvement(%__MODULE__{fitness_history: history}) when length(history) < 2 do
    0.0
  end

  def avg_fitness_improvement(%__MODULE__{fitness_history: history}) do
    [first | rest] = history
    last = List.last(rest)
    (last - first) / length(history)
  end

  @doc """
  Check if lineage shows consistent improvement.

  Returns true if fitness has improved in >50% of generations.
  """
  def consistently_improving?(%__MODULE__{fitness_history: history}) when length(history) < 2 do
    false
  end

  def consistently_improving?(%__MODULE__{fitness_history: history}) do
    improvements = history
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.count(fn [a, b] -> b > a end)

    improvements / (length(history) - 1) > 0.5
  end

  @doc """
  Extract mutation pattern summary.

  Returns frequency distribution of mutation types applied to this lineage.
  """
  def mutation_pattern_summary(%__MODULE__{mutations: mutations}) do
    mutations
    |> Enum.map(& &1.type)
    |> Enum.frequencies()
  end

  # Private helpers

  defp generate_id do
    "lineage_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp determine_dominant_protocol(%Genome{protocols: protocols}) when length(protocols) == 0 do
    nil
  end

  defp determine_dominant_protocol(%Genome{protocols: protocols}) do
    # Find most common protocol type
    protocols
    |> Enum.map(& &1.type)
    |> Enum.frequencies()
    |> Enum.max_by(fn {_type, count} -> count end)
    |> elem(0)
  end
end
