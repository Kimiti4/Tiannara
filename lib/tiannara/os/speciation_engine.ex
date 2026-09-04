defmodule TiannaraOS.SpeciationEngine do
  @moduledoc """
  Tracks and manages speciation in research ecosystems.
  
  When strategy genomes diverge sufficiently, new species emerge.
  This creates ecological diversity rather than single dominant genome.
  
  Species are defined by niche signatures - clusters of similar strategies.
  """
  
  alias TiannaraOS.ResearchProgram
  
  @type species_id :: atom()
  @type niche_signature :: %{
    exploration: float(),
    validation: float(),
    synthesis: float(),
    anomaly_sensitivity: float(),
    risk_tolerance: float()
  }
  
  @speciation_threshold 0.3  # Genome distance threshold for new species
  
  @doc """
  Classify a program into a species based on its genome.
  
  Uses k-means-like clustering to assign programs to species.
  If no existing species matches well enough, create new species.
  """
  @spec classify_species(ResearchProgram.t(), map()) :: {species_id, map()}
  def classify_species(%ResearchProgram{strategy_genome: genome}, species_registry) do
    niche = extract_niche_signature(genome)
    
    # Find closest existing species
    {closest_species_id, distance} = find_closest_species(niche, species_registry)
    
    if distance < @speciation_threshold do
      # Belongs to existing species
      {closest_species_id, species_registry}
    else
      # Create new species
      new_species_id = generate_species_id(niche)
      updated_registry = Map.put(species_registry, new_species_id, %{
        niche_signature: niche,
        founding_programs: [genome],
        created_at: :os.system_time(:millisecond),
        member_count: 1
      })
      
      {new_species_id, updated_registry}
    end
  end
  
  @doc """
  Extract niche signature from strategy genome.
  
  Normalizes genome to create comparable niche profile.
  """
  @spec extract_niche_signature(map()) :: niche_signature()
  def extract_niche_signature(genome) do
    %{
      exploration: genome.exploration_rate,
      validation: genome.validation_priority,
      synthesis: genome.cross_domain_synthesis,
      anomaly_sensitivity: genome.anomaly_sensitivity,
      risk_tolerance: genome.risk_tolerance
    }
  end
  
  @doc """
  Find the closest existing species to a niche signature.
  
  Returns {species_id, euclidean_distance}.
  """
  @spec find_closest_species(niche_signature(), map()) :: {species_id | nil, float()}
  def find_closest_species(niche, species_registry) do
    if map_size(species_registry) == 0 do
      {nil, 999.0}  # No species exist yet
    else
      distances = Enum.map(species_registry, fn {species_id, species_data} ->
        distance = calculate_niche_distance(niche, species_data.niche_signature)
        {species_id, distance}
      end)
      
      Enum.min_by(distances, fn {_id, dist} -> dist end)
    end
  end
  
  @doc """
  Calculate Euclidean distance between two niche signatures.
  """
  @spec calculate_niche_distance(niche_signature(), niche_signature()) :: float()
  def calculate_niche_distance(niche1, niche2) do
    :math.sqrt(
      :math.pow(niche1.exploration - niche2.exploration, 2) +
      :math.pow(niche1.validation - niche2.validation, 2) +
      :math.pow(niche1.synthesis - niche2.synthesis, 2) +
      :math.pow(niche1.anomaly_sensitivity - niche2.anomaly_sensitivity, 2) +
      :math.pow(niche1.risk_tolerance - niche2.risk_tolerance, 2)
    )
  end
  
  @doc """
  Generate unique species ID based on niche characteristics.
  """
  @spec generate_species_id(niche_signature()) :: species_id()
  def generate_species_id(niche) do
    # Create descriptive species name
    primary_trait = determine_primary_trait(niche)
    hash = :erlang.phash2(niche) |> Integer.to_string(36) |> String.slice(0..5)
    
    String.to_atom("species_#{primary_trait}_#{hash}")
  end
  
  @doc """
  Determine the primary trait defining this niche.
  """
  @spec determine_primary_trait(niche_signature()) :: String.t()
  def determine_primary_trait(niche) do
    traits = [
      {"explorer", niche.exploration},
      {"validator", niche.validation},
      {"synthesizer", niche.synthesis},
      {"hunter", niche.anomaly_sensitivity},
      {"risk_taker", niche.risk_tolerance}
    ]
    
    {name, _value} = Enum.max_by(traits, fn {_name, value} -> value end)
    name
  end
  
  @doc """
  Update species registry when programs die or are born.
  """
  @spec update_species_registry(map(), ResearchProgram.t(), :birth | :death) :: map()
  def update_species_registry(species_registry, %ResearchProgram{} = program, event_type) do
    case Map.get(program.metadata, :species_id) do
      nil ->
        species_registry  # Program not classified yet
      
      species_id ->
        case Map.get(species_registry, species_id) do
          nil ->
            species_registry  # Species doesn't exist (shouldn't happen)
          
          species_data ->
            updated_count = 
              case event_type do
                :birth -> species_data.member_count + 1
                :death -> max(species_data.member_count - 1, 0)
              end
            
            # Remove extinct species
            if updated_count == 0 do
              Map.delete(species_registry, species_id)
            else
              Map.put(species_registry, species_id, %{
                species_data |
                member_count: updated_count
              })
            end
        end
    end
  end
  
  @doc """
  Get species diversity metrics.
  
  Returns number of species, population distribution, and Shannon entropy.
  """
  @spec get_species_diversity(map()) :: %{
    species_count: integer(),
    total_population: integer(),
    shannon_entropy: float(),
    dominant_species: species_id | nil
  }
  def get_species_diversity(species_registry) do
    species_list = Map.values(species_registry)
    species_count = length(species_list)
    
    if species_count == 0 do
      %{
        species_count: 0,
        total_population: 0,
        shannon_entropy: 0.0,
        dominant_species: nil
      }
    else
      populations = Enum.map(species_list, & &1.member_count)
      total_population = Enum.sum(populations)
      
      # Calculate Shannon entropy
      shannon_entropy = calculate_shannon_entropy(populations, total_population)
      
      # Find dominant species
      dominant_species = 
        species_list
        |> Enum.max_by(& &1.member_count)
        |> Map.get(:id)
      
      %{
        species_count: species_count,
        total_population: total_population,
        shannon_entropy: Float.round(shannon_entropy, 4),
        dominant_species: dominant_species
      }
    end
  end
  
  @spec calculate_shannon_entropy([integer()], integer()) :: float()
  defp calculate_shannon_entropy(populations, total) do
    if total == 0 do
      0.0
    else
      Enum.reduce(populations, 0.0, fn count, acc ->
        if count > 0 do
          p = count / total
          acc - (p * :math.log2(p))
        else
          acc
        end
      end)
    end
  end
  
  @doc """
  Detect speciation events by comparing registries over time.
  """
  @spec detect_speciation_events(map(), map()) :: [species_id()]
  def detect_speciation_events(old_registry, new_registry) do
    old_species_ids = Map.keys(old_registry) |> MapSet.new()
    new_species_ids = Map.keys(new_registry) |> MapSet.new()
    
    # New species that didn't exist before
    MapSet.difference(new_species_ids, old_species_ids)
    |> MapSet.to_list()
  end
  
  @doc """
  Detect extinction events.
  """
  @spec detect_extinction_events(map(), map()) :: [species_id()]
  def detect_extinction_events(old_registry, new_registry) do
    old_species_ids = Map.keys(old_registry) |> MapSet.new()
    new_species_ids = Map.keys(new_registry) |> MapSet.new()
    
    # Species that existed before but are now gone
    MapSet.difference(old_species_ids, new_species_ids)
    |> MapSet.to_list()
  end
end
