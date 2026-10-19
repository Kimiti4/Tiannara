defmodule TiannaraRuntime.OLEF.BootWiringW3Test do
  @moduledoc """
  5F wiring W3 (operator-approved 2026-10-19): the canonical OLEF set
  (Tiannara.OLEF.Supervisor -> PressureSolver + GradientRouter) must be
  present in the application boot tree — re-parented from the
  reference-less Tiannara.P9XEcosystem.Supervisor (audit §4 item 3).
  Non-destructive: P9XEcosystem itself is left in place, unwired.

  Evidence: PHASE_5F_WIRING_AUDIT.md §4 item 3.
  """

  use ExUnit.Case, async: false

  alias Tiannara.EventBus
  alias Tiannara.OLEF.{GradientRouter, PressureSolver, Supervisor}

  test "Tiannara.EventRegistry is live after application boot" do
    pid = Process.whereis(Tiannara.EventRegistry)
    assert is_pid(pid), "expected Tiannara.EventRegistry in Infrastructure layer (5F wiring W3)"
    assert Process.alive?(pid)
  end

  test "canonical OLEF supervisor + children are live after application boot" do
    for mod <- [Supervisor, PressureSolver, GradientRouter] do
      pid = Process.whereis(mod)
      assert is_pid(pid),
             "expected #{inspect(mod)} wired into Ecology layer (5F wiring W3)"

      assert Process.alive?(pid)
    end
  end

  test "boot-wired PressureSolver round-trips a EventBus pressure_update" do
    EventBus.subscribe("field.pressure_changed")

    GenServer.cast(PressureSolver, {:pressure_update, 0.4})

    assert_receive {:pressure_update, %{pressure: pressure}}, 1000
    assert is_number(pressure)
  end
end
