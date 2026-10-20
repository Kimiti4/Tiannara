defmodule TiannaraRuntime.CausalDiscovery.InterventionPlanTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.InterventionPlan

  describe "new/1" do
    test "creates valid InterventionPlan with target and set_value" do
      {:ok, ip} = InterventionPlan.new(target_variable: "x", set_value: {:fix, 42})
      assert ip.target_variable == "x"
      assert ip.set_value == {:fix, 42}
      assert String.starts_with?(ip.plan_id, "ip_")
    end

    test "fails on empty target_variable" do
      assert {:error, _} = InterventionPlan.new(target_variable: "", set_value: {:fix, 42})
    end

    test "fails on nil set_value" do
      assert {:error, _} = InterventionPlan.new(target_variable: "x", set_value: nil)
    end

    test "fails on invalid intervention_type" do
      assert {:error, _} = InterventionPlan.new(target_variable: "x", set_value: {:fix, 1}, intervention_type: :invalid)
    end

    test "fails on invalid identifiability" do
      assert {:error, _} = InterventionPlan.new(target_variable: "x", set_value: {:fix, 1}, identifiability: :invalid)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid InterventionPlan" do
      ip = %InterventionPlan{target_variable: "x", set_value: {:fix, 1}, intervention_type: :atomic, identifiability: :non_identifiable}
      assert {:ok, _} = InterventionPlan.validate(ip)
    end

    test "fails for invalid InterventionPlan" do
      ip = %InterventionPlan{target_variable: "", set_value: {:fix, 1}, intervention_type: :atomic, identifiability: :non_identifiable}
      assert {:error, _} = InterventionPlan.validate(ip)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with ip_" do
      {:ok, ip} = InterventionPlan.new(target_variable: "z", set_value: :remove)
      id = InterventionPlan.compute_id(ip)
      assert String.starts_with?(id, "ip_")
    end
  end
end
