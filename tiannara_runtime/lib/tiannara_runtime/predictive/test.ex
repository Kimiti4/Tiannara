defmodule TiannaraRuntime.Predictive.Test do
  @moduledoc """
  PHASE 4A: Test Module for Predictive Layer
  
  Usage:
    iex -S mix
    iex> TiannaraRuntime.Predictive.Test.run_full_test()
  """
  
  require Logger
  
  def run_full_test() do
    Logger.info("🧪 Starting Phase 4A Predictive Layer Test...")
    
    # Test 1: State Snapshot
    test_state_snapshot()
    
    # Test 2: Forward Simulation
    test_forward_simulation()
    
    # Test 3: Branched Simulation
    test_branched_simulation()
    
    Logger.info("✅ All Phase 4A tests completed!")
  end
  
  def test_state_snapshot() do
    Logger.info("\n📸 TEST 1: State Snapshot Engine")
    
    # Create sample state
    sample_state = %{
      coalitions: [
        %{id: "C1", coherence: 0.85, position: [10, 5, 0]},
        %{id: "C2", coherence: 0.72, position: [-5, 8, 0]}
      ],
      entropy: 0.62,
      interventions: []
    }
    
    # Capture snapshot
    case TiannaraRuntime.Predictive.StateSnapshot.capture_state(sample_state) do
      {:ok, snapshot_id} ->
        Logger.info("✅ Snapshot captured: #{snapshot_id}")
        
        # Retrieve snapshot
        case TiannaraRuntime.Predictive.StateSnapshot.get_snapshot(snapshot_id) do
          {:ok, snapshot} ->
            Logger.info("✅ Snapshot retrieved successfully")
            Logger.info("   Trace ID: #{snapshot.trace_id}")
            Logger.info("   CAL Coalitions: #{length(snapshot.cal_state.coalitions)}")
            Logger.info("   CIS Entropy: #{snapshot.cis_state.entropy_level}")
            
          {:error, reason} ->
            Logger.error("❌ Failed to retrieve snapshot: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        Logger.error("❌ Failed to capture snapshot: #{inspect(reason)}")
    end
  end
  
  def test_forward_simulation() do
    Logger.info("\n🔮 TEST 2: Forward Simulation")
    
    # Create initial state
    initial_state = %{
      cal_state: %{
        coalitions: [
          %{id: "C1", coherence: 0.85, position: [10, 5, 0]},
          %{id: "C2", coherence: 0.72, position: [-5, 8, 0]},
          %{id: "C3", coherence: 0.91, position: [3, -2, 0]}
        ]
      },
      cis_state: %{
        entropy_level: 0.62,
        interventions: [],
        quarantine_zones: [],
        damping_active: false
      },
      metrics: %{
        total_coalitions: 3,
        avg_coherence: 0.827,
        entropy: 0.62,
        stability_score: 0.827
      }
    }
    
    # Run simulation
    case TiannaraRuntime.Predictive.ForwardSimulation.simulate_future(initial_state, steps: 10) do
      {:ok, futures} ->
        Logger.info("✅ Simulation complete: #{length(futures)} future states")
        
        # Display first few predictions
        Enum.take(futures, 3) |> Enum.each(fn future ->
          Logger.info("   t+#{future.t}: probability=#{future.probability}, " <>
                     "entropy=#{future.state.cis_state.entropy_level}, " <>
                     "coherence=#{future.state.metrics.avg_coherence}")
        end)
        
      {:error, reason} ->
        Logger.error("❌ Simulation failed: #{inspect(reason)}")
    end
  end
  
  def test_branched_simulation() do
    Logger.info("\n🌿 TEST 3: Branched Simulation")
    
    # Create initial state
    initial_state = %{
      cal_state: %{
        coalitions: [
          %{id: "C1", coherence: 0.85, position: [10, 5, 0]}
        ]
      },
      cis_state: %{
        entropy_level: 0.62,
        interventions: [],
        quarantine_zones: [],
        damping_active: false
      },
      metrics: %{
        total_coalitions: 1,
        avg_coherence: 0.85,
        entropy: 0.62,
        stability_score: 0.85
      }
    }
    
    # Run branched simulation
    case TiannaraRuntime.Predictive.ForwardSimulation.simulate_branches(
           initial_state,
           branches: 3,
           steps: 5
         ) do
      {:ok, branches} ->
        Logger.info("✅ Branched simulation complete: #{length(branches)} branches")
        
        Enum.each(branches, fn branch ->
          Logger.info("   Branch #{branch.branch_id}: " <>
                     "#{length(branch.states)} states, " <>
                     "avg_probability=#{Float.round(branch.avg_probability, 3)}")
        end)
        
      {:error, reason} ->
        Logger.error("❌ Branched simulation failed: #{inspect(reason)}")
    end
  end
end
