defmodule Tiannara.Epistemic.PromotionIntegrationTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.DiscoveryRegistry
  alias Tiannara.Sentinel.{DiscoveryEvidenceArchive, DiscoveryVerificationGraph}

  setup do
    unless Process.whereis(DiscoveryEvidenceArchive), do: start_supervised!(DiscoveryEvidenceArchive)
    unless Process.whereis(DiscoveryVerificationGraph), do: start_supervised!(DiscoveryVerificationGraph)
    unless Process.whereis(DiscoveryRegistry), do: start_supervised!(DiscoveryRegistry)
    :ok
  end

  defp register(id) do
    DiscoveryRegistry.register(%{
      id: id,
      name: "epistemic integration",
      domain_id: :verification,
      experiment_ids: ["exp-#{id}"],
      evidence_ids: ["ev-#{id}"],
      theory_ids: [:theory],
      evidence_envelope: %{evidence_class: :simulated, execution_mode: :simulation}
    })
  end

  defp real_evidence do
    %{
      evidence_class: :real,
      execution_mode: :real_execution,
      real_observation: true,
      effect_verified: true,
      acl_status: :pass,
      oavl_status: :pass,
      reproduction_evidence: %{replications: 3, independent_runs: true}
    }
  end

  # DETS tables may be closed when on_exit runs (owner process already
  # stopped). Reopen briefly so the restore always lands, whether the table
  # is currently open or not.
  defp restore_dets_record(table, env_key, default_path, key, record) do
    path = Application.get_env(:tiannara, env_key, default_path)
    {:ok, _} = :dets.open_file(table, type: :set, file: String.to_charlist(path), repair: true)
    :ok = :dets.insert(table, {key, record})
    :ok = :dets.close(table)
  end

  defp restore_archive_record(hash, record) do
    restore_dets_record(
      :tiannara_discovery_evidence_archive,
      :discovery_evidence_archive_file,
      "data/discovery_evidence_archive.dets",
      hash,
      record
    )
  end

  defp restore_graph_record(node_id, record) do
    restore_dets_record(
      :tiannara_discovery_verification_graph,
      :discovery_verification_graph_file,
      "data/discovery_verification_graph.dets",
      node_id,
      record
    )
  end

  test "full discovery promotion persists and reconstructs lineage" do
    id = :"integration_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    reproduction = %{
      evidence_class: :real,
      execution_mode: :real_execution,
      real_observation: true,
      effect_verified: true,
      reproduction_evidence: %{replications: 3, independent_runs: true}
    }

    assert {:ok, reproduced} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, reproduction)

    assert reproduced.validation_status == :reproduced
    assert length(reproduced.lifecycle_events) == 1

    # Status flags supplied by the caller are not trusted ACL/OAVL artifacts.
    # Until provenance-bound operational evidence can be independently verified,
    # the registry must refuse this promotion and preserve the reproduced state.
    assert {:error, :trusted_operational_evidence_verification_unavailable} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :operationally_validated, real_evidence())

    assert {:ok, reproduced_after_refusal} = DiscoveryRegistry.get(id)
    assert reproduced_after_refusal.validation_status == :reproduced
    assert length(reproduced_after_refusal.lifecycle_events) == 1
    assert length(reproduced_after_refusal.verification_graph_ids) == 1
    assert length(reproduced_after_refusal.archive_ids) == 1

    [graph_id] = reproduced_after_refusal.verification_graph_ids
    [archive_hash] = reproduced_after_refusal.archive_ids

    assert {:ok, graph} = DiscoveryVerificationGraph.lineage(graph_id)
    assert Enum.any?(graph, &(&1.node_id == graph_id))
    assert {:ok, archive} = DiscoveryEvidenceArchive.get(archive_hash)
    assert archive.id == graph_id
    assert :ok = DiscoveryEvidenceArchive.verify(archive_hash)
    assert :ok = DiscoveryVerificationGraph.verify_chain()

    graph_pid = Process.whereis(DiscoveryVerificationGraph)
    archive_pid = Process.whereis(DiscoveryEvidenceArchive)
    Process.exit(graph_pid, :kill)
    Process.exit(archive_pid, :kill)
    Process.sleep(50)

    if Process.whereis(DiscoveryVerificationGraph) == nil, do: start_supervised!(DiscoveryVerificationGraph)
    if Process.whereis(DiscoveryEvidenceArchive) == nil, do: start_supervised!(DiscoveryEvidenceArchive)

    assert :ok = DiscoveryVerificationGraph.verify_chain()
    assert :ok = DiscoveryEvidenceArchive.verify(archive_hash)
  end

  test "interrupted registry persistence retries the same lineage and rejects changed evidence" do
    id = :"interrupted_promotion_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    evidence = %{
      evidence_class: :real,
      execution_mode: :real_execution,
      real_observation: true,
      effect_verified: true,
      reproduction_evidence: %{replications: 3, independent_runs: true}
    }

    failing_writer = fn _archive -> {:error, :simulated_persistence_interruption} end

    assert {:error, {:lineage_write_failed, :simulated_persistence_interruption}} =
      DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, evidence, failing_writer)

    # The registry must remain unpromoted even though graph/archive work may have happened.
    assert {:ok, unchanged} = DiscoveryRegistry.get(id)
    assert unchanged.validation_status == :simulated
    assert unchanged.verification_graph_ids == []
    assert unchanged.archive_ids == []

    conflicting_evidence = Map.put(evidence, :observation_source, "different-source")

    assert {:error, {:lineage_write_failed, :transition_identity_conflict}} =
      DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, conflicting_evidence)

    # Retrying the exact original payload must reuse the existing graph/archive record.
    assert {:ok, promoted} =
      DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, evidence)

    assert promoted.validation_status == :reproduced
    assert length(promoted.verification_graph_ids) == 1
    assert length(promoted.archive_ids) == 1

    graph_id = hd(promoted.verification_graph_ids)
    archive_hash = hd(promoted.archive_ids)
    assert {:ok, graph_node} = DiscoveryVerificationGraph.get(graph_id)
    assert graph_node.archive_hash == archive_hash
    assert :ok = DiscoveryEvidenceArchive.verify(archive_hash)
    assert :ok = DiscoveryVerificationGraph.verify_chain()
  end

  test "registry restart preserves promoted state and rejects replay" do
    id = :"registry_restart_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, reproduced} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())

    assert reproduced.validation_status == :reproduced
    old_pid = Process.whereis(DiscoveryRegistry)
    monitor = Process.monitor(old_pid)
    GenServer.stop(old_pid, :shutdown)
    assert_receive {:DOWN, ^monitor, :process, ^old_pid, :shutdown}, 5_000

    new_pid =
      Enum.reduce_while(1..50, nil, fn _, _ ->
        case Process.whereis(DiscoveryRegistry) do
          pid when is_pid(pid) and pid != old_pid -> {:halt, pid}
          _ ->
            Process.sleep(20)
            {:cont, nil}
        end
      end)

    assert is_pid(new_pid)
    assert {:ok, restored} = DiscoveryRegistry.get(id)
    assert restored.validation_status == :reproduced
    assert length(restored.lifecycle_events) == 1
    assert length(restored.verification_graph_ids) == 1
    assert length(restored.archive_ids) == 1

    assert {:error, :invalid_status_transition} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())
  end

  test "all promotion attack paths fail closed" do
    id = :"attack_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:error, :reproduction_evidence_required} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, %{})

    assert {:error, :invalid_evidence_envelope} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, %{evidence_class: :forged})

    assert {:error, :three_replications_required} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               Map.put(real_evidence(), :reproduction_evidence, %{replications: 2, independent_runs: true})
             )

    assert {:error, :missing_parent} =
             DiscoveryVerificationGraph.append_with_archive(%{
               kind: :discovery_validation_transition,
               discovery_id: id,
               parent_ids: ["does-not-exist"],
               provenance: %{source: :test},
               status: :reproduced,
               artifact: %{}
             })

    assert {:ok, reproduced} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               real_evidence()
             )

    assert {:error, :invalid_status_transition} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               %{reproduction_evidence: %{replications: 2}}
             )

    assert {:error, :real_evidence_required} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :operationally_validated,
               Map.put(real_evidence(), :evidence_class, :simulated)
             )

    assert reproduced.validation_status == :reproduced
    assert length(reproduced.lifecycle_events) == 1
  end


  test "verification graph rejects an archive bound to a different discovery identity" do
    id = :"archive_mismatch_#{System.unique_integer([:positive])}"

    assert {:error, :archive_discovery_identity_mismatch} =
             DiscoveryVerificationGraph.append_with_archive(
               %{
                 kind: :discovery_validation_transition,
                 discovery_id: id,
                 parent_ids: [],
                 provenance: %{source: :test},
                 status: :reproduced,
                 artifact: %{}
               },
               fn graph ->
                 DiscoveryEvidenceArchive.append(%{
                   id: "different-discovery",
                   kind: :discovery_verification,
                   status: graph.status,
                   artifact: graph,
                   provenance: graph.provenance
                 })
               end
             )
  end

  test "orphaned archive is recovered when graph persistence is interrupted" do
    # Model the crash window: the archive commit succeeds, but the graph DETS
    # insert never happens. On restart the graph must recover only the exact,
    # content-addressed graph artifact from the archive.
    table = :tiannara_discovery_verification_graph
    existing =
      :dets.traverse(table, fn {_id, node} -> {:continue, node} end)
      |> Enum.sort_by(&Map.get(&1, :sequence, 0))

    previous = List.last(existing)
    sequence = if previous, do: previous.sequence + 1, else: 1
    previous_hash = if previous, do: previous.hash, else: "DISCOVERY_VERIFICATION_GRAPH_GENESIS"
    node_id = "recovery-#{System.unique_integer([:positive])}"

    graph =
      %{
        node_id: node_id,
        sequence: sequence,
        previous_hash: previous_hash,
        kind: :discovery_validation_transition,
        discovery_id: node_id,
        parent_ids: [],
        provenance: %{source: :crash_recovery_test},
        status: :reproduced,
        artifact: %{node_id: node_id}
      }

    graph_hash =
      :crypto.hash(:sha256, :erlang.term_to_binary(graph))
      |> Base.encode16(case: :lower)

    graph = Map.put(graph, :hash, graph_hash)

    assert {:ok, _archive} =
             DiscoveryEvidenceArchive.append(%{
               id: node_id,
               kind: :discovery_verification,
               status: graph.status,
               artifact: graph,
               provenance: graph.provenance
             })

    assert {:error, :node_not_found} = DiscoveryVerificationGraph.get(node_id)

    graph_pid = Process.whereis(DiscoveryVerificationGraph)
    Process.exit(graph_pid, :kill)
    Process.sleep(50)
    if Process.whereis(DiscoveryVerificationGraph) == nil, do: start_supervised!(DiscoveryVerificationGraph)

    assert {:ok, recovered} = DiscoveryVerificationGraph.get(node_id)
    assert recovered.hash == graph_hash
    assert is_binary(recovered.archive_hash)
    assert :ok = DiscoveryEvidenceArchive.verify(recovered.archive_hash)
    assert :ok = DiscoveryVerificationGraph.verify_chain()
  end

  test "verification graph retries are idempotent and reject changed evidence" do
    key = "transition-#{System.unique_integer([:positive])}"
    node = %{
      kind: :discovery_validation_transition,
      discovery_id: key,
      transition_key: key,
      transition_payload_hash: "payload-a",
      provenance: %{source: :test, transition: {:candidate, :reproduced}},
      status: :reproduced,
      artifact: %{from: :candidate, to: :reproduced, evidence: %{evidence_class: :real}}
    }

    assert {:ok, first} = DiscoveryVerificationGraph.append_with_archive(node)
    assert {:ok, retry} = DiscoveryVerificationGraph.append_with_archive(node)
    assert retry.graph.node_id == first.graph.node_id
    assert retry.archive.hash == first.archive.hash

    changed_evidence = Map.put(node, :transition_payload_hash, "payload-b")
    assert {:error, :transition_identity_conflict} =
             DiscoveryVerificationGraph.append_with_archive(changed_evidence)
  end

  test "archive tampering is detectable" do
    id = :"tamper_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, updated} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               real_evidence()
             )

    [hash] = updated.archive_ids
    [{^hash, record}] = :dets.lookup(:tiannara_discovery_evidence_archive, hash)
    :dets.insert(:tiannara_discovery_evidence_archive, {hash, Map.put(record, :status, :tampered)})
    on_exit(fn -> restore_archive_record(hash, record) end)

    assert {:error, :archive_hash_mismatch} = DiscoveryEvidenceArchive.verify(hash)
    assert {:error, {:archive_binding_invalid, _node_id}} = DiscoveryVerificationGraph.verify_chain()
  end

  test "missing archive record blocks chain verification and transition reuse" do
    key = "missing-archive-#{System.unique_integer([:positive])}"
    node = %{
      kind: :discovery_validation_transition,
      discovery_id: key,
      transition_key: key,
      transition_payload_hash: "payload",
      provenance: %{source: :test},
      status: :reproduced,
      artifact: %{from: :candidate, to: :reproduced}
    }

    assert {:ok, %{graph: graph, archive: archive}} =
             DiscoveryVerificationGraph.append_with_archive(node)

    graph_id = graph.node_id
    archive_hash = archive.hash

    [{^archive_hash, original_archive}] = :dets.lookup(:tiannara_discovery_evidence_archive, archive_hash)
    on_exit(fn -> restore_archive_record(archive_hash, original_archive) end)

    assert :ok = :dets.delete(:tiannara_discovery_evidence_archive, archive_hash)

    assert {:error, :archive_not_found} = DiscoveryEvidenceArchive.get(archive_hash)
    assert {:error, :archive_not_found} = DiscoveryEvidenceArchive.verify(archive_hash)
    assert {:error, {:archive_binding_invalid, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()

    # Reusing the same logical transition must fail, never silently succeed
    # with a lost evidence archive.
    assert {:error, :existing_transition_archive_missing} =
             DiscoveryVerificationGraph.append_with_archive(node)

    # Retrying with different evidence is still an identity conflict.
    changed = Map.put(node, :transition_payload_hash, "payload-b")

    assert {:error, :transition_identity_conflict} =
             DiscoveryVerificationGraph.append_with_archive(changed)
  end

  test "corrupted graph node is detected during chain verification" do
    id = :"graph_tamper_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, promoted} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())

    [graph_id] = promoted.verification_graph_ids

    [{^graph_id, original_node}] = :dets.lookup(:tiannara_discovery_verification_graph, graph_id)
    on_exit(fn -> restore_graph_record(graph_id, original_node) end)

    assert :ok =
             :dets.insert(
               :tiannara_discovery_verification_graph,
               {graph_id, Map.put(original_node, :status, :tampered)}
             )

    assert {:error, {:hash_chain_invalid, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()
  end

  test "graph node loss fails chain verification and is recovered from the archive after restart" do
    key = "node-loss-#{System.unique_integer([:positive])}"
    node = %{
      kind: :discovery_validation_transition,
      discovery_id: key,
      transition_key: key,
      transition_payload_hash: "payload",
      provenance: %{source: :test},
      status: :reproduced,
      artifact: %{from: :candidate, to: :reproduced}
    }

    assert {:ok, %{graph: graph}} = DiscoveryVerificationGraph.append_with_archive(node)
    graph_id = graph.node_id

    [{^graph_id, original}] = :dets.lookup(:tiannara_discovery_verification_graph, graph_id)
    on_exit(fn -> restore_graph_record(graph_id, original) end)

    assert :ok = :dets.delete(:tiannara_discovery_verification_graph, graph_id)
    assert {:error, {:graph_node_missing, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()

    graph_pid = Process.whereis(DiscoveryVerificationGraph)
    Process.exit(graph_pid, :kill)
    Process.sleep(50)
    if Process.whereis(DiscoveryVerificationGraph) == nil, do: start_supervised!(DiscoveryVerificationGraph)

    assert {:ok, recovered} = DiscoveryVerificationGraph.get(graph_id)
    assert recovered.hash == graph.hash
    assert recovered.archive_hash == graph.archive_hash
    assert :ok = DiscoveryEvidenceArchive.verify(graph.archive_hash)
    assert :ok = DiscoveryVerificationGraph.verify_chain()
  end

  test "registry restart cannot reconcile a missing lineage archive" do
    id = :"dangling_archive_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, promoted} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())

    [graph_id] = promoted.verification_graph_ids
    [archive_hash] = promoted.archive_ids

    [{^archive_hash, original_archive}] = :dets.lookup(:tiannara_discovery_evidence_archive, archive_hash)
    on_exit(fn -> restore_archive_record(archive_hash, original_archive) end)

    assert :ok = :dets.delete(:tiannara_discovery_evidence_archive, archive_hash)

    # Restart the graph: orphan recovery must not fabricate the missing archive.
    graph_pid = Process.whereis(DiscoveryVerificationGraph)
    Process.exit(graph_pid, :kill)
    Process.sleep(50)
    if Process.whereis(DiscoveryVerificationGraph) == nil, do: start_supervised!(DiscoveryVerificationGraph)

    assert {:ok, node} = DiscoveryVerificationGraph.get(graph_id)
    assert node.archive_hash == archive_hash
    assert {:error, :archive_not_found} = DiscoveryEvidenceArchive.get(archive_hash)
    assert {:error, {:archive_binding_invalid, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()

    # Restart the registry: its own state restores, but the cross-store
    # inconsistency remains and cannot be replayed away.
    registry_pid = Process.whereis(DiscoveryRegistry)
    monitor = Process.monitor(registry_pid)
    GenServer.stop(registry_pid, :shutdown)
    assert_receive {:DOWN, ^monitor, :process, ^registry_pid, :shutdown}, 5_000

    new_pid =
      Enum.reduce_while(1..50, nil, fn _, _ ->
        case Process.whereis(DiscoveryRegistry) do
          pid when is_pid(pid) and pid != registry_pid -> {:halt, pid}
          _ ->
            Process.sleep(20)
            {:cont, nil}
        end
      end)

    assert is_pid(new_pid)
    assert {:ok, restored} = DiscoveryRegistry.get(id)
    assert restored.validation_status == :reproduced
    assert restored.verification_graph_ids == [graph_id]
    assert restored.archive_ids == [archive_hash]

    assert {:error, :archive_not_found} = DiscoveryEvidenceArchive.verify(archive_hash)
    assert {:error, {:archive_binding_invalid, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()

    assert {:error, :invalid_status_transition} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())
  end

  test "verification chain rejects sequence gaps even when the node hash is recomputed" do
    id = :"sequence_tamper_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, promoted} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, real_evidence())

    [graph_id] = promoted.verification_graph_ids
    [{^graph_id, original_node}] = :dets.lookup(:tiannara_discovery_verification_graph, graph_id)
    on_exit(fn -> restore_graph_record(graph_id, original_node) end)

    tampered =
      original_node
      |> Map.put(:sequence, original_node.sequence + 7)
      |> then(fn node ->
        hash =
          :crypto.hash(:sha256, :erlang.term_to_binary(Map.drop(node, [:hash, :archive_hash])))
          |> Base.encode16(case: :lower)

        Map.put(node, :hash, hash)
      end)

    assert :ok = :dets.insert(:tiannara_discovery_verification_graph, {graph_id, tampered})
    assert {:error, {:sequence_invalid, ^graph_id}} = DiscoveryVerificationGraph.verify_chain()
  end

  test "archive verification validates parent ancestry and rejects missing parents" do
    parent_record = %{
      id: "parent-#{System.unique_integer([:positive])}",
      kind: :test_evidence,
      status: :verified,
      artifact: %{source: :test},
      provenance: %{source: :integration_test}
    }

    assert {:ok, parent} = DiscoveryEvidenceArchive.append(parent_record)

    child_record = %{
      id: "child-#{System.unique_integer([:positive])}",
      kind: :test_evidence,
      status: :verified,
      artifact: %{source: :test},
      provenance: %{source: :integration_test}
    }

    assert {:ok, child} = DiscoveryEvidenceArchive.append(child_record, [parent])
    assert :ok = DiscoveryEvidenceArchive.verify(child.hash)

    parent_hash = parent.hash
    on_exit(fn -> restore_archive_record(parent_hash, parent) end)
    assert :ok = :dets.delete(:tiannara_discovery_evidence_archive, parent_hash)

    assert {:error, {:invalid_parent_archive, ^parent_hash, :archive_not_found}} =
             DiscoveryEvidenceArchive.verify(child.hash)

    assert {:error, {:invalid_parent_archive, ^parent_hash, :archive_not_found}} =
             DiscoveryEvidenceArchive.append(
               Map.put(child_record, :id, "child-referencing-missing-parent"),
               [parent]
             )
  end
end
