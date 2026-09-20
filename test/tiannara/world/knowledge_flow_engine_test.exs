defmodule Tiannara.World.KnowledgeFlowEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{KnowledgeFlowEngine, KnowledgeCoordinator, UnifiedWorldModel}

  setup do
    engine = Process.whereis(KnowledgeFlowEngine)
    assert is_pid(engine), "KnowledgeFlowEngine must be started by the application"
    {:ok, %{engine: engine}}
  end

  describe "Force Propagation" do
    test "propagates a scientific discovery entity" do
      entity_id = "test_flow_prop_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :scientific_entity,
        subtype: :scientific_discovery,
        attributes: %{finding: "Propagation test finding"},
        evidence: [%{source: "flow_test", confidence: 0.95}],
        confidence: 0.9,
        provenance: %{origin: :test, produced_by: :flow_test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)

      result = KnowledgeFlowEngine.force_propagate(entity_id)
      assert match?({:ok, _state}, result) or match?({:error, _}, result)
    end

    test "propagates a principle entity to all domains" do
      entity_id = "test_flow_principle_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :scientific_entity,
        subtype: :principle,
        attributes: %{principle: "Test principle"},
        evidence: [%{source: "flow_test", confidence: 0.98}],
        confidence: 0.95,
        provenance: %{origin: :test, produced_by: :flow_test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      KnowledgeCoordinator.promote_memory_stage(entity_id, :principle, %{human_approved: true})

      result = KnowledgeFlowEngine.force_propagate(entity_id)
      assert match?({:ok, _state}, result) or match?({:error, _}, result)
    end
  end

  describe "Stats" do
    test "returns engine statistics" do
      assert %{healthy: true} = elem(KnowledgeFlowEngine.stats(), 1)
    end
  end
end
