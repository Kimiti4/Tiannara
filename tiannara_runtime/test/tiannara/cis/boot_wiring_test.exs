defmodule TiannaraRuntime.CIS.BootWiringTest do
  @moduledoc """
  5F wiring W1 (operator-approved 2026-10-19): the Phase 5F.3.5 Control
  Plane Consolidation Layer and the ChronogramMatrix substrate must be
  present in the application boot tree — not merely callable when a test
  starts them by hand.

  Evidence: PHASE_5F_WIRING_AUDIT.md §4.1 (CIS safety stack wiring),
  PHASE_5F_STATUS_CORRECTION.md C-10.
  """

  use ExUnit.Case, async: false

  alias TiannaraRuntime.CIS.Supervisor, as: CISSupervisor

  @boot_wired [
    Tiannara.Meta.ChronogramMatrix,
    TiannaraRuntime.CIS.Supervisor,
    TiannaraRuntime.CIS.ExecutionController,
    TiannaraRuntime.Resources.QuotaGovernor,
    TiannaraRuntime.Memory.LineageCompression,
    TiannaraRuntime.Causal.GCK
  ]

  test "every W1 module is a live named process after application boot" do
    for mod <- @boot_wired do
      pid = Process.whereis(mod)
      assert is_pid(pid),
             "expected #{inspect(mod)} to be wired into the boot tree (5F wiring W1)"

      assert Process.alive?(pid),
             "expected boot-wired #{inspect(mod)} to be alive"
    end
  end

  test "boot-wired arbitration kernel answers with the frozen decision vocabulary" do
    decision =
      CISSupervisor.authorize_world_suspension("boot_wiring_world", "boot wiring smoke test")

    assert decision in [:approve, :deny, :require_secondary_validation]
  end

  test "boot-wired execution controller can reach the arbitration kernel" do
    # The kill chain is KillSwitch → ExecutionController → CIS Supervisor.
    # terminate_resource/3 requests authorize_resource_termination/3 and maps
    # the frozen caller vocabulary (:executed | :denied | :escalated). The
    # resource path logs only — no termination command is delivered.
    result =
      TiannaraRuntime.CIS.ExecutionController.terminate_resource(
        "boot_wiring_res",
        "boot wiring smoke test",
        :normal
      )

    assert result in [:executed, :denied, :escalated],
           "unexpected ExecutionController result #{inspect(result)}"
  end
end
