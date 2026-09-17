defmodule TiannaraRuntime.Identity.SpeciesRegistry do
  @moduledoc """
  PHASE 4B.4: Species Registry
  
  Maintains a registry of coalition "species" - recurring behavioral patterns
  that persist across time through splits, merges, and reforms.
  
  Each species has:
  - Representative fingerprint (prototype)
  - Member coalitions (current instances)
  - Emergence frequency (how often it appears)
  - Survival performance (average lifespan, recovery rate)
  """
  
  use GenServer
  require Logger
  
  @similarity_threshold 0.85
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Register or update a coalition in the species registry.
  
  If similar species exists, add to it. Otherwise create new species.
  """
  def register_coalition(coalition_id, fingerprint, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register, coalition_id, fingerprint, metadata})
  end
  
  @doc """
  Get all registered species.
  """
  def get_all_species() do
    GenServer.call(__MODULE__, :all_species)
  end
  
  @doc """
  Get details for a specific species.
  """
  def get_species(species_id) do
    GenServer.call(__MODULE__, {:species, species_id})
  end
  
  @doc """
  Find which species a coalition belongs to.
  """
  def find_species_for_coalition(coalition_id) do
    GenServer.call(__MODULE__, {:find, coalition_id})
  end
  
  @doc """
  Get species taxonomy (hierarchical grouping).
  """
  def get_taxonomy() do
    GenServer.call(__MODULE__, :taxonomy)
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    state = %{
      species: %{},           # species_id -> species_data
      coalition_to_species: %{},  # coalition_id -> species_id
      next_species_id: 1
    }
    
    Logger.info("✅ SpeciesRegistry initialized")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:register, coalition_id, fingerprint, metadata}, _from, state) do
    # Try to find matching existing species
    matched_species_id = find_matching_species(fingerprint, state.species)
    
    if matched_species_id do
      # Add to existing species
      species = state.species[matched_species_id]
      updated_species = %{
        species |
        members: MapSet.put(species.members, coalition_id),
        member_count: MapSet.size(MapSet.put(species.members, coalition_id)),
        last_seen: DateTime.utc_now() |> DateTime.to_iso8601(),
        emergence_count: species.emergence_count + 1
      }
      
      new_state = %{
        state |
        species: Map.put(state.species, matched_species_id, updated_species),
        coalition_to_species: Map.put(state.coalition_to_species, coalition_id, matched_species_id)
      }
      
      Logger.debug("🧬 Coalition #{coalition_id} matched to species #{matched_species_id}")
      
      {:reply, {:ok, :matched, matched_species_id}, new_state}
    else
      # Create new species
      species_id = "species_#{state.next_species_id}"
      
      new_species = %{
        id: species_id,
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        prototype_fingerprint: fingerprint,
        members: MapSet.new([coalition_id]),
        member_count: 1,
        emergence_count: 1,
        last_seen: DateTime.utc_now() |> DateTime.to_iso8601(),
        metadata: metadata,
        performance: %{
          avg_lifespan: 0.0,
          avg_recovery_rate: 0.0,
          total_interventions: 0
        }
      }
      
      new_state = %{
        state |
        species: Map.put(state.species, species_id, new_species),
        coalition_to_species: Map.put(state.coalition_to_species, coalition_id, species_id),
        next_species_id: state.next_species_id + 1
      }
      
      Logger.info("🆕 Created new species: #{species_id}")
      
      {:reply, {:ok, :new, species_id}, new_state}
    end
  end
  
  @impl true
  def handle_call(:all_species, _from, state) do
    species_list = Map.values(state.species)
    {:reply, {:ok, species_list}, state}
  end
  
  @impl true
  def handle_call({:species, species_id}, _from, state) do
    case Map.get(state.species, species_id) do
      nil -> {:reply, {:error, :not_found}, state}
      species -> {:reply, {:ok, species}, state}
    end
  end
  
  @impl true
  def handle_call({:find, coalition_id}, _from, state) do
    case Map.get(state.coalition_to_species, coalition_id) do
      nil -> {:reply, {:ok, nil}, state}
      species_id -> {:reply, {:ok, species_id}, state}
    end
  end
  
  @impl true
  def handle_call(:taxonomy, _from, state) do
    # Group species by similarity clusters
    taxonomy = build_taxonomy(state.species)
    {:reply, {:ok, taxonomy}, state}
  end
  
  # Private Functions
  
  defp find_matching_species(fingerprint, species_map) do
    # Compare against all existing species prototypes
    Enum.find_value(species_map, fn {_id, species} ->
      similarity = TiannaraRuntime.Identity.Fingerprint.similarity(
        fingerprint,
        species.prototype_fingerprint
      )
      
      if similarity >= @similarity_threshold do
        species.id
      else
        nil
      end
    end)
  end
  
  defp build_taxonomy(species_map) do
    # Simple clustering by performance characteristics
    clusters = %{
      stable: [],      # High coherence, long lifespan
      volatile: [],    # Low coherence, short lifespan
      resilient: [],   # High recovery rate
      emerging: []     # Recently created, few members
    }
    
    Enum.each(species_map, fn {_id, species} ->
      cluster = classify_species(species)
      Map.update!(clusters, cluster, &[species | &1])
    end)
    
    clusters
  end
  
  defp classify_species(species) do
    perf = species.performance
    
    cond do
      perf.avg_lifespan > 300 and perf.avg_recovery_rate > 0.7 ->
        :stable
      
      perf.avg_lifespan < 60 ->
        :volatile
      
      perf.avg_recovery_rate > 0.8 ->
        :resilient
      
      species.emergence_count <= 2 ->
        :emerging
      
      true ->
        :stable  # Default
    end
  end
end
