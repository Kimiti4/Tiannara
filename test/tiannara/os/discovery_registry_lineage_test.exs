defmodule TiannaraOS.DiscoveryRegistryLineageTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.DiscoveryRegistry

  setup do
    case Process.whereis(DiscoveryRegistry) do
      nil ->
        {:ok, _pid} = DiscoveryRegistry.start_link([])

      _pid ->
        :ok
    end

    :ok
  end

  defp register_discovery(id) do
    DiscoveryRegistry.register(%{
      id: id,
      name: "lineage regression",
      domain_id: :verification,
      experiment_ids: ["exp-#{id}"],
      evidence_ids: ["ev-#{id}"],
      theory_ids: [:theory],
      evidence_envelope: %{
        evidence_class: :simulated,
        execution_mode: :simulation
      }
    })
  end

  test "legacy validation API cannot promote a discovery" do
    id = :"lineage_legacy_#{System.unique_integer([:positive])}"
    assert {:ok, discovery} = register_discovery(id)
    assert discovery.validation_status == :simulated

    assert {:error, :validation_transition_requires_lineage} =
             DiscoveryRegistry.update_validation_status(
               id,
               :reproduced,
               %{reproduction_evidence: %{replications: 2}}
             )

    assert {:ok, unchanged} = DiscoveryRegistry.get(id)
    assert unchanged.validation_status == :simulated
    assert unchanged.lifecycle_events == []
  end

  test "lineage failure prevents registry promotion and leaves state unchanged" do
    id = :"lineage_failure_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register_discovery(id)

    writer = fn _node ->
      {:error, :archive_unavailable}
    end

    evidence = %{reproduction_evidence: %{replications: 3}}

    assert {:error, {:lineage_write_failed, :archive_unavailable}} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               evidence,
               writer
             )

    assert {:ok, unchanged} = DiscoveryRegistry.get(id)
    assert unchanged.validation_status == :simulated
    assert unchanged.lifecycle_events == []
  end

  test "successful promotion creates exactly one lineage transition" do
    id = :"lineage_success_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register_discovery(id)

    writer = fn archived ->
      {:ok, Map.put(archived, :persisted, true)}
    end

    evidence = %{
      reproduction_evidence: %{replications: 3, independent_runs: true}
    }

    assert {:ok, updated} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :reproduced,
               evidence,
               writer
             )

    assert updated.validation_status == :reproduced
    assert length(updated.lifecycle_events) == 1

    [event] = updated.lifecycle_events
    assert event.event == :validation_updated
    assert event.from == :simulated
    assert event.to == :reproduced
    assert event.lineage.graph_id
    assert event.lineage.archive_hash
    assert updated.verification_graph_ids == [event.lineage.graph_id]
    assert updated.archive_ids == [event.lineage.archive_hash]
    assert :ok = Tiannara.Sentinel.DiscoveryVerificationGraph.verify_chain()
  end

  test "operational promotion requires real evidence and lineage" do
    id = :"lineage_operational_#{System.unique_integer([:positive])}"
    assert {:ok, _} = register_discovery(id)

    writer = fn archived ->
      {:ok, Map.put(archived, :persisted, true)}
    end

    assert {:error, :real_evidence_required} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               id,
               :operationally_validated,
               %{
                 evidence_class: :simulated,
                 execution_mode: :simulation,
                 real_observation: false,
                 effect_verified: false,
                 acl_status: :pass,
                 oavl_status: :pass
               },
               writer
             )

    assert {:ok, unchanged} = DiscoveryRegistry.get(id)
    assert unchanged.validation_status == :simulated
    assert unchanged.lifecycle_events == []
  end
end
