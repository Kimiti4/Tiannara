defmodule Tiannara.World.Integration.CrossDomainPipelineTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.{
    UnifiedWorldModel, UnifiedRealityGraph, WorldMutationEngine,
    ProvenanceEngine, ConflictResolutionEngine, KnowledgeCoordinator
  }
  import Tiannara.Test.Phase3Helpers

  describe "Cross-domain scientific workflow" do
    test "knowledge entities build on each other across domains" do
      physics = build_entity_spec(:knowledge, :fact, :measurement, %{value: "speed_of_light = 299792458 m/s"}, confidence: 0.99)
      biology = build_entity_spec(:knowledge, :hypothesis, :mechanism, %{
        hypothesis: "Neural signal propagation speed is near c",
        depends_on: physics.id
      }, confidence: 0.5)
      psychology = build_entity_spec(:knowledge, :hypothesis, :cognitive, %{
        experiment: "Measure reaction time vs distance",
        depends_on: biology.id
      }, confidence: 0.4)

      {:ok, pid} = UnifiedWorldModel.create_entity(physics)
      {:ok, bid} = UnifiedWorldModel.create_entity(biology)
      {:ok, psyid} = UnifiedWorldModel.create_entity(psychology)

      assert {:ok, _p} = UnifiedWorldModel.get_entity(pid)
      assert {:ok, _b} = UnifiedWorldModel.get_entity(bid)
      assert {:ok, _ps} = UnifiedWorldModel.get_entity(psyid)

      ev1 = %{source: "light_speed_experiment", value: 0.99, weight: 1.0}
      ev2 = %{source: "neural_imaging", value: 0.72, weight: 0.8}
      ev3 = %{source: "reaction_time_study", value: 0.68, weight: 0.75}

      UnifiedWorldModel.update_entity(pid, %{evidence: [ev1]})
      UnifiedWorldModel.update_entity(bid, %{evidence: [ev2]})
      UnifiedWorldModel.update_entity(psyid, %{evidence: [ev3]})

      assert {:ok, promoted_p} = KnowledgeCoordinator.promote_to_knowledge(pid)
      assert promoted_p.status == :promoted

      assert {:ok, promoted_b} = KnowledgeCoordinator.promote_to_knowledge(bid)
      assert promoted_b.status == :promoted

      assert {:ok, promoted_psy} = KnowledgeCoordinator.promote_to_knowledge(psyid)
      assert promoted_psy.status == :promoted
    end
  end
end
