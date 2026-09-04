defmodule TiannaraOS.SpeciationDetector do
  @moduledoc """
  Sprint 2: Enhanced Speciation Detection and Tracking
  
  Detects emergent institutional species via strategy clustering and tracks:
  - Species lifecycle (birth, growth, extinction)
  - Lineage depth measurement
  - Speciation event detection
  - Species diversity metrics
  
  Uses k-means-like clustering to identify distinct strategy groups in 5D trait space.
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  
  # Distance threshold for new species formation
  @speciation_distance_threshold 0.3
  

  
  # Ticks without new members before species considered extinct
  @extinction_timeout_ticks 5000
  
  @doc """
  Classify all active programs into species and update species registry.
  
  Returns updated state with species classifications.
  
  ## Process
  
  1. Get all active programs
  2. For each program, find closest existing species or create new one
  3. Update species membership counts
  4. Detect extinction events
  5. Calculate diversity metrics
  """
  @spec classify_and_register_species(State.t()) :: State.t()
  def classify_and_register_species(%State{} = state) do
    programs = state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.status == :active)
    
    if Enum.empty?(programs) do
      state
    else
      current_tick = state.economy[:tick] || 0
      
      # Get current species registry
      current_species = state.species_registry || %{}
      
      # Classify each program and update registry
      {updated_programs, updated_species} = Enum.reduce(programs, {state.research_programs, current_species}, fn program, {progs_acc, species_acc} ->
        {species_id, updated_species} = classify_program(program, species_acc, current_tick)
        
        # Update program with species classification
        updated_metadata = Map.put(program.metadata || %{}, :species_id, species_id)
        updated_prog = %{program | metadata: updated_metadata}
        progs_acc = Map.put(progs_acc, program.id, updated_prog)
        
        {progs_acc, updated_species}
      end)
      
      # Detect extinction events
      final_species = detect_extinctions(updated_species, current_tick)
      
      # Calculate diversity metrics
      diversity_metrics = calculate_diversity_metrics(final_species)
      
      %{state | 
        research_programs: updated_programs,
        species_registry: final_species,
        economy: Map.put(state.economy, :diversity_metrics, diversity_metrics)
      }
    end
  end
  
  @spec classify_program(ResearchProgram.t(), map(), integer()) :: {atom(), map()}
  defp classify_program(%ResearchProgram{} = program, species_registry, current_tick) do
    genome = program.strategy_genome
    
    # Find closest existing species
    {closest_species_id, min_distance} = find_closest_species(genome, species_registry)
    
    if closest_species_id != nil and min_distance <= @speciation_distance_threshold do
      # Belongs to existing species - update membership
      updated_species = add_to_existing_species(species_registry, closest_species_id, program.id, current_tick)
      {closest_species_id, updated_species}
    else
      # Create new species
      new_species_id = generate_species_id()
      new_species = create_new_species(new_species_id, program, current_tick)
      
      updated_registry = Map.put(species_registry, new_species_id, new_species)
      
      IO.puts("  🧬 New species detected: #{new_species_id} (founded by #{program.id})")
      
      {new_species_id, updated_registry}
    end
  end
  
  @spec add_to_existing_species(map(), atom(), atom(), integer()) :: map()
  defp add_to_existing_species(species_registry, species_id, program_id, current_tick) do
    case Map.get(species_registry, species_id) do
      nil ->
        # Species doesn't exist, shouldn't happen but handle gracefully
        species_registry
      
      species ->
        updated_species = %{species |
          member_count: species.member_count + 1,
          total_births: species.total_births + 1,
          current_members: [program_id | species.current_members],
          last_new_member_tick: current_tick,
          extinct: false
        }
        
        Map.put(species_registry, species_id, updated_species)
    end
  end
  
  @spec create_new_species(atom(), ResearchProgram.t(), integer()) :: map()
  defp create_new_species(species_id, %ResearchProgram{} = founding_program, current_tick) do
    %{
      id: species_id,
      founding_program: founding_program.id,
      founded_at_tick: current_tick,
      member_count: 1,
      total_births: 1,
      total_deaths: 0,
      current_members: [founding_program.id],
      extinct: false,
      extinct_at_tick: nil,
      lifespan_ticks: 0,
      centroid_genome: founding_program.strategy_genome,
      primary_domain: infer_primary_domain(founding_program.strategy_genome),
      last_new_member_tick: current_tick,
      max_generation: founding_program.generation || 1,
      avg_portfolio_value: 0.0
    }
  end
  
  @spec detect_extinctions(map(), integer()) :: map()
  defp detect_extinctions(species_registry, current_tick) do
    Enum.map(species_registry, fn {species_id, species} ->
      should_be_extinct = species.member_count == 0 or
                         (current_tick - species.last_new_member_tick) > @extinction_timeout_ticks
      
      if should_be_extinct and not species.extinct do
        # Mark as extinct
        extinct_species = %{species |
          extinct: true,
          extinct_at_tick: current_tick,
          lifespan_ticks: current_tick - species.founded_at_tick
        }
        
        IO.puts("  💀 Species extinct: #{species_id} (lifespan: #{extinct_species.lifespan_ticks} ticks)")
        
        {species_id, extinct_species}
      else
        {species_id, species}
      end
    end)
    |> Enum.into(%{})
  end
  
  @spec calculate_diversity_metrics(map()) :: map()
  defp calculate_diversity_metrics(species_registry) do
    total_species = map_size(species_registry)
    
    active_species = Enum.count(species_registry, fn {_id, species} ->
      not species.extinct
    end)
    
    extinct_species = total_species - active_species
    
    # Shannon diversity index: H = -Σ(p_i * ln(p_i))
    shannon_index = calculate_shannon_index(species_registry)
    
    # Max lineage depth across all species
    max_lineage_depth = species_registry
      |> Map.values()
      |> Enum.map(& &1.max_generation)
      |> Enum.max(fn -> 1 end)
    
    # Average species lifespan
    avg_lifespan = species_registry
      |> Map.values()
      |> Enum.filter(& &1.extinct)
      |> Enum.map(& &1.lifespan_ticks)
      |> case do
        [] -> 0
        lifespans -> Enum.sum(lifespans) / length(lifespans)
      end
    
    %{
      total_species: total_species,
      active_species: active_species,
      extinct_species: extinct_species,
      shannon_diversity: Float.round(shannon_index, 3),
      max_lineage_depth: max_lineage_depth,
      avg_species_lifespan: Float.round(avg_lifespan, 0)
    }
  end
  
  @spec calculate_shannon_index(map()) :: float()
  defp calculate_shannon_index(species_registry) do
    total_members = species_registry
      |> Map.values()
      |> Enum.reduce(0, fn species, acc -> acc + species.member_count end)
    
    if total_members == 0 do
      0.0
    else
      species_registry
        |> Map.values()
        |> Enum.reduce(0.0, fn species, acc ->
          p_i = species.member_count / total_members
          if p_i > 0 do
            acc - (p_i * :math.log(p_i))
          else
            acc
          end
        end)
    end
  end
  
  @spec find_closest_species(map(), map()) :: {atom() | nil, float()}
  defp find_closest_species(genome, species_registry) do
    if map_size(species_registry) == 0 do
      {nil, 999.0}
    else
      distances = Enum.map(species_registry, fn {species_id, species} ->
        distance = calculate_genome_distance(genome, species.centroid_genome)
        {species_id, distance}
      end)
      
      Enum.min_by(distances, fn {_id, dist} -> dist end)
    end
  end
  
  @spec calculate_genome_distance(map(), map()) :: float()
  defp calculate_genome_distance(genome1, genome2) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis, 
              :anomaly_sensitivity, :risk_tolerance]
    
    squared_distances = Enum.map(traits, fn trait ->
      val1 = Map.get(genome1, trait, 0.5)
      val2 = Map.get(genome2, trait, 0.5)
      :math.pow(val1 - val2, 2)
    end)
    
    :math.sqrt(Enum.sum(squared_distances))
  end
  
  @spec infer_primary_domain(map()) :: atom()
  defp infer_primary_domain(genome) do
    cond do
      genome.exploration_rate > 0.7 -> :explorer
      genome.validation_priority > 0.8 -> :validator
      genome.cross_domain_synthesis > 0.7 -> :synthesizer
      genome.anomaly_sensitivity > 0.7 -> :anomaly_hunter
      genome.risk_tolerance < 0.3 -> :conservative
      genome.risk_tolerance > 0.7 -> :aggressive
      true -> :generalist
    end
  end
  
  @spec generate_species_id() :: atom()
  defp generate_species_id do
    :"species_#{:rand.uniform(99999)}"
  end
  
  @doc """
  Summarize speciation state for reporting.
  
  Returns human-readable summary of species diversity and dynamics.
  """
  @spec summarize_speciation(map()) :: String.t()
  def summarize_speciation(species_registry) do
    diversity = calculate_diversity_metrics(species_registry)
    
    lines = [
      "=== Speciation Summary ===",
      "Total species: #{diversity.total_species}",
      "Active species: #{diversity.active_species}",
      "Extinct species: #{diversity.extinct_species}",
      "Shannon diversity: #{Float.round(diversity.shannon_diversity, 3)}",
      "Max lineage depth: #{diversity.max_lineage_depth}",
      "Avg species lifespan: #{Float.round(diversity.avg_species_lifespan, 0)} ticks",
      "",
      "Species Details:",
      format_species_details(species_registry)
    ]
    
    Enum.join(lines, "\n")
  end
  
  @doc false
  @spec format_species_details(map()) :: String.t()
  defp format_species_details(species_registry) do
    if map_size(species_registry) == 0 do
      "  (no species yet)"
    else
      species_registry
        |> Map.values()
        |> Enum.sort_by(& &1.member_count, :desc)
        |> Enum.take(10)  # Top 10 species
        |> Enum.map_join("\n", fn species ->
          status = if species.extinct, do: "💀 EXTINCT", else: "✅ ACTIVE"
          "  - #{species.id}: #{species.member_count} members, #{species.primary_domain}, gen=#{species.max_generation} [#{status}]"
        end)
    end
  end
end
