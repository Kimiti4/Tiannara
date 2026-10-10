defmodule TiannaraOS.Science.TheoryEvolutionEpistemicTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.Science.TheoryEvolution
  alias Tiannara.Sentinel.{DiscoveryEvidenceArchive, DiscoveryVerificationGraph}

  test "theory validation fails closed without graph/archive lineage" do
    assert TheoryEvolution.validate_theory("theory-1", %{}) == :rejected
    assert TheoryEvolution.validate_theory("theory-1", %{lineage: %{graph_id: "missing", archive_hash: "missing"}}) == :rejected
  end

  test "theory validation requires a matching persisted graph node" do
    unless Process.whereis(DiscoveryEvidenceArchive), do: start_supervised!(DiscoveryEvidenceArchive)
    unless Process.whereis(DiscoveryVerificationGraph), do: start_supervised!(DiscoveryVerificationGraph)

    assert {:ok, %{graph: graph, archive: archive}} =
             DiscoveryVerificationGraph.append_with_archive(%{
               kind: :theory_validation,
               discovery_id: "theory-source",
               theory_id: "theory-42",
               provenance: %{source: :test},
               status: :reproduced,
               artifact: %{claim: "test"}
             })

    assert archive.hash == graph.archive_hash
    assert TheoryEvolution.validate_theory("theory-42", %{
             lineage: %{graph_id: graph.node_id, archive_hash: archive.hash}
           }) == :validated

    assert TheoryEvolution.validate_theory("theory-other", %{
             lineage: %{graph_id: graph.node_id, archive_hash: archive.hash}
           }) == :rejected
  end
end
