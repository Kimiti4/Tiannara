defmodule TiannaraRuntime.Meta.BootWiringW2Test do
  @moduledoc """
  5F wiring W2 (operator-approved 2026-10-19): the Phase 5F.2/5F.3
  observer stack (MSCL, MCK, OCAL, OCG, OMRL) and the
  MetaEvolutionStreamManager event router must be present in the
  application boot tree — not merely callable when a test starts them
  by hand.

  Evidence: PHASE_5F_WIRING_AUDIT.md §4 item 2.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Meta.{MSCL, ObserverCollapseGovernor, ObserverMemoryReconciliation}
  alias TiannaraRuntime.MCK

  @boot_wired [
    Tiannara.NATS.MetaEvolutionStreamManager,
    MSCL,
    MCK,
    Tiannara.Meta.ObserverArbitrationLayer,
    ObserverCollapseGovernor,
    ObserverMemoryReconciliation
  ]

  test "every W2 module is a live named process after application boot" do
    for mod <- @boot_wired do
      pid = Process.whereis(mod)
      assert is_pid(pid),
             "expected #{inspect(mod)} to be wired into the boot tree (5F wiring W2)"

      assert Process.alive?(pid),
             "expected boot-wired #{inspect(mod)} to be alive"
    end
  end

  test "boot-wired OCG answers get_score/1 for an unknown observer" do
    assert ObserverCollapseGovernor.get_score("boot_wiring_unknown_obs") ==
             {:error, :not_found}
  end

  test "boot-wired MSCL answers get_msf/1 for an unknown observer" do
    assert MSCL.get_msf("boot_wiring_unknown_obs") in [nil, 0.5]
  end

  test "boot-wired OMRL can ingest and reconcile a memory" do
    event = %{
      id: "boot_wiring_mem_1",
      event: "W2 boot wiring smoke",
      weight: 0.9,
      msf: 0.7,
      oss: 0.8,
      coherence: 0.85
    }

    assert {:ok, :accepted} = ObserverMemoryReconciliation.ingest_memory("boot_obs_a", event)
    Process.sleep(50)

    {:ok, memories} = ObserverMemoryReconciliation.get_observer_memories("boot_obs_a")
    assert Enum.any?(memories, fn m -> m.event == "W2 boot wiring smoke" end)
  end
end
