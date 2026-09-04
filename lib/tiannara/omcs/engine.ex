defmodule Tiannara.OMCS.Engine do
  @moduledoc """
  Core engine for the Ontological Memory Continuity System (OMCS).
  Manages Identity, Lineage, Causal, and Narrative graphs.
  """

  use GenServer
  require Logger

  alias Tiannara.OMCS.Milestone

  @doc "Start the OMCS Engine."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Register a new civilization in OMCS. Edge type can be :reproduced_from, :fissioned_from, :migrated_from, or :spawned."
  def register_civilization(civ_id, parent_id \\ nil, edge_type \\ :spawned) do
    GenServer.call(__MODULE__, {:register_civilization, civ_id, parent_id, edge_type})
  end

  @doc "Record a narrative milestone."
  def record_milestone(civ_id, %Milestone{} = milestone) do
    GenServer.call(__MODULE__, {:record_milestone, civ_id, milestone})
  end

  @doc "Record a causal link (decision -> effect)."
  def record_causal_link(civ_id, decision, effect) do
    GenServer.call(__MODULE__, {:record_causal_link, civ_id, decision, effect})
  end

  @doc "Get the full lineage graph for a civilization."
  def get_lineage(civ_id) do
    GenServer.call(__MODULE__, {:get_lineage, civ_id})
  end

  @doc "Get all milestones for a civilization."
  def get_narrative(civ_id) do
    GenServer.call(__MODULE__, {:get_narrative, civ_id})
  end

  @doc "Get causal graph for a civilization."
  def get_causal_graph(civ_id) do
    GenServer.call(__MODULE__, {:get_causal_graph, civ_id})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting OMCS Engine")

    state = %{
      # civ_id -> %{status: :active | :compressed, parent: {parent_id, edge_type}, children: [{child_id, edge_type}]}
      identity_graph: %{}, 
      
      # civ_id -> [%Milestone{}]
      narrative_graph: %{},
      
      # civ_id -> [{decision, effect}]
      causal_graph: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:register_civilization, civ_id, parent_id, edge_type}, _from, state) do
    if Map.has_key?(state.identity_graph, civ_id) do
      {:reply, {:error, :already_registered}, state}
    else
      parent_tuple = if parent_id, do: {parent_id, edge_type}, else: nil
      new_identity = %{status: :active, parent: parent_tuple, children: []}
      
      # Update parent's children list if parent exists
      updated_identity_graph = if parent_id && Map.has_key?(state.identity_graph, parent_id) do
        parent = state.identity_graph[parent_id]
        updated_parent = %{parent | children: [{civ_id, edge_type} | parent.children]}
        Map.put(state.identity_graph, parent_id, updated_parent)
      else
        state.identity_graph
      end
      
      updated_identity_graph = Map.put(updated_identity_graph, civ_id, new_identity)
      
      new_state = %{state | 
        identity_graph: updated_identity_graph,
        narrative_graph: Map.put(state.narrative_graph, civ_id, []),
        causal_graph: Map.put(state.causal_graph, civ_id, [])
      }
      
      Logger.info("OMCS registered civilization: #{civ_id} (Edge: #{edge_type})")
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:record_milestone, civ_id, milestone}, _from, state) do
    case Map.get(state.narrative_graph, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      milestones ->
        updated_milestones = [milestone | milestones]
        new_state = %{state | narrative_graph: Map.put(state.narrative_graph, civ_id, updated_milestones)}
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:record_causal_link, civ_id, decision, effect}, _from, state) do
    case Map.get(state.causal_graph, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      links ->
        updated_links = [{decision, effect} | links]
        new_state = %{state | causal_graph: Map.put(state.causal_graph, civ_id, updated_links)}
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:get_lineage, civ_id}, _from, state) do
    case Map.get(state.identity_graph, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      _identity -> 
        lineage = build_lineage_tree(state.identity_graph, civ_id)
        {:reply, {:ok, lineage}, state}
    end
  end

  @impl true
  def handle_call({:get_narrative, civ_id}, _from, state) do
    case Map.get(state.narrative_graph, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      milestones -> {:reply, {:ok, Enum.reverse(milestones)}, state} # Return chronologically
    end
  end

  @impl true
  def handle_call({:get_causal_graph, civ_id}, _from, state) do
    case Map.get(state.causal_graph, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      links -> {:reply, {:ok, Enum.reverse(links)}, state}
    end
  end

  defp build_lineage_tree(graph, civ_id) do
    case Map.get(graph, civ_id) do
      nil -> nil
      identity ->
        children = Enum.map(identity.children, fn {child_id, edge_type} -> 
          child_tree = build_lineage_tree(graph, child_id)
          {edge_type, child_tree}
        end)
        %{id: civ_id, parent: identity.parent, children: children}
    end
  end
end
