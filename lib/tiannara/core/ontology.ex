defmodule Tiannara.Core.Ontology do
  @moduledoc """
  Ontological Memory Compression Engine (OMCE).

  Compresses ontology structures into stable semantic tensors, preventing memory explosion
  and ontology duplication while maintaining semantic reversibility.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_ontology(concepts, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:create_ontology, concepts, metadata})
  end

  def compress_ontology(ontology_id) do
    GenServer.call(__MODULE__, {:compress_ontology, ontology_id})
  end

  def merge_ontologies(ontology_ids) do
    GenServer.call(__MODULE__, {:merge_ontologies, ontology_ids})
  end

  def get_ontology(ontology_id) do
    GenServer.call(__MODULE__, {:get_ontology, ontology_id})
  end

  def get_compression_stats() do
    GenServer.call(__MODULE__, :get_compression_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for ontologies and compression cache
    :ets.new(:ontologies, [:set, :public, :named_table])
    :ets.new(:compression_cache, [:set, :public, :named_table])
    :ets.new(:semantic_vectors, [:set, :public, :named_table])
    :ets.new(:ontology_index, [:set, :public, :named_table])

    Logger.info("OMCE initialized with ontology storage tables")

    {:ok, %{
      ontologies: %{},
      compression_stats: %{
        total_ontologies: 0,
        total_compressed: 0,
        compression_ratio: 0.0,
        memory_saved: 0
      }
    }}
  end

  @impl true
  def handle_call({:create_ontology, concepts, metadata}, _from, state) do
    ontology_id = generate_ontology_id()
    timestamp = System.system_time(:millisecond)

    # Create initial ontology structure
    ontology = %{
      id: ontology_id,
      concepts: concepts,
      metadata: metadata,
      created_at: timestamp,
      last_modified: timestamp,
      compression_level: 0,
      semantic_vector: nil,
      vector_hash: nil
    }

    # Store in ETS
    :ets.insert(:ontologies, {ontology_id, ontology})

    # Build semantic vector
    semantic_vector = build_semantic_vector(concepts)
    :ets.insert(:semantic_vectors, {ontology_id, semantic_vector})

    # Build index for fast lookup
    build_ontology_index(ontology_id, concepts)

    Logger.info("Created ontology #{ontology_id} with #{length(concepts)} concepts")

    {:reply, {:ok, ontology_id}, update_state(state, ontology)}
  end

  @impl true
  def handle_call({:compress_ontology, ontology_id}, _from, state) do
    case :ets.lookup(:ontologies, ontology_id) do
      [{^ontology_id, ontology}] ->
        compressed = perform_compression(ontology)
        
        # Update ETS
        :ets.insert(:ontologies, {ontology_id, compressed})
        :ets.insert(:compression_cache, {ontology_id, compressed})

        Logger.info("Compressed ontology #{ontology_id}")

        {:reply, {:ok, compressed}, update_compression_stats(state, compressed)}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:merge_ontologies, ontology_ids}, _from, state) do
    case fetch_ontologies(ontology_ids) do
      {:ok, ontologies} ->
        merged = merge_ontology_structures(ontologies)
        merged_id = generate_ontology_id()

        # Store merged ontology
        :ets.insert(:ontologies, {merged_id, merged})
        :ets.insert(:semantic_vectors, {merged_id, build_semantic_vector(merged.concepts)})

        Logger.info("Merged #{length(ontology_ids)} ontologies into #{merged_id}")

        {:reply, {:ok, merged_id}, update_state(state, merged)}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_ontology, ontology_id}, _from, state) do
    case :ets.lookup(:ontologies, ontology_id) do
      [{^ontology_id, ontology}] ->
        {:reply, {:ok, ontology}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_compression_stats, _from, state) do
    {:reply, {:ok, state.compression_stats}, state}
  end

  # Helper functions
  defp generate_ontology_id() do
    "ont_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp build_semantic_vector(concepts) do
    # Create a semantic vector representation of concepts
    # This is a simplified version - in production, use proper embeddings
    concepts
    |> Enum.map(fn concept -> 
      case concept do
        %{id: id, weight: weight} -> {id, weight}
        %{id: id} -> {id, 1.0}
        id when is_binary(id) -> {id, 1.0}
        _ -> {"unknown", 1.0}
      end
    end)
    |> Enum.sort()
    |> Enum.map(fn {id, weight} -> hash_concept(id, weight) end)
  end

  defp hash_concept(id, weight) do
    # Simple hash function for concept representation
    input = "#{id}:#{weight}"
    :crypto.hash(:sha256, input) |> Base.encode64()
  end

  defp build_ontology_index(ontology_id, concepts) do
    # Create an index for fast concept lookup
    index = concepts
    |> Enum.map(fn concept -> 
      case concept do
        %{id: id} -> {id, ontology_id}
        id when is_binary(id) -> {id, ontology_id}
      end
    end)
    |> Map.new()

    :ets.insert(:ontology_index, {ontology_id, index})
  end

  defp perform_compression(ontology) do
    # Perform ontology compression by:
    # 1. Deduplicating concepts
    # 2. Compressing semantic vectors
    # 3. Building an efficient index structure
    
    original_concepts = ontology.concepts
    deduplicated = deduplicate_concepts(original_concepts)
    
    %{
      ontology |
      concepts: deduplicated,
      compression_level: ontology.compression_level + 1,
      semantic_vector: build_semantic_vector(deduplicated),
      vector_hash: hash_vector(deduplicated),
      last_modified: System.system_time(:millisecond),
      compression_stats: %{
        original_size: length(original_concepts),
        compressed_size: length(deduplicated),
        compression_ratio: length(deduplicated) / max(length(original_concepts), 1)
      }
    }
  end

  defp deduplicate_concepts(concepts) do
    # Remove duplicate concepts based on ID and merge their properties
    concepts
    |> Enum.group_by(fn concept ->
      case concept do
        %{id: id} -> id
        id when is_binary(id) -> id
      end
    end)
    |> Enum.map(fn {id, concept_list} ->
      # Merge properties from duplicate concepts
      merged = concept_list
      |> Enum.reduce(%{id: id}, fn concept, acc ->
        case concept do
          %{weight: weight} -> Map.put(acc, :weight, weight)
          %{metadata: metadata} -> Map.merge(acc, metadata || %{})
          _ -> acc
        end
      end)
      merged
    end)
  end

  defp hash_vector(concepts) do
    vector = build_semantic_vector(concepts)
    :crypto.hash(:sha256, :erlang.term_to_binary(vector)) |> Base.encode64()
  end

  defp fetch_ontologies(ontology_ids) do
    ontologies = ontology_ids
    |> Enum.map(fn id ->
      case :ets.lookup(:ontologies, id) do
        [{^id, ontology}] -> ontology
        [] -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)

    if length(ontologies) == length(ontology_ids) do
      {:ok, ontologies}
    else
      {:error, :some_ontologies_not_found}
    end
  end

  defp merge_ontology_structures(ontologies) do
    # Merge multiple ontology structures while preserving unique concepts
    all_concepts = ontologies |> Enum.flat_map(& &1.concepts)
    
    merged = %{
      id: generate_ontology_id(),
      concepts: deduplicate_concepts(all_concepts),
      metadata: %{
        merged_from: Enum.map(ontologies, & &1.id),
        created_at: System.system_time(:millisecond),
        last_modified: System.system_time(:millisecond)
      },
      compression_level: 0,
      semantic_vector: nil,
      vector_hash: nil
    }

    # Build semantic vector for merged ontology
    semantic_vector = build_semantic_vector(merged.concepts)
    :ets.insert(:semantic_vectors, {merged.id, semantic_vector})

    merged
  end

  defp update_state(state, ontology) do
    %{state | 
      ontologies: Map.put(state.ontologies, ontology.id, ontology),
      compression_stats: %{state.compression_stats | 
        total_ontologies: state.compression_stats.total_ontologies + 1
      }
    }
  end

  defp update_compression_stats(state, ontology) do
    stats = ontology.compression_stats || %{original_size: 0, compressed_size: 0}
    
    %{state | 
      compression_stats: %{state.compression_stats |
        total_compressed: state.compression_stats.total_compressed + 1,
        compression_ratio: (state.compression_stats.compression_ratio + 
                          (stats.compressed_size / max(stats.original_size, 1))) / 2,
        memory_saved: state.compression_stats.memory_saved + 
                      (stats.original_size - stats.compressed_size)
      }
    }
  end
end