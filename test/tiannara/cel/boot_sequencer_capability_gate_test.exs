defmodule Tiannara.CEL.Kernel.BootSequencerCapabilityGateTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.BootSequencer

  defmodule ExplicitStub do
    use Tiannara.Stub, subsystem: :test, phase: "test", priority: :low
  end

  test "rejects explicit stub modules" do
    assert {:fail, "Service module is an explicit stub"} =
             BootSequencer.capability_gate(ExplicitStub)
  end

  test "accepts non-stub service modules" do
    assert :pass = BootSequencer.capability_gate(Tiannara.World.ReplayEngine)
  end
end