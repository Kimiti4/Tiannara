defmodule TiannaraRuntime.CausalDiscovery.IndependentAuditReportTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.IndependentAuditReport

  describe "new/1" do
    test "creates valid IndependentAuditReport with graph_fingerprint and overall" do
      {:ok, ar} = IndependentAuditReport.new(graph_fingerprint: "fp_abc", overall: :pass)
      assert ar.graph_fingerprint == "fp_abc"
      assert ar.overall == :pass
      assert ar.replay_result == :unavailable
      assert ar.evidence_coverage == 0.0
      assert String.starts_with?(ar.audit_id, "ar_")
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, ar} = IndependentAuditReport.new(graph_fingerprint: "fp_abc", overall: :pass)
      assert {:ok, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects empty graph_fingerprint" do
      ar = %IndependentAuditReport{graph_fingerprint: "", overall: :pass}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects nil graph_fingerprint" do
      ar = %IndependentAuditReport{graph_fingerprint: nil, overall: :pass}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects invalid overall" do
      ar = %IndependentAuditReport{graph_fingerprint: "fp", overall: :invalid}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects invalid replay_result" do
      ar = %IndependentAuditReport{graph_fingerprint: "fp", overall: :pass, replay_result: :invalid}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects evidence_coverage below 0.0" do
      ar = %IndependentAuditReport{graph_fingerprint: "fp", overall: :pass, evidence_coverage: -0.5}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects evidence_coverage above 1.0" do
      ar = %IndependentAuditReport{graph_fingerprint: "fp", overall: :pass, evidence_coverage: 1.5}
      assert {:error, _} = IndependentAuditReport.validate(ar)
    end

    test "rejects non-struct input" do
      assert {:error, _} = IndependentAuditReport.validate(%{})
    end
  end
end
