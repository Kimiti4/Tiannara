defmodule Tiannara.A10Test do
  use ExUnit.Case, async: false
  alias Tiannara.EventBus

  setup do
    Registry.start_link(keys: :duplicate, name: Tiannara.EventRegistry)
    Tiannara.A10.AttractorMemory.start_link([])
    Tiannara.A10.DriftTensor.start_link([])
    Tiannara.A10.AttractorAnalyzer.start_link([])
    Tiannara.A10.AdvisoryEmitter.start_link([])
    Tiannara.CIS.ImmuneDecisionEngine.start_link([])
    :ok
  end

  test "DriftTensor calculates magnitude and triggers analyzer correctly" do
    EventBus.subscribe("drift.advisory")
    
    # Manually send a sample to DriftTensor
    d_vector = [5.0, 5.0, 5.0, 5.0, 5.0]
    GenServer.cast(Tiannara.A10.DriftTensor, {:record_sample, d_vector})
    
    # Need to simulate time passage to get acceleration
    # Send another sample with increasing magnitude to simulate negative elasticity
    :timer.sleep(10)
    d_vector_2 = [10.0, 10.0, 10.0, 10.0, 10.0]
    GenServer.cast(Tiannara.A10.DriftTensor, {:record_sample, d_vector_2})

    # This should trigger Phase D and emit an advisory
    assert_receive {:advisory_issued, %{phase: :phase_d}}, 1000
  end

  test "AttractorMemory stores phase history" do
    GenServer.cast(Tiannara.A10.AttractorMemory, {:record_phase, :phase_b})
    GenServer.cast(Tiannara.A10.AttractorMemory, {:record_phase, :phase_c})
    
    state = GenServer.call(Tiannara.A10.AttractorMemory, :get_history)
    
    assert :phase_c in state.phase_history
    assert :phase_b in state.phase_history
  end

  test "CIS ImmuneDecisionEngine respects cooldown and delta cap" do
    EventBus.subscribe("cis.regulation")
    
    # Send advisory to CIS
    send(Process.whereis(Tiannara.CIS.ImmuneDecisionEngine), 
         {:advisory_issued, %{phase: :phase_d, structural_drift: 50.0}})
         
    # Should execute regulation with max 2% cap (0.02)
    assert_receive {:execute_regulation, %{decision: {:tighten_pressure, 0.02}}}, 1000
    
    # Send another one immediately
    send(Process.whereis(Tiannara.CIS.ImmuneDecisionEngine), 
         {:advisory_issued, %{phase: :phase_e, structural_drift: 100.0}})
         
    # Should NOT receive another regulation because of cooldown
    refute_receive {:execute_regulation, _}, 500
  end
end
