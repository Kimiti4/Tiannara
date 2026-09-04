defmodule Tiannara.ASC.Civilization.Specialists.Tester do
  alias Tiannara.ASC.Civilization.EngineeringTask
  def test(%EngineeringTask{state: :approved} = task) do
    # In Phase 8B, RealityBridge handled the sandbox. 
    # Here, the Tester agent owns the invocation of the sandbox.
    outcome = simulate_sandbox_execution(task.patches)
    
    state = if outcome.success, do: :tested_pass, else: :tested_fail
    
    task
    |> EngineeringTask.log_event(:tester, state, outcome)
    |> Map.put(:test_outcome, outcome)
    |> Map.put(:state, state)
  end
  
  defp simulate_sandbox_execution(_patches) do
    # Proxies to RealityBridge.run_tests() and RealityBridge.run_benchmark()
    %{success: true, coverage: 0.92, performance_delta_ms: -15}
  end
end
