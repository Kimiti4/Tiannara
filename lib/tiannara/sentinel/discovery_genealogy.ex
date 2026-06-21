defmodule Tiannara.Sentinel.DiscoveryGenealogy do
  @moduledoc """
  SEA-3: The immortal ancestry graph of all discoveries.
  Never forgets a discovery, even if all civilizations that knew it die.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records a discovery in the immortal graph."
  def record_discovery(discovery) do
    GenServer.cast(__MODULE__, {:record, discovery})
  end

  @doc "Retrieves the full ancestry path for a given discovery."
  def get_ancestry(discovery_id) do
    GenServer.call(__MODULE__, {:get_ancestry, discovery_id})
  end
  
  @doc "Checks if a discovery is a rediscovery of an ancient concept."
  def is_rediscovery?(discovery) do
    GenServer.call(__MODULE__, {:is_rediscovery, discovery})
  end

  @doc "Increments the prestige of all historical records matching this discovery's name."
  def increment_prestige(discovery_name) do
    GenServer.cast(__MODULE__, {:increment_prestige, discovery_name})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Sentinel Discovery Genealogy")
    # Store by ID and by name (to detect independent rediscoveries)
    {:ok, %{by_id: %{}, by_name: %{}}}
  end

  @impl true
  def handle_cast({:record, discovery}, state) do
    new_by_id = Map.put(state.by_id, discovery.id, discovery)
    
    # Store a list of IDs under the same name to track independent discoveries
    existing_for_name = Map.get(state.by_name, discovery.name, [])
    new_by_name = Map.put(state.by_name, discovery.name, [discovery.id | existing_for_name])
    
    {:noreply, %{state | by_id: new_by_id, by_name: new_by_name}}
  end

  @impl true
  def handle_call({:get_ancestry, discovery_id}, _from, state) do
    path = trace_ancestry(discovery_id, state.by_id, [])
    {:reply, path, state}
  end
  
  @impl true
  def handle_call({:is_rediscovery, discovery}, _from, state) do
    # If we have this exact name already from a DIFFERENT civ, it's a rediscovery
    existing_ids = Map.get(state.by_name, discovery.name, [])
    is_rediscovery = Enum.any?(existing_ids, fn id -> 
      old = state.by_id[id]
      old != nil and old.originator_civ_id != discovery.originator_civ_id
    end)
    
    {:reply, is_rediscovery, state}
  end
  
  @impl true
  def handle_cast({:increment_prestige, discovery_name}, state) do
    # Find all IDs for this name
    ids = Map.get(state.by_name, discovery_name, [])
    
    new_by_id = Enum.reduce(ids, state.by_id, fn id, acc ->
      case Map.get(acc, id) do
        nil -> acc
        disc -> Map.put(acc, id, %{disc | prestige: Map.get(disc, :prestige, 0) + 1})
      end
    end)
    
    Logger.info("🌟 [Discovery Genealogy] Prestige of '#{discovery_name}' increased due to rediscovery.")
    {:noreply, %{state | by_id: new_by_id}}
  end
  
  defp trace_ancestry(id, graph, acc) do
    case Map.get(graph, id) do
      nil -> acc
      disc ->
        parents = Map.get(disc, :parents, [])
        if parents == [] do
          [disc | acc]
        else
          # Trace each parent recursively, flatten and uniq
          parent_paths = Enum.flat_map(parents, fn p_id -> trace_ancestry(p_id, graph, []) end)
          Enum.uniq([disc | parent_paths] ++ acc)
        end
    end
  end
end
