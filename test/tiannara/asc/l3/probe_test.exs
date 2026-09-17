defmodule Tiannara.ASC.L3.ProbeTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Core.Supervisor
  alias Tiannara.ASC.L3.Probe

  test "bounded cross-subsystem mission completes through real interfaces" do
    start_supervised!(Supervisor)

    assert {:ok, verdict} = Probe.run()

    assert verdict.verdict == :pass
    assert verdict.checks.trail_complete
    assert verdict.checks.distinct_subsystems
    assert verdict.checks.knowledge_persisted
    assert verdict.checks.lineage_present
    assert verdict.checks.read_only_respected

    assert Enum.sort(verdict.subsystems) ==
             [:knowledge_store, :metrics, :research, :self_evaluation]
  end
end