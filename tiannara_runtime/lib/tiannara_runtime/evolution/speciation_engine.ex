defmodule Tiannara.Evolution.SpeciationEngine do
  @moduledoc """
  Detects emergent species by clustering worlds based on genome similarity.
  
  Species are not arbitrary clusters of worlds - they are recurring
  genome attractors across time, formed when:
    similarity(genome_A, genome_B) > 0.92
    AND shared subsystem dominance pattern exists
  
  This module provides CPU-based speciation analysis. For production-scale
  (10,000+ worlds), integrate with Python UMAP/HDBSCAN pipeline via NATS.
  
  ## Clustering Algorithm
  1. Extract feature vectors from all world genomes
  2. Compute pairwise cosine similarity
  3. Apply hierarchical agglomerative clustering
  4. Identify species boundaries at similarity threshold (0.92)
  5. Detect chimeric hybrid zones (outliers between clusters)
  
  ## Species Classification
  Worlds are classified into:
    - Stable species (population >= 3, high internal similarity)
    - Emerging species (population = 2, forming)
    - Lone wanderers (population = 1, no species match)
    - Chimeric hybrids (outliers with mixed ancestry)
  """

  use GenServer
  require Logger

  alias Tiannara.Genetics.WorldGenome

  @species_similarity_threshold 0.92
  @min_stable_species_population 3
  @feature_vector_length 11  # Length of genome feature vector

  defstruct [
    species_clusters: %{},
    world_species_map: %{},
    genome_map: %{},
    chimeric_hybrids: [],
    last_analysis_time: nil
  ]

  @type t :: %__MODULE__{
    species_clusters: %{String.t() => [String.t()]},
    world_species_map: %{String.t() => String.t()},
    chimeric_hybrids: [hybrid_record()],
    last_analysis_time: DateTime.t() | nil
  }

  @type hybrid_record :: %{
    world_id: String.t(),
    coordinates: [float()],
    hybrid_signature: boolean()
  }

  # Public API

  @doc """
  Starts the SpeciationEngine GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Analyzes all active worlds and classifies them into species.
  
  ## Parameters
    - genomes: List of WorldGenome structs to analyze
  
  ## Returns
    - {:ok, %{species: [...], hybrids: [...]}}
  """
  def analyze_worlds(genomes) do
    GenServer.call(__MODULE__, {:analyze, genomes})
  end

  @doc """
  Returns the species assignment for a specific world.
  """
  def get_world_species(world_id) do
    GenServer.call(__MODULE__, {:get_species, world_id})
  end

  @doc """
  Returns all worlds belonging to a specific species.
  """
  def get_species_members(species_id) do
    GenServer.call(__MODULE__, {:get_members, species_id})
  end

  @doc """
  Lists all identified species with their statistics.
  """
  def list_species do
    GenServer.call(__MODULE__, :list_species)
  end

  @doc """
  Returns all chimeric hybrid worlds (outliers between species).
  """
  def get_chimeric_hybrids do
    GenServer.call(__MODULE__, :get_hybrids)
  end

  @doc """
  Computes similarity matrix between all world genomes.
  
  ## Returns
    - {:ok, %{world_a => %{world_b => similarity}}}
  """
  def compute_similarity_matrix(genomes) do
    GenServer.call(__MODULE__, {:similarity_matrix, genomes})
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    Logger.info(" Speciation Engine initialized (threshold: #{@species_similarity_threshold})")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:analyze, genomes}, _from, state) do
    if length(genomes) < 2 do
      {:reply, {:ok, %{species: [], hybrids: []}}, state}
    else
      {updated_state, result} = execute_speciation_analysis(genomes, state)
      {:reply, {:ok, result}, updated_state}
    end
  end

  @impl true
  def handle_call({:get_species, world_id}, _from, state) do
    species_id = Map.get(state.world_species_map, world_id)
    {:reply, {:ok, species_id}, state}
  end

  @impl true
  def handle_call({:get_members, species_id}, _from, state) do
    members = Map.get(state.species_clusters, species_id, [])
    {:reply, {:ok, members}, state}
  end

  @impl true
  def handle_call(:list_species, _from, state) do
    species_list = Enum.map(state.species_clusters, fn {species_id, members} ->
      stability = compute_species_stability(members, state)
      %{
        species_id: species_id,
        population: length(members),
        stability_index: stability,
        classification: classify_species(length(members), stability)
      }
    end)

    {:reply, {:ok, species_list}, state}
  end

  @impl true
  def handle_call(:get_hybrids, _from, state) do
    {:reply, {:ok, state.chimeric_hybrids}, state}
  end

  @impl true
  def handle_call({:similarity_matrix, genomes}, _from, state) do
    matrix = build_similarity_matrix(genomes)
    {:reply, {:ok, matrix}, state}
  end

  # Speciation Analysis Core

  defp execute_speciation_analysis(genomes, state) do
    Logger.info(" Running speciation analysis on #{length(genomes)} worlds")

    # Step 1: Compute all pairwise similarities
    similarity_matrix = build_similarity_matrix(genomes)

    # Step 2: Cluster worlds into species using threshold-based grouping
    clusters = cluster_worlds_by_similarity(genomes, similarity_matrix)

    # Step 3: Identify chimeric hybrids (worlds between clusters)
    hybrids = identify_chimeric_hybrids(genomes, clusters, similarity_matrix)

    # Step 4: Build updated state
    updated_clusters = Enum.into(clusters, %{}, fn {species_id, members} ->
      {species_id, Enum.map(members, & &1.world_id)}
    end)

    updated_world_map = Enum.into(clusters, %{}, fn {species_id, members} ->
      Enum.map(members, fn genome -> {genome.world_id, species_id} end)
    end)
    |> Enum.reduce(%{}, fn kv, acc -> Map.put(acc, elem(kv, 0), elem(kv, 1)) end)

    genome_map = Enum.into(genomes, %{}, fn g -> {g.world_id, g} end)

    updated_state = %{
      state
      | species_clusters: updated_clusters,
        world_species_map: updated_world_map,
        genome_map: genome_map,
        chimeric_hybrids: hybrids,
        last_analysis_time: DateTime.utc_now()
    }

    result = %{
      species: Enum.map(updated_clusters, fn {species_id, members} ->
        %{
          species_id: species_id,
          population: length(members),
          members: members
        }
      end),
      hybrids: hybrids,
      total_species: map_size(updated_clusters),
      total_hybrids: length(hybrids)
    }

    Logger.info(" Speciation complete: #{result.total_species} species, #{result.total_hybrids} hybrids")

    {updated_state, result}
  end

  defp build_similarity_matrix(genomes) do
    genomes
    |> Enum.reduce(%{}, fn genome_a, acc ->
      inner = Enum.reduce(genomes, %{}, fn genome_b, inner_acc ->
        similarity = WorldGenome.similarity(genome_a, genome_b)
        Map.put(inner_acc, genome_b.world_id, similarity)
      end)
      Map.put(acc, genome_a.world_id, inner)
    end)
  end

  defp cluster_worlds_by_similarity(genomes, similarity_matrix) do
    # Simple threshold-based clustering
    # Production should use HDBSCAN or DBSCAN for density-based clustering

    assigned = %{}
    species_counter = 1

    Enum.reduce(genomes, {assigned, species_counter}, fn genome, {acc_assigned, acc_counter} ->
      world_id = genome.world_id

      case Map.fetch(acc_assigned, world_id) do
        {:ok, _} ->
          # Already assigned to a species
          {acc_assigned, acc_counter}

        :error ->
          # Find similar unassigned worlds
          similar_worlds = find_similar_worlds(world_id, similarity_matrix, genomes, acc_assigned)

          if length(similar_worlds) > 0 do
            # Create new species
            species_id = "SPECIES-#{acc_counter}"
            members = [genome | similar_worlds]
            
            new_assigned = Enum.reduce(members, acc_assigned, fn member, inner_acc ->
              Map.put(inner_acc, member.world_id, species_id)
            end)

            {new_assigned, acc_counter + 1}
          else
            # Lone wanderer - assign to unique species
            species_id = "SPECIES-#{world_id}"
            {Map.put(acc_assigned, world_id, species_id), acc_counter}
          end
      end
    end)
    |> then(fn {assigned_worlds, _counter} ->
      # Group by species_id
      Enum.group_by(assigned_worlds, fn {world_id, species_id} -> species_id end, fn {world_id, _} ->
        Enum.find(genomes, & &1.world_id == world_id)
      end)
    end)
  end

  defp find_similar_worlds(world_id, similarity_matrix, genomes, assigned) do
    case Map.fetch(similarity_matrix, world_id) do
      {:ok, similarities} ->
        Enum.filter(genomes, fn genome ->
          other_id = genome.world_id
          other_id != world_id and
            not Map.has_key?(assigned, other_id) and
            Map.get(similarities, other_id, 0.0) >= @species_similarity_threshold
        end)

      :error ->
        []
    end
  end

  defp identify_chimeric_hybrids(genomes, clusters, similarity_matrix) do
    # Chimeric hybrids are worlds that:
    # 1. Are not clearly assigned to a single species, OR
    # 2. Have high similarity to multiple species

    assigned_worlds = clusters
    |> Enum.flat_map(fn {_species_id, members} -> members end)
    |> Enum.map(& &1.world_id)
    |> MapSet.new()

    all_world_ids = Enum.map(genomes, & &1.world_id)
    unassigned_ids = MapSet.difference(MapSet.new(all_world_ids), assigned_worlds)

    Enum.map(MapSet.to_list(unassigned_ids), fn world_id ->
      genome = Enum.find(genomes, & &1.world_id == world_id)
      vector = WorldGenome.to_feature_vector(genome)

      %{
        world_id: world_id,
        coordinates: vector,
        hybrid_signature: true
      }
    end)
  end

  defp compute_species_stability(member_ids, state) do
    if length(member_ids) == 0 do
      0.0
    else
      similarities = for id_a <- member_ids, id_b <- member_ids, id_a < id_b do
        case {Map.get(state.genome_map, id_a), Map.get(state.genome_map, id_b)} do
          {nil, _} -> 0.5
          {_, nil} -> 0.5
          {ga, gb} -> WorldGenome.similarity(ga, gb)
        end
      end

      if length(similarities) == 0 do
        1.0
      else
        Enum.sum(similarities) / length(similarities)
      end
    end
  end

  defp classify_species(population, stability) do
    cond do
      population >= @min_stable_species_population and stability > 0.7 ->
        :stable

      population >= 2 and population < @min_stable_species_population ->
        :emerging

      population == 1 ->
        :lone_wanderer

      true ->
        :unknown
    end
  end
end
