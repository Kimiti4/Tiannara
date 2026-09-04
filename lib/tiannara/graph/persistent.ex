defmodule Tiannara.Graph.Persistent do
  @moduledoc """
  Event-sourced, durable reality graph. The append-only event log is the source
  of truth; the materialized InMemory graph is a read cache. On restart the
  graph is reconstructed by replaying the log — preserving lineage and
  supporting audit + reproducibility.

  Constitutional basis: "Maintain audit trails", "Support reproducibility",
  "Preserve lineage", "Preserve previous stable states".
  """
  use GenServer

  alias Tiannara.Graph.InMemory

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))

  def add_node(s, id, attrs), do: GenServer.call(s, {:add_node, id, attrs})
  def add_edge(s, eid, from, to, label, meta),
    do: GenServer.call(s, {:add_edge, eid, from, to, label, meta})
  def get_node(s, id), do: GenServer.call(s, {:get_node, id})
  def get_edge(s, eid), do: GenServer.call(s, {:get_edge, eid})
  def node_ids(s), do: GenServer.call(s, :node_ids)
  def edges(s), do: GenServer.call(s, :edges)
  def event_log(s), do: GenServer.call(s, :event_log)
  def replay(s), do: GenServer.call(s, :replay)
  def snapshot(s), do: GenServer.call(s, :snapshot)

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :path)
    events = load_events(path)
    {:ok, %{graph: InMemory.replay(events), events: events, path: path}}
  end

  defp load_events(nil), do: []
  defp load_events(path) do
    if File.exists?(path), do: path |> File.read!() |> :erlang.binary_to_term(), else: []
  end

  defp persist(%{path: nil}), do: :ok
  defp persist(%{path: path, events: events}),
    do: File.write!(path, :erlang.term_to_binary(events))

  @impl true
  def handle_call({:add_node, id, attrs}, _from, st) do
    event = {:add_node, id, attrs}
    st = %{st | graph: InMemory.apply_event(st.graph, event), events: st.events ++ [event]}
    persist(st)
    {:reply, :ok, st}
  end

  def handle_call({:add_edge, eid, from, to, label, meta}, _from, st) do
    event = {:add_edge, eid, from, to, label, meta}

    case InMemory.add_edge(st.graph, eid, from, to, label, meta) do
      {:ok, g} ->
        st = %{st | graph: g, events: st.events ++ [event]}
        persist(st)
        {:reply, :ok, st}

      {:error, _} = e ->
        {:reply, e, st}
    end
  end

  def handle_call({:get_node, id}, _from, st),
    do: {:reply, InMemory.get_node(st.graph, id), st}
  def handle_call({:get_edge, eid}, _from, st),
    do: {:reply, InMemory.get_edge(st.graph, eid), st}
  def handle_call(:node_ids, _from, st), do: {:reply, InMemory.node_ids(st.graph), st}
  def handle_call(:edges, _from, st), do: {:reply, InMemory.edges(st.graph), st}
  def handle_call(:event_log, _from, st), do: {:reply, st.events, st}

  def handle_call(:replay, _from, st),
    do: {:reply, :ok, %{st | graph: InMemory.replay(st.events)}}

  def handle_call(:snapshot, _from, st),
    do: {:reply, InMemory.to_snapshot(st.graph), st}
end