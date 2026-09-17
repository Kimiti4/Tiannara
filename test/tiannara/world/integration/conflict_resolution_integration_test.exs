defmodule Tiannara.World.Integration.ConflictResolutionIntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{ConflictResolutionEngine, UnifiedWorldModel, UnifiedRealityGraph}
  import Tiannara.Test.Phase3Helpers

  setup do
    base_id = unique_id("base")
    challenger_id = unique_id("challenger")
    domain = :physics

    base = build_entity_spec(domain, :fact, :measurement, %{value: 9.81, unit: "m/s^2"}, id: base_id, confidence: 0.9)
    challenger = build_entity_spec(domain, :fact, :measurement, %{value: 9.83, unit: "m/s^2"}, id: challenger_id, confidence: 0.65)

    {:ok, ^base_id} = UnifiedWorldModel.create_entity(base)
    {:ok, ^challenger_id} = UnifiedWorldModel.create_entity(challenger)

    %{base_id: base_id, challenger_id: challenger_id, domain: domain, base: base, challenger: challenger}
  end

  describe "Conflict detection and resolution" do
    test "detects conflicting measurements on same metric", %{base_id: bid, challenger_id: cid} do
      assert {:ok, %{conflict_type: :measurement_discrepancy, entities: [bid, cid]}} =
        ConflictResolutionEngine.detect_conflict(bid, cid)
    end

    test "resolves conflict in favor of higher-confidence entity", %{base_id: bid, challenger_id: cid} do
      assert {:ok, resolution} = ConflictResolutionEngine.resolve(bid, cid, strategy: :confidence_weighted)
      assert resolution.resolution == :override
      assert resolution.winner_id == bid
      assert resolution.loser_id == cid
    end

    test "merges provenance on resolution", %{base_id: bid, challenger_id: cid} do
      assert {:ok, resolution} = ConflictResolutionEngine.resolve(bid, cid, strategy: :merge)
      assert resolution.resolution == :merge
      assert resolution.merged_entity_id != bid
      assert resolution.merged_entity_id != cid
    end
  end
end
