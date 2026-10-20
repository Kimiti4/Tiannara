defmodule Tiannara.MSCL.AdaptiveControllerTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.MSCL.AdaptiveController
  alias Tiannara.MSCL.Supervisor, as: MSCLSupervisor

  setup do
    case Registry.start_link(keys: :duplicate, name: Tiannara.EventRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    Tiannara.MSCL.Supervisor.start_link([])
    Tiannara.MSCL.AdaptiveController.start_link([])
    :ok
  end

  test "AdaptiveController updates MSCL thresholds" do
    # Wait for a couple of ticks to let the AdaptiveController control loop run
    Process.sleep(250)
    
    {:ok, state} = MSCLSupervisor.get_state()
    
    # max_global_pressure should be updated dynamically based on K(t)
    assert state.max_global_pressure > 0.0
    
    # Both should be present and updated
    assert state.critical_collapse_risk > 0.0
    assert state.warning_collapse_risk > 0.0
  end
end
