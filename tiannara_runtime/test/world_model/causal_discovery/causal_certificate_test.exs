defmodule TiannaraRuntime.CausalDiscovery.CausalCertificateTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.CausalCertificate

  describe "new/1" do
    test "creates valid CausalCertificate with graph_fingerprint and empty checks" do
      {:ok, cc} = CausalCertificate.new(graph_fingerprint: "fp456", checks: [])
      assert cc.graph_fingerprint == "fp456"
      assert cc.checks == []
      assert String.starts_with?(cc.certificate_id, "cc_")
    end

    test "version defaults to 1" do
      {:ok, cc} = CausalCertificate.new(graph_fingerprint: "fp", checks: [])
      assert cc.version == 1
    end

    test "issued_by defaults to :causal_discovery" do
      {:ok, cc} = CausalCertificate.new(graph_fingerprint: "fp", checks: [])
      assert cc.issued_by == :causal_discovery
    end

    test "fails on empty graph_fingerprint" do
      assert {:error, _} = CausalCertificate.new(graph_fingerprint: "", checks: [])
    end

    test "fails when overall is not in allowed values" do
      assert {:error, _} = CausalCertificate.new(graph_fingerprint: "fp", checks: [], overall: :invalid)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid CausalCertificate" do
      cc = %CausalCertificate{graph_fingerprint: "fp", checks: [], overall: :pass}
      assert {:ok, _} = CausalCertificate.validate(cc)
    end

    test "fails for invalid CausalCertificate" do
      cc = %CausalCertificate{graph_fingerprint: "", checks: []}
      assert {:error, _} = CausalCertificate.validate(cc)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with cc_" do
      {:ok, cc} = CausalCertificate.new(graph_fingerprint: "fp", checks: [])
      id = CausalCertificate.compute_id(cc)
      assert String.starts_with?(id, "cc_")
    end
  end
end
