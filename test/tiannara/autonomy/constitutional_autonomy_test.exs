defmodule Tiannara.Autonomy.ConstitutionalAutonomyTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.ConstitutionalAutonomy

  describe "supervisor" do
    test "returns status with all subsystem states" do
      status = ConstitutionalAutonomy.status()
      assert status.improvements
      assert status.proposals
      assert status.simulations
      assert status.deployments
      assert status.validation
      assert status.rollbacks
    end

    test "reports healthy" do
      health = ConstitutionalAutonomy.health()
      assert health.status == :healthy
      assert is_integer(health.total_improvements_deployed)
      assert is_integer(health.total_rollbacks)
    end
  end

  describe "run_cycle" do
    test "executes a full improvement cycle" do
      assert {:ok, result} = ConstitutionalAutonomy.run_cycle()
      assert is_map(result)
    end
  end

  describe "submit_proposal" do
    test "submits a manual proposal" do
      assert {:ok, id} = ConstitutionalAutonomy.submit_proposal(%{
        title: "Manual improvement", objective: "Test manual submission",
        category: :performance, target: :scheduler
      })
      assert is_binary(id)
    end
  end

  describe "approve / reject / rollback" do
    test "reject returns error for unknown deployment" do
      assert {:error, :not_found} = ConstitutionalAutonomy.reject("invalid", :test_operator, "Not needed")
    end

    test "rollback reports unavailability truthfully" do
      assert {:error, :rollback_unavailable} = ConstitutionalAutonomy.rollback("invalid", "Testing rollback")
    end
  end
end
