defmodule Tiannara.Sentinel.DiscoveryVerificationGraph do
  @moduledoc """
  Immutable, hash-chained verification lineage for discovery promotion.

  Every promotion appends exactly one node. Nodes may reference earlier nodes,
  but an existing node is never overwritten. The graph is DETS-backed so its
  chain can be reconstructed and verified after process restart.
  """

  use GenServer

  @table :tiannara_discovery_verification_graph
  @genesis "DISCOVERY_VERIFICATION_GRAPH_GENESIS"
  @default_file "data/discovery_verification_graph.dets"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def append_with_archive(node, archive_fun \\ &default_archive/1) when is_map(node) and is_function(archive_fun, 1) do
    ensure_started()
    GenServer.call(__MODULE__, {:append_with_archive, node, archive_fun})
  end

  def get(id) do
    ensure_started()
    GenServer.call(__MODULE__, {:get, id})
  end

  def lineage(id) do
    ensure_started()
    GenServer.call(__MODULE__, {:lineage, id})
  end

  def verify_chain do
    ensure_started()
    GenServer.call(__MODULE__, :verify_chain)
  end

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :file, Application.get_env(:tiannara, :discovery_verification_graph_file, @default_file))
    File.mkdir_p!(Path.dirname(path))
    case :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: true) do
      {:ok, _} ->
        recover_orphan_archives()
        {:ok, %{order: load_order(), last_hash: load_last_hash()}}
      {:error, reason} -> {:stop, {:graph_open_failed, reason}}
    end
  end

  @impl true
  def handle_call({:append_with_archive, node, archive_fun}, _from, state) do
    with :ok <- validate_node(node),
         :ok <- validate_parents(node) do
      case existing_transition(node, state) do
        {:ok, %{graph: graph, archive: archive}} ->
          {:reply, {:ok, %{graph: graph, archive: archive}}, state}

        {:error, :transition_identity_conflict} ->
          {:reply, {:error, :transition_identity_conflict}, state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}

        :not_found ->
          with {:ok, graph} <- build_graph_node(node, state),
               {:ok, archive} <- archive_fun.(graph),
               :ok <- validate_archive_binding(graph, archive),
               graph = Map.put(graph, :archive_hash, archive.hash),
               :ok <- persist_graph(graph) do
            {:reply, {:ok, %{graph: graph, archive: archive}},
             %{state | order: state.order ++ [graph.node_id], last_hash: graph.hash}}
          else
            {:error, reason} -> {:reply, {:error, reason}, state}
          end
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, id}, _from, state) do
    reply =
      case :dets.lookup(@table, id) do
        [{^id, node}] -> {:ok, node}
        [] -> {:error, :node_not_found}
      end
    {:reply, reply, state}
  end

  def handle_call({:lineage, id}, _from, state) do
    nodes = Enum.flat_map(state.order, fn key ->
      case :dets.lookup(@table, key) do
        [{^key, node}] -> [node]
        _ -> []
      end
    end)
    case Enum.find(nodes, &(&1.node_id == id)) do
      nil -> {:reply, {:error, :node_not_found}, state}
      node -> {:reply, {:ok, walk(node, nodes, MapSet.new())}, state}
    end
  end

  def handle_call(:verify_chain, _from, state) do
    result =
      state.order
      |> Enum.with_index(1)
      |> Enum.reduce_while({@genesis, 1}, fn {id, expected_sequence}, {previous, _next_sequence} ->
        case :dets.lookup(@table, id) do
          [{^id, node}] ->
            archive_hash = Map.get(node, :archive_hash)

            cond do
              Map.get(node, :sequence) != expected_sequence ->
                {:halt, {:error, {:sequence_invalid, id}}}

              node.previous_hash != previous ->
                {:halt, {:error, {:hash_chain_invalid, id}}}

              node.hash != hash_record(Map.delete(node, :hash)) ->
                {:halt, {:error, {:hash_chain_invalid, id}}}

              not is_binary(archive_hash) or archive_hash == "" ->
                {:halt, {:error, {:archive_binding_missing, id}}}

              Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash) != :ok ->
                {:halt, {:error, {:archive_binding_invalid, id}}}

              true ->
                case Tiannara.Sentinel.DiscoveryEvidenceArchive.get(archive_hash) do
                  {:ok, archive} ->
                    if Map.get(archive, :id) != node.node_id do
                      {:halt, {:error, {:archive_identity_mismatch, id}}}
                    else
                      case Map.get(archive, :artifact) do
                        artifact when is_map(artifact) ->
                          if Map.get(artifact, :node_id) == node.node_id and
                               Map.get(artifact, :hash) == node.hash do
                            {:cont, {node.hash, expected_sequence + 1}}
                          else
                            {:halt, {:error, {:archive_artifact_mismatch, id}}}
                          end

                        _ ->
                          {:halt, {:error, {:archive_artifact_missing, id}}}
                      end
                    end

                  _ ->
                    {:halt, {:error, {:archive_identity_mismatch, id}}}
                end
            end

          [] ->
            {:halt, {:error, {:graph_node_missing, id}}}
        end
      end)

    reply =
      case result do
        {:error, _} = error -> error
        {_hash, _next_sequence} -> :ok
      end

    {:reply, reply, state}
  end

  # A transition key identifies the logical lifecycle edge; the payload
  # hash prevents retries with different evidence from being mistaken as the
  # same successful operation.
  defp existing_transition(%{transition_key: key} = candidate, state) when is_binary(key) do
    candidate_payload_hash = Map.get(candidate, :transition_payload_hash)

    existing =
      Enum.find_value(state.order, fn id ->
        case :dets.lookup(@table, id) do
          [{^id, %{transition_key: ^key} = graph}] -> graph
          _ -> nil
        end
      end)

    case existing do
      nil ->
        :not_found

      %{transition_payload_hash: payload_hash, archive_hash: archive_hash} = graph
      when payload_hash == candidate_payload_hash ->
        case Tiannara.Sentinel.DiscoveryEvidenceArchive.get(archive_hash) do
          {:ok, archive} ->
            if Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash) == :ok and
                 Map.get(archive, :id) == graph.node_id do
              {:ok, %{graph: graph, archive: archive}}
            else
              {:error, :existing_transition_archive_invalid}
            end

          _ ->
            {:error, :existing_transition_archive_missing}
        end

      _different_payload ->
        {:error, :transition_identity_conflict}
    end
  end

  defp existing_transition(_candidate, _state), do: :not_found

  defp build_graph_node(node, state) do
    graph = Map.merge(node, %{
      node_id: Map.get(node, :node_id, unique_id()),
      sequence: length(state.order) + 1,
      previous_hash: state.last_hash
    })
    {:ok, Map.put(graph, :hash, hash_record(graph))}
  end

  defp validate_archive_binding(graph, archive) when is_map(archive) do
    archive_hash = Map.get(archive, :hash)
    artifact = Map.get(archive, :artifact)

    cond do
      not is_binary(archive_hash) or archive_hash == "" ->
        {:error, :archive_hash_missing}
      Map.get(archive, :id) != graph.node_id ->
        {:error, :archive_discovery_identity_mismatch}
      not is_map(artifact) or Map.get(artifact, :node_id) != graph.node_id ->
        {:error, :archive_artifact_identity_mismatch}
      Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash) != :ok ->
        {:error, :archive_record_not_verified}
      true ->
        :ok
    end
  end

  defp validate_archive_binding(_graph, _archive), do: {:error, :invalid_archive_record}

  defp persist_graph(graph) do
    case :dets.lookup(@table, graph.node_id) do
      [] -> :dets.insert(@table, {graph.node_id, graph})
      [{_, ^graph}] -> :ok
      [{_, _}] -> {:error, :immutable_graph_conflict}
    end
  end

  defp validate_node(node) do
    required = [:kind, :discovery_id, :provenance]
    case Enum.find(required, &(not Map.has_key?(node, &1))) do
      nil -> :ok
      key -> {:error, {:missing_node_field, key}}
    end
  end

  defp validate_parents(node) do
    parent_ids = Map.get(node, :parent_ids, [])
    if Enum.all?(parent_ids, fn id -> :dets.lookup(@table, id) != [] end), do: :ok, else: {:error, :missing_parent}
  end

  defp walk(node, nodes, seen) do
    if MapSet.member?(seen, node.node_id), do: [], else: [node | Enum.flat_map(Map.get(node, :parent_ids, []), fn id ->
      case Enum.find(nodes, &(&1.node_id == id)) do
        nil -> []
        parent -> walk(parent, nodes, MapSet.put(seen, node.node_id))
      end
    end)]
  end

  defp hash_record(record), do: :crypto.hash(:sha256, :erlang.term_to_binary(Map.drop(record, [:hash, :archive_hash]))) |> Base.encode16(case: :lower)
  defp unique_id, do: "dvg-" <> Integer.to_string(System.unique_integer([:positive, :monotonic]))

  defp default_archive(graph) do
    Tiannara.Sentinel.DiscoveryEvidenceArchive.append(%{
      id: graph.node_id,
      kind: :discovery_verification,
      status: graph.status,
      artifact: graph,
      provenance: graph.provenance
    }, parent_archives(graph))
  end

  defp parent_archives(graph) do
    Enum.flat_map(Map.get(graph, :parent_ids, []), fn parent_id ->
      case :dets.lookup(@table, parent_id) do
        [{^parent_id, parent}] ->
          case Tiannara.Sentinel.DiscoveryEvidenceArchive.get(Map.get(parent, :archive_hash)) do
            {:ok, archive} -> [archive]
            _ -> []
          end
        _ -> []
      end
    end)
  end

  # Archive and graph use separate DETS tables. If a crash occurs after the
  # archive commit but before the graph commit, recover the graph from the
  # immutable archive artifact on the next startup.
  defp recover_orphan_archives do
    # all/0 ensures the archive is opened if the graph starts before the
    # archive process. Recovery only trusts content-addressed records whose
    # archive hash and embedded graph hash both verify.
    Tiannara.Sentinel.DiscoveryEvidenceArchive.all()
    |> Enum.each(fn archive ->
      artifact = Map.get(archive, :artifact, %{})
      node_id = Map.get(artifact, :node_id)
      archive_hash = Map.get(archive, :hash)

      if archive_hash && node_id &&
           Map.get(archive, :id) == node_id &&
           Map.get(archive, :kind) == :discovery_verification &&
           :dets.lookup(@table, node_id) == [] &&
           Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash) == :ok do
        graph = Map.put(artifact, :archive_hash, archive_hash)

        if Map.get(graph, :hash) == hash_record(graph) do
          _ = :dets.insert(@table, {node_id, graph})
        end
      end
    end)
  end

  defp load_order do
    :dets.traverse(@table, fn {id, _node} -> {:continue, id} end)
    |> Enum.sort_by(fn id ->
      case :dets.lookup(@table, id) do
        [{^id, node}] -> Map.get(node, :sequence, 0)
        _ -> 0
      end
    end)
  end

  defp load_last_hash do
    case load_order() |> List.last() do
      nil -> @genesis
      id -> :dets.lookup(@table, id) |> List.first() |> elem(1) |> Map.get(:hash)
    end
  end

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil ->
        case start_link([]) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
          {:error, reason} -> raise "discovery verification graph unavailable: #{inspect(reason)}"
        end
      _ -> :ok
    end
  end
end
