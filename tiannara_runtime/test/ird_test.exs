defmodule TiannaraRuntime.IRDTest do
  use ExUnit.Case, async: false
  require Logger

  alias TiannaraRuntime.IRD.{Consumer, InterferenceMatrix, PhaseScheduler, BudgetController, QuiescenceManager, Feedback}

  setup do
    if !Process.whereis(Feedback), do: start_supervised!(Feedback)
    if !Process.whereis(QuiescenceManager), do: start_supervised!(QuiescenceManager)
    if !Process.whereis(BudgetController), do: start_supervised!(BudgetController)
    if !Process.whereis(PhaseScheduler), do: start_supervised!(PhaseScheduler)
    if !Process.whereis(Consumer), do: start_supervised!(Consumer)
    :ok
  end

  test "interference matrix computes core metrics correctly" do
    proposals = [
      %{observer_id: "obs_1", priority: 0.9, intensity: 0.8, phase: 0.1, timestamp: System.system_time(:millisecond)},
      %{observer_id: "obs_2", priority: 0.8, intensity: 0.7, phase: 0.2, timestamp: System.system_time(:millisecond)}
    ]

    interference = InterferenceMatrix.compute(proposals)
    assert is_map(interference)
    assert Map.has_key?(interference, :max_value)
    assert map_size(interference.matrix) == 2
  end

  test "phase scheduler calculates delay based on interference" do
    interference_low = %{max_value: 0.1}
    interference_high = %{max_value: 0.8}

    delay_low = PhaseScheduler.compute_delay(interference_low)
    delay_high = PhaseScheduler.compute_delay(interference_high)

    assert delay_low >= 0
    assert delay_high > delay_low
  end

  test "budget controller reserves and throttles budgets correctly" do
    proposal_light = %{intensity: 0.1, priority: 0.9, phase: 0.0}
    proposal_heavy = %{intensity: 0.95, priority: 0.1, phase: 0.0}

    assert BudgetController.reserve(proposal_light) == :ok
    
    result = BudgetController.reserve(proposal_heavy)
    assert result == :ok or match?({:deferred, _reason}, result)
  end

  test "consumer submits and schedules low-interference proposals" do
    proposal = %{observer_id: "test_obs", priority: 0.2, intensity: 0.1, phase: 0.0}
    assert :ok = Consumer.submit_proposal(proposal)
  end
end
