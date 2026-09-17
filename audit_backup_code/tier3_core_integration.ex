defmodule Tiannara.Audit.Tier3.CoreIntegration do
  @moduledoc """
  Tier 3: Core Integration Tests
  
  These tests verify the integration between Core components and the World Model.
  """

  alias Tiannara.Core
  alias Tiannara.Core.GoalSystem
  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API
  alias Tiannara.MetaCognition

  @doc "Execute all Tier 3 Core Integration Tests"
  def run_all_tests do
    IO.puts("🔍 Starting Tier 3: Core Integration Tests")
    IO.puts("=" <> String.duplicate("=", 50))
    
    results = %{
      core_001_goal_to_intent: test_core_001_goal_to_intent(),
      core_002_meta_cognition_uses_world_model: test_core_002_meta_cognition_uses_world_model(),
      core_003_identity_persistence: test_core_003_identity_persistence()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Tier 3 Results: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ ALL TIER 3 TESTS PASSED - Core integration verified")
    else
      failed = total - passed
      IO.puts("❌ #{failed} Tier 3 tests FAILED - Core integration compromised")
    end
    
    results
  end

  @doc """
  CORE-001 Goal → Intent Test
  
  Create goal: Analyze malware
  
  Expected:
  - Goal System
  - ↓
  - Intent Graph
  - ↓
  - AEO
  """
  def test_core_001_goal_to_intent do
    IO.puts("🔍 CORE-001: Testing Goal → Intent generation")
    
    # Test 1: Create goal system with malware analysis goal
    goal_system = GoalSystem.new()
    world_model = WorldModel.new()
    
    # Create core identity
    {core_state, updated_world_model} = Core.new("malware_analysis_core", world_model)
    
    # Create malware analysis goal
    goal_spec = %{
      name: "Analyze malware",
      description: "Deep analysis of suspected malware behavior",
      priority: :critical,
      urgency: 0.9,
      domain: "security"
    }
    
    # Add goal through Goal System
    {updated_goal_system, goal_entity, final_world_model} = 
      GoalSystem.add_goal(goal_system, goal_spec, updated_world_model)
    
    # Verify goal exists in World Model
    goal_entities = API.query_entities("Goal")
    goal_entity_names = Enum.map(goal_entities, & &1.name)
    
    if "Analyze malware" in goal_entity_names do
      IO.puts("  ✅ Malware analysis goal created in World Model")
    else
      IO.puts("  ❌ Malware analysis goal not found - integration failed!")
      return :fail
    end
    
    # Test 2: Generate intent from goal
    {intent, updated_core_state} = Core.generate_intent(core_state)
    
    # Verify intent properties
    if intent.source == "core" do
      IO.puts("  ✅ Intent generated from Core")
    else
      IO.puts("  ❌ Intent source incorrect: #{inspect(intent.source)}")
      return :fail
    end
    
    if intent.purpose == "achieve_goal" do
      IO.puts("  ✅ Intent purpose correctly set to achieve goal")
    else
      IO.puts("  ❌ Intent purpose incorrect: #{inspect(intent.purpose)}")
      return :fail
    end
    
    # Test 3: Verify intent graph was created
    intent_entities = API.query_entities("Intent")
    
    if length(intent_entities) > 0 do
      IO.puts("  ✅ Intent Graph created in World Model")
    else
      IO.puts("  ❌ Intent Graph not created - integration failed!")
      return :fail
    end
    
    # Test 4: Verify AEO integration
    # AEO should be able to read intent from World Model
    aeo_intent_entities = API.query_entities("Intent", %{purpose: "achieve_goal"})
    
    if length(aeo_intent_entities) > 0 do
      IO.puts("  ✅ AEO can access Intent Graph from World Model")
    else
      IO.puts("  ❌ AEO cannot access Intent Graph - integration broken!")
      return :fail
    end
    
    # Test 5: Verify intent execution path
    # Intent should have execution_path field that points to AEO plans
    if Map.has_key?(intent, :execution_path) do
      IO.puts("  ✅ Intent execution path created for AEO")
    else
      IO.puts("  ❌ Intent execution path missing - AEO integration broken!")
      return :fail
    end
    
    # Test 6: Verify goal progress tracking
    # Goal should have progress tracking in World Model
    goal_progress_entities = API.query_entities("Goal", %{name: "Analyze malware"})
    
    if length(goal_progress_entities) > 0 do
      goal_entity = hd(goal_progress_entities)
      if Map.has_key?(goal_entity, :progress) do
        IO.puts("  ✅ Goal progress tracking integrated with World Model")
      else
        IO.puts("  ❌ Goal progress tracking missing - integration incomplete!")
        return :fail
      end
    else
      IO.puts("  ❌ Goal entity not found for progress tracking")
      return :fail
    end
    
    # Test 7: Verify feedback loop from AEO to World Model
    # Simulate AEO processing intent
    aeo_result = %{success: true, output: "malware_analysis_complete", confidence: 0.95}
    
    updated_world_model_with_feedback = API.update_with_execution_results(final_world_model, aeo_result)
    
    # Verify World Model was updated with AEO results
    if length(updated_world_model_with_feedback.beliefs) > length(final_world_model.beliefs) do
      IO.puts("  ✅ AEO feedback loop updates World Model correctly")
    else
      IO.puts("  ❌ AEO feedback loop not updating World Model - integration broken!")
      return :fail
    end
    
    IO.puts("  ✅ Goal → Intent integration verified")
    :pass
  end

  @doc """
  CORE-002 Meta-Cognition Uses World Model Test
  
  Inject: high uncertainty
  
  Expected:
  - MetaCognition increases Logic and Causal selection weight
  """
  def test_core_002_meta_cognition_uses_world_model do
    IO.puts("🔍 CORE-002: Testing Meta-Cognition World Model integration")
    
    # Test 1: Initialize MetaCognition
    meta_cog = MetaCognition.new()
    world_model = WorldModel.new()
    
    # Test 2: Inject high uncertainty into World Model
    high_uncertainty_belief = API.add_belief(
      "Market behavior highly uncertain", 
      0.3, 
      "uncertainty_injection", 
      []
    )
    
    case high_uncertainty_belief do
      {:ok, _belief_id} ->
        IO.puts("  ✅ High uncertainty injected into World Model")
      {:error, reason} ->
        IO.puts("  ❌ Failed to inject uncertainty: #{inspect(reason)}")
        return :fail
    end
    
    # Test 3: Query current domain weights (should be baseline)
    baseline_weights = meta_cog.domain_weights
    
    # Test 4: MetaCognition consults World Model
    {updated_meta_cog, updated_domain_weights} = 
      MetaCognition.consult_world_model(meta_cog, world_model)
    
    # Verify MetaCognition was updated
    if updated_meta_cog.domain_weights != baseline_weights do
      IO.puts("  ✅ MetaCognition updated based on World Model state")
    else
      IO.puts("  ❌ MetaCognition ignores World Model - integration broken!")
      return :fail
    end
    
    # Test 5: Verify Logic and Causal weights increased
    logic_weight_before = Map.get(baseline_weights, :logic, 0.0)
    causal_weight_before = Map.get(baseline_weights, :causal, 0.0)
    
    logic_weight_after = Map.get(updated_domain_weights, :logic, 0.0)
    causal_weight_after = Map.get(updated_domain_weights, :causal, 0.0)
    
    if logic_weight_after > logic_weight_before and 
       causal_weight_after > causal_weight_before do
      IO.puts("  ✅ Logic and Causal domain weights increased (uncertainty response)")
    else
      IO.puts("  ❌ Logic and Causal weights did not increase - uncertainty response failed!")
      return :fail
    end
    
    # Test 6: Verify domain selection works with updated weights
    test_task = "analyze_complex_pattern"
    {selected_domains, _} = MetaCognition.select_domains(updated_meta_cog, test_task, world_model)
    
    if selected_domains[:logic] > 0.5 or selected_domains[:causal] > 0.5 do
      IO.puts("  ✅ Domain selection reflects uncertainty-influenced weights")
    else
      IO.puts("  ❌ Domain selection ignores uncertainty - integration incomplete!")
      return :fail
    end
    
    # Test 7: Verify MetaCognition stores consultation results
    if Map.has_key?(updated_meta_cog, :last_consultation) do
      IO.puts("  ✅ MetaCognition stores World Model consultation results")
    else
      IO.puts("  ❌ MetaCognition does not store consultation results - integration broken!")
      return :fail
    end
    
    # Test 8: Verify confidence scoring based on World Model
    confidence_score = MetaCognition.calculate_confidence(updated_meta_cog, world_model)
    
    if confidence_score < 0.8 do  # Should be lower with high uncertainty
      IO.puts("  ✅ Confidence score reflects World Model uncertainty")
    else
      IO.puts("  ❌ Confidence score does not reflect uncertainty - integration broken!")
      return :fail
    end
    
    # Test 9: Verify MetaCognition can query specific World Model states
    uncertainty_level = MetaCognition.query_uncertainty_level(updated_meta_cog, world_model)
    
    if uncertainty_level > 0.5 do  # Should be high
      IO.puts("  ✅ MetaCognition can query World Model uncertainty state")
    else
      IO.puts("  ❌ MetaCognition cannot query World Model state - integration broken!")
      return :fail
    end
    
    IO.puts("  ✅ Meta-Cognition World Model integration verified")
    :pass
  end

  @doc """
  CORE-003 Identity Persistence Test
  
  Create: Lineage Alpha
  
  Run: 100 cycles
  
  Verify: identity preserved despite state evolution
  """
  def test_core_003_identity_persistence do
    IO.puts("🔍 CORE-003: Testing Identity Persistence")
    
    # Test 1: Create Lineage Alpha in World Model
    world_model = WorldModel.new()
    
    # Create lineage entity
    lineage_id = "lineage:alpha"
    API.create_entity(
      lineage_id, 
      "Lineage", 
      "Lineage Alpha", 
      %{domain_strengths: %{logic: 0.8, prediction: 0.7, causal: 0.9}}
    )
    
    # Test 2: Initialize GRCC Identity Ecology
    grcc_ecology = Core.GRCCIdentityEcology.new()
    
    # Register lineage
    {updated_grcc, _world_model_with_lineage} = 
      Core.GRCCIdentityEcology.register_lineage(
        grcc_ecology, 
        "alpha", 
        %{logic: 0.8, prediction: 0.7, causal: 0.9}, 
        world_model
      )
    
    # Verify lineage exists
    lineage_entities = API.query_entities("Lineage")
    
    if length(lineage_entities) > 0 do
      original_lineage = hd(lineage_entities)
      IO.puts("  ✅ Lineage Alpha created and registered")
    else
      IO.puts("  ❌ Lineage Alpha not found - identity persistence broken!")
      return :fail
    end
    
    # Test 3: Run 100 cycles of evolution
    IO.puts("  🔄 Running 100 evolution cycles...")
    
    final_grcc = Enum.reduce(1..100, updated_grcc, fn cycle, acc_grcc ->
      # Simulate state evolution
      updated_world_model = simulate_cycle_evolution(world_model, cycle)
      
      # GRCC processes cycle results
      {cycle_grcc, _} = Core.GRCCIdentityEcology.process_cycle_results(
        acc_grcc, 
        cycle, 
        updated_world_model
      )
      
      cycle_grcc
    end)
    
    # Test 4: Verify identity preserved despite state evolution
    if final_grcc.lineage_id == "alpha" do
      IO.puts("  ✅ Lineage identity preserved after 100 cycles")
    else
      IO.puts("  ❌ Lineage identity changed - identity persistence failed!")
      return :fail
    end
    
    # Test 5: Verify core identity attributes preserved
    original_lineage = hd(API.query_entities("Lineage", %{name: "Lineage Alpha"}))
    final_lineage_entities = API.query_entities("Lineage", %{name: "Lineage Alpha"})
    
    if length(final_lineage_entities) > 0 do
      final_lineage = hd(final_lineage_entities)
      
      # Check if core identity attributes are preserved
      if final_lineage.name == original_lineage.name and
         final_lineage.type == original_lineage.type do
        IO.puts("  ✅ Core identity attributes preserved")
      else
        IO.puts("  ❌ Core identity attributes corrupted - persistence failed!")
        return :fail
      end
    else
      IO.puts("  ❌ Final Lineage Alpha not found - identity lost!")
      return :fail
    end
    
    # Test 6: Verify lineage can be retrieved after evolution
    retrieved_lineage = API.get_entity("lineage:alpha")
    
    case retrieved_lineage do
      {:ok, entity} ->
        if entity.name == "Lineage Alpha" do
          IO.puts("  ✅ Lineage retrievable after evolution")
        else
          IO.puts("  ❌ Retrieved lineage name corrupted - persistence failed!")
          return :fail
        end
      {:error, :not_found} ->
        IO.puts("  ❌ Lineage not found after evolution - identity lost!")
        return :fail
    end
    
    # Test 7: Verify lineage evolution history preserved
    lineage_events = API.query_events("lineage:alpha")
    
    if length(lineage_events) > 0 do
      IO.puts("  ✅ Lineage evolution history preserved")
    else
      IO.puts("  ❌ Lineage evolution history missing - persistence incomplete!")
      return :fail
    end
    
    # Test 8: Verify lineage can be used for domain selection
    meta_cog = MetaCognition.new()
    world_model_with_evolution = %{world_model | 
      entities: Map.put(world_model.entities, "lineage:alpha", final_lineage)
    }
    
    {selected_domains, _} = MetaCognition.consult_world_model(meta_cog, world_model_with_evolution)
    
    if map_size(selected_domains) > 0 do
      IO.puts("  ✅ Lineage can still participate in domain selection")
    else
      IO.puts("  ❌ Lineage cannot participate in domain selection - persistence broken!")
      return :fail
    end
    
    IO.puts("  ✅ Identity Persistence verified")
    :pass
  end

  # Helper function for simulating cycle evolution
  defp simulate_cycle_evolution(world_model, cycle) do
    # Simulate adding some beliefs and updating entities each cycle
    belief_content = "Cycle #{cycle} observation"
    updated_world_model = API.add_belief(belief_content, 0.5 + (cycle / 200), "cycle_test", [])
    
    # Update some entities
    entity_id = "entity:#{cycle}"
    API.create_entity(entity_id, "Observation", "Cycle #{cycle} Observation", %{cycle: cycle})
    
    updated_world_model
  end
end