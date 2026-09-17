defmodule ObservationBus.LineageEngine do
  @moduledoc """
  Lineage tracking engine.

  Every event remembers its parent, cause, evidence, and children.
  Nothing becomes orphaned.

  Lineage is stored in ETS for fast graph traversal.
  """

  use GenServer

  alias ObservationBus.Event

  @table __MODULE__

  @doc """
  Records an event in the lineage graph.
  """
  @spec record(Event.t()) :: :ok
  def record(%Event{id: id, parent_id: parent_id, cause_id: cause_id} = event) do
    entry = %{
      event_id: id,
      parent_id: parent_id,
      cause_id: cause_id,
      domain: event.domain,
      timestamp: event.timestamp,
      global_sequence: event.global_sequence,
      children: [],
    }

    :ets.insert(@table, {id, entry})

    if parent_id do
      update_children(parent_id, id)
    end

    :ok
  end

  @doc """
  Returns the full lineage chain for an event (ancestors, excluding the event itself).
  """
  @spec ancestors(String.t()) :: list(map())
  def ancestors(event_id) do
    case lookup(event_id) do
      nil -> []
      %{parent_id: nil} -> []
      %{parent_id: parent} -> traverse(parent, :up, [])
    end
  end

  @doc """
  Returns all descendants of an event.
  """
  @spec descendants(String.t()) :: list(map())
  def descendants(event_id) do
    case lookup(event_id) do
      nil -> []
      %{children: children} ->
        children
        |> Enum.map(&lookup/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.flat_map(fn child ->
          [child | descendants(child.event_id)]
        end)
    end
  end

  @doc """
  Returns the lineage graph rooted at an event (parents + children).
  """
  @spec graph(String.t()) :: map()
  def graph(event_id) do
    %{
      event: lookup(event_id),
      ancestors: ancestors(event_id),
      descendants: descendants(event_id),
      depth: depth(event_id),
    }
  end

  @doc """
  Returns the depth of an event in the lineage tree.
  """
  @spec depth(String.t()) :: non_neg_integer()
  def depth(event_id, current_depth \\ 0) do
    case lookup(event_id) do
      nil -> current_depth
      %{parent_id: nil} -> current_depth
      %{parent_id: parent} -> depth(parent, current_depth + 1)
    end
  end

  @doc """
  Returns all events that share the same lineage (siblings).
  """
  @spec siblings(String.t()) :: list(map())
  def siblings(event_id) do
    case lookup(event_id) do
      nil -> []
      %{parent_id: nil} -> []
      %{parent_id: parent} ->
        case lookup(parent) do
          nil -> []
          %{children: children} ->
            children
            |> Enum.reject(&(&1 == event_id))
            |> Enum.map(&lookup/1)
            |> Enum.reject(&is_nil/1)
        end
    end
  end

  @doc """
  Returns lineage integrity metrics.
  """
  @spec integrity() :: map()
  def integrity do
    entries = :ets.tab2list(@table) |> Enum.map(fn {_id, entry} -> entry end)
    %{
      total_events: length(entries),
      with_parent: entries |> Enum.count(&(&1.parent_id != nil)),
      orphans: entries |> Enum.count(&(&1.parent_id == nil)),
      with_children: entries |> Enum.count(&(length(&1.children) > 0)),
      avg_depth: if(entries != [], do: entries |> Enum.map(&depth(&1.event_id)) |> Enum.sum() |> div(length(entries)), else: 0),
    }
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true, write_concurrency: true])
    {:ok, %{}}
  end

  # Private

  defp lookup(event_id) do
    case :ets.lookup(@table, event_id) do
      [{^event_id, entry}] -> entry
      [] -> nil
    end
  end

  defp update_children(parent_id, child_id) do
    case lookup(parent_id) do
      nil -> :ok
      %{children: children} = entry ->
        :ets.insert(@table, {parent_id, %{entry | children: [child_id | children]}})
    end
  end

  defp traverse(_event_id, _dir, acc, _visited \\ MapSet.new())

  defp traverse(nil, _dir, acc, _visited), do: acc

  defp traverse(event_id, :up, acc, visited) do
    if MapSet.member?(visited, event_id) do
      acc
    else
      case lookup(event_id) do
        nil -> acc
        %{parent_id: parent} = entry ->
          traverse(parent, :up, [entry | acc], MapSet.put(visited, event_id))
      end
    end
  end

  defp traverse(event_id, :down, acc, visited) do
    if MapSet.member?(visited, event_id) do
      acc
    else
      case lookup(event_id) do
        nil -> acc
        %{children: children} = entry ->
          child_entries = children
            |> Enum.map(&lookup/1)
            |> Enum.reject(&is_nil/1)

          rest = child_entries
            |> Enum.flat_map(fn c ->
              traverse(c.event_id, :down, acc, MapSet.put(visited, c.event_id))
            end)

          [entry | rest] ++ acc
      end
    end
  end
end
