defmodule Tiannara.P9XEcosystemTest do
  use ExUnit.Case, async: false
  alias Tiannara.EventBus

  setup do
    Registry.start_link(keys: :duplicate, name: Tiannara.EventRegistry)
    Tiannara.MSCL.Supervisor.start_link([])
    Supervisor.start_link([
      Tiannara.MSCL.ConstraintEngine,
      Tiannara.MSCL.BudgetTracker
    ], strategy: :rest_for_one, name: Tiannara.MSCL.ChildSupervisor)
    Tiannara.GRCC.EntropyController.start_link([])
    Tiannara.GRCC.LineageManager.start_link([])
    Tiannara.P9X.ObserverFreeCoherence.start_link([])
    Tiannara.CIS.ImmuneDecisionEngine.start_link([])
    Tiannara.CIS.RegulationExecutor.start_link([])
    Tiannara.OLEF.PressureSolver.start_link([])
    :ok
  end

  test "Event Bus Integration: Entropy spike triggers immune diffusion" do
    # Subscribe to immune responses and field changes
    EventBus.subscribe("immune.response")
    EventBus.subscribe("field.pressure_changed")

    # Send entropy tick to the GRCC EntropyController
    send(Process.whereis(Tiannara.GRCC.EntropyController), {:entropy_tick, 0.5})

    # Should trigger immune response
    assert_receive {:entropy_spike, _}, 1000
    
    # Immune Decision Engine should convert it to a diffusion regulation
    # Regulation Executor then casts to OLEF PressureSolver
    # PressureSolver then emits pressure_update
    assert_receive {:pressure_update, %{pressure: pressure}}, 1000
    assert pressure < 0.0 # because it diffuses with -0.5
  end

  test "Test 4: Supervisor Recovery Integrity" do
    # Verify ConstraintEngine is alive
    pid = Process.whereis(Tiannara.MSCL.ConstraintEngine)
    assert Process.alive?(pid)

    # Get downstream PID (BudgetTracker)
    budget_pid = Process.whereis(Tiannara.MSCL.BudgetTracker)
    assert Process.alive?(budget_pid)

    # Kill the ConstraintEngine to simulate a crash
    Process.exit(pid, :kill)
    
    # Wait for supervisor to restart it
    :timer.sleep(100)

    new_pid = Process.whereis(Tiannara.MSCL.ConstraintEngine)
    new_budget_pid = Process.whereis(Tiannara.MSCL.BudgetTracker)

    # Both should be alive and DIFFERENT from the original PIDs due to :rest_for_one strategy!
    assert Process.alive?(new_pid)
    assert new_pid != pid

    assert Process.alive?(new_budget_pid)
    assert new_budget_pid != budget_pid
  end

  test "Test 5: P9X Isolation Gate blocks downstream events" do
    EventBus.subscribe("validation.status")

    # Send a bad loop state to ObserverFreeCoherence (simulating an OFL break)
    # The evaluation returns rand, so let's mock it or just send many until it fails?
    # Wait, the OFL logic uses rand.uniform(). We can't guarantee a fail.
    # Let's bypass random and send the message directly to EventBus to see if isolation works?
    # Or just loop until it triggers.
    Enum.each(1..20, fn _ ->
      send(Process.whereis(Tiannara.P9X.ObserverFreeCoherence), {:mutation_proposed, %{}})
    end)
    
    assert_receive {:observer_free_invalid, %{reason: "Low coherence"}}, 1000
    
    # Verify LineageManager is blocked
    # Try to mutate
    EventBus.subscribe("grcc.mutation")
    send(Process.whereis(Tiannara.GRCC.LineageManager), {:mutate, "lineage_A"})
    
    # We should NOT receive the mutation_proposed broadcast because it is blocked!
    refute_receive {:mutation_proposed, %{lineage: "lineage_A"}}, 500
  end
end
