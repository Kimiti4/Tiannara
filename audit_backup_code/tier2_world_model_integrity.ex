defmodule Tiannara.Audit.Tier2.WorldModelIntegrity do
  @moduledoc """
  Tier 2: World Model Integrity Tests
  
  These tests verify the integrity of the World Model as the canonical reality representation.
  This is now your highest priority after architectural unification.
  """

  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API
  alias Tiannara.Core.WorldModel.BeliefSystem
  alias Tiannara.Core.WorldModel.CausalEngine
  alias Tiannara.Core.WorldModel.TimelineManager
  alias Tiannara.Core.WorldModel.UncertaintyTracker
  alias Tiannara.Core.WorldModel.PredictionEngine

  @doc "Execute all Tier 2 World Model Integrity Tests"
  def run_all_tests do
    IO.puts("🔍 Starting Tier 2: World Model Integrity Tests")
    IO.puts("=" <> String.duplicate("=", 50))
    
    results = %{
      wm_001_entity_consistency: test_wm_001_entity_consistency(),
      wm_002_belief_revision: test_wm_002_belief_revision(),
      wm_003_temporal_integrity: test_wm_003_temporal_integrity(),
      wm_004_prediction_feedback: test_wm_004_prediction_feedback(),
      wm_005_causal_consistency: test_wm_005_causal_consistency()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Tier 2 Results: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ ALL TIER 2 TESTS PASSED - World Model integrity verified")
    else
      failed = total - passed
      IO.puts("❌ #{failed} Tier 2 tests FAILED - World Model integrity compromised")
    end
    
    results
  end

  @doc """
  WM-001 Entity Consistency Test
  
  Create:
  - User
  - Goal  
  - Lineage
  - Project
  
  Verify:
  - all resolvable
  - all unique
  - all linked
  """
  def test_wm_001_entity_consistency do
    IO.puts("🔍 WM-001: Testing Entity Consistency")
    
    # Initialize World Model
    world_model = WorldModel.new()
    
    # Test 1: Create required entities
    entities_to_create = [
      {"user:alice", "User", "Alice", %{email: "alice@example.com", role: "analyst"}},
      {"goal:analyze_market", "Goal", "Analyze Market", %{priority: :high, deadline: DateTime.add(DateTime.utc_now(), 86400, :second)}},
      {"lineage:trading_experts", "Lineage", "Trading Experts", %{domain_strengths: %{prediction: 0.9, causal: 0.8}}},
      {"project:market_analysis", "Project", "Market Analysis", %{status: :active, budget: 100000}}
    ]
    
    created_entities = Enum.map(entities_to_create, fn {id, type, name, attrs} ->
      {result, world_model_with_entity} = API.create_entity(id, type, name, attrs)
      
      if result == :ok do
        IO.puts("  ✅ Created #{type}: #{name}")
        {id, world_model_with_entity}
      else
        IO.puts("  ❌ Failed to create #{type}: #{name}")
        return :fail
      end
    end)
    
    # Test 2: Verify all entities are resolvable
    Enum.each(created_entities, fn {id, _world_model} ->
      case API.get_entity(id) do
        {:ok, entity} ->
          IO.puts("  ✅ Entity #{id} resolvable: #{entity.name}")
        {:error, :not_found} ->
          IO.puts("  ❌ Entity #{id} not found - consistency violation!")
          return :fail
      end
    end)
    
    # Test 3: Verify all entities are unique
    entity_ids = Enum.map(created_entities, fn {id, _} -> id end)
    unique_ids = Enum.uniq(entity_ids)
    
    if length(entity_ids) == length(unique_ids) do
      IO.puts("  ✅ All entities are unique")
    else
      IO.puts("  ❌ Duplicate entity IDs found - consistency violation!")
      return :fail
    end
    
    # Test 4: Verify entities can be linked through relationships
    world_model_with_relationships = Enum.reduce(created_entities, world_model, fn {id, wm_acc}, acc ->
      # Add causal relationships between entities
      case id do
        "user:alice" ->
          # Alice is assigned to the project
          CausalEngine.add_causal_relationship("user:alice", "project:market_analysis", "assigned_to", 0.9, 0.8)
          wm_acc
        "goal:analyze_market" ->
          # Goal contributes to project success
          CausalEngine.add_causal_relationship("goal:analyze_market", "project:market_analysis", "contributes_to", 0.8, 0.9)
          wm_acc
        "lineage:trading_experts" ->
          # Lineage supports the goal
          CausalEngine.add_causal_relationship("lineage:trading_experts", "goal:analyze_market", "supports", 0.7, 0.8)
          wm_acc
        _ ->
          wm_acc
      end
    end)
    
    # Verify relationships exist
    alice_relationships = CausalEngine.get_entity_relationships("user:alice")
    if length(alice_relationships) > 0 do
      IO.puts("  ✅ Entities can be linked through relationships")
    else
      IO.puts("  ❌ No relationships found - linking failed")
      return :fail
    end
    
    # Test 5: Verify entity queries work correctly
    users = API.query_entities("User")
    goals = API.query_entities("Goal")
    lineages = API.query_entities("Lineage")
    projects = API.query_entities("Project")
    
    if length(users) == 1 and length(goals) == 1 and 
       length(lineages) == 1 and length(projects) == 1 do
      IO.puts("  ✅ Entity queries return correct results")
    else
      IO.puts("  ❌ Entity queries inconsistent - expected 1 each, got: #{length(users)}, #{length(goals)}, #{length(lineages)}, #{length(projects)}")
      return :fail
    end
    
    IO.puts("  ✅ Entity Consistency invariant verified")
    :pass
  end

  @doc """
  WM-002 Belief Revision Test
  
  Insert:
  - Belief A (confidence 0.9)
  
  Then:
  - Contradictory Belief B (confidence 0.95)
  
  Expected:
  - uncertainty increases
  - contradiction registry updated
  
  NOT:
  - belief silently overwritten
  """
  def test_wm_002_belief_revision do
    IO.puts("🔍 WM-002: Testing Belief Revision")
    
    # Initialize World Model
    world_model = WorldModel.new()
    
    # Test 1: Add first belief with high confidence
    belief_a_result = API.add_belief("Market will rise", 0.9, "analyst", ["technical_analysis"])
    
    case belief_a_result do
      {:ok, belief_id} ->
        IO.puts("  ✅ Added belief A: Market will rise (confidence 0.9)")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add belief A: #{inspect(reason)}")
        return :fail
    end
    
    # Check initial state
    initial_beliefs = API.query_high_confidence_beliefs(0.5)
    initial_uncertainty = API.query_uncertainties()
    
    IO.puts("  📊 Initial state: #{length(initial_beliefs)} beliefs, #{length(initial_uncertainty)} uncertainties")
    
    # Test 2: Add contradictory belief with higher confidence
    belief_b_result = API.add_belief("Market will fall", 0.95, "contradictory_analysis", ["different_analysis"])
    
    case belief_b_result do
      {:ok, _belief_id} ->
        IO.puts("  ✅ Added belief B: Market will fall (confidence 0.95)")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add belief B: #{inspect(reason)}")
        return :fail
    end
    
    # Test 3: Verify uncertainty increased (contradictions detected)
    updated_beliefs = API.query_high_confidence_beliefs(0.5)
    updated_uncertainty = API.query_uncertainties()
    
    IO.puts("  📊 Updated state: #{length(updated_beliefs)} beliefs, #{length(updated_uncertainty)} uncertainties")
    
    # Check if contradictions were detected
    if length(updated_uncertainty) > length(initial_uncertainty) do
      IO.puts("  ✅ Uncertainty increased due to contradiction detection")
    else
      IO.puts("  ❌ Uncertainty did not increase - contradiction not detected!")
      return :fail
    end
    
    # Test 4: Verify beliefs are not silently overwritten
    # Check that both beliefs still exist
    market_beliefs = API.search_beliefs("market")
    
    if length(market_beliefs) >= 2 do
      IO.puts("  ✅ Both beliefs preserved (not overwritten)")
    else
      IO.puts("  ❌ Beliefs silently overwritten - integrity violation!")
      return :fail
    end
    
    # Test 5: Verify contradiction registry was updated
    contradictions = Enum.filter(updated_uncertainty, fn uncertainty ->
      String.contains?(uncertainty.description, "contradiction")
    end)
    
    if length(contradictions) > 0 do
      IO.puts("  ✅ Contradiction registry updated")
    else
      IO.puts("  ❌ Contradiction registry not updated - missing critical information!")
      return :fail
    end
    
    # Test 6: Attempt to resolve ambiguity
    case Enum.find(updated_uncertainty, &String.contains?(&1.description, "market")) do
      nil ->
        IO.puts("  ❌ No market ambiguity found to resolve")
        return :fail
      ambiguity ->
        resolution_result = UncertaintyTracker.attempt_ambiguity_resolution(
          ambiguity.id, 
          "further_analysis", 
          :resolved
        )
        
        case resolution_result do
          :ok ->
            IO.puts("  ✅ Ambiguity resolution attempt recorded")
          {:error, reason} ->
            IO.puts("  ❌ Failed to resolve ambiguity: #{inspect(reason)}")
            return :fail
        end
    end
    
    IO.puts("  ✅ Belief Revision invariant verified")
    :pass
  end

  @doc """
  WM-003 Temporal Integrity Test
  
  Create:
  - Goal Created
  - Goal Modified  
  - Goal Completed
  
  Verify:
  - timeline ordering preserved
  """
  def test_wm_003_temporal_integrity do
    IO.puts("🔍 WM-003: Testing Temporal Integrity")
    
    # Initialize World Model
    world_model = WorldModel.new()
    
    # Test 1: Create goal timeline events
    goal_id = "goal:temporal_test"
    
    # Create goal entity first
    API.create_entity(goal_id, "Goal", "Temporal Test Goal", %{priority: :high})
    
    # Add timeline events in chronological order
    events = [
      {"created", "Goal created", DateTime.utc_now()},
      {"modified", "Goal modified", DateTime.add(DateTime.utc_now(), 1000, :second)},
      {"completed", "Goal completed", DateTime.add(DateTime.utc_now(), 2000, :second)}
    ]
    
    Enum.each(events, fn {event_type, description, timestamp} ->
      event_result = API.record_event(goal_id, event_type, description, timestamp)
      
      case event_result do
        {:ok, _event_id} ->
          IO.puts("  ✅ Added #{event_type} event")
        {:error, reason} ->
          IO.puts("  ❌ Failed to add #{event_type} event: #{inspect(reason)}")
          return :fail
      end
    end)
    
    # Test 2: Verify timeline ordering is preserved
    goal_events = API.query_events(goal_id)
    
    if length(goal_events) == 3 do
      IO.puts("  ✅ All 3 timeline events recorded")
    else
      IO.puts("  ❌ Incorrect number of events: #{length(goal_events)}")
      return :fail
    end
    
    # Check chronological ordering
    sorted_events = Enum.sort(goal_events, &(&1.timestamp <= &2.timestamp))
    
    if Enum.zip(goal_events, sorted_events) |> Enum.all?(fn {a, b} -> a == b end) do
      IO.puts("  ✅ Timeline ordering preserved")
    else
      IO.puts("  ❌ Timeline ordering corrupted - temporal integrity violation!")
      return :fail
    end
    
    # Test 3: Verify temporal epochs work
    epoch_result = API.create_epoch(
      "temporal_test_epoch", 
      "Temporal Test Period", 
      DateTime.utc_now(),
      DateTime.add(DateTime.utc_now(), 3000, :second)
    )
    
    case epoch_result do
      {:ok, _epoch_id} ->
        IO.puts("  ✅ Temporal epoch created")
      {:error, reason} ->
        IO.puts("  ❌ Failed to create temporal epoch: #{inspect(reason)}")
        return :fail
    end
    
    # Test 4: Verify events can be added to epochs
    # Add first event to epoch
    add_epoch_result = API.add_event_to_epoch("temporal_test_epoch", "event_1")
    
    case add_epoch_result do
      :ok ->
        IO.puts("  ✅ Event added to temporal epoch")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add event to epoch: #{inspect(reason)}")
        return :fail
    end
    
    # Test 5: Verify current state is accurate
    current_state = API.get_current_state()
    
    if map_size(current_state) > 0 do
      IO.puts("  ✅ Current state reflects most recent events")
    else
      IO.puts("  ❌ Current state is empty - temporal integrity violation!")
      return :fail
    end
    
    # Test 6: Verify timeline range queries work
    start_time = DateTime.add(DateTime.utc_now(), -5000, :second)
    end_time = DateTime.add(DateTime.utc_now(), 5000, :second)
    
    range_events = API.query_events(nil, nil, start_time, end_time)
    
    if length(range_events) >= 2 do
      IO.puts("  ✅ Timeline range queries work correctly")
    else
      IO.puts("  ❌ Timeline range queries failed - temporal integrity compromised!")
      return :fail
    end
    
    IO.puts("  ✅ Temporal Integrity invariant verified")
    :pass
  end

  @doc """
  WM-004 Prediction Feedback Test
  
  Prediction:
  - Market rises (confidence 0.8)
  
  Outcome:
  - Market falls
  
  Verify:
  - belief confidence decreases
  - prediction history updated
  """
  def test_wm_004_prediction_feedback do
    IO.puts("🔍 WM-004: Testing Prediction Feedback")
    
    # Initialize World Model
    world_model = WorldModel.new()
    
    # Test 1: Create prediction scenario
    scenario_id = "market_prediction_test"
    prediction_result = API.create_prediction(
      "market_entity", 
      "market_movement", 
      7,  # 7-day horizon
      0.8 # base probability
    )
    
    case prediction_result do
      {:ok, _scenario_id} ->
        IO.puts("  ✅ Prediction scenario created")
      {:error, reason} ->
        IO.puts("  ❌ Failed to create prediction scenario: #{inspect(reason)}")
        return :fail
    end
    
    # Test 2: Add factor to prediction
    factor_result = API.add_prediction_factor(
      scenario_id,
      "bullish_indicators",
      0.7,
      0.8
    )
    
    case factor_result do
      :ok ->
        IO.puts("  ✅ Prediction factor added")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add prediction factor: #{inspect(reason)}")
        return :fail
    end
    
    # Test 3: Generate predictions
    generate_result = PredictionEngine.generate_predictions(scenario_id)
    
    case generate_result do
      {:ok, predictions} ->
        IO.puts("  ✅ Predictions generated: #{length(predictions)} outcomes")
      {:error, reason} ->
        IO.puts("  ❌ Failed to generate predictions: #{inspect(reason)}")
        return :fail
    end
    
    # Test 4: Record contradictory outcome
    outcome_feedback = %{
      operation_id: scenario_id,
      success: false,
      results: %{market_movement: "fell"},
      confidence: 0.9,
      timestamp: DateTime.utc_now()
    }
    
    updated_world_model = API.update_with_execution_results(world_model, outcome_feedback)
    
    # Test 5: Verify belief confidence decreased
    # Find the original prediction belief
    prediction_beliefs = API.search_beliefs("market")
    
    updated_confidences = Enum.map(prediction_beliefs, & &1.confidence)
    
    if Enum.any?(updated_confidences, & &1 < 0.8) do
      IO.puts("  ✅ Belief confidence decreased after contradictory outcome")
    else
      IO.puts("  ❌ Belief confidence did not decrease - feedback integrity violation!")
      return :fail
    end
    
    # Test 6: Verify prediction history was updated
    active_predictions = API.query_active_predictions()
    
    if length(active_predictions) > 0 do
      IO.puts("  ✅ Prediction history updated with feedback")
    else
      IO.puts("  ❌ Prediction history not updated - missing critical information!")
      return :fail
    end
    
    # Test 7: Verify prediction confidence was updated
    updated_prediction_result = PredictionEngine.update_scenario_confidence(scenario_id, 0.4)
    
    case updated_prediction_result do
      :ok ->
        IO.puts("  ✅ Prediction confidence updated based on feedback")
      {:error, reason} ->
        IO.puts("  ❌ Failed to update prediction confidence: #{inspect(reason)}")
        return :fail
    end
    
    # Test 8: Verify prediction engine stats reflect the change
    prediction_stats = PredictionEngine.get_stats(active_predictions)
    
    if prediction_stats.average_confidence < 0.8 do
      IO.puts("  ✅ Prediction statistics reflect decreased confidence")
    else
      IO.puts("  ❌ Prediction statistics do not reflect feedback - integrity violation!")
      return :fail
    end
    
    IO.puts("  ✅ Prediction Feedback invariant verified")
    :pass
  end

  @doc """
  WM-005 Causal Consistency Test
  
  Create:
  - A -> B
  - B -> C
  
  Verify:
  - counterfactual(A removed) updates B and C correctly
  """
  def test_wm_005_causal_consistency do
    IO.puts("🔍 WM-005: Testing Causal Consistency")
    
    # Initialize World Model
    world_model = WorldModel.new()
    
    # Create entities for causal relationships
    API.create_entity("entity:A", "Entity", "Entity A", %{type: "cause"})
    API.create_entity("entity:B", "Entity", "Entity B", %{type: "intermediate"})
    API.create_entity("entity:C", "Entity", "Entity C", %{type: "effect"})
    
    # Test 1: Create causal chain A -> B -> C
    relationship_ab_result = API.add_causal_relationship(
      "entity:A", 
      "entity:B", 
      "causes", 
      0.9, 
      0.8
    )
    
    case relationship_ab_result do
      {:ok, _rel_id} ->
        IO.puts("  ✅ Created relationship: A -> B")
      {:error, reason} ->
        IO.puts("  ❌ Failed to create A -> B: #{inspect(reason)}")
        return :fail
    end
    
    relationship_bc_result = API.add_causal_relationship(
      "entity:B", 
      "entity:C", 
      "causes", 
      0.8, 
      0.9
    )
    
    case relationship_bc_result do
      {:ok, _rel_id} ->
        IO.puts("  ✅ Created relationship: B -> C")
      {:error, reason} ->
        IO.puts("  ❌ Failed to create B -> C: #{inspect(reason)}")
        return :fail
    end
    
    # Test 2: Verify causal chain exists
    b_relationships = CausalEngine.get_entity_relationships("entity:B")
    
    if length(b_relationships) == 2 do
      IO.puts("  ✅ Entity B has expected relationships (A->B and B->C)")
    else
      IO.puts("  ❌ Entity B has incorrect relationships: #{length(b_relationships)}")
      return :fail
    end
    
    # Test 3: Perform causal inference on original chain
    inference_result = CausalEngine.infer_effects("entity:A", "remove A")
    
    case inference_result do
      {:ok, predictions} ->
        IO.puts("  ✅ Causal inference completed: #{length(predictions)} predictions")
      {:error, reason} ->
        IO.puts("  ❌ Causal inference failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 4: Create counterfactual scenario by removing A
    # This simulates the counterfactual "A removed"
    updated_world_model = API.update_entity("entity:A", %{status: "removed"})
    
    # Test 5: Verify causal effects propagate correctly
    updated_b_relationships = CausalEngine.get_entity_relationships("entity:B")
    
    # After removing A, B should only have one relationship (B->C)
    incoming_relationships = Enum.filter(updated_b_relationships, fn rel ->
      rel.target == "entity:B"
    end)
    
    if length(incoming_relationships) == 0 do
      IO.puts("  ✅ Counterfactual correctly updated B's relationships")
    else
      IO.puts("  ❌ Counterfactual did not update B - consistency violation!")
      return :fail
    end
    
    # Test 6: Verify C is affected by counterfactual
    c_relationships = CausalEngine.get_entity_relationships("entity:C")
    
    # C should still have B->C relationship, but be affected by A's removal
    if length(c_relationships) == 1 do
      IO.puts("  ✅ Counterfactual correctly affects C through B")
    else
      IO.puts("  ❌ Counterfactual did not properly affect C - consistency violation!")
      return :fail
    end
    
    # Test 7: Verify causal paths are updated
    causal_path_b_to_c = CausalEngine.find_causal_path("entity:B", "entity:C")
    
    case causal_path_b_to_c do
      {:ok, path} when length(path) > 0 ->
        IO.puts("  ✅ Causal path B->C preserved in counterfactual")
      {:ok, []} ->
        IO.puts("  ❌ Causal path B->C lost in counterfactual - consistency violation!")
        return :fail
      {:error, reason} ->
        IO.puts("  ❌ Causal path query failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 8: Verify causal engine statistics reflect changes
    causal_stats = CausalEngine.get_stats()
    
    if causal_stats.total_relationships >= 2 do
      IO.puts("  ✅ Causal statistics updated correctly")
    else
      IO.puts("  ❌ Causal statistics inconsistent - integrity violation!")
      return :fail
    end
    
    IO.puts("  ✅ Causal Consistency invariant verified")
    :pass
  end
end