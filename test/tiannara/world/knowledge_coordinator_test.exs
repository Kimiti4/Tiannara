defmodule Tiannara.World.KnowledgeCoordinatorTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{KnowledgeCoordinator, UnifiedWorldModel}

  setup do
    {:ok, coordinator} = start_supervised(KnowledgeCoordinator)
    {:ok, %{coordinator: coordinator}}
  end

  describe "Discovery Ingestion" do
    test "ingests a raw observation" do
      discovery_id = "test_obs_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: discovery_id,
        type: :observation,
        attributes: %{claim: "Test observation"},
        evidence: [%{source: "test", confidence: 0.8}],
        confidence: 0.6,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      assert {:ok, ^discovery_id} = KnowledgeCoordinator.ingest_discovery(spec)
    end

    test "ingests a hypothesis" do
      discovery_id = "test_hyp_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: discovery_id,
        type: :hypothesis,
        attributes: %{statement: "Test hypothesis"},
        evidence: [%{source: "test", confidence: 0.7}],
        confidence: 0.5,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      assert {:ok, ^discovery_id} = KnowledgeCoordinator.ingest_discovery(spec)

      {:ok, entity} = UnifiedWorldModel.get_entity(discovery_id)
      assert entity.confidence == 0.5
    end

    test "ingests with metadata tracking" do
      discovery_id = "test_meta_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: discovery_id,
        type: :experimental_result,
        attributes: %{result: 42},
        evidence: [%{source: "lab", confidence: 0.9}],
        confidence: 0.8,
        provenance: %{origin: :test, produced_by: :lab_equipment, produced_at: DateTime.utc_now()}
      }

      assert {:ok, ^discovery_id} = KnowledgeCoordinator.ingest_discovery(spec)
    end
  end

  describe "Evidence Fusion" do
    test "increases confidence with corroborating evidence" do
      entity_id = "test_fuse_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :hypothesis,
        attributes: %{statement: "Fuse test"},
        evidence: [%{source: "initial", confidence: 0.5}],
        confidence: 0.5,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      new_evidence = [%{source: "experiment_1", confidence: 0.9}]
      assert {:ok, new_conf} = KnowledgeCoordinator.fuse_evidence(entity_id, new_evidence, 1.0)
      assert new_conf > 0.5
    end

    test "handles empty evidence gracefully" do
      entity_id = "test_fuse_empty_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :hypothesis,
        attributes: %{statement: "Empty fuse test"},
        evidence: [],
        confidence: 0.5,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      assert {:ok, _} = KnowledgeCoordinator.fuse_evidence(entity_id, [], 0.0)
    end

    test "preserves existing evidence chain" do
      entity_id = "test_fuse_chain_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :hypothesis,
        attributes: %{statement: "Chain test"},
        evidence: [%{source: "initial", confidence: 0.5}],
        confidence: 0.5,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      KnowledgeCoordinator.fuse_evidence(entity_id, [%{source: "second", confidence: 0.8}], 0.5)

      {:ok, entity} = UnifiedWorldModel.get_entity(entity_id)
      evidence = case entity.attributes do
        %{evidence: ev} when is_list(ev) -> ev
        _ -> []
      end

      assert length(evidence) >= 2
    end
  end

  describe "Memory Stage Promotion" do
    test "promotes from data to information" do
      entity_id = "test_promote_1_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :observation,
        attributes: %{data: "raw data"},
        evidence: [%{source: "test", confidence: 0.8}],
        confidence: 0.7,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      assert {:ok, :information} = KnowledgeCoordinator.promote_memory_stage(entity_id, :information)
    end

    test "rejects promotion to same or lower stage" do
      entity_id = "test_promote_same_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :pattern,
        attributes: %{pattern: "test"},
        evidence: [%{source: "test", confidence: 0.9}],
        confidence: 0.8,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      assert {:error, :target_stage_not_higher} = KnowledgeCoordinator.promote_memory_stage(entity_id, :data)
    end

    test "requires human review for high-impact promotion to principle" do
      entity_id = "test_promote_principle_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :model,
        attributes: %{model: "test model"},
        evidence: [%{source: "test", confidence: 0.95}],
        confidence: 0.95,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      context = %{impact_level: :high}
      assert {:error, {:requires_human_review, _}} = KnowledgeCoordinator.promote_memory_stage(entity_id, :principle, context)
    end

    test "allows direct promotion to principle for low-impact with human approval" do
      entity_id = "test_promote_approved_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: entity_id,
        type: :model,
        attributes: %{model: "approved model"},
        evidence: [%{source: "test", confidence: 0.95}],
        confidence: 0.95,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      context = %{human_approved: true}
      assert {:ok, :principle} = KnowledgeCoordinator.promote_memory_stage(entity_id, :principle, context)
    end
  end

  describe "Stats Reporting" do
    test "returns coordinator statistics" do
      assert {:ok, stats} = KnowledgeCoordinator.stats() |> then(fn s -> {:ok, s} end)

      entity_id = "test_stats_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
      spec = %{
        id: entity_id,
        type: :observation,
        attributes: %{stat: "test"},
        evidence: [],
        confidence: 0.5,
        provenance: %{origin: :test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      KnowledgeCoordinator.ingest_discovery(spec)
      assert %{total_knowledge_items: n} = elem(KnowledgeCoordinator.stats(), 1)
      assert n >= 1
    end
  end
end
