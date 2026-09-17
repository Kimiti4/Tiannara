defmodule Tiannara.ASC.Reality.AuditTest do
  use ExUnit.Case, async: false

  setup do
    case Tiannara.ASC.Reality.DeploymentAuditEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    %{}
  end

  describe "DeploymentAuditEngine" do
    test "records deployment audit entry" do
      artifact = %{name: "audited_service"}
      {:ok, entry} = Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-audit-1", artifact, :digital, %{version: "2.0.0"})

      assert entry.deployment_id == "dep-audit-1"
      assert entry.event_type == :deployment_recorded
      assert entry.metadata.version == "2.0.0"
    end

    test "retrieves audit trail for deployment" do
      artifact = %{name: "svc_x"}
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-trail-1", artifact, :digital, %{})
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-trail-1", artifact, :digital, %{version: "2.0.0"})

      trail = Tiannara.ASC.Reality.DeploymentAuditEngine.get_audit_trail("dep-trail-1")
      assert length(trail) == 2
    end

    test "searches compliance records by target" do
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-s1", %{name: "a"}, :digital, %{})
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-s2", %{name: "b"}, :physical, %{})

      digital = Tiannara.ASC.Reality.DeploymentAuditEngine.search_audit(%{target: :digital})
      assert length(digital) >= 1
      assert hd(digital).target == :digital
    end

    test "compliance_records returns all records" do
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-c1", %{name: "svc_1"}, :digital, %{})
      Tiannara.ASC.Reality.DeploymentAuditEngine.record("dep-c2", %{name: "svc_2"}, :physical, %{})

      records = Tiannara.ASC.Reality.DeploymentAuditEngine.get_compliance_records()
      assert length(records) >= 2
    end
  end
end
