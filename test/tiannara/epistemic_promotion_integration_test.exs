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

    assert {:ok, operational} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :operationally_validated, real_evidence())

    assert operational.validation_status == :operationally_validated
    assert length(operational.lifecycle_events) == 2
    assert length(operational.verification_graph_ids) == 2
    assert length(operational.archive_ids) == 2

    [graph_id | _] = operational.verification_graph_ids
    [archive_hash | _] = operational.archive_ids

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

    assert {:error, :archive_hash_mismatch} = DiscoveryEvidenceArchive.verify(hash)
    assert {:error, {:archive_binding_invalid, _node_id}} = DiscoveryVerificationGraph.verify_chain()
  end
end
