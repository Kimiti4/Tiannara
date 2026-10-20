defmodule TiannaraRuntime.CausalDiscovery.CausalValidationResultTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.CausalValidationResult
  alias TiannaraRuntime.CausalDiscovery.ValidationCheck

  describe "new/1" do
    test "creates valid CausalValidationResult with graph_fingerprint and checks" do
      {:ok, vc} = ValidationCheck.new(check_name: "acyclic", status: :pass)
      {:ok, vr} = CausalValidationResult.new(graph_fingerprint: "fp_abc", checks: [vc])
      assert vr.graph_fingerprint == "fp_abc"
      assert length(vr.checks) == 1
      assert vr.overall == :inconclusive
      assert vr.created_at =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, vc} = ValidationCheck.new(check_name: "acyclic", status: :pass)
      {:ok, vr} = CausalValidationResult.new(graph_fingerprint: "fp_abc", checks: [vc])
      assert {:ok, _} = CausalValidationResult.validate(vr)
    end

    test "rejects empty graph_fingerprint" do
      vr = %CausalValidationResult{graph_fingerprint: "", checks: []}
      assert {:error, _} = CausalValidationResult.validate(vr)
    end

    test "rejects invalid overall" do
      vr = %CausalValidationResult{graph_fingerprint: "fp", checks: [], overall: :invalid}
      assert {:error, _} = CausalValidationResult.validate(vr)
    end

    test "rejects non-list checks" do
      vr = %CausalValidationResult{graph_fingerprint: "fp", checks: :not_a_list}
      assert {:error, _} = CausalValidationResult.validate(vr)
    end

    test "rejects non-struct input" do
      assert {:error, _} = CausalValidationResult.validate(%{})
    end
  end

  describe "ValidationCheck" do
    test "new/1 creates valid ValidationCheck" do
      {:ok, vc} = ValidationCheck.new(check_name: "d_separation", status: :pass)
      assert vc.check_name == "d_separation"
      assert vc.status == :pass
    end

    test "new/1 rejects empty check_name" do
      assert {:error, _} = ValidationCheck.new(check_name: "", status: :pass)
    end

    test "new/1 rejects invalid status" do
      assert {:error, _} = ValidationCheck.new(check_name: "test", status: :invalid)
    end
  end
end
