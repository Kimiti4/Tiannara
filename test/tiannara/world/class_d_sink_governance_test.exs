defmodule Tiannara.World.ClassDSinkGovernanceTest do
  use ExUnit.Case, async: false

  # Step-12 §8 rows "S08 coordinator" and "S10 snapshot": the M5 write-order
  # migration (authorize BEFORE graph write) for the two Class-D sinks that
  # still wrote first or ungated. Each test proves both phases: under council
  # emergency nothing is written and nothing crashes; after the lift the very
  # same operation writes exactly what it authorized.

  alias Tiannara.Council
  alias Tiannara.World.{RealityCoordinator, SnapshotManager, UnifiedRealityGraph,
                        UnifiedWorldModel, WorldMutationEngine}
  import Tiannara.Test.Phase3Helpers

  @moduletag timeout: 30_000

  defmodule StubAdapter do
    @behaviour Tiannara.World.GraphAdapter

    @impl true
    def pull_graph(opts, _offset),
      do: {:ok, %{entities: Map.get(opts, :entities, []), offset: 1}}

    @impl true
    def push_entity(_entity, _opts), do: {:ok, :pushed}

    @impl true
    def current_offset(_opts), do: {:ok, 1}

    @impl true
    def metadata, do: %{name: "class_d_stub"}
  end

  setup do
    unless Process.whereis(RealityCoordinator) do
      start_supervised!(RealityCoordinator)
    end

    on_exit(fn ->
      if Process.whereis(Council) do
        _ = Council.lift_emergency(:class_d_sink_test)
      end
    end)

    :ok
  end

  defp stub_entity(id, attrs, confidence) do
    %{
      id: id,
      type: :knowledge_entity,
      subtype: :fact,
      attributes: attrs,
      confidence: confidence,
      uncertainty: 1.0 - confidence,
      provenance: %{source: :class_d_test},
      relationships: []
    }
  end

  defp with_adapter(adapter_id, opts, fun) do
    :ok = RealityCoordinator.register_adapter(adapter_id, StubAdapter, opts)

    try do
      fun.()
    after
      :ok = RealityCoordinator.unregister_adapter(adapter_id)
    end
  end

  test "S08: emergency refuses graph_migration with no write and no crash; after the lift the write lands" do
    entity = stub_entity(unique_id("s08_notfound"), %{s08: "seed"}, 0.9)

    with_adapter(:s08_refusal, %{entities: [entity]}, fn ->
      :ok = Council.invoke_emergency(:class_d_sink_test, "S08 M5-order probe")

      try do
        assert {:ok, refused} = RealityCoordinator.migrate_graph(:s08_refusal)
        assert refused.mutation_ids == []
        assert {:error, :not_found} = UnifiedRealityGraph.get_entity(entity.id)
      after
        :ok = Council.lift_emergency(:class_d_sink_test)
      end

      assert {:ok, allowed} = RealityCoordinator.migrate_graph(:s08_refusal)
      assert [mutation_id] = allowed.mutation_ids
      assert is_binary(mutation_id)
      assert {:ok, written} = UnifiedRealityGraph.get_entity(entity.id)
      assert written.id == entity.id
      assert written.attributes == %{s08: "seed"}
    end)
  end

  test "S08: source_wins conflict authorizes first — emergency defers with the old data intact, lift rewrites" do
    entity_id = unique_id("s08_conflict")
    original = stub_entity(entity_id, %{s08: "v1"}, 0.9)
    incoming = stub_entity(entity_id, %{s08: "v2"}, 0.9)
    assert {:ok, ^entity_id} = UnifiedRealityGraph.add_entity(original)

    with_adapter(:s08_source_wins, %{entities: [incoming], conflict_policy: :source_wins}, fn ->
      :ok = Council.invoke_emergency(:class_d_sink_test, "S08 conflict probe")

      try do
        assert {:ok, refused} = RealityCoordinator.migrate_graph(:s08_source_wins)
        assert refused.mutation_ids == []
        assert {:ok, kept} = UnifiedRealityGraph.get_entity(entity_id)
        assert kept.attributes == %{s08: "v1"}
      after
        :ok = Council.lift_emergency(:class_d_sink_test)
      end

      assert {:ok, allowed} = RealityCoordinator.migrate_graph(:s08_source_wins)
      assert [_mutation_id] = allowed.mutation_ids
      assert {:ok, rewritten} = UnifiedRealityGraph.get_entity(entity_id)
      assert rewritten.attributes == %{s08: "v2"}
    end)
  end

  test "S10: emergency refuses snapshot restore with no writes; after the lift restore returns :ok and records the mutation" do
    spec =
      build_entity_spec(:knowledge, :fact, :data, %{s10: "seed"},
        id: unique_id("s10_entity"),
        confidence: 0.8
      )

    {:ok, entity_id} = UnifiedWorldModel.create_entity(spec)
    assert {:ok, snapshot_id} = SnapshotManager.create_snapshot(:world_model, %{reason: :s10_probe})

    UnifiedWorldModel.delete_entity(entity_id, mint_delete_authorization(entity_id))
    refute_entity_exists(entity_id)

    :ok = Council.invoke_emergency(:class_d_sink_test, "S10 restore probe")

    try do
      assert {:error, {:restore_not_authorized, _reason}} =
               SnapshotManager.restore_from_snapshot(snapshot_id)

      # nothing was written back
      refute_entity_exists(entity_id)
    after
      :ok = Council.lift_emergency(:class_d_sink_test)
    end

    assert :ok = SnapshotManager.restore_from_snapshot(snapshot_id)
    assert_entity_exists(entity_id)

    assert WorldMutationEngine.history(limit: 100_000)
           |> Enum.any?(&(&1.type == :snapshot_restore))
  end
end
