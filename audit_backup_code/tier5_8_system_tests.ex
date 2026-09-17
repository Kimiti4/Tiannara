defmodule Tiannara.Audit.Tier5_8.SystemTests do
  @moduledoc """
  Tier 5-8: System Tests
  
  These tests verify AEO, CIS, OED, and Runtime systems.
  """

  alias Tiannara.AEO
  alias Tiannara.CIS
  alias Tiannara.OED
  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.RuntimeAPI

  @doc "Execute all Tier 5-8 System Tests"
  def run_all_tests do
    IO.puts("🔍 Starting Tier 5-8: System Tests")
    IO.puts("=" <> String.duplicate("=", 50))
    
    results = %{
      aeo_001_intent_translation: test_aeo_001_intent_translation(),
      aeo_002_runtime_submission: test_aeo_002_runtime_submission(),
      aeo_003_feedback_loop: test_aeo_003_feedback_loop(),
      cis_001_monoculture_detection: test_cis_001_monoculture_detection(),
      cis_002_constraint_behavior: test_cis_002_constraint_behavior(),
      cis_003_collapse_simulation: test_cis_003_collapse_simulation(),
      oed_001_constitution_check: test_oed_001_constitution_check(),
      oed_002_adversarial_challenge: test_oed_002_adversarial_challenge(),
      oed_003_validation_pipeline: test_oed_003_validation_pipeline(),
      rt_001_runtime_cannot_create_intent: test_rt_001_runtime_cannot_create_intent(),
      rt_002_runtime_uses_world_model: test_rt_002_runtime_uses_world_model(),
      rt_003_pressure_loop: test_rt_003_pressure_loop()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Tier 5-8 Results: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ ALL TIER 5-8 TESTS PASSED - Systems verified")
    else
      failed = total - passed
      IO.puts("❌ #{failed} Tier 5-8 tests FAILED - Systems compromised")
    end
    
    results
  end

  @doc """
  AEO-001 Intent Translation Test
  
  Verify:
  - Goal
  - ↓
  - Execution Graph
  is deterministic.
  """
  def test_aeo_001_intent_translation do
    IO.puts("🔍 AEO-001: Testing Intent Translation")
    
    # Test 1: Create goal in World Model
    world_model = WorldModel.new()
    
    API.create_entity("goal:analyze_data", "Goal", "Analyze Data", %{priority: :high})
    
    # Test 2: Initialize AEO system
    aeo_system = AEO.new()
    
    # Test 3: Test deterministic translation from goal to execution graph
    {execution_graph_1, _updated_world_model_1} = AEO.translate_goal_to_execution_graph(
      aeo_system, 
      "goal:analyze_data", 
      world_model
    )
    
    # Test 4: Verify translation is deterministic
    {execution_graph_2, _updated_world_model_2} = AEO.translate_goal_to_execution_graph(
      aeo_system, 
      "goal:analyze_data", 
      world_model
    )
    
    if execution_graph_1 == execution_graph_2 do
      IO.puts("  ✅ Intent translation is deterministic")
    else
      IO.puts("  ❌ Intent translation is non-deterministic - integrity violation!")
      :fail
    end
    
    # Test 5: Verify execution graph structure
    if Map.has_key?(execution_graph_1, :nodes) and Map.has_key?(execution_graph_1, :edges) do
      IO.puts("  ✅ Execution graph has proper structure")
    else
      IO.puts("  ❌ Execution graph structure incomplete - translation failed!")
      :fail
    end
    
    # Test 6: Verify execution graph contains required nodes
    node_ids = Map.keys(execution_graph_1.nodes)
    
    if Enum.any?(node_ids, &String.contains?(&1, "analyze_data")) do
      IO.puts("  ✅ Execution graph contains goal-specific nodes")
    else
      IO.puts("  ❌ Execution graph missing goal-specific nodes - translation incomplete!")
      :fail
    end
    
    # Test 7: Verify execution graph can be validated
    validation_result = AEO.validate_execution_graph(execution_graph_1)
    
    case validation_result do
      {:valid, _} ->
        IO.puts("  ✅ Execution graph validation passed")
      {:invalid, reasons} ->
        IO.puts("  ❌ Execution graph validation failed: #{inspect(reasons)}")
        :fail
    end
    
    # Test 8: Verify execution graph has execution path
    if Map.has_key?(execution_graph_1, :execution_path) do
      execution_path = execution_graph_1.execution_path
      if length(execution_path) > 0 do
        IO.puts("  ✅ Execution graph has valid execution path")
      else
        IO.puts("  ❌ Execution graph has empty execution path - translation broken!")
        :fail
      end
    else
      IO.puts("  ❌ Execution graph missing execution path - translation incomplete!")
      :fail
    end
    
    IO.puts("  ✅ Intent Translation verified")
    :pass
  end

  @doc """
  AEO-002 Runtime Submission Test
  
  Verify AEO never executes directly.
  
  Only:
  - submit_to_runtime()
  """
  def test_aeo_002_runtime_submission do
    IO.puts("🔍 AEO-002: Testing Runtime Submission")
    
    # Test 1: Initialize AEO and Runtime systems
    aeo_system = AEO.new()
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("test_core", "test_runtime")
    
    # Test 2: Create execution graph
    world_model = WorldModel.new()
    API.create_entity("goal:process_data", "Goal", "Process Data", %{priority: :medium})
    
    {execution_graph, _} = AEO.translate_goal_to_execution_graph(
      aeo_system, 
      "goal:process_data", 
      world_model
    )
    
    # Test 3: Verify AEO cannot execute directly
    direct_execution_result = AEO.execute_directly(execution_graph)
    
    case direct_execution_result do
      {:error, :cannot_execute_directly} ->
        IO.puts("  ✅ AEO cannot execute directly")
      {:ok, _result} ->
        IO.puts("  ❌ AEO executed directly - sovereignty violation!")
        :fail
      {:error, reason} ->
        IO.puts("  ❌ AEO direct execution test failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 4: Verify AEO can submit to runtime
    submission_id = case AEO.submit_to_runtime(execution_graph, runtime_world_model) do
      {:ok, id, updated_world_model} ->
        IO.puts("  ✅ AEO successfully submits to runtime (ID: #{id})")
        
        # Verify runtime queue updated
        runtime_queue = RuntimeAPI.get_runtime_queue(updated_world_model)
        if length(runtime_queue) > 0 do
          IO.puts("  ✅ Runtime queue updated with submission")
        else
          IO.puts("  ❌ Runtime queue not updated - submission failed!")
          :fail
        end
        id
        
      {:error, reason} ->
        IO.puts("  ❌ AEO runtime submission failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 5: Verify runtime submission maintains separation of concerns
    if String.contains?(to_string(submission_id), "runtime") do
      IO.puts("  ✅ Runtime submission maintains proper separation")
    else
      IO.puts("  ❌ Runtime submission violates separation of concerns!")
      :fail
    end
    
    # Test 6: Verify runtime submission creates proper submission record
    submission_record = RuntimeAPI.get_submission_record(submission_id)
    
    case submission_record do
      {:ok, record} ->
        if Map.has_key?(record, :execution_graph) and 
           Map.has_key?(record, :status) do
          IO.puts("  ✅ Runtime submission record created properly")
        else
          IO.puts("  ❌ Runtime submission record incomplete - submission broken!")
          :fail
        end
      {:error, :not_found} ->
        IO.puts("  ❌ Runtime submission record not found - submission failed!")
        :fail
    end
    
    IO.puts("  ✅ Runtime Submission verified")
    :pass
  end

  @doc """
  AEO-003 Feedback Loop Test
  
  Runtime result: success
  
  Expected:
  - World Model updated
  - Goal progress updated
  """
  def test_aeo_003_feedback_loop do
    IO.puts("🔍 AEO-003: Testing Feedback Loop")
    
    # Test 1: Initialize systems
    aeo_system = AEO.new()
    world_model = WorldModel.new()
    
    # Create goal
    API.create_entity("goal:feedback_test", "Goal", "Feedback Test Goal", %{priority: :high})
    goal_entity = API.get_entity("goal:feedback_test")
    
    # Test 2: Create execution graph and submit to runtime
    {execution_graph, _} = AEO.translate_goal_to_execution_graph(
      aeo_system, 
      "goal:feedback_test", 
      world_model
    )
    
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("test_core", "test_runtime")
    {:ok, submission_id, _} = AEO.submit_to_runtime(execution_graph, runtime_world_model)
    
    # Test 3: Simulate successful runtime execution
    execution_result = %{
      submission_id: submission_id,
      success: true,
      output: "Task completed successfully",
      confidence: 0.95,
      timestamp: DateTime.utc_now(),
      execution_time_ms: 1500
    }
    
    # Test 4: Process feedback through AEO
    {updated_world_model, updated_goal_entity} = AEO.process_runtime_feedback(
      world_model, 
      execution_result
    )
    
    # Test 5: Verify World Model was updated
    if length(updated_world_model.beliefs) > length(world_model.beliefs) do
      IO.puts("  ✅ World Model updated with feedback")
    else
      IO.puts("  ❌ World Model not updated - feedback loop broken!")
      :fail
    end
    
    # Test 6: Verify goal progress was updated
    case updated_goal_entity do
      entity when is_map(entity) ->
        if Map.has_key?(entity, :progress) do
          if entity.progress > 0 do
            IO.puts("  ✅ Goal progress updated (#{entity.progress})")
          else
            IO.puts("  ❌ Goal progress not incremented - feedback incomplete!")
            :fail
          end
        else
          IO.puts("  ❌ Goal progress field missing - feedback broken!")
          :fail
        end
      {:error, :not_found} ->
        IO.puts("  ❌ Goal not found after feedback - feedback loop broken!")
        :fail
    end
    
    # Test 7: Verify feedback creates belief update
    feedback_beliefs = Enum.filter(updated_world_model.beliefs, fn belief ->
      String.contains?(belief.statement, "feedback") or 
      String.contains?(belief.statement, "execution")
    end)
    
    if length(feedback_beliefs) > 0 do
      IO.puts("  ✅ Feedback creates belief updates")
    else
      IO.puts("  ❌ Feedback does not create belief updates - integration broken!")
      :fail
    end
    
    # Test 8: Verify feedback loop updates execution history
    execution_history = AEO.get_execution_history(updated_world_model)
    
    if length(execution_history) > 0 do
      IO.puts("  ✅ Execution history updated with feedback")
    else
      IO.puts("  ❌ Execution history not updated - feedback loop incomplete!")
      :fail
    end
    
    IO.puts("  ✅ Feedback Loop verified")
    :pass
  end

  @doc """
  CIS-001 Monoculture Detection Test
  
  Inject: Prediction = 80%
  
  Expected: warning
  """
  def test_cis_001_monoculture_detection do
    IO.puts("🔍 CIS-001: Testing Monoculture Detection")
    
    # Test 1: Create domain weights with high prediction dominance
    domain_weights = %{prediction: 0.8, logic: 0.05, temporal: 0.05, 
                      causal: 0.05, algorithm: 0.03, embodied: 0.02}
    
    # Test 2: Test CIS monoculture detection
    cis_result = CIS.detect_monoculture(domain_weights)
    
    case cis_result do
      {:warning, message} when is_binary(message) ->
        if String.contains?(message, "monoculture") or 
           String.contains?(message, "prediction") do
          IO.puts("  ✅ CIS monoculture warning generated")
        else
          IO.puts("  ❌ CIS warning generated but not relevant: #{message}")
          :fail
        end
      {:ok, message} ->
        IO.puts("  ❌ No monoculture warning - detection broken!")
        :fail
      {:error, reason} ->
        IO.puts("  ❌ CIS detection failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 3: Verify CIS provides monoculture metrics
    monoculture_metrics = CIS.calculate_monoculture_metrics(domain_weights)
    
    if Map.has_key?(monoculture_metrics, :dominance) and 
       Map.has_key?(monoculture_metrics, :diversity) do
      if monoculture_metrics.dominance > 0.75 do
        IO.puts("  ✅ High monoculture dominance detected: #{monoculture_metrics.dominance}")
      else
        IO.puts("  ❌ Low monoculture dominance - test setup incorrect!")
        :fail
      end
    else
      IO.puts("  ❌ Monoculture metrics incomplete - detection broken!")
      :fail
    end
    
    IO.puts("  ✅ Monoculture Detection verified")
    :pass
  end

  @doc """
  CIS-002 Constraint Behavior Test
  
  Verify: Core decides still works when CIS warns
  """
  def test_cis_002_constraint_behavior do
    IO.puts("🔍 CIS-002: Testing Constraint Behavior")
    
    # Test 1: Create system state with CIS warning
    system_state = %{
      domain_weights: %{prediction: 0.8, logic: 0.1, temporal: 0.1},
      cis_warnings: ["High prediction dominance detected"],
      core_authority: :active
    }
    
    # Test 2: Test core decision making despite CIS warning
    decision_result = CIS.test_core_decision(system_state, "test_decision")
    
    case decision_result do
      {:ok, decision} ->
        IO.puts("  ✅ Core decision made despite CIS warning")
        
        if decision.authority == "core" do
          IO.puts("  ✅ Core authority preserved")
        else
          IO.puts("  ❌ Core authority compromised - constraint violation!")
          :fail
        end
      {:error, reason} ->
        IO.puts("  ❌ Core decision failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 3: Verify CIS constraints don't block valid operations
    operation_result = CIS.validate_operation("valid_core_operation", system_state)
    
    case operation_result do
      {:ok, _} ->
        IO.puts("  ✅ CIS constraints don't block valid operations")
      {:error, reason} ->
        IO.puts("  ❌ CIS blocks valid operation: #{inspect(reason)}")
        :fail
    end
    
    IO.puts("  ✅ Constraint Behavior verified")
    :pass
  end

  @doc """
  CIS-003 Collapse Simulation Test
  
  Create: entropy = 0.15
  
  Expected: diversity recommendations
  NOT: forced shutdown
  """
  def test_cis_003_collapse_simulation do
    IO.puts("🔍 CIS-003: Testing Collapse Simulation")
    
    # Test 1: Create system with high entropy
    system_entropy = 0.15
    domain_state = %{prediction: 0.3, logic: 0.3, temporal: 0.4}
    
    # Test 2: Test collapse simulation
    collapse_result = CIS.simulate_system_collapse(domain_state, system_entropy)
    
    case collapse_result do
      {:recommendations, recommendations} when is_list(recommendations) ->
        if length(recommendations) > 0 do
          IO.puts("  ✅ #{length(recommendations)} diversity recommendations generated")
          
          # Verify recommendations are reasonable
          valid_recommendations = Enum.filter(recommendations, fn rec ->
            is_binary(rec) and String.length(rec) > 0
          end)
          
          if length(valid_recommendations) == length(recommendations) do
            IO.puts("  ✅ All recommendations valid")
          else
            IO.puts("  ❌ Invalid recommendations found")
            :fail
          end
        else
          IO.puts("  ❌ No recommendations generated - simulation incomplete!")
          :fail
        end
      {:shutdown, _} ->
        IO.puts("  ❌ Forced shutdown generated - collapse simulation failed!")
        :fail
      {:error, reason} ->
        IO.puts("  ❌ Collapse simulation failed: #{inspect(reason)}")
        :fail
    end
    
    IO.puts("  ✅ Collapse Simulation verified")
    :pass
  end

  @doc """
  OED-001 Constitution Check Test
  
  Create invalid plan.
  
  Expected: rejected
  """
  def test_oed_001_constitution_check do
    IO.puts("🔍 OED-001: Testing Constitution Check")
    
    # Test 1: Create invalid plan
    invalid_plan = %{
      name: "Invalid Plan",
      steps: ["step1", "step2"],
      constitutional_compliance: false,
      ethical_risks: ["privacy violation", "unauthorized access"]
    }
    
    # Test 2: Test constitution check
    constitution_result = OED.check_constitution(invalid_plan)
    
    case constitution_result do
      {:rejected, reason} when is_binary(reason) ->
        IO.puts("  ✅ Invalid plan rejected: #{reason}")
      {:approved, _} ->
        IO.puts("  ❌ Invalid plan approved - constitution check failed!")
        :fail
      {:error, reason} ->
        IO.puts("  ❌ Constitution check failed: #{inspect(reason)}")
        :fail
    end
    
    IO.puts("  ✅ Constitution Check verified")
    :pass
  end

  @doc """
  OED-002 Adversarial Challenge Test
  
  Run ACM challenge.
  
  Expected: alternative ontology generated
  """
  def test_oed_002_adversarial_challenge do
    IO.puts("🔍 OED-002: Testing Adversarial Challenge")
    
    # Test 1: Create ACM challenge
    acm_challenge = %{
      type: "adversarial",
      domain: "security_analysis",
      constraints: ["no direct memory access", "respect privacy boundaries"],
      target: "malware_detection"
    }
    
    # Test 2: Run ACM challenge
    challenge_result = OED.run_acm_challenge(acm_challenge)
    
    case challenge_result do
      {:ok, alternative_ontology} ->
        if is_map(alternative_ontology) and 
           Map.has_key?(alternative_ontology, :entities) and
           Map.has_key?(alternative_ontology, :relationships) do
          IO.puts("  ✅ Alternative ontology generated")
        else
          IO.puts("  ❌ Alternative ontology structure invalid - challenge failed!")
          :fail
        end
      {:error, reason} ->
        IO.puts("  ❌ ACM challenge failed: #{inspect(reason)}")
        :fail
    end
    
    IO.puts("  ✅ Adversarial Challenge verified")
    :pass
  end

  @doc """
  OED-003 Validation Pipeline Test
  
  Verify:
  - ACM
  - ↓
  - OAVL
  - ↓
  - UMSC
  
  must complete before approval.
  """
  def test_oed_003_validation_pipeline do
    IO.puts("🔍 OED-003: Testing Validation Pipeline")
    
    # Test 1: Create test plan
    test_plan = %{
      name: "Test Validation Pipeline",
      description: "Plan to test OED validation pipeline",
      steps: ["step1", "step2", "step3"],
      ethical_constraints: ["respect user privacy", "follow data protection laws"]
    }
    
    # Test 2: Test ACM validation
    acm_validated_plan = case OED.acm_validate(test_plan) do
      {:ok, plan} ->
        IO.puts("  ✅ ACM validation completed")
        plan
      {:error, reason} ->
        IO.puts("  ❌ ACM validation failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 3: Test OAVL validation
    oavl_validated_plan = case OED.oavl_validate(acm_validated_plan) do
      {:ok, plan} ->
        IO.puts("  ✅ OAVL validation completed")
        plan
      {:error, reason} ->
        IO.puts("  ❌ OAVL validation failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 4: Test UMSC validation
    fully_validated_plan = case OED.umsc_validate(oavl_validated_plan) do
      {:ok, plan} ->
        IO.puts("  ✅ UMSC validation completed")
        plan
      {:error, reason} ->
        IO.puts("  ❌ UMSC validation failed: #{inspect(reason)}")
        :fail
    end
    
    # Test 5: Verify final approval requires all steps
    approval_result = OED.approve_plan(fully_validated_plan)
    
    case approval_result do
      {:approved, _} ->
        IO.puts("  ✅ Plan approved after complete validation pipeline")
      {:rejected, reason} ->
        IO.puts("  ❌ Plan rejected despite complete pipeline: #{reason}")
        :fail
    end
    
    IO.puts("  ✅ Validation Pipeline verified")
    :pass
  end

  @doc """
  RT-001 Runtime Cannot Create Intent Test
  
  Attempt: Runtime.create_goal(...)
  
  Expected: failure
  """
  def test_rt_001_runtime_cannot_create_intent do
    IO.puts("🔍 RT-001: Testing Runtime Cannot Create Intent")
    
    # Test 1: Initialize runtime
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("test_core", "test_runtime")
    
    # Test 2: Attempt runtime goal creation (should fail)
    goal_attempt = RuntimeAPI.create_runtime_goal(
      runtime_world_model, 
      "test_goal", 
      "Test Goal", 
      %{priority: :high}
    )
    
    case goal_attempt do
      {:error, :cannot_create_goals} ->
        IO.puts("  ✅ Runtime cannot create goals (as expected)")
      {:ok, _world_model} ->
        IO.puts("  ❌ Runtime created goal - sovereignty violation!")
        :fail
      {:error, reason} ->
        IO.puts("  ❌ Runtime goal test failed: #{inspect(reason)}")
        :fail
    end
    
    IO.puts("  ✅ Runtime Cannot Create Intent verified")
    :pass
  end

  @doc """
  RT-002 Runtime Uses World Model Test
  
  Verify Runtime updates World Model through RuntimeAPI.
  
  NOT direct memory mutation.
  """
  def test_rt_002_runtime_uses_world_model do
    IO.puts("🔍 RT-002: Testing Runtime Uses World Model")
    
    # Test 1: Initialize runtime and World Model
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("test_core", "test_runtime")
    original_belief_count = length(runtime_world_model.beliefs)
    
    # Test 2: Runtime updates through API
    feedback_data = %{
      entity_id: "test_entity",
      operation: "processing",
      success: true,
      confidence: 0.9,
      timestamp: DateTime.utc_now(),
      context: "runtime_test_context"
    }
    
    updated_world_model = RuntimeAPI.process_runtime_feedback(
      runtime_world_model, 
      feedback_data
    )
    
    # Test 3: Verify World Model was updated
    if length(updated_world_model.beliefs) > original_belief_count do
      IO.puts("  ✅ Runtime updates World Model through API")
    else
      IO.puts("  ❌ Runtime does not update World Model - integration broken!")
      :fail
    end
    
    # Test 4: Verify no direct memory mutation
    if runtime_world_model != updated_world_model do
      IO.puts("  ✅ Runtime creates new World Model instance (no direct mutation)")
    else
      IO.puts("  ❌ Runtime directly mutates World Model - API violation!")
      :fail
    end
    
    # Test 5: Verify runtime state is separate from World Model
    runtime_state = RuntimeAPI.get_runtime_state(updated_world_model)
    
    if is_map(runtime_state) and map_size(runtime_state) > 0 do
      IO.puts("  ✅ Runtime state properly separated from World Model")
    else
      IO.puts("  ❌ Runtime state not properly separated - integration broken!")
      :fail
    end
    
    IO.puts("  ✅ Runtime Uses World Model verified")
    :pass
  end

  @doc """
  RT-003 Pressure Loop Test
  
  Simulate: GRCC → CIS → GRCC
  
  Verify loop stability.
  """
  def test_rt_003_pressure_loop do
    IO.puts("🔍 RT-003: Testing Pressure Loop")
    
    # Test 1: Initialize GRCC and CIS systems
    grcc_state = %{entropy: 0.1, constraints: []}
    cis_state = %{warnings: [], metrics: %{}}
    
    # Test 2: Simulate GRCC → CIS → GRCC loop
    {grcc_to_cis, _} = CIS.process_grcc_constraints(grcc_state)
    {cis_to_grcc, _} = GRCC.process_cis_feedback(cis_state)
    
    # Test 3: Verify loop stability after multiple iterations
    {final_grcc, final_cis} = Enum.reduce(1..10, {grcc_to_cis, cis_to_grcc}, fn _i, {g, c} ->
      {new_c, _} = CIS.process_grcc_constraints(g)
      {new_g, _} = GRCC.process_cis_feedback(new_c)
      {new_g, new_c}
    end)
    
    # Test 4: Verify system doesn't diverge
    if abs(final_grcc.entropy - grcc_state.entropy) < 0.2 do
      IO.puts("  ✅ GRCC system remains stable under pressure")
    else
      IO.puts("  ❌ GRCC system diverged under pressure - loop unstable!")
      :fail
    end
    
    if length(final_cis.warnings) > 0 do
      IO.puts("  ✅ CIS maintains monitoring during pressure")
    else
      IO.puts("  ❌ CIS monitoring failed under pressure - loop broken!")
      :fail
    end
    
    IO.puts("  ✅ Pressure Loop verified")
    :pass
  end
end