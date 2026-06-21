defmodule Tiannara.Core.Ontology.Index do
  @moduledoc """
  Index for fast concept lookup across ontologies.

  Provides efficient search and retrieval of concepts from across all ontologies.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def search_concept(concept_id) do
    GenServer.call(__MODULE__, {:search_concept, concept_id})
  end

  def search_concepts_by_term(term) do
    GenServer.call(__MODULE__, {:search_concepts_by_term, term})
  end

  def get_ontology_by_concept(concept_id) do
    GenServer.call(__MODULE__, {:get_ontology_by_concept, concept_id})
  end

  def add_concept_index(concept_id, ontology_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:add_concept_index, concept_id, ontology_id, metadata})
  end

  def remove_concept_index(concept_id, ontology_id) do
    GenServer.call(__MODULE__, {:remove_concept_index, concept_id, ontology_id})
  end

  def get_index_stats() do
    GenServer.call(__MODULE__, :get_index_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for indexing
    :ets.new(:concept_index, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:ontology_concepts, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:search_terms, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    Logger.info("Ontology index initialized")
    
    {:ok, %{
      total_concepts: 0,
      total_ontologies: 0,
      search_count: 0
    }}
  end

  @impl true
  def handle_call({:search_concept, concept_id}, _from, state) do
    case :ets.lookup(:concept_index, concept_id) do
      [{^concept_id, entries}] ->
        # Return all ontologies containing this concept
        results = Enum.map(entries, fn {ontology_id, metadata} ->
          %{
            ontology_id: ontology_id,
            metadata: metadata,
            concept_id: concept_id
          }
        end)
        
        Logger.debug("Found concept #{concept_id} in #{length(results)} ontologies")
        
        {:reply, {:ok, results}, update_search_stats(state)}

      [] ->
        Logger.debug("Concept #{concept_id} not found in index")
        {:reply, {:error, :not_found}, update_search_stats(state)}
    end
  end

  @impl true
  def handle_call({:search_concepts_by_term, term}, _from, state) do
    # Search for concepts containing the term
    matches = :ets.match_object(:search_terms, {:"$1", term})
    
    results = Enum.map(matches, fn {concept_id, term_data} ->
      case :ets.lookup(:concept_index, concept_id) do
        [{^concept_id, entries}] ->
          Enum.map(entries, fn {ontology_id, metadata} ->
            %{
              concept_id: concept_id,
              term: term,
              ontology_id: ontology_id,
              metadata: metadata
            }
          end)
        [] -> []
      end
    end)
    |> List.flatten()

    Logger.debug("Search for term '#{term}' returned #{length(results)} concepts")
    
    {:reply, {:ok, results}, update_search_stats(state)}
  end

  @impl true
  def handle_call({:get_ontology_by_concept, concept_id}, _from, state) do
    case :ets.lookup(:concept_index, concept_id) do
      [{^concept_id, entries}] ->
        ontology_ids = Enum.map(entries, fn {ontology_id, _} -> ontology_id end)
        {:reply, {:ok, ontology_ids}, update_search_stats(state)}
      [] ->
        {:reply, {:error, :not_found}, update_search_stats(state)}
    end
  end

  @impl true
  def handle_call({:add_concept_index, concept_id, ontology_id, metadata}, _from, state) do
    # Add concept to index
    case :ets.lookup(:concept_index, concept_id) do
      [{^concept_id, existing_entries}] ->
        # Update existing entries
        updated_entries = [{ontology_id, metadata} | existing_entries]
        :ets.insert(:concept_index, {concept_id, updated_entries})
        
        # Add to ontology concepts bag
        :ets.insert(:ontology_concepts, {ontology_id, concept_id})
        
        Logger.debug("Updated index for concept #{concept_id} in ontology #{ontology_id}")
        {:reply, :ok, update_stats(state)}

      [] ->
        # New concept entry
        :ets.insert(:concept_index, {concept_id, [{ontology_id, metadata}]})
        :ets.insert(:ontology_concepts, {ontology_id, concept_id})
        
        Logger.debug("Added concept #{concept_id} to index")
        {:reply, :ok, update_stats(state)}
    end
  end

  @impl true
  def handle_call({:remove_concept_index, concept_id, ontology_id}, _from, state) do
    case :ets.lookup(:concept_index, concept_id) do
      [{^concept_id, entries}] ->
        # Remove this ontology's entry
        filtered_entries = Enum.reject(entries, fn {id, _} -> id == ontology_id end)
        
        case filtered_entries do
          [] ->
            # No more ontologies have this concept, remove from index
            :ets.delete(:concept_index, concept_id)
            :ets.match_delete(:ontology_concepts, {ontology_id, concept_id})
          remaining ->
            # Update with remaining entries
            :ets.insert(:concept_index, {concept_id, remaining})
        end
        
        Logger.debug("Removed concept #{concept_id} from ontology #{ontology_id} index")
        {:reply, :ok, state}

      [] ->
        Logger.debug("Concept #{concept_id} not found in index")
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:get_index_stats, _from, state) do
    stats = %{
      total_concepts: :ets.info(:concept_index, :size),
      total_ontologies: :ets.info(:ontology_concepts, :size),
      search_count: state.search_count
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp update_stats(%{total_concepts: current} = state) do
    total_concepts = :ets.info(:concept_index, :size)
    %{state | total_concepts: total_concepts}
  end

  defp update_search_stats(%{search_count: count} = state) do
    %{state | search_count: count + 1}
  end
end