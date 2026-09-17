defmodule Tiannara.World.Integration.KnowledgePromotionIntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{KnowledgeCoordinator, UnifiedWorldModel, BeliefState}
  import Tiannara.Test.Phase3Helpers

  describe "Knowledge promotion pipeline" do
    test "entity with sufficient evidence and confidence is promoted" do
      spec = build_entity_spec(:knowledge, :fact, :validated, %{finding: "Earth orbits the Sun"},
        confidence: 0.95)
      {:ok, eid} = UnifiedWorldModel.create_entity(spec)

      for i <- 0..4 do
        UnifiedWorldModel.update_entity(eid, %{evidence: [%{source: "obs_#{i}", value: 0.95, weight: 0.9}]})
      end
      UnifiedWorldModel.transition_stage(eid, :information)
      UnifiedWorldModel.transition_stage(eid, :knowledge)
      UnifiedWorldModel.transition_stage(eid, :wisdom)

      assert {:ok, promoted} = KnowledgeCoordinator.promote_to_knowledge(eid)
      assert promoted.status == :promoted
      assert promoted.id == eid
    end

    test "entity with low confidence is not promoted" do
      spec = build_entity_spec(:knowledge, :fact, :speculative, %{finding: "Maybe..."},
        confidence: 0.3)
      {:ok, eid} = UnifiedWorldModel.create_entity(spec)
      assert {:error, :insufficient_confidence} = KnowledgeCoordinator.promote_to_knowledge(eid)
    end

    test "entity with insufficient evidence count is not promoted" do
      spec = build_entity_spec(:knowledge, :fact, :untested, %{finding: "Untested theory"},
        confidence: 0.9)
      {:ok, eid} = UnifiedWorldModel.create_entity(spec)
      UnifiedWorldModel.transition_stage(eid, :information)
      UnifiedWorldModel.transition_stage(eid, :knowledge)
      UnifiedWorldModel.transition_stage(eid, :wisdom)
      assert {:error, :insufficient_evidence} = KnowledgeCoordinator.promote_to_knowledge(eid)
    end
  end
end
