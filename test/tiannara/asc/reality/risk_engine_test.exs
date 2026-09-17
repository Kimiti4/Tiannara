defmodule Tiannara.ASC.Reality.RiskEngineTest do
  use ExUnit.Case, async: false

  setup do
    for mod <- [
      Tiannara.ASC.Reality.RiskAssessmentEngine,
      Tiannara.ASC.Reality.SafetyVerificationEngine,
      Tiannara.ASC.Reality.ComplianceEngine,
      Tiannara.ASC.Reality.IncidentResponseEngine
    ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    %{}
  end

  describe "RiskAssessmentEngine" do
    test "assess returns risk profile with mitigations" do
      artifact = %{name: "test_artifact", uncertainty_level: :high, real_world_interaction: false}
      {:ok, profile} = Tiannara.ASC.Reality.RiskAssessmentEngine.assess(artifact, %{})

      assert profile.artifact == artifact
      assert profile.overall_risk_score > 0
      assert length(profile.risks) > 0
      assert profile.is_acceptable == (profile.overall_risk_score < 0.7)
    end

    test "assess returns critical risks for real-world interaction artifacts" do
      artifact = %{name: "physical_artifact", uncertainty_level: :low, real_world_interaction: true}
      {:ok, profile} = Tiannara.ASC.Reality.RiskAssessmentEngine.assess(artifact, %{})

      risk_ids = Enum.map(profile.risks, fn r -> r.id end)
      assert :physical_safety in risk_ids
      assert :regulatory in risk_ids
    end

    test "get_risk_profile returns latest assessment" do
      artifact = %{name: "test", uncertainty_level: :low, real_world_interaction: false}
      Tiannara.ASC.Reality.RiskAssessmentEngine.assess(artifact, %{})

      profile = Tiannara.ASC.Reality.RiskAssessmentEngine.get_risk_profile()
      assert profile.artifact == artifact
    end
  end

  describe "SafetyVerificationEngine" do
    test "verify returns cleared verdict when all constraints pass" do
      artifact = %{name: "safe_artifact"}
      {:ok, verification} = Tiannara.ASC.Reality.SafetyVerificationEngine.verify(artifact, %{})

      assert verification.verdict == :cleared
      assert verification.passed == true
      assert verification.critical_safe == true
      assert length(verification.checks) > 0
    end

    test "verification log accumulates" do
      artifact = %{name: "test"}
      Tiannara.ASC.Reality.SafetyVerificationEngine.verify(artifact, %{})
      Tiannara.ASC.Reality.SafetyVerificationEngine.verify(%{name: "test2"}, %{})

      log = Tiannara.ASC.Reality.SafetyVerificationEngine.get_verification_log()
      assert length(log) >= 2
    end
  end

  describe "ComplianceEngine" do
    test "check returns pending approval for digital target" do
      artifact = %{name: "compliance_test"}
      {:ok, report} = Tiannara.ASC.Reality.ComplianceEngine.check(artifact, :digital, %{})

      assert report.overall_status == :pending_approval
      assert report.target == :digital
      assert report.pending_approvals > 0
    end

    test "approve changes status to approved" do
      artifact = %{name: "approval_test"}
      {:ok, report} = Tiannara.ASC.Reality.ComplianceEngine.check(artifact, :digital, %{})
      {:ok, approved} = Tiannara.ASC.Reality.ComplianceEngine.approve(report.id, :test_reviewer)

      assert approved.overall_status == :approved
      assert approved.approved_by == :test_reviewer
    end

    test "reject changes status to rejected" do
      artifact = %{name: "reject_test"}
      {:ok, report} = Tiannara.ASC.Reality.ComplianceEngine.check(artifact, :digital, %{})
      {:ok, rejected} = Tiannara.ASC.Reality.ComplianceEngine.reject(report.id, :test_reviewer, :non_compliant)

      assert rejected.overall_status == :rejected
      assert rejected.rejected_by == :test_reviewer
      assert rejected.rejection_reason == :non_compliant
    end
  end

  describe "IncidentResponseEngine" do
    test "initializes monitoring for a deployment" do
      {:ok, monitor} = Tiannara.ASC.Reality.IncidentResponseEngine.initialize("dep-1", :digital)

      assert monitor.status == :active
      assert monitor.deployment_id == "dep-1"
      assert monitor.health_score == 1.0
    end

    test "reports active monitors" do
      Tiannara.ASC.Reality.IncidentResponseEngine.initialize("dep-1", :digital)
      Tiannara.ASC.Reality.IncidentResponseEngine.initialize("dep-2", :physical)

      monitors = Tiannara.ASC.Reality.IncidentResponseEngine.get_active_monitors()
      assert length(monitors) == 2
    end
  end
end
