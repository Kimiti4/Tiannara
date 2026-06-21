defmodule TiannaraOS.DiscoveryAssetEconomy do
  @moduledoc """
  Connects validated discoveries to asset-backed research economics.
  
  This closes the civilizational loop:
  Discovery → Asset → Value → Royalties → Funding → More Research
  
  Instead of transient royalties, discoveries become persistent assets
  that generate ongoing revenue streams, enabling institutions to sustain
  long-term research programs.
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.DiscoveryAsset
  
  @doc """
  Convert a validated discovery into a discovery asset.
  
  Assets have:
  - Initial value based on discovery quality and domain importance
  - Depreciation/appreciation over time
  - Ongoing royalty generation
  - Tradeability between institutions
  """
  @spec create_discovery_asset(State.t(), atom(), atom()) :: {:ok, State.t(), DiscoveryAsset.t()} | {:error, any()}
  def create_discovery_asset(%State{} = state, discovery_id, program_id) do
    with {:ok, discovery} <- get_discovery(state, discovery_id),
         {:ok, program} <- get_program(state, program_id) do
      
      # Calculate initial asset value
      base_value = calculate_asset_value(discovery, program, state)
      
      # Create asset (using actual DiscoveryAsset struct fields)
      asset_id = :"asset_#{discovery_id}"
      
      # Extract domain vector from discovery if available
      domain_vector = Map.get(discovery, :domain_vector, %{})
      
      # Calculate primary domain (highest weight in domain_vector)
      primary_domain = if map_size(domain_vector) > 0 do
        domain_vector
        |> Enum.max_by(fn {_domain, weight} -> weight end, fn -> {:unknown, 0.0} end)
        |> elem(0)
      else
        :unknown
      end
      
      asset = %DiscoveryAsset{
        discovery_id: discovery_id,
        domain_vector: domain_vector,  # NEW: Vector-based domain identity
        primary_domain: primary_domain,  # NEW: Primary domain for competition tracking
        valuation: base_value,
        royalty_rate: calculate_royalty_rate(discovery, program),
        license_type: :permissive,
        maturity: :experimental,
        confidence: discovery.confidence || 0.8,
        utility: calculate_utility(discovery, program),
        created_at: :os.system_time(:millisecond),
        updated_at: :os.system_time(:millisecond),
        transaction_history: [%{
          type: :creation,
          value: base_value,
          timestamp: :os.system_time(:millisecond),
          owner_program: program_id
        }]
      }
      
      # Add to state
      new_assets = Map.put(state.discovery_assets, asset_id, asset)
      updated_state = %{state | discovery_assets: new_assets}
      
      {:ok, updated_state, asset}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Calculate ongoing royalties from all active discovery assets owned by a program.
  
  This replaces the simple `discoveries * royalty_rate` formula with
  genuine asset-backed revenue streams.
  """
  @spec calculate_asset_royalties(State.t(), atom()) :: %{funding: float(), compute: float(), attention: float()}
  def calculate_asset_royalties(%State{} = state, program_id) do
    # Find assets owned by this program (via transaction_history)
    program_assets = Enum.filter(state.discovery_assets, fn {_id, asset} ->
      owns_asset?(asset, program_id)
    end)
    
    if map_size(program_assets) == 0 do
      %{funding: 0.0, compute: 0.0, attention: 0.0}
    else
      # Sum royalties from all assets
      Enum.reduce(program_assets, %{funding: 0.0, compute: 0.0, attention: 0.0}, 
        fn {_id, asset}, acc ->
          royalty = asset.valuation * asset.royalty_rate
          
          %{
            funding: acc.funding + (royalty * 0.6),
            compute: acc.compute + (royalty * 0.3),
            attention: acc.attention + (royalty * 0.1)
          }
        end)
    end
  end
  
  @doc """
  Update asset values based on market dynamics and discovery impact.
  
  Assets can appreciate or depreciate based on:
  - Citation count (more citations → higher value)
  - Time since creation (older discoveries may depreciate)
  - Domain maturity (emerging domains appreciate faster)
  - Contradiction events (contradicted discoveries crash in value)
  """
  @spec update_asset_values(State.t()) :: State.t()
  def update_asset_values(%State{} = state) do
    updated_assets = Enum.map(state.discovery_assets, fn {asset_id, asset} ->
      new_value = revalue_asset(asset, state)
      updated_asset = %DiscoveryAsset{
        asset |
        valuation: new_value,
        updated_at: :os.system_time(:millisecond)
      }
      {asset_id, updated_asset}
    end)
    |> Enum.into(%{})
    
    %{state | discovery_assets: updated_assets}
  end
  
  @doc """
  Calculate initial asset value for a discovery.
  
  Value depends on:
  - Discovery confidence (higher confidence → higher value)
  - Strategy genome quality (better strategies produce more valuable discoveries)
  - Domain importance (some domains are more economically valuable)
  - Epistemic physics (uncertain domains have higher potential value)
  """
  @spec calculate_asset_value(map(), ResearchProgram.t(), State.t()) :: float()
  defp calculate_asset_value(discovery, program, state) do
    # Base value from confidence
    base_value = discovery.confidence * 100.0
    
    # Quality multiplier from strategy effectiveness
    quality_multiplier = 1.0 + (program.metrics.strategy_effectiveness * 0.5)
    
    # Domain importance multiplier
    domain = Map.get(discovery, :domain, :unknown)
    domain_multiplier = get_domain_importance(domain)
    
    # Epistemic physics adjustment (uncertain domains have higher potential)
    physics = Map.get(program.metadata, :epistemic_physics, nil)
    uncertainty_multiplier = if physics, do: 1.0 + physics.uncertainty, else: 1.0
    
    base_value * quality_multiplier * domain_multiplier * uncertainty_multiplier
  end
  
  @doc """
  Calculate royalty rate for an asset.
  
  Higher-quality discoveries generate higher royalty rates.
  """
  @spec calculate_royalty_rate(map(), ResearchProgram.t()) :: float()
  defp calculate_royalty_rate(discovery, _program) do
    # Base royalty rate scaled by confidence
    base_rate = 0.02
    base_rate * discovery.confidence
  end
  
  @doc """
  Revalue an asset based on current market conditions.
  """
  @spec revalue_asset(DiscoveryAsset.t(), State.t()) :: float()
  defp revalue_asset(%DiscoveryAsset{} = asset, %State{} = state) do
    age_ms = :os.system_time(:millisecond) - asset.created_at
    age_ticks = trunc(age_ms / 1000)  # Approximate ticks
    
    # Time-based depreciation (discoveries lose value over time)
    depreciation_rate = 0.0001  # 0.01% per tick
    time_factor = :math.exp(-depreciation_rate * age_ticks)
    
    # Check if discovery has been contradicted
    contradiction_penalty = check_contradiction_penalty(asset.discovery_id, state)
    
    # New value (use initial_value from first transaction if available)
    initial_value = get_initial_value(asset)
    new_value = initial_value * time_factor * contradiction_penalty
    
    # Minimum value floor
    max(new_value, initial_value * 0.1)
  end
  
  @doc """
  Check if a discovery has been contradicted.
  
  Returns penalty multiplier (1.0 = no penalty, 0.1 = severe penalty).
  """
  @spec check_contradiction_penalty(atom(), State.t()) :: float()
  defp check_contradiction_penalty(discovery_id, %State{} = state) do
    # Check evidence graph for contradictions
    # Simplified: look for negative relations
    case Map.get(state.evidence_graph, discovery_id) do
      nil -> 1.0  # No node found, assume no contradiction
      node ->
        # Check if node has negative support relations
        has_contradiction = Enum.any?(node.relations || [], fn rel ->
          rel.type == :contradicts or rel.weight < 0
        end)
        
        if has_contradiction, do: 0.1, else: 1.0
    end
  end
  
  @doc """
  Get domain importance multiplier.
  
  Some domains are inherently more economically valuable.
  """
  @spec get_domain_importance(atom()) :: float()
  defp get_domain_importance(domain) do
    case domain do
      :medicine -> 1.5       # High economic value
      :cybernetics -> 1.4    # High commercial potential
      :physics -> 1.2        # Foundational science
      :mathematics -> 1.1    # Abstract but foundational
      :ecology -> 1.0        # Moderate value
      :chemistry -> 1.3      # Industrial applications
      _ -> 1.0               # Unknown domain
    end
  end
  
  @doc """
  Get discovery from state.
  """
  @spec get_discovery(State.t(), atom()) :: {:ok, map()} | {:error, :not_found}
  defp get_discovery(%State{} = state, discovery_id) do
    case Map.get(state.discoveries, discovery_id) do
      nil -> {:error, :not_found}
      discovery -> {:ok, discovery}
    end
  end
  
  @doc """
  Get program from state.
  """
  @spec get_program(State.t(), atom()) :: {:ok, ResearchProgram.t()} | {:error, :not_found}
  defp get_program(%State{} = state, program_id) do
    case Map.get(state.research_programs, program_id) do
      nil -> {:error, :not_found}
      program -> {:ok, program}
    end
  end
  
  @doc """
  Calculate utility score for a discovery based on its properties and strategy.
  """
  @spec calculate_utility(map(), ResearchProgram.t()) :: float()
  defp calculate_utility(discovery, program) do
    # Base utility from confidence
    base_utility = (discovery.confidence || 0.8) * 1.0
    
    # Strategy quality bonus
    genome_quality = (
      program.strategy_genome.exploration_rate +
      program.strategy_genome.validation_priority +
      program.strategy_genome.cross_domain_synthesis
    ) / 3.0
    
    base_utility * (1.0 + genome_quality * 0.5)
  end
  
  @doc """
  Check if an asset is owned by a program (via transaction history).
  """
  @spec owns_asset?(DiscoveryAsset.t(), atom()) :: boolean()
  defp owns_asset?(%DiscoveryAsset{} = asset, program_id) do
    Enum.any?(asset.transaction_history, fn txn ->
      txn.type == :creation && txn.owner_program == program_id
    end)
  end
  
  @doc """
  Get initial value from asset's first transaction.
  """
  @spec get_initial_value(DiscoveryAsset.t()) :: float()
  defp get_initial_value(%DiscoveryAsset{} = asset) do
    case List.first(asset.transaction_history) do
      %{value: value} when is_number(value) -> value
      _ -> asset.valuation  # Fallback to current valuation
    end
  end
end
