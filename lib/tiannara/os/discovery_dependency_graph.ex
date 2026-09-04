defmodule TiannaraOS.DiscoveryDependencyGraph do
  @moduledoc """
  Tracks prerequisite relationships between discoveries.
  
  Discoveries unlock future discovery regions by providing capabilities.
  Example: Advanced Materials → enables High-Density Batteries → enables Electric Aviation
  
  This creates emergent technological trees without hardcoding domains.
  
  ## Key Concepts
  
  - **Prerequisites**: Some discoveries require certain capabilities to exist first
  - **Capability Registry**: Each world tracks what domains it has mastered
  - **Difficulty Scaling**: Missing prerequisites make discoveries harder
  - **Domain Inference**: Multi-domain discoveries unlock hybrid/synthesis domains
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  
  @type dependency :: %{
    required_discovery: atom(),
    required_domain_vector: map(),
    unlocks_domain: atom(),
    capability_boost: float()
  }
  
  # Threshold for domain mastery (weight in domain_vector)
  @mastery_threshold 0.7
  
  # Base difficulty multiplier per missing prerequisite
  @missing_prereq_penalty 0.5
  
  # Minimum breakthrough probability even with missing prereqs
  @breakthrough_probability 0.1
  
  @doc """
  Check if a discovery's prerequisites are satisfied.
  
  Returns: {:ok, unlocked_capabilities} or {:blocked, missing_prerequisites}
  
  ## Parameters
  
  - `state`: Current simulation state
  - `discovery`: Proposed discovery to check
  
  ## Examples
  
      iex> DiscoveryDependencyGraph.check_prerequisites(state, discovery)
      {:ok, [:advanced_materials, :energy_storage]}
      
      iex> DiscoveryDependencyGraph.check_prerequisites(state, discovery)
      {:blocked, [:quantum_computing, :nanotechnology]}
  """
  @spec check_prerequisites(State.t(), Discovery.t()) :: {:ok, [atom()]} | {:blocked, [atom()]}
  def check_prerequisites(%State{} = state, %Discovery{} = discovery) do
    # Get all existing discoveries in this world
    world_discoveries = get_world_discoveries(state, Map.get(discovery, :world_id))
    
    # Extract domain vectors from existing discoveries
    existing_capabilities = Enum.map(world_discoveries, & &1.domain_vector)
    
    # Check if discovery's required domains are covered
    required_domains = extract_required_domains(discovery)
    
    satisfied = Enum.filter(required_domains, fn required_domain ->
      domain_covered?(required_domain, existing_capabilities)
    end)
    
    missing = required_domains -- satisfied
    
    if Enum.empty?(missing) do
      # All prerequisites met - calculate unlocked capabilities
      unlocked = calculate_unlocked_capabilities(discovery, existing_capabilities)
      {:ok, unlocked}
    else
      {:blocked, missing}
    end
  end
  
  @doc """
  Register a new discovery and update dependency graph.
  
  Adds this discovery as potential prerequisite for future discoveries.
  
  ## Parameters
  
  - `state`: Current simulation state
  - `discovery`: New discovery to register
  
  ## Returns
  
  Updated state with capability registry updated.
  """
  @spec register_discovery(State.t(), Discovery.t()) :: State.t()
  def register_discovery(%State{} = state, %Discovery{} = discovery) do
    # Add to world's capability registry
    updated_worlds = update_world_capabilities(state.worlds, discovery)
    
    # Track which domains this discovery enables
    enabled_domains = infer_enabled_domains(discovery)
    
    # Update dependency registry
    updated_dependencies = add_to_dependency_registry(
      Map.get(state, :discovery_dependencies) || %{},
      discovery.id,
      enabled_domains
    )
    
    state
    |> Map.put(:worlds, updated_worlds)
    |> Map.put(:discovery_dependencies, updated_dependencies)
  end
  
  @doc """
  Calculate discovery difficulty based on prerequisite complexity.
  
  More prerequisites = harder discovery = lower probability.
  
  ## Parameters
  
  - `state`: Current simulation state
  - `discovery`: Proposed discovery
  
  ## Returns
  
  Difficulty multiplier (1.0 = base difficulty, >1.0 = harder)
  """
  @spec calculate_difficulty(State.t(), Discovery.t()) :: float()
  def calculate_difficulty(%State{} = state, %Discovery{} = discovery) do
    case check_prerequisites(state, discovery) do
      {:ok, _unlocked} ->
        # Prerequisites met - base difficulty
        base_difficulty(discovery)
      
      {:blocked, missing} ->
        # Missing prerequisites - much harder
        base_difficulty(discovery) * (1.0 + length(missing) * @missing_prereq_penalty)
    end
  end
  
  @doc """
  Infer what new domains this discovery enables.
  
  Uses domain vector analysis to predict capability expansion.
  
  ## Parameters
  
  - `discovery`: Discovery to analyze
  
  ## Returns
  
  List of newly enabled domain atoms
  """
  @spec infer_enabled_domains(Discovery.t()) :: [atom()]
  def infer_enabled_domains(%Discovery{} = discovery) do
    domain_vector = Map.get(discovery, :domain_vector) || %{}

    # High-weight domains become "enabled"
    enabled = domain_vector
      |> Enum.filter(fn {_domain, weight} -> weight >= @mastery_threshold end)
      |> Enum.map(fn {domain, _weight} -> domain end)
    
    # Add cross-domain synthesis opportunities
    if map_size(domain_vector) >= 2 do
      synthesis_domain = generate_synthesis_domain(domain_vector)
      [synthesis_domain | enabled]
    else
      enabled
    end
  end
  
  @doc """
  Check if a breakthrough attempt should succeed despite missing prerequisites.
  
  Occasionally programs make unexpected discoveries that bypass normal requirements.
  
  ## Parameters
  
  - `missing_count`: Number of missing prerequisites
  
  ## Returns
  
  Boolean indicating if breakthrough succeeds
  """
  @spec attempt_breakthrough(integer()) :: boolean()
  def attempt_breakthrough(missing_count) when missing_count > 0 do
    # Probability decreases with more missing prerequisites
    probability = @breakthrough_probability / missing_count
    :rand.uniform() < probability
  end
  
  # ============================================================================
  # Private Helper Functions
  # ============================================================================
  
  @spec get_world_discoveries(State.t(), atom()) :: [Discovery.t()]
  defp get_world_discoveries(%State{} = state, world_id) do
    discoveries = state.discoveries || %{}
    
    discoveries
      |> Map.values()
      |> Enum.filter(fn discovery ->
        discovery.world_id == world_id
      end)
  end
  
  @spec extract_required_domains(Discovery.t()) :: [atom()]
  defp extract_required_domains(%Discovery{} = discovery) do
    # For now, use domain_vector weights as requirement indicators
    # Domains with weight > 0.5 are considered "required"
    domain_vector = Map.get(discovery, :domain_vector) || %{}
    
    domain_vector
      |> Enum.filter(fn {_domain, weight} -> weight > 0.5 end)
      |> Enum.map(fn {domain, _weight} -> domain end)
  end
  
  @spec domain_covered?(atom(), [map()]) :: boolean()
  defp domain_covered?(domain, capabilities_list) do
    # Check if any existing capability covers this domain
    Enum.any?(capabilities_list, fn cap_vector ->
      Map.get(cap_vector, domain, 0.0) >= @mastery_threshold
    end)
  end
  
  @spec calculate_unlocked_capabilities(Discovery.t(), [map()]) :: [atom()]
  defp calculate_unlocked_capabilities(discovery, _existing_capabilities) do
    # For now, return the high-weight domains from this discovery
    domain_vector = Map.get(discovery, :domain_vector) || %{}

    domain_vector
      |> Enum.filter(fn {_domain, weight} -> weight >= @mastery_threshold end)
      |> Enum.map(fn {domain, _weight} -> domain end)
  end

  @spec update_world_capabilities(map(), Discovery.t()) :: map()
  defp update_world_capabilities(worlds, discovery) do
    world_id = discovery.world_id
    world = Map.get(worlds, world_id)
    
    if world == nil do
      worlds
    else
      # Add discovery's domain_vector to world's capability registry
      current_capabilities = world.capabilities || []
      updated_capabilities = [discovery.domain_vector | current_capabilities]
      
      updated_world = %{world | capabilities: updated_capabilities}
      Map.put(worlds, world_id, updated_world)
    end
  end
  
  @spec add_to_dependency_registry(map(), atom(), [atom()]) :: map()
  defp add_to_dependency_registry(dependencies, discovery_id, enabled_domains) do
    Map.put(dependencies, discovery_id, enabled_domains)
  end
  
  @spec base_difficulty(Discovery.t()) :: float()
  defp base_difficulty(_discovery) do
    # Base difficulty is 1.0 for all discoveries
    # Can be enhanced later to consider domain complexity
    1.0
  end
  
  @spec generate_synthesis_domain(map()) :: atom()
  defp generate_synthesis_domain(domain_vector) do
    # Combine top 2 domains into synthesis domain name
    sorted_domains = domain_vector
      |> Enum.sort_by(fn {_domain, weight} -> weight end, :desc)
      |> Enum.take(2)
      |> Enum.map(fn {domain, _weight} -> domain end)
    
    # Convert to string and combine
    domain_names = Enum.map(sorted_domains, &Atom.to_string/1)
    synthesis_name = Enum.join(domain_names, "_") <> "_synthesis"
    
    String.to_atom(synthesis_name)
  end
end
