defmodule Tiannara.Graph.Server do
  @moduledoc """
  Concurrent-safe reality graph. Wraps `InMemory` in a GenServer so all reads
  and writes are serialized through the process mailbox — safe under concurrent
  access, unlike raw `:digraph`.

  Constitutional basis: Fault tolerance, "Capability must never outpace
  verification", Modularity/Replaceability (same operation surface, swappable
  behind the Graph.Behaviour seam).
  """
  use GenServer

  alias Tiannara.Graph.InMemory

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))

  # client API
  def add_node(s, id, attrs), do: GenServer.call(s, {:add_node, id, attrs})
  def update_node(s, id, attrs), do: GenServer.call(s, {:update_node, id, attrs})
  def get_node(s, id), do: GenServer.call(s, {:get_node, id})
  def node_ids(s), do: GenServer.call(s, :node_ids)
  def add_edge(s, eid, from, to, label, meta),
    do: GenServer.call(s, {:add_edge, eid, from, to, label, meta})
  def get_edge(s, eid), do: GenServer.call(s, {:get_edge, eid})
  def edges(s), do: GenServer.call(s, :edges)
  def out_edges(s, id), do: GenServer.call(s, {:out_edges, id})
  def in_edges(s, id), do: GenServer.call(s, {:in_edges, id})
  def snapshot(s), do: GenServer.call(s, :snapshot)

  @impl true
  def init(_opts), do: {:ok, %{graph: InMemory.new()}}

  @impl true
  def handle_call({:add_node, id, attrs}, _from, st) do
    {:reply, :ok, %{st | graph: InMemory.add_node(st.graph, id, attrs)}}
  end

  def handle_call({:update_node, id, attrs}, _from, st) do
    case InMemory.update_node(st.graph, id, attrs) do
      {:error, _} = e -> {:reply, e, st}
      g -> {:reply, :ok, %{st | graph: g}}
    end
  end

  def handle_call({:get_node, id}, _from, st),
    do: {:reply, InMemory.get_node(st.graph, id), st}

  def handle_call(:node_ids, _from, st),
    do: {:reply, InMemory.node_ids(st.graph), st}

  def handle_call({:add_edge, eid, from, to, label, meta}, _from, st) do
    case InMemory.add_edge(st.graph, eid, from, to, label, meta) do
      {:ok, g} -> {:reply, :ok, %{st | graph: g}}
      {:error, _} = e -> {:reply, e, st}
    end
  end

  def handle_call({:get_edge, eid}, _from, st),
    do: {:reply, InMemory.get_edge(st.graph, eid), st}

  def handle_call(:edges, _from, st), do: {:reply, InMemory.edges(st.graph), st}
  def handle_call({:out_edges, id}, _from, st),
    do: {:reply, InMemory.out_edges(st.graph, id), st}
  def handle_call({:in_edges, id}, _from, st),
    do: {:reply, InMemory.in_edges(st.graph, id), st}
  def handle_call(:snapshot, _from, st),
    do: {:reply, InMemory.to_snapshot(st.graph), st}
end