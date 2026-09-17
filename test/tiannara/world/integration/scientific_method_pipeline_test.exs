defmodule Tiannara.World.Integration.ScientificMethodPipelineTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.{
    UnifiedWorldModel, UnifiedRealityGraph, WorldMutationEngine,
    ProvenanceEngine, VersionManager, ConflictResolutionEngine,
    KnowledgeCoordinator, CanonicalWorldState, BeliefState,
    SnapshotManager, OntologyManager
  }
  import Tiannara.Test.Phase3Helpers

  setup do
    test_id = unique_id("pipeline")
    domain = :knowledge
    entity_spec = build_entity_spec(domain, :hypothesis, :testable, %{question: "What is the meaning of life?", prediction: "42"})
    {:ok, entity_id} = UnifiedWorldModel.create_entity(entity_spec)
    %{test_id: test_id, entity_id: entity_id, domain: domain, spec: entity_spec}
  end

  describe "Full scientific method pipeline" do
    test "hypothesis -> experiment -> analysis -> conclusion -> knowledge promotion", %{entity_id: eid, test_id: tid} do
      assert {:ok, entity} = UnifiedWorldModel.get_entity(eid)
      assert entity.status == :active
      assert entity.subtype == :testable

      ev1 = %{metric: :confidence, value: 0.75, weight: 0.8, source: tid}
      ev2 = %{metric: :confidence, value: 0.85, weight: 0.9, source: tid}
      assert :ok = UnifiedWorldModel.update_entity(eid, %{evidence: [ev1, ev2]})
      assert :ok = UnifiedWorldModel.transition_stage(eid, :information)
      assert {:ok, e1} = UnifiedWorldModel.get_entity(eid)
      assert e1.subtype == :information

      analysis = %{method: :statistical, result: "Confidence increased by 10%", p_value: 0.01}
      assert :ok = UnifiedWorldModel.update_entity(eid, %{analysis: analysis})
      assert :ok = UnifiedWorldModel.transition_stage(eid, :knowledge)
      assert {:ok, e2} = UnifiedWorldModel.get_entity(eid)
      assert e2.subtype == :knowledge

      assertion = %{conclusion: "The answer is 42", confidence: 0.85, uncertainty: 0.15}
      assert :ok = UnifiedWorldModel.update_entity(eid, %{assertion: assertion})
      assert :ok = UnifiedWorldModel.transition_stage(eid, :pattern)
      assert {:ok, e3} = UnifiedWorldModel.get_entity(eid)
      assert e3.subtype == :pattern

      assert {:ok, promoted} = KnowledgeCoordinator.promote_to_knowledge(eid)
      assert promoted.status == :promoted
    end
  end
end
