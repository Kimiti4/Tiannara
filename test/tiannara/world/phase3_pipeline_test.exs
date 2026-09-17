defmodule Tiannara.World.Phase3PipelineTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.{
    KnowledgeCoordinator, KnowledgeFlowEngine, ConflictResolutionEngine,
    UnifiedWorldModel
  }
  alias Tiannara.ValidationCampaigns
  alias Tiannara.Validation.Scenarios.Phase3

  setup do
    start_supervised(KnowledgeCoordinator)
    start_supervised(KnowledgeFlowEngine)
    start_supervised(ConflictResolutionEngine)
    start_supervised(ValidationCampaigns)
    :ok
  end

  describe "End-to-End: Scientific Method Pipeline" do
    @tag :phase3_pipeline
    test "full pipeline: observation -> ingestion -> fusion -> promotion -> propagation" do
      claim_id = "pipeline_obs_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

      spec = %{
        id: claim_id,
        type: :observation,
        attributes: %{claim: "Pipeline test observation"},
        evidence: [%{source: "pipeline_test", confidence: 0.7}],
        confidence: 0.6,
        provenance: %{origin: :pipeline_test, produced_by: :test, produced_at: DateTime.utc_now()}
      }

      assert {:ok, ^claim_id} = KnowledgeCoordinator.ingest_discovery(spec)

      new_evidence = [%{source: "corroborating_experiment", confidence: 0.9}]
      assert {:ok, new_conf} = KnowledgeCoordinator.fuse_evidence(claim_id, new_evidence, 1.0)
      assert new_conf > 0.6

      assert {:ok, :information} = KnowledgeCoordinator.promote_memory_stage(claim_id, :information)
      assert {:ok, :knowledge} = KnowledgeCoordinator.promote_memory_stage(claim_id, :knowledge)

      result = KnowledgeFlowEngine.force_propagate(claim_id)
      assert match?({:ok, _state}, result) or match?({:error, _}, result)

      {:ok, entity} = UnifiedWorldModel.get_entity(claim_id)
      assert entity.status == :active
    end

    @tag :phase3_pipeline
    test "full pipeline: conflict detection -> recording -> resolution" do
      entity_a = "pipeline_conflict_a_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"
      entity_b = "pipeline_conflict_b_#{:crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)}"

      create_entity(entity_a, "Claim: speed of light is constant in all frames", 0.95)
      create_entity(entity_b, "Claim: speed of light varies with quantum foam density", 0.6)

      {:ok, conflict_id} = ConflictResolutionEngine.record_conflict(%{
        entity_ids: [entity_a, entity_b],
        domain: :physics,
        description: "Contradictory claims about light propagation",
        severity: :high,
        evidence: [%{type: :direct_contradiction, detail: "One claims invariance, the other claims variance"}],
        requires_human_review: false
      })

      assert {:ok, resolved} = ConflictResolutionEngine.resolve_conflict(conflict_id, {:deprecate_lower_confidence, entity_b})
      assert resolved.status == :resolved
      assert length(resolved.resolution_history) == 1
    end
  end

  describe "Validation Campaigns Integration" do
    test "runs a full Phase 3 validation campaign" do
      {:ok, campaign_id} = Phase3.run_full_campaign()
      {:ok, campaign} = ValidationCampaigns.get_campaign(campaign_id)

      assert campaign.status == :defined
      assert length(campaign.scenarios) == 5
      assert campaign.name == "Phase 3 — Full Validation Campaign"
    end

    test "executes scenarios and collects results" do
      {:ok, campaign_id} = Phase3.run_full_campaign()
      {:ok, completed} = ValidationCampaigns.run_campaign(campaign_id)

      assert completed.status == :completed
      assert completed.total == 5
      assert completed.passed + completed.failed == completed.total
    end

    test "generates a campaign report" do
      {:ok, campaign_id} = Phase3.run_full_campaign()
      ValidationCampaigns.run_campaign(campaign_id)
      {:ok, report} = ValidationCampaigns.report(campaign_id)

      assert report.pass_rate >= 0.0
      assert report.pass_rate <= 1.0
      assert report.summary != ""
    end
  end

  defp create_entity(id, content, confidence \\ 0.7) do
    KnowledgeCoordinator.ingest_discovery(%{
      id: id, type: :hypothesis,
      attributes: %{claim: content},
      evidence: [%{source: "pipeline_test", confidence: confidence}],
      confidence: confidence,
      provenance: %{origin: :pipeline_test, produced_by: :test, produced_at: DateTime.utc_now()}
    })
  end
end
