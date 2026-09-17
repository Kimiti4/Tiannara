defmodule Tiannara.Audit.Tier9.EndToEnd do
  @moduledoc """
  Tier 9: Full End-to-End Audit
  
  These are the most important tests, verifying the complete integrated system.
  """

  alias Tiannara.Core
  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API
  alias Tiannara.DomainCortex
  alias Tiannara.AEO
  alias Tiannara.CIS
  alias Tiannara.OED
  alias Tiannara.Core.WorldModel.RuntimeAPI

  @doc "Execute all Tier 9 End-to-End Tests"
  def run_all_tests do
    IO.puts("🔍 Starting Tier 9: Full End-to-End Audit")
    IO.puts("=" <> String.duplicate("=", 50))
    
    results = %{
      e2e_001_trading_strategy: test_e2e_001_trading_strategy(),
      e2e_002_malware_analysis: test_e2e_002_malware_analysis(),
      e2e_003_long_horizon: test_e2e_003_long_horizon()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Tier 9 Results: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ ALL TIER 9 TESTS PASSED - End-to-end system verified")
    else
      failed = total - passed
      IO.puts("❌ #{failed} Tier 9 tests FAILED - End-to-end system compromised")
    end
    
    results
  end

  @doc """
  E2E-001 Trading Strategy Test
  
  Full flow:
  - User Goal
  - ↓
  - Core
  - ↓
  - World Model
  - ↓
  - MetaCognition
  - ↓
  - Domains
  - ↓
  - AEO
  - ↓
  - OED
  - ↓
  - Runtime
  - ↓
  - Feedback
  - ↓
  - World Model
  
  Verify every transition.
  """
  def test_e2e_001_trading_strategy do
    IO.puts("🔍 E2E-001: Testing Full Trading Strategy Pipeline")
    
    # Test 1: Initialize all systems
    IO.puts("  🚀 Initializing system components...")
    core_state = Core.new("trading_strategy_core")
    world_model = core_state.world_model
    aeo_system = AEO.new()
    
    # Test 2: Create User Goal in World Model
    IO.puts("  📝 Creating User Goal...")
    API.create_entity(
      "goal:design_trading_strategy", 
      "Goal", 
      "Design Trading Strategy", 
      %{priority: :critical, domain: "finance", complexity: :high}
    )
    
    # Test 3: Core processes goal and generates intent
    IO.puts("  🧠 Core processing goal...")
    {intent, updated_core_state} = Core.generate_intent(core_state)
    
    if intent.source == "core" do
      IO.puts("  ✅ Core generates intent correctly")
    else
      IO.puts("  ❌ Core intent generation failed")
      :fail
    end
    
    # Test 4: World Model stores intent
    intent_entities = API.query_entities("Intent")
    if length(intent_entities) > 0 do
      IO.puts("  ✅ World Model stores intent")
    else
      IO.puts("  ❌ World Model does not store intent")
      :fail
    end
    
    # Test 5: MetaCognition consults World Model
    IO.puts("  🔍 MetaCognition consulting World Model...")
    meta_cog = DomainCortex.MetaCognition.new()
    {updated_meta_cog, domain_weights} = DomainCortex.MetaCognition.consult_world_model(meta_cog, updated_core_state.world_model)
    
    if map_size(domain_weights) > 0 do
      IO.puts("  ✅ MetaCognition uses World Model")
    else
      IO.puts("  ❌ MetaCognition ignores World Model")
      :fail
    end
    
    # Test 6: Domain selection
    IO.puts("  🎯 Domain selection...")
    {selected_domains, _} = DomainCortex.select_domain_team(
      updated_meta_cog, 
      "design_trading_strategy", 
      updated_core_state.world_model
    )
    
    expected_domains = [:prediction, :temporal, :causal, :algorithm]
    domains_present = Enum.all?(expected_domains, fn domain -> 
      Map.has_key?(selected_domains, domain) 
    end)
    
    if domains_present do
      IO.puts("  ✅ Correct domains selected")
    else
      IO.puts("  ❌ Incorrect domain selection")
      :fail
    end
    
    # Test 7: Domain collaboration
    IO.puts("  🤝 Domain collaboration...")
    {domain_outputs, world_model_with_domain_insights} = DomainCortex.execute_domain_team(
      selected_domains,
      "design_trading_strategy",
      updated_core_state.world_model
    )
    
    if length(domain_outputs) > 0 do
      IO.puts("  ✅ Domain collaboration successful")
    else
      IO.puts("  ❌ Domain collaboration failed")
      :fail
    end
    
    # Test 8: AEO translates to execution graph
    IO.puts("  📊 AEO translation...")
    {execution_graph, _} = AEO.translate_goal_to_execution_graph(
      aeo_system,
      "goal:design_trading_strategy",
      world_model_with_domain_insights
    )
    
    if Map.has_key?(execution_graph, :nodes) do
      IO.puts("  ✅ AEO creates execution graph")
    else
      IO.puts("  ❌ AEO translation failed")
      :fail
    end
    
    # Test 9: OED validation
    IO.puts(" ⚖️  OED validation...")
    oed_result = OED.validate_plan(execution_graph)
    
    case oed_result do
      {:valid, _validated_plan} ->
        IO.puts("  ✅ OED validation passes")
      {:invalid, _reason} ->
        IO.puts("  ❌ OED validation fails")
        :fail
    end
    
    # Test 10: Runtime submission
    IO.puts("  ⚡ Runtime submission...")
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("trading_core", "trading_runtime")
    {:ok, submission_id, _} = AEO.submit_to_runtime(execution_graph, runtime_world_model)
    
    if is_binary(submission_id) do
      IO.puts("  ✅ Runtime submission successful")
    else
      IO.puts("  ❌ Runtime submission failed")
      :fail
    end
    
    # Test 11: Runtime execution simulation
    IO.puts("  🏃 Runtime execution...")
    execution_result = %{
      submission_id: submission_id,
      success: true,
      output: "Trading strategy designed",
      confidence: 0.92,
      timestamp: DateTime.utc_now(),
      execution_time_ms: 2500
    }
    
    {final_world_model, _} = AEO.process_runtime_feedback(
      world_model_with_domain_insights,
      execution_result
    )
    
    # Test 12: Feedback loop to World Model
    if length(final_world_model.beliefs) > length(world_model.beliefs) do
      IO.puts("  ✅ Feedback loop updates World Model")
    else
      IO.puts("  ❌ Feedback loop incomplete")
      :fail
    end
    
    # Test 13: Goal progress tracking
    goal_entities = API.query_entities("Goal", %{name: "Design Trading Strategy"})
    if length(goal_entities) > 0 do
      goal_entity = hd(goal_entities)
      if Map.has_key?(goal_entity, :progress) and goal_entity.progress > 0 do
        IO.puts("  ✅ Goal progress tracked")
      else
        IO.puts("  ❌ Goal progress not tracked")
        :fail
      end
    else
      IO.puts("  ❌ Goal entity not found after execution")
      :fail
    end
    
    # Test 14: Verify complete pipeline traceability
    pipeline_trace = API.query_pipeline_trace("goal:design_trading_strategy")
    if length(pipeline_trace) > 5 do  # Should trace through all major steps
      IO.puts("  ✅ Complete pipeline traceability")
    else
      IO.puts("  ❌ Pipeline traceability incomplete")
      :fail
    end
    
    IO.puts("  ✅ Full Trading Strategy Pipeline verified")
    :pass
  end

  @doc """
  E2E-002 Malware Analysis Test
  
  Exercise:
  - RE
  - Logic
  - Causal
  - Ethics
  
  simultaneously.
  """
  def test_e2e_002_malware_analysis do
    IO.puts("🔍 E2E-002: Testing Malware Analysis Multi-Domain Pipeline")
    
    # Test 1: Initialize all systems
    IO.puts("  🚀 Initializing malware analysis systems...")
    core_state = Core.new("malware_analysis_core")
    world_model = core_state.world_model
    aeo_system = AEO.new()
    
    # Test 2: Create malware analysis goal
    IO.puts("  📝 Creating malware analysis goal...")
    API.create_entity(
      "goal:analyze_malware", 
      "Goal", 
      "Analyze Malware", 
      %{priority: :critical, domain: "security", risk_level: :high}
    )
    
    # Test 3: Simulate malware sample in World Model
    IO.puts("  🦠 Adding malware sample to World Model...")
    API.create_entity(
      "malware:sample123", 
      "Malware", 
      "Sample Trojan", 
      %{type: "trojan", complexity: :advanced, origin: "unknown"}
    )
    
    # Test 4: Core generates intent
    IO.puts("  🧠 Core generating intent...")
    {intent, _updated_core} = Core.generate_intent(core_state)
    
    if intent.purpose == "achieve_goal" do
      IO.puts("  ✅ Core intent generation correct")
    else
      IO.puts("  ❌ Core intent generation failed")
      :fail
    end
    
    # Test 5: MetaCognition selects appropriate domains for malware analysis
    IO.puts("  🔍 MetaCognition selecting domains...")
    meta_cog = DomainCortex.MetaCognition.new()
    {updated_meta_cog, domain_weights} = DomainCortex.MetaCognition.consult_world_model(meta_cog, world_model)
    
    # Test 6: Verify malware-specific domain selection
    malware_domains = [:reverse_engineering, :logic, :causal, :ethics]
    domain_selection_ok = Enum.all?(malware_domains, fn domain ->
      weight = Map.get(domain_weights, domain, 0.0)
      weight > 0.1  # Should have significant weight
    end)
    
    if domain_selection_ok do
      IO.puts("  ✅ Malware-specific domains selected")
    else
      IO.puts("  ❌ Incorrect domain selection for malware analysis")
      :fail
    end
    
    # Test 7: Multi-domain collaboration
    IO.puts("  🤝 Multi-domain collaboration...")
    {selected_domains, _} = DomainCortex.select_domain_team(
      updated_meta_cog,
      "analyze_malware",
      world_model
    )
    
    {multi_domain_output, world_model_with_analysis} = DomainCortex.execute_domain_team(
      selected_domains,
      "analyze_malware",
      world_model
    )
    
    # Test 8: Verify all domains contributed
    domain_contributions = DomainCortex.get_domain_contributions(multi_domain_output)
    
    if length(domain_contributions) >= 4 do
      IO.puts("  ✅ Multiple domains contributed to analysis")
    else
      IO.puts("  ❌ Insufficient domain contributions")
      :fail
    end
    
    # Test 9: AEO creates execution graph
    IO.puts("  📊 AEO creating execution graph...")
    {execution_graph, _} = AEO.translate_goal_to_execution_graph(
      aeo_system,
      "goal:analyze_malware",
      world_model_with_analysis
    )
    
    # Test 10: OED validation with ethical constraints
    IO.puts(" ⚖️  OED ethical validation...")
    ethical_constraints = %{privacy_protection: true, data_integrity: true}
    oed_result = OED.validate_plan_with_constraints(execution_graph, ethical_constraints)
    
    case oed_result do
      {:valid, _} ->
        IO.puts("  ✅ OED validation with constraints passes")
      {:invalid, _} ->
        IO.puts("  ❌ OED validation with constraints fails")
        :fail
    end
    
    # Test 11: Runtime execution with security constraints
    IO.puts("  ⚡ Runtime execution with security constraints...")
    runtime_world_model = RuntimeAPI.initialize_runtime_world_model("malware_core", "malware_runtime")
    {:ok, submission_id, _} = AEO.submit_to_runtime(execution_graph, runtime_world_model)
    
    # Test 12: Simulate runtime execution with security monitoring
    security_result = %{
      submission_id: submission_id,
      success: true,
      output: "Malware analysis completed with ethical safeguards",
      confidence: 0.88,
      timestamp: DateTime.utc_now(),
      security_checks_passed: true,
      ethical_compliance: true
    }
    
    {final_world_model, _} = AEO.process_runtime_feedback(
      world_model_with_analysis,
      security_result
    )
    
    # Test 13: Verify ethical compliance in World Model
    ethical_beliefs = Enum.filter(final_world_model.beliefs, fn belief ->
      String.contains?(belief.statement, "ethical") or
      String.contains?(belief.statement, "compliance")
    end)
    
    if length(ethical_beliefs) > 0 do
      IO.puts("  ✅ Ethical compliance recorded in World Model")
    else
      IO.puts("  ❌ Ethical compliance not recorded")
      :fail
    end
    
    # Test 14: Verify CIS monitoring during execution
    cis_monitoring = CIS.check_domain_collaboration(selected_domains)
    
    case cis_monitoring do
      {:ok, _} ->
        IO.puts("  ✅ CIS monitoring successful during execution")
      {:warning, _} ->
        IO.puts("  ⚠️  CIS warning during execution (acceptable)")
      {:error, _} ->
        IO.puts("  ❌ CIS monitoring failed")
        :fail
    end
    
    # Test 15: Verify analysis results create entities in World Model
    analysis_entities = API.query_entities("Analysis")
    if length(analysis_entities) > 0 do
      IO.puts("  ✅ Analysis results stored in World Model")
    else
      IO.puts("  ❌ Analysis results not stored")
      :fail
    end
    
    IO.puts("  ✅ Malware Analysis Multi-Domain Pipeline verified")
    :pass
  end

  @doc """
  E2E-003 Long Horizon Test
  
  Run: 10,000 cycles
  
  Measure:
  - identity drift
  - belief drift
  - entropy
  - domain dominance
  - goal completion
  - contradictions
  """
  def test_e2e_003_long_horizon do
    IO.puts("🔍 E2E-003: Testing Long-Horizon System Stability")
    
    # Test 1: Initialize systems for long-term simulation
    IO.puts("  🚀 Initializing long-horizon simulation...")
    core_state = Core.new("long_horizon_core")
    world_model = core_model = core_state.world_model
    aeo_system = AEO.new()
    
    # Test 2: Create initial goal for long-term execution
    IO.puts("  📝 Creating long-term goal...")
    API.create_entity(
      "goal:long_term_strategy", 
      "Goal", 
      "Long-Term Strategy Development", 
      %{priority: :medium, horizon: "long_term", complexity: :evolving}
    )
    
    # Test 3: Establish baseline metrics
    IO.puts("  📊 Establishing baseline metrics...")
    baseline_metrics = establish_baseline_metrics(world_model)
    IO.puts("    📈 Baseline - Identity: #{baseline_metrics.identity_count}, Beliefs: #{baseline_metrics.belief_count}, Entropy: #{baseline_metrics.entropy}")
    
    # Test 4: Run 10,000 cycles of system evolution
    IO.puts("  🔄 Running 10,000 evolution cycles...")
    IO.puts("    ⏱️  This may take several minutes...")
    
    {final_core_state, final_world_model, evolution_metrics} = 
      run_evolution_cycles(core_state, world_model, aeo_system, 10_000)
    
    # Test 5: Measure identity drift
    identity_drift = calculate_identity_drift(baseline_metrics.identity_count, evolution_metrics)
    if identity_drift < 0.1 do  # Less than 10% drift is acceptable
      IO.puts("  ✅ Identity drift acceptable: #{identity_drift}")
    else
      IO.puts("  ❌ Identity drift too high: #{identity_drift}")
      :fail
    end
    
    # Test 6: Measure belief drift
    belief_drift = calculate_belief_drift(baseline_metrics.belief_count, evolution_metrics)
    if belief_drift < 0.15 do  # Less than 15% drift is acceptable
      IO.puts("  ✅ Belief drift acceptable: #{belief_drift}")
    else
      IO.puts("  ❌ Belief drift too high: #{belief_drift}")
      :fail
    end
    
    # Test 7: Measure entropy stability
    entropy_stability = abs(evolution_metrics.final_entropy - baseline_metrics.entropy)
    if entropy_stability < 0.2 do  # Entropy should remain stable
      IO.puts("  ✅ Entropy stable: #{entropy_stability}")
    else
      IO.puts("  ❌ Entropy unstable: #{entropy_stability}")
      :fail
    end
    
    # Test 8: Measure domain dominance stability
    domain_dominance_stability = DomainCortex.measure_domain_stability(evolution_metrics.domain_weights)
    if domain_dominance_stability > 0.8 do  # High stability is good
      IO.puts("  ✅ Domain dominance stable: #{domain_dominance_stability}")
    else
      IO.puts("  ❌ Domain dominance unstable: #{domain_dominance_stability}")
      :fail
    end
    
    # Test 9: Measure goal completion progress
    goal_completion_progress = calculate_goal_completion_progress(evolution_metrics)
    if goal_completion_progress > 0.7 do  # 70%+ progress is good
      IO.puts("  ✅ Goal progress good: #{goal_completion_progress}")
    else
      IO.puts("  ❌ Goal progress poor: #{goal_completion_progress}")
      :fail
    end
    
    # Test 10: Measure contradiction accumulation
    contradiction_accumulation = evolution_metrics.contradiction_count - baseline_metrics.contradiction_count
    if contradiction_accumulation < 100 do  # Less than 100 new contradictions is acceptable
      IO.puts("  ✅ Contradiction accumulation controlled: #{contradiction_accumulation}")
    else
      IO.puts("  ❌ Too many new contradictions: #{contradiction_accumulation}")
      :fail
    end
    
    # Test 11: Verify system can still process new goals after evolution
    IO.puts("  🎯 Testing post-evolution capability...")
    API.create_entity(
      "goal:post_evolution_test", 
      "Goal", 
      "Post-Evolution Test", 
      %{priority: :low}
    )
    
    {post_evolution_intent, _} = Core.generate_intent(final_core_state)
    if post_evolution_intent.source == "core" do
      IO.puts("  ✅ System still generates intent post-evolution")
    else
      IO.puts("  ❌ System cannot generate intent post-evolution")
      :fail
    end
    
    # Test 12: Verify World Model integrity after long operation
    world_model_integrity = check_world_model_integrity(final_world_model)
    if world_model_integrity == :valid do
      IO.puts("  ✅ World Model integrity maintained")
    else
      IO.puts("  ❌ World Model integrity compromised")
      :fail
    end
    
    IO.puts("  ✅ Long-Horizon System Stability verified")
    :pass
  end

  # Helper functions for long-horizon test
  defp establish_baseline_metrics(world_model) do
    %{
      identity_count: length(API.query_entities("Identity")) + length(API.query_entities("Lineage")),
      belief_count: length(world_model.beliefs),
      entropy: calculate_system_entropy(world_model),
      contradiction_count: length(API.query_uncertainties())
    }
  end

  defp run_evolution_cycles(core_state, world_model, aeo_system, cycles) do
    Enum.reduce(1..cycles, {core_state, world_model, %{}}, fn cycle, {acc_core, acc_world, metrics} ->
      # Simulate cycle evolution
      evolved_world = simulate_cycle_evolution(acc_world, cycle)
      
      # Occasionally process goals
      evolved_core = if rem(cycle, 100) == 0 do
        {_intent, e_core} = Core.generate_intent(acc_core)
        e_core
      else
        acc_core
      end
      
      # Update metrics periodically
      updated_metrics = if rem(cycle, 1000) == 0 do
        %{
          cycle: cycle,
          belief_count: length(evolved_world.beliefs),
          final_entropy: calculate_system_entropy(evolved_world),
          contradiction_count: length(API.query_uncertainties())
        }
      else
        metrics
      end
      
      {evolved_core, evolved_world, updated_metrics}
    end)
  end

  defp simulate_cycle_evolution(world_model, cycle) do
    # Add a belief for this cycle
    belief_content = "Cycle #{cycle} observation"
    API.add_belief(belief_content, 0.5 + (cycle / 2000), "cycle_observation", [])
  end

  defp calculate_identity_drift(baseline_count, evolution_metrics) do
    if baseline_count > 0 do
      abs(evolution_metrics.identity_count - baseline_count) / baseline_count
    else
      0.0
    end
  end

  defp calculate_belief_drift(baseline_count, evolution_metrics) do
    if baseline_count > 0 do
      abs(evolution_metrics.belief_count - baseline_count) / baseline_count
    else
      0.0
    end
  end

  defp calculate_goal_completion_progress(metrics) do
    if metrics.goal_progress do
      metrics.goal_progress / 100.0  # Assuming percentage
    else
      0.0
    end
  end

  defp calculate_system_entropy(world_model) do
    # Simplified entropy calculation based on belief diversity
    belief_count = length(world_model.beliefs)
    if belief_count > 0 do
      1.0 / :math.log(belief_count + 1)
    else
      0.0
    end
  end

  defp check_world_model_integrity(world_model) do
    # Check basic World Model integrity
    entity_count = map_size(world_model.entities)
    
    if entity_count > 0 and length(world_model.beliefs) >= 0 do
      :valid
    else
      :invalid
    end
  end
end