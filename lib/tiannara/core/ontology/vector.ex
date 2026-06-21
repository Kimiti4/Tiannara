defmodule Tiannara.Core.Ontology.Vector do
  @moduledoc """
  Semantic vector management for ontologies.

  Handles the creation, storage, and comparison of semantic vectors.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_vector(concepts, opts \\ []) do
    GenServer.call(__MODULE__, {:create_vector, concepts, opts})
  end

  def get_vector(ontology_id) do
    GenServer.call(__MODULE__, {:get_vector, ontology_id})
  end

  def compare_vectors(ontology_id1, ontology_id2) do
    GenServer.call(__MODULE__, {:compare_vectors, ontology_id1, ontology_id2})
  end

  def find_similar(ontology_id, threshold \\ 0.7) do
    GenServer.call(__MODULE__, {:find_similar, ontology_id, threshold})
  end

  def vector_similarity(vector1, vector2) do
    GenServer.call(__MODULE__, {:vector_similarity, vector1, vector2})
  end

  def get_vector_stats() do
    GenServer.call(__MODULE__, :get_vector_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for vector storage
    :ets.new(:semantic_vectors, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:vector_similarities, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:vector_metadata, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    Logger.info("Semantic vector manager initialized")
    
    {:ok, %{
      vector_count: 0,
      comparison_count: 0,
      cache_hits: 0
    }}
  end

  @impl true
  def handle_call({:create_vector, concepts, opts}, _from, state) do
    ontology_id = Keyword.get(opts, :ontology_id, generate_vector_id())
    
    # Create semantic vector from concepts
    vector = build_semantic_vector(concepts)
    
    # Store vector
    :ets.insert(:semantic_vectors, {ontology_id, vector})
    
    # Store metadata
    metadata = %{
      created_at: System.system_time(:millisecond),
      concept_count: length(concepts),
      vector_hash: hash_vector(vector),
      dimension: vector_dimension(vector)
    }
    
    :ets.insert(:vector_metadata, {ontology_id, metadata})
    
    Logger.info("Created semantic vector for ontology #{ontology_id}")
    
    {:reply, {:ok, vector}, update_vector_stats(state)}
  end

  @impl true
  def handle_call({:get_vector, ontology_id}, _from, state) do
    case :ets.lookup(:semantic_vectors, ontology_id) do
      [{^ontology_id, vector}] ->
        {:reply, {:ok, vector}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:compare_vectors, ontology_id1, ontology_id2}, _from, state) do
    with {:ok, vector1} <- get_vector_safe(ontology_id1),
         {:ok, vector2} <- get_vector_safe(ontology_id2) do
      
      # Check cached similarity first
      case :ets.lookup(:vector_similarities, {ontology_id1, ontology_id2}) do
        [{key, similarity}] ->
          Logger.debug("Cache hit for vector similarity comparison")
          {:reply, {:ok, similarity}, %{state | cache_hits: state.cache_hits + 1}}
        [] ->
          # Calculate similarity
          similarity = calculate_similarity(vector1, vector2)
          
          # Cache the result
          :ets.insert(:vector_similarities, {{ontology_id1, ontology_id2}, similarity})
          :ets.insert(:vector_similarities, {{ontology_id2, ontology_id1}, similarity})
          
          Logger.debug("Calculated vector similarity: #{similarity}")
          {:reply, {:ok, similarity}, update_comparison_stats(state)}
      end
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:find_similar, ontology_id, threshold}, _from, state) do
    case get_vector_safe(ontology_id) do
      {:ok, target_vector} ->
        # Find all vectors similar to the target
        all_vectors = :ets.tab2list(:semantic_vectors)
        
        similar = Enum.reduce(all_vectors, [], fn {other_id, other_vector}, acc ->
          case other_id do
            ^ontology_id -> acc
            _ ->
              case :ets.lookup(:vector_similarities, {ontology_id, other_id}) do
                [{_, similarity}] when similarity >= threshold ->
                  [{other_id, similarity} | acc]
                [] ->
                  similarity = calculate_similarity(target_vector, other_vector)
                  if similarity >= threshold do
                    :ets.insert(:vector_similarities, {{ontology_id, other_id}, similarity})
                    :ets.insert(:vector_similarities, {{other_id, ontology_id}, similarity})
                    [{other_id, similarity} | acc]
                  else
                    acc
                  end
              end
          end
        end)
        
        # Sort by similarity (descending)
        sorted = Enum.sort_by(similar, &elem(&1, 1), :desc)
        
        {:reply, {:ok, sorted}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:vector_similarity, vector1, vector2}, _from, state) do
    similarity = calculate_similarity(vector1, vector2)
    {:reply, {:ok, similarity}, update_comparison_stats(state)}
  end

  @impl true
  def handle_call(:get_vector_stats, _from, state) do
    stats = %{
      vector_count: :ets.info(:semantic_vectors, :size),
      similarity_cache_size: :ets.info(:vector_similarities, :size),
      comparison_count: state.comparison_count,
      cache_hits: state.cache_hits
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp generate_vector_id() do
    "vec_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp build_semantic_vector(concepts) do
    # Create a semantic vector representation
    # This is a simplified version - in production, use proper embeddings
    
    concepts
    |> Enum.map(fn concept -> 
      case concept do
        %{id: id, weight: weight} -> hash_concept(id, weight)
        %{id: id} -> hash_concept(id, 1.0)
        id when is_binary(id) -> hash_concept(id, 1.0)
      end
    end)
    |> Enum.sort()
  end

  defp hash_concept(id, weight) do
    input = "#{id}:#{weight}"
    :crypto.hash(:sha256, input) |> Base.encode64()
  end

  defp vector_dimension(vector) when is_list(vector) do
    length(vector)
  end

  defp vector_dimension(_), do: 0

  defp hash_vector(vector) do
    :crypto.hash(:sha256, :erlang.term_to_binary(vector)) |> Base.encode64()
  end

  defp get_vector_safe(ontology_id) do
    case :ets.lookup(:semantic_vectors, ontology_id) do
      [{^ontology_id, vector}] -> {:ok, vector}
      [] -> {:error, :not_found}
    end
  end

  defp calculate_similarity(vector1, vector2) when is_list(vector1) and is_list(vector2) do
    # Calculate cosine similarity between two vectors
    # This is a simplified version
    
    len1 = length(vector1)
    len2 = length(vector2)
    
    # If vectors have different lengths, pad the shorter one
    max_len = max(len1, len2)
    padded1 = vector1 ++ List.duplicate(0.0, max_len - len1)
    padded2 = vector2 ++ List.duplicate(0.0, max_len - len2)
    
    # Calculate dot product
    dot_product = Enum.zip(padded1, padded2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    
    # Calculate magnitudes
    mag1 = Enum.map(padded1, &(&1 * &1)) |> Enum.sum() |> :math.sqrt()
    mag2 = Enum.map(padded2, &(&1 * &1)) |> Enum.sum() |> :math.sqrt()
    
    # Avoid division by zero
    case {mag1, mag2} do
      {0.0, 0.0} -> 1.0  # Identical zero vectors
      {0.0, _} -> 0.0  # One vector is zero
      {_, 0.0} -> 0.0  # One vector is zero
      _ -> dot_product / (mag1 * mag2)
    end
  end

  defp calculate_similarity(_, _), do: 0.0

  defp update_vector_stats(%{vector_count: count} = state) do
    vector_count = :ets.info(:semantic_vectors, :size)
    %{state | vector_count: vector_count}
  end

  defp update_comparison_stats(%{comparison_count: count} = state) do
    %{state | comparison_count: count + 1}
  end
end