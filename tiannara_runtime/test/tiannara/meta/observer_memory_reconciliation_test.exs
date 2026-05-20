defmodule Tiannara.Meta.ObserverMemoryReconciliationTest do
  @moduledoc """
  Integration tests for Phase 5F.3 — Observer Memory Reconciliation Layer (OMRL)

  Tests cover:
  - OMSV (Observer Memory State Vector) construction
  - Memory ingestion from multiple observers
  - Reconciliation factor calculation (R = MSF × OSS × coherence)
  - Three reconciliation modes (blended, layered, split)
  - Contradiction analysis and mode selection
  - ETS table management and caching
  - Integration with MSCL and OCG
  """

  use ExUnit.Case, async: false

  alias Tiannara.Meta.ObserverMemoryReconciliation, as: OMRL

  setup do
    # Start OMRL for each test
    {:ok, pid} = OMRL.start_link([])
    %{pid: pid}
  end

  describe "ingest_memory/2" do
    test "ingests memory event from observer" do
      memory_event = %{
        id: "test_mem_1",
        event: "Event X occurred",
        weight: 0.8,
        msf: 0.75,
        oss: 0.70,
        coherence: 0.80
      }

      assert {:ok, :accepted} = OMRL.ingest_memory("observer_a", memory_event)

      # Allow async processing
      Process.sleep(50)

      # Verify memory was stored
      {:ok, memories} = OMRL.get_observer_memories("observer_a")
      assert length(memories) == 1
      assert hd(memories).event == "Event X occurred"
    end

    test "auto-hydrates missing MSF and OSS values" do
      memory_event = %{
        id: "test_mem_hydrate",
        event: "Auto-hydrated memory",
        weight: 0.9
        # No msf, oss, or coherence provided
      }

      assert {:ok, :accepted} = OMRL.ingest_memory("observer_b", memory_event)
      Process.sleep(50)

      {:ok, memories} = OMRL.get_observer_memories("observer_b")
      omsv = hd(memories)

      # Should have default values
      assert is_number(omsv.msf)
      assert is_number(omsv.oss)
      assert is_number(omsv.coherence)
      assert omsv.msf > 0.0
      assert omsv.oss > 0.0
    end

    test "calculates reconciliation weight on ingestion" do
      memory_event = %{
        id: "test_mem_weight",
        event: "Weighted memory",
        msf: 0.8,
        oss: 0.7,
        coherence: 0.9
      }

      assert {:ok, :accepted} = OMRL.ingest_memory("observer_c", memory_event)
      Process.sleep(50)

      {:ok, memories} = OMRL.get_observer_memories("observer_c")
      omsv = hd(memories)

      # R = MSF × OSS × coherence = 0.8 × 0.7 × 0.9 = 0.504
      expected_r = 0.8 * 0.7 * 0.9
      assert_in_delta omsv.reconciliation_weight, expected_r, 0.001
    end

    test "handles multiple memories from same observer" do
      for i <- 1..5 do
        memory_event = %{
          id: "multi_mem_#{i}",
          event: "Memory #{i}",
          msf: 0.7,
          oss: 0.6
        }

        OMRL.ingest_memory("observer_multi", memory_event)
      end

      Process.sleep(100)

      {:ok, memories} = OMRL.get_observer_memories("observer_multi")
      assert length(memories) == 5
    end
  end

  describe "reconcile/1" do
    test "reconciles single observer memory (no conflict)" do
      memory_event = %{
        id: "single_obs_mem",
        event: "Single observer event",
        weight: 0.9,
        msf: 0.8,
        oss: 0.75,
        coherence: 0.85
      }

      OMRL.ingest_memory("solo_observer", memory_event)
      Process.sleep(50)

      {:ok, result} = OMRL.reconcile("single_obs_mem")

      assert result.memory_id == "single_obs_mem"
      assert result.contributor_count == 1
      assert result.mode == nil  # No reconciliation needed for single observer
    end

    test "reconciles multiple observers with blended mode" do
      # Two observers with similar, stable memories
      mem_a = %{
        id: "blend_test",
        event: "Event happened similarly",
        weight: 0.8,
        msf: 0.85,
        oss: 0.80,
        coherence: 0.90,
        interference: 0.2
      }

      mem_b = %{
        id: "blend_test",
        event: "Event happened similarly",
        weight: 0.7,
        msf: 0.80,
        oss: 0.75,
        coherence: 0.85,
        interference: 0.25
      }

      OMRL.ingest_memory("stable_obs_a", mem_a)
      OMRL.ingest_memory("stable_obs_b", mem_b)
      Process.sleep(100)

      {:ok, result} = OMRL.reconcile("blend_test")

      assert result.memory_id == "blend_test"
      assert result.contributor_count == 2
      assert result.mode == :blended
      assert length(result.contributors) == 2
      assert "stable_obs_a" in result.contributors
      assert "stable_obs_b" in result.contributors
    end

    test "reconciles with layered mode for incompatible but stable memories" do
      mem_a = %{
        id: "layer_test",
        event: "Version A of history",
        weight: 0.9,
        msf: 0.85,
        oss: 0.80,
        coherence: 0.90,
        interference: 0.3
      }

      mem_b = %{
        id: "layer_test",
        event: "Version B of history",
        weight: 0.85,
        msf: 0.80,
        oss: 0.75,
        coherence: 0.85,
        interference: 0.35
      }

      OMRL.ingest_memory("layer_obs_a", mem_a)
      OMRL.ingest_memory("layer_obs_b", mem_b)
      Process.sleep(100)

      {:ok, result} = OMRL.reconcile("layer_test")

      assert result.mode == :layered
      assert result.contributor_count == 2
    end

    test "reconciles with split mode for high interference" do
      mem_a = %{
        id: "split_test",
        event: "Causal timeline A",
        weight: 0.7,
        msf: 0.6,
        oss: 0.55,
        coherence: 0.65,
        interference: 0.85  # High interference triggers split
      }

      mem_b = %{
        id: "split_test",
        event: "Causal timeline B",
        weight: 0.65,
        msf: 0.55,
        oss: 0.50,
        coherence: 0.60,
        interference: 0.90
      }

      OMRL.ingest_memory("split_obs_a", mem_a)
      OMRL.ingest_memory("split_obs_b", mem_b)
      Process.sleep(100)

      {:ok, result} = OMRL.reconcile("split_test")

      assert result.mode == :split
    end

    test "returns error for non-existent memory" do
      assert {:error, :no_observers} = OMRL.reconcile("non_existent_mem")
    end

    test "caches reconciliation result" do
      memory_event = %{
        id: "cache_test",
        event: "Cached memory",
        msf: 0.8,
        oss: 0.75
      }

      OMRL.ingest_memory("cache_observer", memory_event)
      Process.sleep(50)

      # First reconciliation
      {:ok, result1} = OMRL.reconcile("cache_test")

      # Should be cached
      {:ok, cached} = OMRL.get_cached_reconciliation("cache_test")
      assert cached.memory_id == "cache_test"

      # Invalidate cache
      :ok = OMRL.invalidate_cache("cache_test")
      assert {:error, :not_found} = OMRL.get_cached_reconciliation("cache_test")
    end
  end

  describe "analyze_contradiction/2" do
    test "identifies low contradiction (blended mode)" do
      mem_a = %{
        event: "Similar event description",
        msf: 0.85,
        oss: 0.80,
        coherence: 0.90,
        interference: 0.2
      }

      mem_b = %{
        event: "Similar event description",
        msf: 0.80,
        oss: 0.75,
        coherence: 0.85,
        interference: 0.25
      }

      {:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)

      assert analysis.mode == :blended
      assert analysis.contradiction_score == 0.0  # Identical events
      assert analysis.recommendation =~ "probabilistic composite"
    end

    test "identifies high contradiction with high interference (split mode)" do
      mem_a = %{
        event: "Timeline alpha",
        msf: 0.6,
        oss: 0.55,
        coherence: 0.65,
        interference: 0.85
      }

      mem_b = %{
        event: "Timeline beta",
        msf: 0.55,
        oss: 0.50,
        coherence: 0.60,
        interference: 0.90
      }

      {:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)

      assert analysis.mode == :split
      assert analysis.recommendation =~ "separate causal timelines"
    end

    test "identifies moderate contradiction (layered mode)" do
      mem_a = %{
        event: "History version one",
        msf: 0.80,
        oss: 0.75,
        coherence: 0.85,
        interference: 0.4
      }

      mem_b = %{
        event: "History version two",
        msf: 0.75,
        oss: 0.70,
        coherence: 0.80,
        interference: 0.45
      }

      {:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)

      assert analysis.mode == :layered
      assert analysis.recommendation =~ "stratified"
    end
  end

  describe "full_sweep/0" do
    test "reconciles all multi-observer memories" do
      # Create several memories with multiple observers
      for i <- 1..3 do
        mem_a = %{
          id: "sweep_mem_#{i}",
          event: "Sweep event #{i} - A",
          msf: 0.8,
          oss: 0.75
        }

        mem_b = %{
          id: "sweep_mem_#{i}",
          event: "Sweep event #{i} - B",
          msf: 0.75,
          oss: 0.70
        }

        OMRL.ingest_memory("sweep_obs_a_#{i}", mem_a)
        OMRL.ingest_memory("sweep_obs_b_#{i}", mem_b)
      end

      Process.sleep(150)

      # Perform full sweep
      assert {:ok, :sweep_initiated} = OMRL.full_sweep()
      Process.sleep(200)

      # Check stats to verify reconciliations occurred
      {:ok, stats} = OMRL.stats()
      assert stats.total_reconciled >= 3
    end
  end

  describe "stats/0" do
    test "returns accurate statistics" do
      # Ingest some memories
      for i <- 1..5 do
        mem = %{
          id: "stat_mem_#{i}",
          event: "Stat test #{i}",
          msf: 0.7 + i * 0.05,
          oss: 0.6 + i * 0.05
        }

        observer = if rem(i, 2) == 0, do: "obs_even", else: "obs_odd"
        OMRL.ingest_memory(observer, mem)
      end

      Process.sleep(100)

      {:ok, stats} = OMRL.stats()

      assert stats.total_ingested == 5
      assert stats.total_unique_memories == 5
      assert is_map(stats.mode_distribution)
      assert Map.has_key?(stats.mode_distribution, :blended)
      assert Map.has_key?(stats.mode_distribution, :layered)
      assert Map.has_key?(stats.mode_distribution, :split)
    end

    test "tracks mode distribution correctly" do
      # Force different modes through specific configurations
      # Blended
      blended_a = %{id: "mode_blend", event: "same", msf: 0.9, oss: 0.85, interference: 0.1}
      blended_b = %{id: "mode_blend", event: "same", msf: 0.85, oss: 0.80, interference: 0.15}
      OMRL.ingest_memory("blend_a", blended_a)
      OMRL.ingest_memory("blend_b", blended_b)

      Process.sleep(100)
      OMRL.reconcile("mode_blend")
      Process.sleep(50)

      {:ok, stats} = OMRL.stats()
      assert stats.mode_distribution.blended > 0
    end
  end

  describe "ETS table management" do
    test "stores memories in ETS correctly" do
      memory_event = %{
        id: "ets_test",
        event: "ETS storage test",
        msf: 0.8,
        oss: 0.75
      }

      OMRL.ingest_memory("ets_observer", memory_event)
      Process.sleep(50)

      # Verify ETS table has entry
      table_size = :ets.info(:omrl_memory_store, :size)
      assert table_size > 0

      # Verify we can retrieve it
      {:ok, memories} = OMRL.get_observer_memories("ets_observer")
      assert length(memories) > 0
    end

    test "handles concurrent access safely" do
      tasks =
        for i <- 1..20 do
          Task.async(fn ->
            mem = %{
              id: "concurrent_#{i}",
              event: "Concurrent test #{i}",
              msf: 0.7,
              oss: 0.65
            }

            OMRL.ingest_memory("concurrent_obs", mem)
          end)
        end

      Task.await_many(tasks, 5000)
      Process.sleep(200)

      {:ok, memories} = OMRL.get_observer_memories("concurrent_obs")
      assert length(memories) == 20
    end
  end

  describe "edge cases and error handling" do
    test "handles malformed memory events gracefully" do
      malformed_event = %{}  # Empty map

      # Should not crash
      assert {:ok, :accepted} = OMRL.ingest_memory("malformed_obs", malformed_event)
      Process.sleep(50)

      # Should still store with defaults
      {:ok, memories} = OMRL.get_observer_memories("malformed_obs")
      assert length(memories) > 0
    end

    test "handles very large number of observers for single memory" do
      for i <- 1..50 do
        mem = %{
          id: "many_observers",
          event: "Many observer test",
          msf: 0.7 + rem(i, 10) * 0.02,
          oss: 0.65 + rem(i, 10) * 0.02
        }

        OMRL.ingest_memory("observer_#{i}", mem)
      end

      Process.sleep(200)

      {:ok, result} = OMRL.reconcile("many_observers")
      assert result.contributor_count == 50
    end

    test "maintains consistency after cache invalidation" do
      mem = %{
        id: "invalidate_test",
        event: "Cache invalidation test",
        msf: 0.8,
        oss: 0.75
      }

      OMRL.ingest_memory("inv_observer", mem)
      Process.sleep(50)

      # Reconcile and cache
      {:ok, _result1} = OMRL.reconcile("invalidate_test")
      {:ok, _cached} = OMRL.get_cached_reconciliation("invalidate_test")

      # Invalidate
      :ok = OMRL.invalidate_cache("invalidate_test")

      # Re-reconcile should work
      {:ok, result2} = OMRL.reconcile("invalidate_test")
      assert result2.memory_id == "invalidate_test"
    end
  end

  describe "integration scenarios" do
    test "complete lifecycle: ingest → reconcile → cache → invalidate" do
      # Step 1: Ingest from multiple observers
      mem_a = %{
        id: "lifecycle_test",
        event: "Lifecycle event",
        weight: 0.9,
        msf: 0.85,
        oss: 0.80,
        coherence: 0.90
      }

      mem_b = %{
        id: "lifecycle_test",
        event: "Lifecycle event",
        weight: 0.85,
        msf: 0.80,
        oss: 0.75,
        coherence: 0.85
      }

      OMRL.ingest_memory("lifecycle_a", mem_a)
      OMRL.ingest_memory("lifecycle_b", mem_b)
      Process.sleep(100)

      # Step 2: Reconcile
      {:ok, result} = OMRL.reconcile("lifecycle_test")
      assert result.mode == :blended

      # Step 3: Verify cached
      {:ok, cached} = OMRL.get_cached_reconciliation("lifecycle_test")
      assert cached.mode == :blended

      # Step 4: Invalidate and re-reconcile
      :ok = OMRL.invalidate_cache("lifecycle_test")
      {:ok, result2} = OMRL.reconcile("lifecycle_test")
      assert result2.mode == :blended
    end

    test "memory persistence across multiple reconciliations" do
      mem = %{
        id: "persistence_test",
        event: "Persistent memory",
        msf: 0.8,
        oss: 0.75
      }

      OMRL.ingest_memory("persist_obs", mem)
      Process.sleep(50)

      # Reconcile multiple times
      for _ <- 1..5 do
        {:ok, result} = OMRL.reconcile("persistence_test")
        assert result.memory_id == "persistence_test"
      end

      # Stats should show multiple reconciliations
      {:ok, stats} = OMRL.stats()
      assert stats.total_reconciled >= 5
    end
  end
end
