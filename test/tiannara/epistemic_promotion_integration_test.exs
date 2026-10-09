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

    reproduction = %{reproduction_evidence: %{replications: 3, independent_runs: true}}

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

  test "all promotion attack paths fail closed" do
    id = :"attack_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:error, :reproduction_evidence_required} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, %{})

    assert {:error, :invalid_evidence_envelope} =
             DiscoveryRegistry.update_validation_status_with_lineage(id, :reproduced, %{evidence_class: :forged})

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
               %{reproduction_evidence: %{replications: 2}}
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

  test "archive tampering is detectable" do
    id = :"tamper_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register(id)

    assert {:ok, updated} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               %{reproduction_evidence: %{replications: 2}}
             )

    [hash] = updated.archive_ids
    [{^hash, record}] = :dets.lookup(:tiannara_discovery_evidence_archive, hash)
    :dets.insert(:tiannara_discovery_evidence_archive, {hash, Map.put(record, :status, :tampered)})

    assert {:error, :archive_hash_mismatch} = DiscoveryEvidenceArchive.verify(hash)
  end
end
