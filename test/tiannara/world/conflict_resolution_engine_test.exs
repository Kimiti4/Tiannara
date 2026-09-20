defmodule Tiannara.World.ConflictResolutionEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{ConflictResolutionEngine, KnowledgeCoordinator, UnifiedWorldModel}

  setup do
    engine = Process.whereis(ConflictResolutionEngine)
    assert is_pid(engine), "ConflictResolutionEngine must be started by the application"
    {:ok, %{engine: engine}}
  end

  describe "Conflict Recording" do
    test "records a conflict between two entities" do
      entity_a = "test_conflict_a_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "test_conflict_b_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "Claim A")
      create_entity(entity_b, "Claim B (contradicts A)")

      conflict_spec = %{
        entity_ids: [entity_a, entity_b],
        domain: :physics,
        description: "Two contradictory claims about the same phenomenon",
        severity: :high,
        evidence: [%{type: :direct_contradiction}],
        requires_human_review: false
      }

      assert {:ok, conflict_id} = ConflictResolutionEngine.record_conflict(conflict_spec)
      assert String.starts_with?(conflict_id, "conflict_")
    end

    test "records a critical conflict requiring human review" do
      entity_a = "test_critical_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "test_critical_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "Critical claim A")
      create_entity(entity_b, "Critical claim B")

      conflict_spec = %{
        entity_ids: [entity_a, entity_b],
        domain: :governance,
        description: "Constitutional contradiction requiring human arbitration",
        severity: :critical,
        evidence: [%{type: :constitutional_conflict}],
        requires_human_review: true
      }

      assert {:ok, _conflict_id} = ConflictResolutionEngine.record_conflict(conflict_spec)
    end
  end

  describe "Conflict Resolution" do
    test "resolves via deprecating lower confidence entity" do
      entity_a = "test_resolve_dep_a_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "test_resolve_dep_b_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "High confidence claim", 0.9)
      create_entity(entity_b, "Low confidence claim", 0.3)

      {:ok, conflict_id} = ConflictResolutionEngine.record_conflict(%{
        entity_ids: [entity_a, entity_b],
        domain: :physics,
        description: "Confidence-based conflict",
        severity: :medium,
        evidence: [%{type: :confidence_gap}],
        requires_human_review: false
      })

      assert {:ok, resolved} = ConflictResolutionEngine.resolve_conflict(conflict_id, {:deprecate_lower_confidence, entity_b})
      assert resolved.status == :resolved
    end

    test "resolves via requesting human review" do
      entity_a = "test_resolve_human_a_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "test_resolve_human_b_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "Claim requiring human review")
      create_entity(entity_b, "Counterclaim")

      {:ok, conflict_id} = ConflictResolutionEngine.record_conflict(%{
        entity_ids: [entity_a, entity_b],
        domain: :ethics,
        description: "Ethical dilemma requiring human judgment",
        severity: :high,
        evidence: [%{type: :value_conflict}],
        requires_human_review: false
      })

      assert {:ok, resolved} = ConflictResolutionEngine.resolve_conflict(conflict_id, :request_human_review)
      assert resolved.status == :resolved
    end
  end

  describe "Active Conflicts Query" do
    test "lists active conflicts" do
      entity_a = "test_active_a_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "test_active_b_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "Active A")
      create_entity(entity_b, "Active B")
      ConflictResolutionEngine.record_conflict(%{
        entity_ids: [entity_a, entity_b], domain: :test,
        description: "Active conflict", severity: :low,
        evidence: [], requires_human_review: false
      })

      assert length(elem(ConflictResolutionEngine.active_conflicts(), 1)) >= 1
    end
  end

  describe "Stats" do
    test "returns engine statistics" do
      assert %{healthy: true} = elem(ConflictResolutionEngine.stats(), 1)
    end
  end

  defp create_entity(id, content, confidence \\ 0.7) do
    KnowledgeCoordinator.ingest_discovery(%{
      id: id, type: :hypothesis,
      attributes: %{claim: content},
      evidence: [%{source: "test", confidence: confidence}],
      confidence: confidence,
      provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
    })
  end
end
