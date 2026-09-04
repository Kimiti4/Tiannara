defmodule Tiannara.Graph.InMemory do
  @moduledoc """
  Pure in-memory reality-graph implementation (map-backed, no processes).

  Returns the NEW graph from mutating functions so it can be stored in a
  GenServer state or passed along a pipeline; reads return `{:ok, value}`
  tuples that never collide with `{:error, _}` writes.

  Constitutional basis: Replaceability (same surface as Persistent/Postgres),
  "Preserve lineage", "Maintain audit trails".
  """

  @behaviour Tiannara.Graph.Behaviour

  alias Tiannara.Graph.Edge

  defstruct nodes: %{}, edges: %{}

  @impl true
  def new, do: %__MODULE__{}

  @impl true
  def add_node(%__MODULE__{} = g, node_id, attrs) do
    %{g | nodes: Map.put(g.nodes, node_id, attrs)}
  end

  @impl true
  def update_node(%__MODULE__{} = g, node_id, attrs) do
    case Map.fetch(g.nodes, node_id) do
      {:ok, _} -> %{g | nodes: Map.put(g.nodes, node_id, attrs)}
      :error -> {:error, :missing_node}
    end
  end

  @impl true
  def get_node(%__MODULE__{} = g, node_id) do
    case Map.fetch(g.nodes, node_id) do
      {:ok, attrs} -> {:ok, attrs}
      :error -> :not_found
    end
  end

  @impl true
  def node_ids(%__MODULE__{} = g), do: Map.keys(g.nodes)

  @impl true
  def add_edge(%__MODULE__{} = g, edge_id, from, to, label, metadata) do
    with {:ok, _} <- Map.fetch(g.nodes, from),
         {:ok, _} <- Map.fetch(g.nodes, to) do
      edge = %Edge{id: edge_id, from: from, to: to, label: label, metadata: metadata}
      {:ok, %{g | edges: Map.put(g.edges, edge_id, edge)}}
    else
      :error -> {:error, :missing_node}
    end
  end

  @impl true
  def get_edge(%__MODULE__{} = g, edge_id) do
    case Map.fetch(g.edges, edge_id) do
      {:ok, %Edge{} = e} -> {:ok, e}
      :error -> :not_found
    end
  end

  @impl true
  def edges(%__MODULE__{} = g), do: Map.values(g.edges)

  @impl true
  def out_edges(%__MODULE__{} = g, node_id) do
    for %Edge{from: ^node_id} = e <- Map.values(g.edges), do: e
  end

  @impl true
  def in_edges(%__MODULE__{} = g, node_id) do
    for %Edge{to: ^node_id} = e <- Map.values(g.edges), do: e
  end

  @doc "Serialize the graph to a plain term (for persistence or snapshots)."
  def to_snapshot(%__MODULE__{} = g), do: %{nodes: g.nodes, edges: g.edges}

  @doc "Reconstruct a graph from a snapshot produced by `to_snapshot/1`."
  def from_snapshot(%{nodes: nodes, edges: edges}) do
    %__MODULE__{nodes: nodes, edges: edges}
  end

  @doc "Apply a single event to the graph (event-sourcing)."
  def apply_event(%__MODULE__{} = g, {:add_node, id, attrs}), do: add_node(g, id, attrs)

  def apply_event(%__MODULE__{} = g, {:add_edge, eid, from, to, label, meta}) do
    case add_edge(g, eid, from, to, label, meta) do
      {:ok, g} -> g
      {:error, _} -> g
    end
  end

  @doc "Replay an event log into a fresh graph."
  def replay(events) do
    Enum.reduce(events, new(), &apply_event(&2, &1))
  end
end