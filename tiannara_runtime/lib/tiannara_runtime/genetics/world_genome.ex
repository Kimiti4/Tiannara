defmodule Tiannara.Genetics.WorldGenome do
  @moduledoc """
  Represents the genetic blueprint of a cognitive world.
  
  Each world is not a monolithic state object, but a genetic vector field
  containing evolvable subsystem parameters (CAL, CIS, Entropy, Selection).
  
  This struct enables:
  - Horizontal Law Transfer (HLT) between resonant worlds
  - Chimeric Collapse with subsystem-level recombination
  - Species emergence via genome similarity clustering
  - Evolutionary memory tracking across generations
  """

  @type genome_vector :: [float()]
  @type subsystem_genes :: %{
    base_params: %{atom() => float()},
    mutation_rate: float(),
    inheritance_bias: float()
  }

  @type t :: %__MODULE__{
    world_id: String.t(),
    cal_genes: subsystem_genes(),
    cis_genes: subsystem_genes(),
    entropy_genes: subsystem_genes(),
    selection_genes: subsystem_genes(),
    mutation_rate: float(),
    stability_trace: [stability_record()],
    generation: non_neg_integer(),
    parent_ids: [String.t()],
    species_id: String.t() | nil
  }

  @type stability_record :: %{
    timestamp: DateTime.t(),
    fitness: float(),
    entropy: float(),
    subsystem_health: %{atom() => float()}
  }

  defstruct [
    :world_id,
    :cal_genes,
    :cis_genes,
    :entropy_genes,
    :selection_genes,
    :mutation_rate,
    :stability_trace,
    generation: 0,
    parent_ids: [],
    species_id: nil
  ]

  @default_mutation_rate 0.05
  @default_inheritance_bias 0.5
  @max_stability_trace_length 100

  @doc """
  Creates a new world genome with default genetic parameters.
  
  ## Parameters
    - world_id: Unique identifier for the world
    - parent_ids: List of parent world IDs (empty for root worlds)
    - initial_params: Optional override for initial gene values
  
  ## Examples
      iex> WorldGenome.new("W1")
      %WorldGenome{world_id: "W1", generation: 0, parent_ids: []}
      
      iex> WorldGenome.new("W2", ["W1"], %{mutation_rate: 0.08})
      %WorldGenome{world_id: "W2", generation: 1, parent_ids: ["W1"], mutation_rate: 0.08}
  """
  def new(world_id, parent_ids \\ [], initial_params \\ %{}) do
    %__MODULE__{
      world_id: world_id,
      cal_genes: initialize_subsystem_genes(:cal, initial_params),
      cis_genes: initialize_subsystem_genes(:cis, initial_params),
      entropy_genes: initialize_subsystem_genes(:entropy, initial_params),
      selection_genes: initialize_subsystem_genes(:selection, initial_params),
      mutation_rate: Map.get(initial_params, :mutation_rate, @default_mutation_rate),
      stability_trace: [],
      generation: calculate_generation(parent_ids),
      parent_ids: parent_ids,
      species_id: nil
    }
  end

  @doc """
  Applies mutation to genome with probability based on mutation_rate.
  
  Mutations are applied independently to each subsystem, allowing for
  modular evolution where CAL might mutate while CIS remains stable.
  
  ## Parameters
    - genome: The genome to mutate
    - mutation_strength: Magnitude of mutation (default: 0.1)
  
  ## Returns
    - Mutated genome with updated gene parameters
  """
  def mutate(genome, mutation_strength \\ 0.1) do
    mutated_cal = mutate_subsystem(genome.cal_genes, genome.mutation_rate, mutation_strength)
    mutated_cis = mutate_subsystem(genome.cis_genes, genome.mutation_rate, mutation_strength)
    mutated_entropy = mutate_subsystem(genome.entropy_genes, genome.mutation_rate, mutation_strength)
    mutated_selection = mutate_subsystem(genome.selection_genes, genome.mutation_rate, mutation_strength)
    
    %{
      genome
      | cal_genes: mutated_cal,
        cis_genes: mutated_cis,
        entropy_genes: mutated_entropy,
        selection_genes: mutated_selection
    }
  end

  @doc """
  Creates a chimeric genome by merging two parent genomes using Boltzmann selection.
  
  Each subsystem is independently selected based on local fitness using:
    P(field_A) = exp(φ_A / τ) / (exp(φ_A / τ) + exp(φ_B / τ))
  
  ## Parameters
    - genome_a: First parent genome
    - genome_b: Second parent genome
    - subsystem_fitness: Map of subsystem fitness values %{cal: 0.89, cis: 0.94, ...}
    - selection_temperature: Boltzmann temperature τ (lower = more deterministic)
  
  ## Returns
    - New chimeric genome with recombined subsystems
  """
  def merge_chimeric(genome_a, genome_b, subsystem_fitness, selection_temperature \\ 0.15) do
    chimera_id = "CHIMERA-#{genome_a.world_id}-#{genome_b.world_id}"
    
    # Select each subsystem independently via Boltzmann distribution
    cal_genes = select_subsystem(:cal, genome_a, genome_b, subsystem_fitness, selection_temperature)
    cis_genes = select_subsystem(:cis, genome_a, genome_b, subsystem_fitness, selection_temperature)
    entropy_genes = select_subsystem(:entropy, genome_a, genome_b, subsystem_fitness, selection_temperature)
    selection_genes = select_subsystem(:selection, genome_a, genome_b, subsystem_fitness, selection_temperature)
    
    # Entropy penalty for collapse event
    merged_mutation_rate = max(genome_a.mutation_rate, genome_b.mutation_rate) + 0.05
    
    %__MODULE__{
      world_id: chimera_id,
      cal_genes: cal_genes,
      cis_genes: cis_genes,
      entropy_genes: entropy_genes,
      selection_genes: selection_genes,
      mutation_rate: merged_mutation_rate,
      stability_trace: [],
      generation: max(genome_a.generation, genome_b.generation) + 1,
      parent_ids: [genome_a.world_id, genome_b.world_id],
      species_id: nil
    }
  end

  @doc """
  Extracts genome as a numeric vector for UMAP/HDBSCAN clustering.
  
  Returns a flattened vector representing the world's position in
  multi-dimensional genetic space.
  
  ## Example vector components:
    [cal_cohesion, cal_decay, cis_sensitivity, cis_dampening, 
     entropy_base, entropy_leak, selection_temperature, mutation_rate]
  """
  def to_feature_vector(%__MODULE__{} = genome) do
    [
      # CAL genes (cohesion optimization)
      genome.cal_genes.base_params[:cohesion_weight] || 0.5,
      genome.cal_genes.base_params[:decay_rate] || 0.1,
      
      # CIS genes (shock dampening)
      genome.cis_genes.base_params[:sensitivity] || 0.7,
      genome.cis_genes.base_params[:dampening_factor] || 0.3,
      
      # Entropy genes (controlled chaos)
      genome.entropy_genes.base_params[:base_entropy] || 0.2,
      genome.entropy_genes.base_params[:leak_rate] || 0.05,
      
      # Selection genes (survival optimization)
      genome.selection_genes.base_params[:selection_pressure] || 0.6,
      genome.selection_genes.base_params[:exploration_bonus] || 0.1,
      
      # Global parameters
      genome.mutation_rate
    ]
  end

  @doc """
  Computes cosine similarity between two genomes for species classification.
  
  Worlds with similarity > 0.92 are considered the same species.
  
  ## Returns
    - Similarity score in range [0.0, 1.0]
  """
  def similarity(genome_a, genome_b) do
    vector_a = to_feature_vector(genome_a)
    vector_b = to_feature_vector(genome_b)
    
    dot_product = Enum.zip(vector_a, vector_b) |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
    magnitude_a = :math.sqrt(Enum.reduce(vector_a, 0, fn x, acc -> acc + x * x end))
    magnitude_b = :math.sqrt(Enum.reduce(vector_b, 0, fn x, acc -> acc + x * x end))
    
    if magnitude_a == 0 or magnitude_b == 0 do
      0.0
    else
      dot_product / (magnitude_a * magnitude_b)
    end
  end

  @doc """
  Records a stability snapshot in the evolutionary memory trace.
  
  Maintains a rolling window of the most recent 100 stability records.
  """
  def record_stability(%__MODULE__{} = genome, fitness, entropy, subsystem_health) do
    new_record = %{
      timestamp: DateTime.utc_now(),
      fitness: fitness,
      entropy: entropy,
      subsystem_health: subsystem_health
    }
    
    updated_trace = [new_record | genome.stability_trace]
    |> Enum.take(@max_stability_trace_length)
    
    %{genome | stability_trace: updated_trace}
  end

  # Private helper functions

  defp initialize_subsystem_genes(subsystem_type, initial_params) do
    base_params = get_default_params(subsystem_type)
    |> merge_with_initial(initial_params, subsystem_type)
    
    %{
      base_params: base_params,
      mutation_rate: Map.get(initial_params, :mutation_rate, @default_mutation_rate),
      inheritance_bias: @default_inheritance_bias
    }
  end

  defp get_default_params(:cal), do: %{
    cohesion_weight: 0.5,
    decay_rate: 0.1,
    coalition_bonus: 0.3,
    cluster_tolerance: 0.2
  }

  defp get_default_params(:cis), do: %{
    sensitivity: 0.7,
    dampening_factor: 0.3,
    shock_threshold: 0.5,
    recovery_speed: 0.4
  }

  defp get_default_params(:entropy), do: %{
    base_entropy: 0.2,
    leak_rate: 0.05,
    exploration_bonus: 0.15,
    collapse_penalty: 0.8
  }

  defp get_default_params(:selection), do: %{
    selection_pressure: 0.6,
    exploration_bonus: 0.1,
    survival_threshold: 0.2,
    adaptive_temperature: 0.15
  }

  defp merge_with_initial(defaults, initial_params, subsystem_type) do
    key = subsystem_type
    case Map.get(initial_params, key) do
      nil -> defaults
      overrides -> Map.merge(defaults, overrides)
    end
  end

  defp calculate_generation(parent_ids) do
    case parent_ids do
      [] -> 0
      _ -> 1  # Will be properly set by parent tracking
    end
  end

  defp mutate_subsystem(genes, mutation_rate, mutation_strength) do
    if :rand.uniform() <= mutation_rate do
      mutated_params = genes.base_params
      |> Enum.map(fn {param, value} ->
        delta = (:rand.uniform() * 2 - 1) * mutation_strength
        {param, max(0.0, min(1.0, value + delta))}
      end)
      |> Map.new()
      
      %{genes | base_params: mutated_params}
    else
      genes  # No mutation this cycle
    end
  end

  defp select_subsystem(field_type, genome_a, genome_b, subsystem_fitness, tau_selection) do
    phi_a = Map.get(subsystem_fitness, field_type, 0.5)
    phi_b = Map.get(subsystem_fitness, field_type, 0.5)
    
    # Boltzmann selection probability
    p_a = :math.exp(phi_a / tau_selection)
    p_b = :math.exp(phi_b / tau_selection)
    probability_a = p_a / (p_a + p_b)
    
    if :rand.uniform() <= probability_a do
      genome_a |> Map.get(:"#{field_type}_genes")
    else
      genome_b |> Map.get(:"#{field_type}_genes")
    end
  end
end
