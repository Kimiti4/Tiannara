defmodule TiannaraRuntime.CIS.AuthorizationContractTest do
  @moduledoc """
  5F-P0 regression: the KillSwitch → CIS safety-authorization contract.

  Commit `8610c558` removed `authorize_kill/3` and friends while callers
  kept calling them (UndefinedFunctionError on the safety chain). This
  suite pins the restored contract:

  - the original `51847461` decision table, exactly (every mode × severity);
  - the caller-visible decision vocabulary `:approve | :deny |
    :require_secondary_validation` (never a raise/exit while the kernel runs);
  - the controller mapping `:executed | :denied | :escalated` for
    `execute_kill/3` and `terminate_resource/3`;
  - fail-closed behavior when the arbitration process is absent;
  - `:reset` cast (used by integration-test helpers) does not crash.
  """

  use ExUnit.Case, async: false

  alias TiannaraRuntime.CIS.{ExecutionController, Supervisor}

  # Original decision table from 51847461 (pinned, not reimplemented).
  @decision_table %{
    # mode: :normal
    {{:normal, :normal}, :kill} => :approve,
    {{:normal, :elevated}, :kill} => :approve,
    {{:normal, :critical}, :kill} => :approve,
    {{:normal, :emergency}, :kill} => :approve,
    # mode: :elevated
    {{:elevated, :normal}, :kill} => :approve,
    {{:elevated, :elevated}, :kill} => :approve,
    {{:elevated, :critical}, :kill} => :approve,
    {{:elevated, :emergency}, :kill} => :require_secondary_validation,
    # mode: :critical
    {{:critical, :normal}, :kill} => :require_secondary_validation,
    {{:critical, :elevated}, :kill} => :approve,
    {{:critical, :critical}, :kill} => :approve,
    {{:critical, :emergency}, :kill} => :approve,
    # mode: :lockdown denies everything
    {{:lockdown, :normal}, :kill} => :deny,
    {{:lockdown, :elevated}, :kill} => :deny,
    {{:lockdown, :critical}, :kill} => :deny,
    {{:lockdown, :emergency}, :kill} => :deny
  }

  setup do
    ensure_started(Supervisor)
    ensure_started(ExecutionController)
    :ok = Supervisor.set_safety_mode(:normal)
    :ok
  end

  defp ensure_started(mod) do
    case mod.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  describe "authorize_kill/3 decision table (original contract)" do
    test "every mode × severity combination matches the pinned table" do
      for {{mode, severity}, :kill} <- @decision_table do
        :ok = Supervisor.set_safety_mode(mode)

        assert Supervisor.authorize_kill(:world_a, "contract test", severity) ==
                 @decision_table[{{mode, severity}, :kill}],
               "unexpected decision for {#{mode}, #{severity}}"
      end
    end

    test "decision vocabulary is exactly the three atoms (no raise, no exit)" do
      decision = Supervisor.authorize_kill(:world_b, "vocabulary check", :critical)

      assert decision in [:approve, :deny, :require_secondary_validation]
    end

    test "default arity behaves as severity :normal" do
      assert Supervisor.authorize_kill(:world_c, "default severity") ==
               Supervisor.authorize_kill(:world_c, "default severity", :normal)
    end
  end

  describe "authorize_resource_termination/3 mirrors the kill table" do
    test "operation type does not change the decision" do
      for {{mode, severity}, :kill} <- @decision_table do
        :ok = Supervisor.set_safety_mode(mode)

        assert Supervisor.authorize_resource_termination(:res_a, "contract test", severity) ==
                 @decision_table[{{mode, severity}, :kill}],
               "resource termination diverged for {#{mode}, #{severity}}"
      end
    end
  end

  describe "safety mode handling" do
    test "lockdown denies kills; leaving lockdown restores approvals" do
      :ok = Supervisor.set_safety_mode(:lockdown)
      assert Supervisor.authorize_kill(:world_d, "locked down", :critical) == :deny

      :ok = Supervisor.set_safety_mode(:normal)
      assert Supervisor.authorize_kill(:world_d, "unlocked", :critical) == :approve
    end

    test "invalid safety modes are rejected (guarded set_safety_mode/1)" do
      assert_raise FunctionClauseError, fn ->
        Supervisor.set_safety_mode(:not_a_mode)
      end
    end

    test "get_safety_mode/0 returns the bare atom (live-caller compat)" do
      :ok = Supervisor.set_safety_mode(:elevated)
      assert Supervisor.get_safety_mode() == :elevated
    end

    test "authorize_world_suspension/3 denies only under lockdown" do
      :ok = Supervisor.set_safety_mode(:normal)
      assert Supervisor.authorize_world_suspension(:world_e, "pause") == :approve

      :ok = Supervisor.set_safety_mode(:lockdown)
      assert Supervisor.authorize_world_suspension(:world_e, "pause") == :deny
    end
  end

  describe "arbitration state" do
    test "counters track decisions and :reset restores defaults without crashing" do
      # :reset is what integration-test helpers cast — the pre-restoration
      # stub had no handle_cast/2 at all and crashed on it.
      GenServer.cast(Supervisor, :reset)
      assert Supervisor.get_safety_mode() == :normal

      :ok = Supervisor.set_safety_mode(:normal)
      assert Supervisor.authorize_kill(:world_f, "approve me", :normal) == :approve

      :ok = Supervisor.set_safety_mode(:lockdown)
      assert Supervisor.authorize_kill(:world_f, "deny me", :normal) == :deny

      assert {:ok, stats} = Supervisor.get_stats()
      assert stats.total_approvals >= 1
      assert stats.total_denials >= 1
      assert stats.safety_mode == :lockdown
      assert length(stats.recent_decisions) >= 2

      GenServer.cast(Supervisor, :reset)
      assert {:ok, reset_stats} = Supervisor.get_stats()
      assert reset_stats.total_approvals == 0
      assert reset_stats.total_denials == 0
      assert reset_stats.log_size == 0
    end
  end

  describe "ExecutionController chain (kill_switch / quota_governor caller shapes)" do
    test "execute_kill/3 maps authorization to :executed/:denied/:escalated, never raises" do
      :ok = Supervisor.set_safety_mode(:normal)
      result = ExecutionController.execute_kill(:world_g, "chain test", :critical)
      assert result in [:executed, :denied, :escalated]

      :ok = Supervisor.set_safety_mode(:lockdown)
      assert ExecutionController.execute_kill(:world_g, "chain test", :critical) == :denied

      :ok = Supervisor.set_safety_mode(:critical)
      assert ExecutionController.execute_kill(:world_g, "chain test", :normal) == :escalated
    end

    test "terminate_resource/3 maps authorization the same way" do
      :ok = Supervisor.set_safety_mode(:normal)
      result = ExecutionController.terminate_resource(:res_b, "chain test", :elevated)
      assert result in [:executed, :denied, :escalated]

      :ok = Supervisor.set_safety_mode(:lockdown)
      assert ExecutionController.terminate_resource(:res_b, "chain test", :elevated) == :denied
    end
  end

  describe "fail-closed on absent arbitration kernel" do
    test "authorize_kill/3 exits (nothing proceeds) when the CIS process is gone" do
      if pid = Process.whereis(Supervisor) do
        GenServer.stop(pid)
      end

      assert catch_exit(Supervisor.authorize_kill(:world_h, "kernel absent"))

      # Restart for the rest of the suite (setup of later tests also re-checks).
      ensure_started(Supervisor)
      :ok = Supervisor.set_safety_mode(:normal)
    end
  end
end
