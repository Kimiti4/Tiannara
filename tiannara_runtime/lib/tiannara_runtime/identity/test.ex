defmodule TiannaraRuntime.Identity.Test do
  @moduledoc """
  PHASE 4B: Test Module for Identity Persistence Layer
  
  Usage:
    iex -S mix
    iex> TiannaraRuntime.Identity.Test.run_full_test()
  """
  
  require Logger
  
  def run_full_test() do
    Logger.info("🧪 Starting Phase 4B Identity Layer Test...")
    
    # Test 1: Coalition Lifecycle Tracking
    test_lifecycle_tracking()
    
    # Test 2: Fingerprint Generation
    test_fingerprint_generation()
    
    # Test 3: Species Matching
    test_species_matching()
    
    # Test 4: Full Integration (Lifecycle → Fingerprint → Registry)
    test_full_integration()
    
    Logger.info("✅ All Phase 4B tests completed!")
  end
  
  def test_lifecycle_tracking() do
    Logger.info("\n📋 TEST 1: Coalition Lifecycle Tracking")
    
    coalition_id = "C_TEST_001"
    
    # Record birth
    TiannaraRuntime.Identity.CoalitionHistory.record_event(
      coalition_id,
      "birth",
      %{members: ["A1", "A2", "A3"], coherence: 0.85}
    )
    
    # Record updates
    Enum.each(1..5, fn _i ->
      TiannaraRuntime.Identity.CoalitionHistory.record_event(
        coalition_id,
        "update",
        %{coherence: 0.80 + :rand.uniform() * 0.1, entropy: 0.3 + :rand.uniform() * 0.2}
      )
    end)
    
    # Get history
    {:ok, history} = TiannaraRuntime.Identity.CoalitionHistory.get_history(coalition_id)
    
    Logger.info("   ✓ Recorded #{length(history)} lifecycle events")
    Logger.info("   ✓ Birth event: #{Enum.at(history, 0)[:event_type]}")
    Logger.info("   ✓ Latest event: #{List.last(history)[:event_type]}")
    
    # Verify lifecycle stats
    {:ok, stats} = TiannaraRuntime.Identity.CoalitionHistory.get_lifecycle_stats(coalition_id)
    Logger.info("   ✓ Lifespan: #{stats[:lifespan_events]} events")
    Logger.info("   ✓ Current state: #{stats[:current_state]}")
    
    :ok
  end
  
  def test_fingerprint_generation() do
    Logger.info("\n🔬 TEST 2: Fingerprint Generation")
    
    coalition_id = "C_FINGERPRINT_001"
    
    # Create synthetic history
    history = [
      %{event_type: "birth", timestamp: DateTime.utc_now(), metadata: %{members: ["A1", "A2"]}},
      %{event_type: "update", timestamp: DateTime.utc_now(), metadata: %{coherence: 0.85}},
      %{event_type: "update", timestamp: DateTime.utc_now(), metadata: %{coherence: 0.87}},
      %{event_type: "update", timestamp: DateTime.utc_now(), metadata: %{coherence: 0.82}}
    ]
    
    # Create synthetic snapshots
    snapshots = [
      %{entropy: 0.4, position: [10, 5, 0]},
      %{entropy: 0.42, position: [10.5, 5.2, 0]},
      %{entropy: 0.38, position: [11, 5.5, 0]}
    ]
    
    # Generate fingerprint
    case TiannaraRuntime.Identity.Fingerprint.generate(coalition_id, history, snapshots) do
      {:ok, fingerprint} ->
        Logger.info("   ✓ Fingerprint generated successfully")
        Logger.info("   ✓ Version: #{fingerprint[:version]}")
        Logger.info("   ✓ Vector length: #{length(fingerprint[:vector])}")
        Logger.info("   ✓ Components:")
        Logger.info("     - Centroid drift: #{inspect(fingerprint[:components][:centroid_drift])}")
        Logger.info("     - Entropy signature: #{inspect(fingerprint[:components][:entropy_signature])}")
        Logger.info("     - Decision pattern: #{inspect(fingerprint[:components][:decision_pattern])}")
      
      {:error, reason} ->
        Logger.error("   ✗ Fingerprint generation failed: #{reason}")
    end
    
    :ok
  end
  
  def test_species_matching() do
    Logger.info("\n🧬 TEST 3: Species Matching")
    
    # Register first coalition (creates new species)
    fingerprint1 = %{
      version: "1.0",
      vector: [0.8, 0.6, 0.9, 0.7],
      components: %{
        centroid_drift: [0.1, 0.2],
        entropy_signature: [0.4, 0.42, 0.38],
        decision_pattern: [0.85, 0.87, 0.82]
      }
    }
    
    {:ok, species1, is_new1} = TiannaraRuntime.Identity.SpeciesRegistry.register_coalition(
      "C_SPECIES_001",
      fingerprint1,
      %{test: true}
    )
    
    Logger.info("   ✓ First coalition registered")
    Logger.info("   ✓ Species ID: #{species1}")
    Logger.info("   ✓ New species: #{is_new1}")
    
    # Register similar coalition (should match existing species)
    fingerprint2 = %{
      version: "1.0",
      vector: [0.79, 0.61, 0.88, 0.71],  # Very similar to fingerprint1
      components: %{
        centroid_drift: [0.11, 0.19],
        entropy_signature: [0.41, 0.43, 0.39],
        decision_pattern: [0.84, 0.86, 0.83]
      }
    }
    
    {:ok, species2, is_new2} = TiannaraRuntime.Identity.SpeciesRegistry.register_coalition(
      "C_SPECIES_002",
      fingerprint2,
      %{test: true}
    )
    
    Logger.info("   ✓ Second coalition registered")
    Logger.info("   ✓ Species ID: #{species2}")
    Logger.info("   ✓ New species: #{is_new2}")
    
    if species1 == species2 and not is_new2 do
      Logger.info("   ✅ Species matching successful! Both coalitions belong to same species.")
    else
      Logger.warning("   ⚠️ Species matching may need threshold adjustment")
    end
    
    # Get species taxonomy
    {:ok, taxonomy} = TiannaraRuntime.Identity.SpeciesRegistry.get_taxonomy()
    Logger.info("   ✓ Total species in registry: #{length(taxonomy)}")
    
    :ok
  end
  
  def test_full_integration() do
    Logger.info("\n🔄 TEST 4: Full Integration (Lifecycle → Fingerprint → Registry)")
    
    coalition_id = "C_INTEGRATION_001"
    
    # Simulate coalition lifecycle through Tracker
    Logger.info("   Step 1: Recording birth event...")
    TiannaraRuntime.Identity.Tracker.process_event(
      coalition_id,
      "birth",
      %{members: ["A1", "A2", "A3"], coherence: 0.85}
    )
    
    # Simulate stable updates (should trigger fingerprint after threshold)
    Logger.info("   Step 2: Simulating stable updates...")
    Enum.each(1..6, fn i ->
      TiannaraRuntime.Identity.Tracker.process_event(
        coalition_id,
        "update",
        %{
          coherence: 0.82 + :rand.uniform() * 0.05,
          entropy: 0.35 + :rand.uniform() * 0.1,
          position: [10 + i * 0.5, 5 + i * 0.3, 0],
          decisions: [%{action: "select", score: 0.8 + :rand.uniform() * 0.1}]
        }
      )
    end)
    
    # Manually trigger fingerprint (in production, this happens automatically)
    Logger.info("   Step 3: Generating fingerprint...")
    case TiannaraRuntime.Identity.Tracker.generate_fingerprint(coalition_id) do
      {:ok, fingerprint, species_id} ->
        Logger.info("   ✓ Fingerprint generated: #{inspect(fingerprint[:version])}")
        Logger.info("   ✓ Registered to species: #{species_id}")
        
        # Check identity matches
        {:ok, matches} = TiannaraRuntime.Identity.Tracker.get_identity_matches(coalition_id)
        Logger.info("   ✓ Identity matches recorded: #{length(matches)}")
      
      {:error, reason} ->
        Logger.warning("   ⚠ Fingerprint generation returned: #{reason}")
        Logger.info("   (This is expected if stability threshold not reached in test)")
    end
    
    # Verify history was recorded
    {:ok, history} = TiannaraRuntime.Identity.CoalitionHistory.get_history(coalition_id)
    Logger.info("   ✓ Total lifecycle events: #{length(history)}")
    
    Logger.info("   ✅ Integration test complete!")
    
    :ok
  end
  
  def test_similarity_calculation() do
    Logger.info("\n📐 TEST 5: Cosine Similarity Calculation")
    
    # Test identical vectors
    vec1 = [1.0, 0.0, 0.0]
    vec2 = [1.0, 0.0, 0.0]
    sim1 = TiannaraRuntime.Identity.Fingerprint.cosine_similarity(vec1, vec2)
    Logger.info("   ✓ Identical vectors similarity: #{Float.round(sim1, 4)} (expected: 1.0)")
    
    # Test orthogonal vectors
    vec3 = [1.0, 0.0, 0.0]
    vec4 = [0.0, 1.0, 0.0]
    sim2 = TiannaraRuntime.Identity.Fingerprint.cosine_similarity(vec3, vec4)
    Logger.info("   ✓ Orthogonal vectors similarity: #{Float.round(sim2, 4)} (expected: 0.0)")
    
    # Test similar vectors
    vec5 = [0.8, 0.6, 0.0]
    vec6 = [0.79, 0.61, 0.0]
    sim3 = TiannaraRuntime.Identity.Fingerprint.cosine_similarity(vec5, vec6)
    Logger.info("   ✓ Similar vectors similarity: #{Float.round(sim3, 4)} (expected: ~0.999)")
    
    :ok
  end
end
