defmodule Tiannara.ASC.Reality.DeploymentTest do
  use ExUnit.Case, async: false

  setup do
    for mod <- [
          Tiannara.ASC.Reality.DigitalDeploymentManager,
          Tiannara.ASC.Reality.Adapters.SimulatedAdapter,
          Tiannara.ASC.Reality.PhysicalDeploymentManager,
          Tiannara.ASC.Reality.Director,
          Tiannara.ASC.Reality.RiskAssessmentEngine,
          Tiannara.ASC.Reality.SafetyVerificationEngine,
          Tiannara.ASC.Reality.ComplianceEngine,
          Tiannara.ASC.Reality.IncidentResponseEngine,
          Tiannara.ASC.Reality.DeploymentAuditEngine,
          Tiannara.ASC.Reality.StagedRolloutManager,
          Tiannara.ASC.Reality.RollbackEngine,
          Tiannara.ASC.Reality.ResourceOptimizationEngine,
          Tiannara.ASC.Reality.InfrastructurePlanner,
          Tiannara.ASC.Reality.EnvironmentalImpactEngine
        ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    %{}
  end

  describe "DigitalDeploymentManager" do
    test "deploys artifact to digital target" do
      artifact = %{name: "test_service"}

      {:ok, deployment} =
        Tiannara.ASC.Reality.DigitalDeploymentManager.deploy("dep-dig-1", artifact, %{
          environment: :staging
        })

      assert deployment.status == :deployed
      assert deployment.environment == :staging
      assert length(deployment.execution_plan) > 0
    end

    test "deployment status returns correct data" do
      artifact = %{name: "test_service"}
      Tiannara.ASC.Reality.DigitalDeploymentManager.deploy("dep-dig-2", artifact, %{})
      status = Tiannara.ASC.Reality.DigitalDeploymentManager.get_deployment_status("dep-dig-2")

      assert status.id == "dep-dig-2"
      assert status.status == :deployed
    end

    test "lists digital artefacts" do
      Tiannara.ASC.Reality.DigitalDeploymentManager.deploy("dep-dig-3", %{name: "svc_a"}, %{})
      Tiannara.ASC.Reality.DigitalDeploymentManager.deploy("dep-dig-4", %{name: "svc_b"}, %{})

      artefacts = Tiannara.ASC.Reality.DigitalDeploymentManager.list_artefacts()
      assert length(artefacts) >= 2
    end
  end

  describe "PhysicalDeploymentManager" do
    test "plans a physical deployment with safety verification" do
      design = %{
        name: "test_embedded",
        type: :physical,
        steps: [:calibrate, :initialize, :run_diagnostics]
      }

      {:ok, deployment} = Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      assert deployment.stage == :planned
      assert deployment.safety_verification.passed == true
      assert deployment.summary.steps == 3
      assert deployment.approval == nil
    end

    test "staged lifecycle blocks machine advance at the human approval gate" do
      design = %{name: "gated_unit", type: :physical}
      {:ok, deployment} = Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      assert {:ok, %{stage: :safety_reviewed}} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      assert {:ok, %{stage: :pending_approval}} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      assert {:error, :requires_human_approval} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)
    end

    test "human approval unlocks the full lifecycle" do
      design = %{name: "approved_unit", type: :physical}
      {:ok, deployment} = Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)
      Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      {:ok, approved} =
        Tiannara.ASC.Reality.PhysicalDeploymentManager.approve(
          deployment.id,
          "tiannara-admin",
          "approved for sim"
        )

      assert approved.approval.decision == :approved

      assert {:ok, %{stage: :approved}} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      assert {:ok, %{stage: :simulated}} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      assert {:ok, _} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.execute(deployment.id, %{
                 action: :calibrate
               })

      for expected <- [:dry_run, :supervised, :autonomous, :completed] do
        assert {:ok, deployment} =
                 Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

        assert deployment.stage == expected
      end
    end

    test "rejection is terminal" do
      design = %{name: "rejected_unit", type: :physical}
      {:ok, deployment} = Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)
      Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)

      {:ok, rejected} =
        Tiannara.ASC.Reality.PhysicalDeploymentManager.reject(
          deployment.id,
          "tiannara-admin",
          "insufficient evidence"
        )

      assert rejected.stage == :rejected
      assert rejected.approval.decision == :rejected

      assert {:error, :terminal_stage} =
               Tiannara.ASC.Reality.PhysicalDeploymentManager.advance(deployment.id)
    end

    test "tracks deployments and exposes adapter info" do
      design = %{name: "tracked_unit", type: :physical}
      {:ok, deployment} = Tiannara.ASC.Reality.PhysicalDeploymentManager.plan(design)

      status = Tiannara.ASC.Reality.PhysicalDeploymentManager.get_deployment(deployment.id)
      assert status.id == deployment.id

      deployments = Tiannara.ASC.Reality.PhysicalDeploymentManager.list_deployments()
      assert Enum.any?(deployments, fn d -> d.id == deployment.id end)

      {:ok, info} = Tiannara.ASC.Reality.PhysicalDeploymentManager.adapter_info(deployment.id)
      assert info.capabilities.hardware == :simulated
      assert is_integer(info.status.estop_count)
    end
  end

  describe "RealityDirector physical routing" do
    test "routes physical deployments through the staged planner" do
      artifact = %{
        name: "bridge_test_rig",
        uncertainty_level: :medium,
        real_world_interaction: true
      }

      {status, _id, result} =
        Tiannara.ASC.Reality.Director.deploy(artifact, :physical, %{location: :test_facility})

      assert status == :deployed
      assert {:ok, pipeline} = result
      assert %{stage: :planned} = pipeline.details.execution
      assert pipeline.details.execution.safety_verification.passed == true
      assert pipeline.details.execution.type == :physical
    end
  end

  describe "StagedRolloutManager" do
    test "creates rollout plan with rings" do
      {:ok, plan} =
        Tiannara.ASC.Reality.StagedRolloutManager.plan(
          "rollout-1",
          %{name: "release_1"},
          :digital,
          %{}
        )

      assert plan.status == :planned
      assert length(plan.rings) == 4
      assert hd(plan.rings) == :canary_1_percent
    end

    test "advances through rollout rings" do
      Tiannara.ASC.Reality.StagedRolloutManager.plan(
        "rollout-2",
        %{name: "release_2"},
        :digital,
        %{}
      )

      {:ok, next_ring, _} = Tiannara.ASC.Reality.StagedRolloutManager.advance_ring("rollout-2")

      assert next_ring == :canary_5_percent
    end

    test "pause and resume rollout" do
      Tiannara.ASC.Reality.StagedRolloutManager.plan(
        "rollout-3",
        %{name: "release_3"},
        :digital,
        %{}
      )

      {:ok, paused} = Tiannara.ASC.Reality.StagedRolloutManager.pause_rollout("rollout-3")
      assert paused.status == :paused

      {:ok, resumed} = Tiannara.ASC.Reality.StagedRolloutManager.resume_rollout("rollout-3")
      assert resumed.status == :in_progress
    end
  end

  describe "RollbackEngine" do
    test "creates and lists snapshots" do
      {:ok, snapshot} = Tiannara.ASC.Reality.RollbackEngine.create_snapshot("dep-rollback-1")
      assert snapshot.deployment_id == "dep-rollback-1"

      snapshots = Tiannara.ASC.Reality.RollbackEngine.list_snapshots("dep-rollback-1")
      assert length(snapshots) == 1
    end

    test "rolls back to pre-deployment snapshot" do
      Tiannara.ASC.Reality.RollbackEngine.create_snapshot("dep-rollback-2")
      {:ok, rollback_record} = Tiannara.ASC.Reality.RollbackEngine.rollback("dep-rollback-2")

      assert rollback_record.status == :completed
      assert rollback_record.deployment_id == "dep-rollback-2"
    end

    test "tracks rollback history" do
      Tiannara.ASC.Reality.RollbackEngine.create_snapshot("dep-h-1")
      Tiannara.ASC.Reality.RollbackEngine.rollback("dep-h-1")
      Tiannara.ASC.Reality.RollbackEngine.create_snapshot("dep-h-2")

      history = Tiannara.ASC.Reality.RollbackEngine.get_rollback_history()
      assert length(history) >= 1
    end
  end

  describe "ResourceOptimizationEngine" do
    test "optimizes digital deployment resources" do
      {:ok, report} =
        Tiannara.ASC.Reality.ResourceOptimizationEngine.optimize("dep-opt-1", :digital, %{
          expected_instances: 5
        })

      assert report.resource_estimate.compute.cpu_cores == 10
      assert report.resource_estimate.compute.ram_gb == 20
      assert report.cost_estimate.estimated_cost > 0
    end

    test "optimizes physical deployment resources" do
      {:ok, report} =
        Tiannara.ASC.Reality.ResourceOptimizationEngine.optimize("dep-opt-2", :physical, %{
          expected_units: 3
        })

      assert report.resource_estimate.hardware.microcontrollers == 6
      assert report.resource_estimate.hardware.sensors == 15
    end
  end

  describe "InfrastructurePlanner" do
    test "plans digital infrastructure" do
      {:ok, plan} =
        Tiannara.ASC.Reality.InfrastructurePlanner.plan("infra-1", :digital, %{
          regions: [:us_east, :eu_west]
        })

      assert plan.network.topology == :mesh
      assert plan.network.regions == [:us_east, :eu_west]
      assert plan.compute.compute_type == :kubernetes
    end

    test "plans physical infrastructure" do
      {:ok, plan} =
        Tiannara.ASC.Reality.InfrastructurePlanner.plan("infra-2", :physical, %{edge_nodes: 10})

      assert plan.network.topology == :star
      assert plan.compute.compute_type == :edge_processor
      assert plan.storage.storage_type == :flash
    end
  end

  describe "EnvironmentalImpactEngine" do
    test "assesses carbon footprint" do
      artifact = %{name: "env_test"}
      {:ok, assessment} = Tiannara.ASC.Reality.EnvironmentalImpactEngine.assess(artifact, %{})

      assert assessment.carbon_footprint_kg.total > 0
      assert assessment.sustainability_score > 0
      assert length(assessment.recommendations) > 0
    end

    test "reports sustainability score" do
      Tiannara.ASC.Reality.EnvironmentalImpactEngine.assess(%{name: "a"}, %{})
      Tiannara.ASC.Reality.EnvironmentalImpactEngine.assess(%{name: "b"}, %{})

      score = Tiannara.ASC.Reality.EnvironmentalImpactEngine.get_sustainability_score()
      assert score.average_sustainability > 0
      assert score.total_assessments >= 2
    end

    test "tracks carbon history" do
      Tiannara.ASC.Reality.EnvironmentalImpactEngine.assess(%{name: "c"}, %{
        estimated_compute_hours: 200
      })

      history = Tiannara.ASC.Reality.EnvironmentalImpactEngine.get_carbon_footprint_history()
      assert history.total_carbon_kg > 0
      assert length(history.history) >= 1
    end
  end
end
