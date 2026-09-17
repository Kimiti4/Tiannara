defmodule Tiannara.CCI.CCITest do
  use ExUnit.Case, async: false

  setup do
    start_supervised!(Tiannara.CCI.Supervisor)
    :ok
  end

  describe "functional: civilization self-model" do
    test "maintains and updates civilization state" do
      state = Tiannara.CCI.CivilizationSelfModel.get_state(:cci_csm)
      assert state.health_score > 0
      assert state.knowledge_state.validated_assets == 0

      Tiannara.CCI.CivilizationSelfModel.update_state(:cci_csm, %{
        knowledge_state: %{validated_assets: 100, pending_validation: 20, principles: 10}
      })

      updated = Tiannara.CCI.CivilizationSelfModel.get_state(:cci_csm)
      assert updated.knowledge_state.validated_assets == 100
    end
  end

  describe "functional: constitutional governance" do
    test "evaluates proposals against constitutional principles" do
      proposal = %{id: "p1", type: :capability_deployment, description: "Deploy new energy capability"}

      {:ok, decision} = Tiannara.CCI.ConstitutionalGovernanceEngine.evaluate_proposal(:cci_cge, proposal)

      assert decision.decision == :pending_human_approval
      assert decision.requires_human_approval == true
      assert decision.constitutional_alignment > 0
      assert length(decision.audit_trail) > 0
    end

    test "records human decisions in audit trail" do
      proposal = %{id: "p2", type: :research_program, description: "Test"}
      {:ok, decision} = Tiannara.CCI.ConstitutionalGovernanceEngine.evaluate_proposal(:cci_cge, proposal)

      Tiannara.CCI.ConstitutionalGovernanceEngine.record_human_decision(:cci_cge, decision.id, :approved)

      updated = Tiannara.CCI.ConstitutionalGovernanceEngine.get_decision(:cci_cge, decision.id)
      assert updated.decision == :approved
      assert Enum.any?(updated.audit_trail, & &1.step == :human_decision)
    end
  end

  describe "functional: forecasting" do
    test "generates multiple possible futures" do
      civ_state = Tiannara.CCI.CivilizationSelfModel.get_state(:cci_csm)
      {:ok, forecast} = Tiannara.CCI.CivilizationForecastingEngine.forecast(:cci_cfe, civ_state, 50)

      assert length(forecast.possible_futures) >= 3
      assert forecast.confidence > 0 and forecast.confidence <= 1.0
      assert forecast.horizon_cycles == 50
    end
  end

  describe "functional: civilizational memory" do
    test "preserves failures as civilizational knowledge" do
      {:ok, record} = Tiannara.CCI.CivilizationalMemoryEngine.preserve(:cci_cme, %{
        type: :failure, domain: :materials,
        content: "Alloy composition failed under thermal stress",
        failure_mode: "insufficient_thermal_resistance"
      })

      assert record.type == :failure
      assert length(record.lessons_learned) > 0
      assert record.preservation_reason =~ "Prevent recurrence"
    end

    test "rejects invalid record types" do
      result = Tiannara.CCI.CivilizationalMemoryEngine.preserve(:cci_cme, %{
        type: :invalid_type, domain: :test, content: "test"
      })
      assert result == {:error, :invalid_type}
    end
  end

  describe "functional: civilization experiments" do
    test "experiments require simulation before trial" do
      {:ok, experiment} = Tiannara.CCI.CivilizationExperimentRuntime.propose_experiment(
        :cci_cxr, "Test governance reform", :governance_model
      )

      result = Tiannara.CCI.CivilizationExperimentRuntime.run_trial(:cci_cxr, experiment.id)
      assert result == {:error, :simulation_required}

      {:ok, _simulated} = Tiannara.CCI.CivilizationExperimentRuntime.run_simulation(:cci_cxr, experiment.id)
      {:ok, trialed} = Tiannara.CCI.CivilizationExperimentRuntime.run_trial(:cci_cxr, experiment.id)
      assert trialed.trial_phase == :completed
    end
  end

  describe "functional: risk intelligence" do
    test "detects civilizational risks" do
      civ_state = %Tiannara.CCI.Models.CivilizationState{
        id: "test", timestamp: DateTime.utc_now(),
        knowledge_state: %{validated_assets: 10, pending_validation: 5, principles: 2},
        capability_state: %{emerging: 30, promoted: 5, obsolete: 0},
        institutional_state: %{active: 2, forming: 0, declining: 0},
        resource_state: %{available: 500, allocated: 200, reserved: 50},
        risk_state: %{critical: 0, elevated: 0, nominal: 5},
        confidence: 0.7, health_score: 0.6
      }

      {:ok, assessment} = Tiannara.CCI.CivilizationRiskIntelligence.assess_risks(:cci_cri, civ_state)

      assert length(assessment.risks) > 0
      assert assessment.overall_risk_level in [:critical, :elevated, :moderate, :nominal]
    end
  end

  describe "constitutional: augments human intelligence" do
    test "all major decisions require human approval" do
      proposal = %{id: "p3", type: :institutional_reform, description: "Major reform"}
      {:ok, decision} = Tiannara.CCI.ConstitutionalGovernanceEngine.evaluate_proposal(:cci_cge, proposal)

      assert decision.requires_human_approval == true
      assert decision.decision == :pending_human_approval
    end

    test "experiments require human approval" do
      {:ok, experiment} = Tiannara.CCI.CivilizationExperimentRuntime.propose_experiment(
        :cci_cxr, "Test", :governance_model
      )
      assert experiment.human_approval == :pending
    end
  end

  describe "constitutional: evidence before confidence" do
    test "priorities include evidence and confidence" do
      civ_state = Tiannara.CCI.CivilizationSelfModel.get_state(:cci_csm)
      {:ok, priorities} = Tiannara.CCI.PriorityResearchEngine.recommend_priorities(:cci_pre, [], civ_state)

      assert length(priorities) > 0
      priority = hd(priorities)
      assert length(priority.evidence) > 0
      assert priority.confidence > 0 and priority.confidence <= 1.0
      assert length(priority.unknowns) > 0
      assert length(priority.alternatives) > 0
    end
  end

  describe "constitutional: verification first" do
    test "every experiment has rollback plan and failure conditions" do
      {:ok, experiment} = Tiannara.CCI.CivilizationExperimentRuntime.propose_experiment(
        :cci_cxr, "Test", :research_structure
      )

      assert experiment.rollback_plan != nil and experiment.rollback_plan != ""
      assert length(experiment.failure_conditions) > 0
      assert length(Map.keys(experiment.success_criteria)) > 0
    end
  end

  describe "integration: full civilizational cycle" do
    test "orchestrator produces comprehensive report" do
      report = Tiannara.CCI.Orchestrator.civilizational_cycle()

      assert report.civilization_state != nil
      assert report.risk_assessment != nil
      assert report.forecast != nil
      assert length(report.priorities) > 0
      assert report.requires_human_review == true
    end
  end
end
