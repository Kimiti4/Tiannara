defmodule Tiannara.Autonomy.RollbackEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.RollbackEngine

  describe "rollback" do
    test "reports unavailability instead of fabricating a rollback" do
      assert {:error, :rollback_unavailable} = RollbackEngine.rollback("deploy_1", "Manual rollback for testing")
    end

    test "rollback unavailable for any deployment id" do
      assert {:error, :rollback_unavailable} = RollbackEngine.rollback("any_id", "Simulated rollback")
    end
  end

  describe "automatic_rollback" do
    test "executes automatic rollback unavailable truthfully" do
      assert {:error, :rollback_unavailable} = RollbackEngine.automatic_rollback("deploy_2", "Performance degradation detected")
    end
  end

  describe "total_rollbacks" do
    test "never counts fabricated rollbacks" do
      before = RollbackEngine.total_rollbacks()
      RollbackEngine.rollback("d1", "reason 1")
      RollbackEngine.rollback("d2", "reason 2")
      assert RollbackEngine.total_rollbacks() == before
    end
  end

  describe "status" do
    test "returns metrics" do
      status = RollbackEngine.status()
      assert is_integer(status.total_rollbacks)
      assert is_integer(status.total_successful)
      assert is_integer(status.total_failed)
      assert is_float(status.success_rate)
    end

    test "does not fabricate success counts" do
      before = RollbackEngine.status().total_successful
      RollbackEngine.rollback("d_success_1", "ok")
      status = RollbackEngine.status()
      assert status.total_successful == before
    end
  end
end