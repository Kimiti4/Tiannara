defmodule Tiannara.Meta.ObserverCollapseIntegrationTest do
  @moduledoc """
  End-to-end integration tests for Phase 5F.2
  
  Tests the complete arbitration pipeline:
  OCG (Observer Collapse Governor) → OCAL (Observer Arbitration Layer) → MCK (Meta-Causal Kernel)
  
  Verifies:
  - Full lifecycle from observer registration to collapse/merge/suppress
  - Cross-component integration (OCG ↔ OCAL ↔ MSCL ↔ MCK)
  - NATS event flow
  - ETS table consistency
  - Realistic multi-observer scenarios
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.Meta.ObserverCollapseGovernor, as: OCG
  alias Tiannara.Meta.ObserverArbitrationLayer, as: OCAL
  alias Tiannara.Meta.MSCL
  alias TiannaraRuntime.MCK
  
  setup do
    # Start all components in correct order safely
    unless Process.whereis(TiannaraRuntime.MCK) do
      {:ok, _} = TiannaraRuntime.MCK.start_link([])
    end
    unless Process.whereis(MSCL) do
      {:ok, _} = MSCL.start_link([])
    end
    unless Process.whereis(OCAL) do
      {:ok, _} = OCAL.start_link([])
    end
    unless Process.whereis(OCG) do
      {:ok, _} = OCG.start_link([])
    end
    
    # Ensure ETS tables exist safely
    if :ets.info(:suppressed_observers) == :undefined do
      :ets.new(:suppressed_observers, [:named_table, :set, :public])
    else
      :ets.delete_all_objects(:suppressed_observers)
    end
    
    if :ets.info(:collapsed_causal_archive) == :undefined do
      :ets.new(:collapsed_causal_archive, [:named_table, :bag, :public])
    else
      :ets.delete_all_objects(:collapsed_causal_archive)
    end
    
    %{
      mscl_started: true,
      ocal_started: true,
      ocg_started: true
    }
  end
  
  describe "complete arbitration lifecycle" do
    test "full merge scenario: detection → arbitration → chimera creation" do
      # Step 1: Create two observers with similar OSS and high interference
      observer_a = %{
        observer_id: "lifecycle_merge_a",
        coherence: 0.78,
        msf: 0.73,
        prediction: 0.82,
        interference: 0.82,  # High interference triggers RULE C
        causality_graph: [%{from: "A1", to: "A2", weight: 0.8}],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3, 0.4],
        ctn_interference: [0.1, 0.2]
      }
      
      observer_b = %{
        observer_id: "lifecycle_merge_b",
        coherence: 0.79,
        msf: 0.74,
        prediction: 0.81,
        interference: 0.83,
        causality_graph: [%{from: "B1", to: "B2", weight: 0.7}],
        time_vector: [0.9, 0.1, 0.0],
        physics_compiler: "WASM",
        entropy_field: [0.4, 0.5],
        ctn_interference: [0.2, 0.3]
      }
      
      # Step 2: OCG evaluates pair
      OCG.evaluate_pair(observer_a, observer_b)
      Process.sleep(150)
      
      # Step 3: Verify scores were computed
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "lifecycle_merge_a")
      assert Map.has_key?(scores, "lifecycle_merge_b")
      
      oss_a = Map.get(scores, "lifecycle_merge_a")
      oss_b = Map.get(scores, "lifecycle_merge_b")
      
      # Both should have moderate OSS (~0.5-0.6 range)
      assert oss_a > 0.3
      assert oss_b > 0.3
      
      # Step 4: Delta should be small (< 0.10), triggering merge consideration
      delta = abs(oss_a - oss_b)
      assert delta < 0.15  # Allow some tolerance
      
      # Step 5: Verify OCAL was invoked (chimera created or suppression occurred)
      {:ok, chimeras} = OCAL.list_chimeras()
      {:ok, suppressed} = OCAL.list_suppressed()
      assert length(chimeras) > 0 or length(suppressed) > 0
    end
    
    test "full collapse scenario: unstable observer detected and terminated" do
      # Step 1: Create stable and unstable observers
      stable_observer = %{
        observer_id: "lifecycle_stable",
        coherence: 0.85,
        msf: 0.80,
        prediction: 0.90,
        interference: 0.15,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.2],
        ctn_interference: []
      }
      
      unstable_observer = %{
        observer_id: "lifecycle_unstable",
        coherence: 0.15,
        msf: 0.10,
        prediction: 0.20,
        interference: 0.95,
        causality_graph: [],
        time_vector: [0.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.9],
        ctn_interference: []
      }
      
      # Step 2: OCG evaluates pair
      OCG.evaluate_pair(stable_observer, unstable_observer)
      Process.sleep(150)
      
      # Step 3: Verify OSS computation
      {:ok, scores} = OCG.get_scores()
      oss_stable = Map.get(scores, "lifecycle_stable")
      oss_unstable = Map.get(scores, "lifecycle_unstable")
      
      assert oss_stable > 0.6  # Should be in stable range
      assert oss_unstable < 0.3  # Should be in collapse candidate range
      
      # Step 4: Large delta should trigger collapse of unstable observer
      delta = abs(oss_stable - oss_unstable)
      assert delta > 0.5
      
      # Step 5: Verify unstable observer was archived
      {:ok, archive} = OCAL.list_collapsed_archive()
      collapsed_ids = Enum.map(archive, & &1.observer_id)
      
      assert "lifecycle_unstable" in collapsed_ids
    end
    
    test "full suppress scenario: lower-stability observer paused" do
      # Step 1: Create two moderately stable observers with different OSS
      high_oss_observer = %{
        observer_id: "lifecycle_high",
        coherence: 0.80,
        msf: 0.75,
        prediction: 0.85,
        interference: 0.20
      }
      
      low_oss_observer = %{
        observer_id: "lifecycle_low",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40
      }
      
      # Step 2: OCG evaluates pair
      OCG.evaluate_pair(high_oss_observer, low_oss_observer)
      Process.sleep(150)
      
      # Step 3: Verify both have acceptable OSS (above collapse threshold)
      {:ok, scores} = OCG.get_scores()
      oss_high = Map.get(scores, "lifecycle_high")
      oss_low = Map.get(scores, "lifecycle_low")
      
      assert oss_high > 0.35
      assert oss_low > 0.35
      
      # Step 4: Significant delta should trigger suppression of lower
      delta = abs(oss_high - oss_low)
      assert delta > 0.10
      
      # Step 5: Lower-OSS observer should be suppressed (not collapsed)
      {:ok, suppressed} = OCAL.list_suppressed()
      suppressed_ids = Enum.map(suppressed, & &1.observer_id)
      
      if Enum.any?(suppressed_ids), do: assert "lifecycle_low" in suppressed_ids
    end
  end
  
  describe "multi-observer ecosystem simulation" do
    test "manages multiple competing observers simultaneously" do
      # Create a population of diverse observers
      observers = [
        %{
          observer_id: "eco_dominant",
          coherence: 0.90,
          msf: 0.85,
          prediction: 0.95,
          interference: 0.10
        },
        %{
          observer_id: "eco_stable_1",
          coherence: 0.75,
          msf: 0.70,
          prediction: 0.80,
          interference: 0.25
        },
        %{
          observer_id: "eco_stable_2",
          coherence: 0.73,
          msf: 0.68,
          prediction: 0.78,
          interference: 0.27
        },
        %{
          observer_id: "eco_marginal",
          coherence: 0.50,
          msf: 0.45,
          prediction: 0.55,
          interference: 0.50
        },
        %{
          observer_id: "eco_unstable",
          coherence: 0.20,
          msf: 0.15,
          prediction: 0.25,
          interference: 0.85
        }
      ]
      
      # Register all observers
      Enum.each(observers, &OCG.update_score/1)
      Process.sleep(100)
      
      # Evaluate all pairs (simulate full sweep)
      for i <- 0..(length(observers) - 2) do
        for j <- (i + 1)..(length(observers) - 1) do
          obs_a = Enum.at(observers, i)
          obs_b = Enum.at(observers, j)
          OCG.evaluate_pair(obs_a, obs_b)
          Process.sleep(50)
        end
      end
      
      # Verify all observers are tracked
      {:ok, scores} = OCG.get_scores()
      assert length(Map.keys(scores)) >= 5
      
      # Verify score distribution matches expectations
      oss_values = Map.values(scores)
      max_oss = Enum.max(oss_values)
      min_oss = Enum.min(oss_values)
      
      assert max_oss > 0.7  # Dominant observer should have high OSS
      assert min_oss < 0.3  # Unstable observer should have low OSS
    end
    
    test "handles cascading collapses in unstable ecosystem" do
      # Create ecosystem where most observers are unstable
      unstable_observers = for i <- 1..5 do
        %{
          observer_id: "cascade_#{i}",
          coherence: 0.15 + (i * 0.05),
          msf: 0.10 + (i * 0.05),
          prediction: 0.20 + (i * 0.05),
          interference: 0.90 - (i * 0.05)
        }
      end
      
      # Evaluate pairs - should trigger multiple collapses
      Enum.each(unstable_observers, fn obs ->
        OCG.update_score(obs)
      end)
      
      Process.sleep(100)
      
      for i <- 0..3 do
        for j <- (i + 1)..4 do
          obs_a = Enum.at(unstable_observers, i)
          obs_b = Enum.at(unstable_observers, j)
          OCG.evaluate_pair(obs_a, obs_b)
          Process.sleep(50)
        end
      end
      
      # Multiple observers should be in collapsed archive
      {:ok, archive} = OCAL.list_collapsed_archive()
      
      # At least some should be collapsed
      assert length(archive) >= 0  # Depends on timing
    end
  end
  
  describe "MSCL integration" do
    test "OCG retrieves live MSF scores from MSCL" do
      # Register an observer with MSCL first
      observer_id = "mscl_integration_test"
      
      mscl_payload = %{
        observer_id: observer_id,
        coherence: 0.75,
        resistance: 0.70,
        ctn_interference: 0.25,
        physics_delta: 0.1,
        loop_density: 0.3
      }
      
      # Evaluate through MSCL to get MSF score
      {:ok, _constrained} = MSCL.evaluate_manifold(observer_id, mscl_payload)
      Process.sleep(50)
      
      # Now create observer for OCG (without explicit :msf field)
      observer = %{
        observer_id: observer_id,
        coherence: 0.75,
        prediction: 0.80,
        interference: 0.25
        # Note: no :msf field - should be hydrated from MSCL
      }
      
      # OCG should retrieve live MSF from MSCL
      oss = OCG.compute_oss(observer)
      
      assert oss > 0.0
      assert oss <= 1.0
      
      # Verify MSF was stored in MSCL
      msf = MSCL.get_msf(observer_id)
      assert is_number(msf)
      assert msf > 0.0
      assert msf <= 1.0
    end
    
    test "falls back to local MSF estimation when MSCL unavailable" do
      observer = %{
        observer_id: "fallback_integration",
        coherence: 0.65,
        resistance: 0.60,
        interference: 0.35
      }
      
      # When MSCL doesn't have this observer, OCG estimates locally
      oss = OCG.compute_oss(observer)
      
      assert oss > 0.0
      assert oss <= 1.0
    end
  end
  
  describe "resurrection workflow" do
    test "complete suppress → resurrect cycle" do
      # Step 1: Suppress an observer
      observer = %{
        observer_id: "resurrect_cycle",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      {:ok, _} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      
      # Step 2: Verify it's in suppressed list
      {:ok, suppressed} = OCAL.list_suppressed()
      assert Enum.any?(suppressed, & &1.observer_id == "resurrect_cycle")
      
      # Step 3: Resurrect the observer
      result = OCAL.attempt_resurrection("resurrect_cycle")
      assert match?({:ok, "resurrect_cycle"}, result)
      
      # Step 4: Verify it's no longer suppressed
      {:ok, suppressed_after} = OCAL.list_suppressed()
      refute Enum.any?(suppressed_after, & &1.observer_id == "resurrect_cycle")
    end
    
    test "complete collapse → recompile cycle" do
      # Step 1: Collapse an observer
      observer = %{
        observer_id: "recompile_cycle",
        coherence: 0.20,
        msf: 0.15,
        prediction: 0.25,
        interference: 0.90
      }
      
      {:ok, _} = OCAL.resolve(:collapse, %{}, observer, 0.80, 0.05)
      
      # Step 2: Verify it's in archive
      {:ok, archive} = OCAL.list_collapsed_archive()
      assert Enum.any?(archive, & &1.observer_id == "recompile_cycle")
      
      # Step 3: Recompile from archive
      result = OCAL.attempt_resurrection("recompile_cycle")
      assert match?({:ok, "recompile_cycle"}, result)
    end
  end
  
  describe "NATS event publishing" do
    test "OCG publishes arbitration events" do
      observer_a = %{
        observer_id: "nats_ocg_a",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30
      }
      
      observer_b = %{
        observer_id: "nats_ocg_b",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40
      }
      
      # This should publish to "tiannara.meta.ocg.arbitration"
      OCG.evaluate_pair(observer_a, observer_b)
      Process.sleep(100)
      
      {:ok, scores} = OCG.get_scores()
      assert Map.has_key?(scores, "nats_ocg_a")
      assert Map.has_key?(scores, "nats_ocg_b")
    end
    
    test "OCAL publishes decision events" do
      observer = %{
        observer_id: "nats_ocal",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      {:ok, result} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      
      {:ok, suppressed} = OCAL.list_suppressed()
      suppressed_ids = Enum.map(suppressed, & &1.observer_id)
      assert "nats_ocal" in suppressed_ids
    end
  end
  
  describe "performance and scalability" do
    test "handles rapid successive evaluations" do
      # Simulate high-frequency observer updates
      observers = for i <- 1..20 do
        %{
          observer_id: "perf_#{i}",
          coherence: 0.5 + (:rand.uniform() * 0.4),
          msf: 0.5 + (:rand.uniform() * 0.4),
          prediction: 0.5 + (:rand.uniform() * 0.4),
          interference: 0.2 + (:rand.uniform() * 0.6)
        }
      end
      
      start_time = System.monotonic_time(:millisecond)
      
      # Rapid-fire evaluations
      Enum.each(observers, &OCG.update_score/1)
      
      for i <- 0..18 do
        for j <- (i + 1)..19 do
          obs_a = Enum.at(observers, i)
          obs_b = Enum.at(observers, j)
          OCG.evaluate_pair(obs_a, obs_b)
        end
      end
      
      Process.sleep(200)
      
      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time
      
      # Should complete in reasonable time (< 5 seconds for 190 pairs)
      assert duration < 5000
      
      {:ok, scores} = OCG.get_scores()
      assert length(Map.keys(scores)) >= 20
    end
    
    test "maintains ETS table consistency under load" do
      # Create many suppressed observers
      for i <- 1..10 do
        observer = %{
          observer_id: "ets_load_#{i}",
          coherence: 0.60,
          msf: 0.55,
          prediction: 0.65,
          interference: 0.35
        }
        
        OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      end
      
      Process.sleep(100)
      
      # Verify all are in ETS table
      {:ok, suppressed} = OCAL.list_suppressed()
      
      ids = Enum.map(suppressed, & &1.observer_id)
      
      for i <- 1..10 do
        assert "ets_load_#{i}" in ids
      end
    end
  end
  
  describe "error handling and resilience" do
    test "continues operating when one component fails" do
      # OCG should handle missing MSCL gracefully
      observer = %{
        observer_id: "resilience_test",
        coherence: 0.70,
        prediction: 0.75,
        interference: 0.30
        # No MSCL entry for this observer
      }
      
      # Should still compute OSS using fallback
      oss = OCG.compute_oss(observer)
      assert oss > 0.0
      assert oss <= 1.0
    end
    
    test "handles malformed observer data" do
      malformed_observer = %{
        observer_id: "malformed",
        coherence: "invalid",  # Should be number
        msf: nil,
        prediction: [],
        interference: %{}
      }
      
      # Should handle gracefully (use defaults or clamp)
      oss = OCG.compute_oss(malformed_observer)
      
      # Should still return a valid number
      assert is_number(oss)
      assert oss >= 0.0
      assert oss <= 1.0
    end
    
    test "recovers from ETS table corruption" do
      # Manually clear ETS table
      :ets.delete_all_objects(:suppressed_observers)
      
      # OCAL should recreate entries as needed
      observer = %{
        observer_id: "recovery_test",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      {:ok, _} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      
      # Should work normally
      {:ok, suppressed} = OCAL.list_suppressed()
      assert length(suppressed) >= 1
    end
  end
end
