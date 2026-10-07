defmodule Tiannara.Discoveries.PromotionGateTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discoveries.Discovery
  alias Tiannara.Sentinel.DiscoveryVerificationGraph

  setup do
    unless Process.whereis(Tiannara.Sentinel.DiscoveryEvidenceArchive), do: start_supervised!(Tiannara.Sentinel.DiscoveryEvidenceArchive)
    unless Process.whereis(DiscoveryVerificationGraph), do: start_supervised!(DiscoveryVerificationGraph)
    :ok
  end

  defp lineage_for(id, target) do
    assert {:ok, %{graph: graph, archive: archive}} =
             DiscoveryVerificationGraph.append_with_archive(%{
               kind: :discovery_promotion,
               discovery_id: id,
               provenance: %{source: :promotion_gate_test},
               status: target,
               artifact: %{claim: id}
             })

    %{evidence_class: :real, execution_mode: :real_execution,
      lineage: %{graph_id: graph.node_id, archive_hash: archive.hash}}
  end

  test "legacy promotion API fails closed" do
    disc = %Discovery{id: "legacy", status: :observation, confidence: 0.8,
      worlds_evidence: 600, operational_runs_evidence: 60}
    assert Discovery.promote(disc) == {:error, :promotion_requires_lineage}
  end

  test "supported_law promotion requires durable lineage" do
    disc = %Discovery{id: "disc1", name: "Decay Speedup", confidence: 0.80,
      worlds_evidence: 600, operational_runs_evidence: 10, claim: "Fast decay enhances resilience",
      status: :observation}
    evidence = lineage_for(disc.id, :supported_law)
    {:ok, promoted} = Discovery.promote(disc, evidence)
    assert promoted.status == :supported_law
    assert length(promoted.verification_graph_ids) == 1
    assert length(promoted.archive_ids) == 1
  end

  test "candidate_law promotion requires durable lineage" do
    disc = %Discovery{id: "disc2", name: "Identity Anchor", confidence: 0.65,
      worlds_evidence: 120, operational_runs_evidence: 5, claim: "Static identity stabilizes system",
      status: :observation}
    evidence = lineage_for(disc.id, :candidate_law)
    {:ok, promoted} = Discovery.promote(disc, evidence)
    assert promoted.status == :candidate_law
  end

  test "validated promotion requires real evidence and durable lineage" do
    disc = %Discovery{id: "disc3", name: "Causal Loop Prevention", confidence: 0.50,
      worlds_evidence: 50, operational_runs_evidence: 60, claim: "Loop detection prevents stack collapse",
      status: :observation}
    evidence = lineage_for(disc.id, :validated)
    {:ok, promoted} = Discovery.promote(disc, evidence)
    assert promoted.status == :validated
  end

  test "validated promotion rejects simulated evidence" do
    disc = %Discovery{id: "disc4", confidence: 0.8,
      worlds_evidence: 50, operational_runs_evidence: 60, status: :observation}
    evidence = Map.put(lineage_for(disc.id, :validated), :evidence_class, :simulated)
    assert Discovery.promote(disc, evidence) == {:error, :real_evidence_required}
  end
end
