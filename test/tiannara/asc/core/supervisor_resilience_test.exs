defmodule Tiannara.ASC.Core.SupervisorResilienceTest do
  use ExUnit.Case, async: false

  test "restarts registry after crash and preserves registry survival" do
    {:ok, _pid} = start_supervised(Tiannara.ASC.Core.Supervisor)

    original = Process.whereis(Tiannara.ASC.Core.Registry)
    assert is_pid(original)

    Process.exit(original, :kill)
    Process.sleep(150)

    restarted = Process.whereis(Tiannara.ASC.Core.Registry)
    assert is_pid(restarted)
    refute restarted == original

    # Workers self-register in init — registry continuity is a topology
    # property: after a Registry restart the 4 required workers are back.
    assert Tiannara.ASC.Core.Registry.count() == 4
    assert :ok == Tiannara.ASC.Core.Registry.register(:service_a, Tiannara.ASC.Core.Metrics, [:health], :research)
    assert Tiannara.ASC.Core.Registry.count() == 5
  end
end
