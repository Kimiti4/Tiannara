defmodule Tiannara.Sentinel.DiscoveryVerificationGraph do
  @moduledoc """
  Immutable, replayable lineage for discovery verification and improvement.

  Nodes represent discoveries, domain reviews, faults, corrections, experiments,
  verification results, and revisions. Edges preserve why each artifact exists.
  This graph is evidence lineage, not a truth oracle.
  """

  use GenServer

  @genesis "DISCOVERY_VERIFICATION_GRAPH_GENESIS"

  def start_link(opts \ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec append(map()) :: {:ok, map()} | {:error, term()}
  def append(node) when is_map(node), do: GenServer.call(__MODULE__, {:append, node})

  @spec lineage(term()) :: {:ok, [map()]} | {:error, term()}
  def lineage(id), do: GenServer.call(__MODULE__, {:lineage, id})

  @spec verify_chain() :: :ok | {:error, term()}
  def verify_chain, do: GenServer.call(__MODULE__, :verify_chain)

  def init(_), do: {:ok, %{order: [], nodes: %{}, last_hash: @genesis}}

  def handle_call({:append, node}, _from, state) do
    with :ok <- validate_node(node),
         :ok <- validate_parents(node, state.nodes) do
      record = Map.merge(node, %{
        node_id: Map.get(node, :node_id, unique_id()),
        previous_hash: state.last_hash
      })
      hash = hash_record(record)
      stored = Map.put(record, :hash, hash)
      {:reply, {:ok, stored}, %{state | order: state.order ++ [stored.node_id], nodes: Map.put(state.nodes, stored.node_id, stored), last_hash: hash}}
    end
  end

  def handle_call({:lineage, id}, _from, state) do
    case Map.get(state.nodes, id) do
      nil -> {:reply, {:error, :node_not_found}, state}
      node -> {:reply, {:ok, walk(node, state.nodes, MapSet.new())}, state}
    end
  end

  def handle_call(:verify_chain, _from, state) do
    case verify_order(state.order, state.nodes, @genesis, nil) do
      :ok -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  defp validate_node(node) do
    required = [:kind, :discovery_id, :provenance]
    case Enum.find(required, &(not Map.has_key?(node, &1))) do
      nil -> :ok
      key -> {:error, {:missing_node_field, key}}
    end
  end

  defp validate_parents(node, nodes) do
    parents = Map.get(node, :parent_ids, [])
    if Enum.all?(parents, &Map.has_key?(nodes, &1)), do: :ok, else: {:error, :missing_parent}
  end

  defp walk(node, nodes, seen) do
    if MapSet.member?(seen, node.node_id) do
      []
    else
      parents = Enum.flat_map(Map.get(node, :parent_ids, []), fn id ->
        case Map.get(nodes, id) do
          nil -> []
          parent -> walk(parent, nodes, MapSet.put(seen, node.node_id))
        end
      end)
      [node | parents]
    end
  end

  defp verify_order([], _nodes, _previous, _), do: :ok
  defp verify_order([id | rest], nodes, previous, _) do
    node = Map.fetch!(nodes, id)
    if node.previous_hash != previous or node.hash != hash_record(Map.delete(node, :hash)) do
      {:error, {:hash_chain_invalid, id}}
    else
      verify_order(rest, nodes, node.hash, nil)
    end
  end

  defp hash_record(record), do: :crypto.hash(:sha256, :erlang.term_to_binary(record)) |> Base.encode16(case: :lower)
  defp unique_id, do: "dvg-" <> Integer.to_string(System.unique_integer([:positive]))
end
