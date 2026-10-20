defmodule Tiannara.P9XEcosystemTest do
  use ExUnit.Case, async: false
  alias Tiannara.EventBus

  setup do
    case Registry.start_link(keys: :duplicate, name: Tiannara.EventRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
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

    case Tiannara.OLEF.PressureSolver.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

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

    # Send bad loop states to ObserverFreeCoherence (simulating OFL breaks).
    # OFL evaluates :rand.uniform() inside its OWN GenServer process, so the
    # test process cannot seed it. Make the expectation statistically sound
    # instead: each message gates with p(reject) = 0.2, so
    # P(no rejection after N) = 0.8^N; N = 64 → P ≈ 6.3e-7.
    Enum.each(1..64, fn _ ->
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
