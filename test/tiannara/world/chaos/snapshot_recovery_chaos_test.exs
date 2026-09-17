defmodule Tiannara.World.Chaos.SnapshotRecoveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{SnapshotManager, UnifiedWorldModel}
  import Tiannara.Test.Phase3Helpers

  @moduletag :chaos
  @moduletag timeout: 60_000

  describe "Snapshot and recovery under chaos" do
    test "can take snapshot mid-stream, crash, and recover with data intact" do
      entities =
        Enum.map(1..5, fn i ->
          spec = build_entity_spec(:knowledge, :fact, :data, %{chaos_value: i},
            id: unique_id("chaos_entity"), confidence: 0.5 + i * 0.1)
          {:ok, id} = UnifiedWorldModel.create_entity(spec)
          id
        end)

      assert {:ok, snapshot_id} = SnapshotManager.create_snapshot(:world_model, %{reason: :chaos_test})
      assert is_binary(snapshot_id)

      for eid <- entities do
        UnifiedWorldModel.update_entity(eid, %{chaos_field: "corrupted"})
      end

      for eid <- entities do
        UnifiedWorldModel.delete_entity(eid)
      end

      for eid <- entities do
        refute_entity_exists(eid)
      end

      assert :ok = SnapshotManager.restore_from_snapshot(snapshot_id)

      for eid <- entities do
        assert {:ok, restored} = UnifiedWorldModel.get_entity(eid)
        refute Map.has_key?(restored, :chaos_field)
        assert restored.status == :active
      end
    end

    test "multiple snapshots are independently recoverable" do
      s1_id = unique_id("snap_a")
      s2_id = unique_id("snap_b")

      e1 = build_entity_spec(:physics, :fact, :constant, %{value: "snap_a_val"}, id: unique_id("e1_snap"), confidence: 0.9)
      {:ok, e1_id} = UnifiedWorldModel.create_entity(e1)

      assert {:ok, snap1} = SnapshotManager.create_snapshot(:world_model, %{label: s1_id})
      assert snap1 != nil

      e2 = build_entity_spec(:physics, :fact, :constant, %{value: "snap_b_val"}, id: unique_id("e2_snap"), confidence: 0.8)
      {:ok, e2_id} = UnifiedWorldModel.create_entity(e2)

      assert {:ok, snap2} = SnapshotManager.create_snapshot(:world_model, %{label: s2_id})

      UnifiedWorldModel.delete_entity(e1_id)
      UnifiedWorldModel.delete_entity(e2_id)

      assert :ok = SnapshotManager.restore_from_snapshot(snap1)
      assert_entity_exists(e1_id)
      refute_entity_exists(e2_id)

      assert :ok = SnapshotManager.restore_from_snapshot(snap2)
      assert_entity_exists(e1_id)
      assert_entity_exists(e2_id)
    end
  end
end
