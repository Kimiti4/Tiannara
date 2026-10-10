defmodule TiannaraRuntime.WorldModel.ModelRegistryEpistemicTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias Tiannara.Sentinel.DiscoveryVerificationGraph

  setup do
    ModelRegistry.reset_table()
    unless Process.whereis(Tiannara.Sentinel.DiscoveryEvidenceArchive), do: start_supervised!(Tiannara.Sentinel.DiscoveryEvidenceArchive)
    unless Process.whereis(DiscoveryVerificationGraph), do: start_supervised!(DiscoveryVerificationGraph)
    :ok
  end

  defp model(id) do
    %{
      model_id: id,
      version: 1,
      name: "test model",
      domain: :physics,
      status: :draft,
      fingerprint: "fp-#{id}",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  test "status cannot be seeded or mutated outside transition gate" do
    assert {:error, :initial_model_must_be_draft} =
             ModelRegistry.store_model(%{model("bad") | status: :validated})

    assert {:ok, _} = ModelRegistry.store_model(model("m1"))

    assert {:error, :status_changes_require_transition_api} =
             ModelRegistry.update_model("m1", 1, status: :validated)

    assert {:error, :epistemic_evidence_required} =
             ModelRegistry.transition_status("m1", 1, :validated)
  end

  test "validated transition requires persisted graph and archive lineage" do
    assert {:ok, _} = ModelRegistry.store_model(model("m2"))

    assert {:ok, %{graph: graph, archive: archive}} =
             DiscoveryVerificationGraph.append_with_archive(%{
               kind: :world_model_validation,
               discovery_id: "m2",
               model_id: "m2",
               model_version: 1,
               provenance: %{source: :test},
               status: :validated,
               artifact: %{result: :pass}
             })

    assert {:ok, updated} =
             ModelRegistry.transition_status("m2", 1, :validated, %{
               evidence_class: :real,
               execution_mode: :real_execution,
               lineage: %{graph_id: graph.node_id, archive_hash: archive.hash}
             })

    assert updated.status == :validated
    assert updated.verification_graph_ids == [graph.node_id]
    assert updated.archive_ids == [archive.hash]
  end
end
