defmodule ReplayStore.CausalLineage do
  use GenServer

  @causal_chain [
    :observation,
    :question,
    :hypothesis,
    :experiment,
    :evidence,
    :discovery,
    :theory,
    :engineering,
    :deployment
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_link(parent_id, child_id, relationship, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:link, parent_id, child_id, relationship, metadata})
  end

  def ancestors(event_id) do
    GenServer.call(__MODULE__, {:ancestors, event_id})
  end

  def descendants(event_id) do
    GenServer.call(__MODULE__, {:descendants, event_id})
  end

  def lineage_path(from_id, to_id) do
    GenServer.call(__MODULE__, {:path, from_id, to_id})
  end

  def causal_chain do
    GenServer.call(__MODULE__, :chain)
  end

  @impl true
  def init(_opts) do
    {:ok, %{edges: %{}, reverse_edges: %{}, relationship_index: %{}, chain: @causal_chain}}
  end

  @impl true
  def handle_cast({:link, parent_id, child_id, relationship, metadata}, state) do
    link = %{
      parent: parent_id,
      child: child_id,
      relationship: relationship,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }

    children = Map.get(state.edges, parent_id, [])
    parents = Map.get(state.reverse_edges, child_id, [])
    rel_entries = Map.get(state.relationship_index, relationship, [])

    {:noreply,
     %{
       state
       | edges: Map.put(state.edges, parent_id, [link | children]),
         reverse_edges: Map.put(state.reverse_edges, child_id, [link | parents]),
         relationship_index: Map.put(state.relationship_index, relationship, [link | rel_entries])
     }}
  end

  @impl true
  def handle_call({:ancestors, event_id}, _from, state) do
    path = trace_ancestors(event_id, state.reverse_edges, [])
    {:reply, path, state}
  end

  @impl true
  def handle_call({:descendants, event_id}, _from, state) do
    path = trace_descendants(event_id, state.edges, [])
    {:reply, path, state}
  end

  @impl true
  def handle_call({:path, from_id, to_id}, _from, state) do
    path = bfs_path(from_id, to_id, state.edges)
    {:reply, path, state}
  end

  @impl true
  def handle_call(:chain, _from, %{chain: c} = state) do
    {:reply, c, state}
  end

  defp trace_ancestors(_id, _reverse, path, _depth \\ 100)
  defp trace_ancestors(_id, _reverse, path, depth) when depth <= 0, do: path

  defp trace_ancestors(id, reverse, path, depth) do
    case Map.get(reverse, id) do
      nil ->
        path

      links ->
        Enum.reduce(links, path, fn link, acc ->
          if link.parent in acc do
            acc
          else
            trace_ancestors(link.parent, reverse, [link.parent | acc], depth - 1)
          end
        end)
    end
  end

  defp trace_descendants(_id, _edges, path, _depth \\ 100)
  defp trace_descendants(_id, _edges, path, depth) when depth <= 0, do: path

  defp trace_descendants(id, edges, path, depth) do
    case Map.get(edges, id) do
      nil ->
        path

      links ->
        Enum.reduce(links, path, fn link, acc ->
          if link.child in acc do
            acc
          else
            trace_descendants(link.child, edges, [link.child | acc], depth - 1)
          end
        end)
    end
  end

  defp bfs_path(from, to, edges, visited \\ MapSet.new()) do
    cond do
      from == to ->
        [from]

      MapSet.member?(visited, from) ->
        nil

      true ->
        case Map.get(edges, from) do
          nil ->
            nil

          links ->
            Enum.reduce_while(links, nil, fn link, _acc ->
              case bfs_path(link.child, to, edges, MapSet.put(visited, from)) do
                nil -> {:cont, nil}
                path -> {:halt, [from | path]}
              end
            end)
        end
    end
  end
end
