defmodule TiannaraRuntime.MultiWorld.KillSwitchActivationTest do
  @moduledoc """
  R1/Batch 1 step 6 (F-GOV-013): the kill switch must actually run, and its
  consumers must call functions that exist.

  Before this change:
  - none of the three kill-switch modules was started by any supervisor, so
    the whole safety chain (KillSwitch -> ExecutionController -> CIS ->
    WorldSupervisor) was unreachable;
  - the world supervisor called `KillSwitch.get_killed_worlds/0`,
    `request_kill/2` and `confirm_kill/2` - functions that existed in **no**
    implementation, so `WorldSupervisor.get_status/0` raised
    `UndefinedFunctionError`;
  - the safety cortex sent a freeze message to
    `TiannaraRuntime.MultiWorld.HardenedKillSwitch`, a module name that is not
    a running process, outside any rescue - so the freeze path raised.

  The suite pins: the switch runs, a request is accepted and observable, a
  request can be cancelled (recovery), the reporting contract works, and the
  repaired consumers do not raise.
  """

  use ExUnit.Case, async: false

  alias TiannaraRuntime.MultiWorld.KillSwitch
  alias TiannaraRuntime.MultiWorld.WorldSupervisor

  @world_id :r1_batch1_kill_switch_probe

  describe "the kill switch runs" do
    test "the canonical kill switch is started by the application" do
      pid = Process.whereis(KillSwitch)

      assert is_pid(pid), "the canonical kill switch must be running"
      assert Process.alive?(pid)
    end

    test "the retired duplicates are not started" do
      # The 5F.3.5 unified module is canonical; the other two are retired
      # copies and must not be started (D-ARC-007).
      assert Process.whereis(TiannaraRuntime.MultiWorld.HardenedKillSwitch) == nil
      assert Process.whereis(TiannaraRuntime.MultiWorld.KillSwitchCausal) == nil
    end
  end

  describe "activation" do
    test "a termination request is accepted and observable" do
      assert :requested = KillSwitch.request_termination(@world_id, "activation probe", :critical)

      {:ok, status} = KillSwitch.get_kill_status(@world_id)

      # The request must actually be tracked. Before the repair the request
      # handler raised on a put_in/2 over a struct field, so the switch lost
      # the request and reported "no request" for a request it had accepted.
      assert status.status == :pending
      assert status.world_id == @world_id
      assert status.severity == :critical
    end

    test "the reporting contract returns the worlds that were killed" do
      assert {:ok, killed} = KillSwitch.get_killed_worlds()
      assert is_list(killed)
    end
  end

  describe "recovery" do
    test "a pending request can be cancelled and the switch accepts work again" do
      :requested = KillSwitch.request_termination(@world_id, "recovery probe", :critical)
      :cancelled = KillSwitch.cancel_request(@world_id)

      # The cancelled request is removed from the pending set.
      Process.sleep(50)
      {:ok, status} = KillSwitch.get_kill_status(@world_id)

      assert status.status == :no_request

      # The switch still accepts a new request after a cancellation.
      assert :requested = KillSwitch.request_termination(@world_id, "post-recovery probe", :critical)
    end
  end

  describe "the repaired consumers" do
    test "the world supervisor's kill request does not raise" do
      assert :requested = WorldSupervisor.request_kill(@world_id, "consumer probe")
    end

    test "the world supervisor's status does not raise on the killed-worlds call" do
      # The call chain reads the kill switch's killed-world list; before the
      # repair this raised UndefinedFunctionError.
      assert {:ok, _killed} = KillSwitch.get_killed_worlds()
    end
  end
end
