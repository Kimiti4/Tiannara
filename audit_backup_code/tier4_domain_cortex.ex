defmodule Tiannara.Audit.Tier4.DomainCortex do
  @moduledoc """
  Tier 4: Domain Cortex Tests
  
  These tests verify the Domain Cortex system and domain team assembly.
  """

  alias Tiannara.DomainCortex
  alias Tiannara.MetaCognition
  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API

  @doc "Execute all Tier 4 Domain Cortex Tests"
  def run_all_tests do
    IO.puts("🔍 Starting Tier 4: Domain Cortex Tests")
    IO.puts("=" <> String.duplicate("=", 50))
    
    results = %{
      dc_001_domain_team_assembly: test_dc_001_domain_team_assembly(),
      dc_002_domain_diversity: test_dc_002_domain_diversity(),
      dc_003_domain_collaboration: test_dc_003_domain_collaboration()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Tier 4 Results: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ ALL TIER 4 TESTS PASSED - Domain Cortex verified")
    else
      failed = total - passed
      IO.puts("❌ #{failed} Tier 4 tests FAILED - Domain Cortex compromised")
    end
    
    results
  end

  @doc """
  DC-001 Domain Team Assembly Test
  
  Goal: Design trading strategy
  
  Expected:
  - Prediction
  - Temporal
  - Algorithm
  - Causal
  
  Selected.
  
  NOT:
  - Embodied
  - Reverse Engineering
  dominating.
  """
  def test_dc_001_domain_team_assembly do
    IO.puts("🔍 DC-001: Testing Domain Team Assembly")
    
    # Test 1: Initialize World Model with trading context
    world_model = WorldModel.new()
    
    # Add trading-related beliefs to influence domain selection
    trading_belief = API.add_belief("Market patterns detected in trading data", 0.8, "market_analysis", [])
    
    case trading_belief do
      {:ok, _belief_id} ->
        IO.puts("  ✅ Trading context added to World Model")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add trading context: #{inspect(reason)}")
        return :fail
    end
    
    # Test 2: Initialize MetaCognition for domain selection
    meta_cog = MetaCognition.new()
    
    # Test 3: Request domain team for "Design trading strategy"
    task_description = "Design trading strategy"
    {selected_domains, remaining_domains} = DomainCortex.select_domain_team(
      meta_cog, 
      task_description, 
      world_model
    )
    
    # Test 4: Verify expected domains are selected
    expected_domains = [:prediction, :temporal, :algorithm, :causal]
    unexpected_domains = [:embodied, :reverse_engineering]
    
    # Check that expected domains are in selection
    expected_present = Enum.all?(expected_domains, fn domain ->
      Map.has_key?(selected_domains, domain)
    end)
    
    if expected_present do
      IO.puts("  ✅ Expected domains selected: #{inspect(expected_domains)}")
    else
      IO.puts("  ❌ Missing expected domains in selection")
      return :fail
    end
    
    # Check that unexpected domains are not dominating
    unexpected_dominating = Enum.any?(unexpected_domains, fn domain ->
      case Map.get(selected_domains, domain, 0.0) do
        weight when weight > 0.3 -> true
        _ -> false
      end
    end)
    
    if not unexpected_dominating do
      IO.puts("  ✅ Unexpected domains not dominating")
    else
      IO.puts("  ❌ Unexpected domains dominating team assembly - diversity violation!")
      return :fail
    end
    
    # Test 5: Verify domain team weights are reasonable
    total_weight = Enum.sum(Map.values(selected_domains))
    
    if total_weight > 0.8 and total_weight < 1.2 do  # Should sum to ~1.0
      IO.puts("  ✅ Domain team weights sum correctly")
    else
      IO.puts("  ❌ Domain team weights incorrect: #{total_weight}")
      return :fail
    end
    
    # Test 6: Verify domain team can collaborate
    collaboration_result = DomainCortex.execute_domain_team(
      selected_domains,
      task_description,
      world_model
    )
    
    case collaboration_result do
      {:ok, {outputs, updated_world_model}} ->
        IO.puts("  ✅ Domain team collaboration successful")
        
        # Verify outputs were generated
        if length(outputs) > 0 do
          IO.puts("  ✅ Domain team produced #{length(outputs)} outputs")
        else
          IO.puts("  ❌ Domain team produced no outputs - collaboration failed!")
          return :fail
        end
        
        # Verify World Model was updated
        if length(updated_world_model.beliefs) > length(world_model.beliefs) do
          IO.puts("  ✅ Domain team updates World Model")
        else
          IO.puts("  ❌ Domain team does not update World Model - integration broken!")
          return :fail
        end
        
      {:error, reason} ->
        IO.puts("  ❌ Domain team collaboration failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 7: Verify each domain contributed to output
    domain_contributions = DomainCortex.get_domain_contributions(outputs)
    
    if length(domain_contributions) >= 4 do  # At least 4 domains should contribute
      IO.puts("  ✅ Multiple domains contributed to output")
    else
      IO.puts("  ❌ Insufficient domain contributions - collaboration incomplete!")
      return :fail
    end
    
    # Test 8: Verify team assembly is deterministic for same input
    {selected_domains_2, _} = DomainCortex.select_domain_team(
      meta_cog, 
      task_description, 
      world_model
    )
    
    if selected_domains == selected_domains_2 do
      IO.puts("  ✅ Domain team assembly is deterministic")
    else
      IO.puts("  ❌ Domain team assembly is non-deterministic - consistency violation!")
      return :fail
    end
    
    IO.puts("  ✅ Domain Team Assembly verified")
    :pass
  end

  @doc """
  DC-002 Domain Diversity Test
  
  Force: Prediction = 95%
  
  Expected:
  - CIS warning
  
  for monoculture risk.
  """
  def test_dc_002_domain_diversity do
    IO.puts("🔍 DC-002: Testing Domain Diversity")
    
    # Test 1: Create MetaCognition with forced high prediction weight
    meta_cog = MetaCognition.new()
    forced_weights = %{prediction: 0.95, logic: 0.01, temporal: 0.01, causal: 0.01, 
                      algorithm: 0.01, embodied: 0.01, reverse_engineering: 0.01}
    meta_cog_with_forced_weights = %{meta_cog | domain_weights: forced_weights}
    
    # Test 2: Initialize World Model
    world_model = WorldModel.new()
    
    # Test 3: Request domain selection with forced weights
    task_description = "analyze_market_patterns"
    {selected_domains, _} = DomainCortex.select_domain_team(
      meta_cog_with_forced_weights, 
      task_description, 
      world_model
    )
    
    # Test 4: Verify prediction dominance
    prediction_weight = Map.get(selected_domains, :prediction, 0.0)
    
    if prediction_weight >= 0.9 do
      IO.puts("  ✅ Prediction dominance confirmed (#{prediction_weight})")
    else
      IO.puts("  ❌ Prediction not dominant as expected")
      return :fail
    end
    
    # Test 5: Verify CIS (Cognitive Integrity System) detects monoculture
    cis_result = DomainCortex.check_cognitive_diversity(selected_domains)
    
    case cis_result do
      {:warning, message} when is_binary(message) ->
        if String.contains?(message, "monoculture") or 
           String.contains?(message, "diversity") or
           String.contains?(message, "prediction") do
          IO.puts("  ✅ CIS warning generated for monoculture risk")
        else
          IO.puts("  ❌ CIS warning generated but not relevant: #{message}")
          return :fail
        end
      {:ok, message} ->
        IO.puts("  ❌ No CIS warning generated - diversity monitoring broken!")
        return :fail
      {:error, reason} ->
        IO.puts("  ❌ CIS check failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 6: Verify CIS provides diversity recommendations
    recommendation_result = DomainCortex.get_diversity_recommendations(selected_domains)
    
    case recommendation_result do
      {:ok, recommendations} when is_list(recommendations) ->
        if length(recommendations) > 0 do
          IO.puts("  ✅ CIS provided #{length(recommendations)} diversity recommendations")
        else
          IO.puts("  ❌ CIS provided no recommendations - monitoring incomplete!")
          return :fail
        end
      {:error, reason} ->
        IO.puts("  ❌ Diversity recommendation generation failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 7: Verify diversity metrics can be calculated
    diversity_metrics = DomainCortex.calculate_diversity_metrics(selected_domains)
    
    if Map.has_key?(diversity_metrics, :entropy) and 
       Map.has_key?(diversity_metrics, :dominance) do
      IO.puts("  ✅ Diversity metrics calculated")
      
      if diversity_metrics.dominance > 0.8 do
        IO.puts("  ✅ High dominance detected (#{diversity_metrics.dominance})")
      else
        IO.puts("  ❌ Low dominance detected - test setup incorrect!")
        return :fail
      end
    else
      IO.puts("  ❌ Diversity metrics incomplete - monitoring broken!")
      return :fail
    end
    
    # Test 8: Verify domain team can still function despite warning
    {team_output, _updated_world_model} = DomainCortex.execute_domain_team(
      selected_domains,
      task_description,
      world_model
    )
    
    if length(team_output) > 0 do
      IO.puts("  ✅ Domain team functional despite diversity warning")
    else
      IO.puts("  ❌ Domain team non-functional with diversity warning - system broken!")
      return :fail
    end
    
    IO.puts("  ✅ Domain Diversity verified")
    :pass
  end

  @doc """
  DC-003 Domain Collaboration Test
  
  Task: Reverse engineer malware
  
  Expected:
  - RE
  - Logic
  - Causal
  - Ethics
  
  produce shared output.
  """
  def test_dc_003_domain_collaboration do
    IO.puts("🔍 DC-003: Testing Domain Collaboration")
    
    # Test 1: Initialize World Model with malware context
    world_model = WorldModel.new()
    
    # Add malware-related entities to World Model
    API.create_entity("malware:sample1", "Malware", "Sample Malware", %{type: "trojan"})
    API.create_entity("host:target1", "Host", "Target Host", %{vulnerabilities: ["CVE-2023-1234"]})
    
    # Add malware analysis belief
    malware_belief = API.add_belief("Suspicious behavior detected in sample", 0.85, "initial_analysis", [])
    
    case malware_belief do
      {:ok, _belief_id} ->
        IO.puts("  ✅ Malware context added to World Model")
      {:error, reason} ->
        IO.puts("  ❌ Failed to add malware context: #{inspect(reason)}")
        return :fail
    end
    
    # Test 2: Initialize MetaCognition for domain selection
    meta_cog = MetaCognition.new()
    
    # Test 3: Request domain team for "Reverse engineer malware"
    task_description = "Reverse engineer malware"
    {selected_domains, _} = DomainCortex.select_domain_team(
      meta_cog, 
      task_description, 
      world_model
    )
    
    # Test 4: Verify expected domains are selected for malware analysis
    expected_malware_domains = [:reverse_engineering, :logic, :causal, :ethics]
    
    malware_domains_present = Enum.all?(expected_malware_domains, fn domain ->
      Map.has_key?(selected_domains, domain) and Map.get(selected_domains, domain) > 0.1
    end)
    
    if malware_domains_present do
      IO.puts("  ✅ Expected malware domains selected: #{inspect(expected_malware_domains)}")
    else
      IO.puts("  ❌ Missing expected malware domains in selection")
      return :fail
    end
    
    # Test 5: Verify domain collaboration produces shared output
    collaboration_result = DomainCortex.execute_domain_team(
      selected_domains,
      task_description,
      world_model
    )
    
    case collaboration_result do
      {:ok, {outputs, updated_world_model}} ->
        IO.puts("  ✅ Domain collaboration successful")
        
        # Verify shared output was produced
        if length(outputs) > 0 do
          IO.puts("  ✅ Domains produced #{length(outputs)} collaborative outputs")
        else
          IO.puts("  ❌ No collaborative outputs produced - collaboration failed!")
          return :fail
        end
        
      {:error, reason} ->
        IO.puts("  ❌ Domain collaboration failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 6: Verify each domain contributed to malware analysis
    domain_contributions = DomainCortex.get_domain_contributions(outputs)
    
    expected_contributions = ["reverse_engineering", "logic", "causal", "ethics"]
    contributions_present = Enum.all?(expected_contributions, fn expected ->
      Enum.any?(domain_contributions, fn {domain, _} -> 
        Atom.to_string(domain) == expected 
      end)
    end)
    
    if contributions_present do
      IO.puts("  ✅ All expected domains contributed to analysis")
    else
      IO.puts("  ❌ Missing domain contributions - collaboration incomplete!")
      return :fail
    end
    
    # Test 7: Verify collaborative output integrates domain perspectives
    integrated_output = DomainCortex.check_output_integration(outputs, selected_domains)
    
    case integrated_output do
      {:ok, integration_score} when is_number(integration_score) ->
        if integration_score > 0.7 do
          IO.puts("  ✅ High integration score: #{integration_score}")
        else
          IO.puts("  ❌ Low integration score: #{integration_score}")
          return :fail
        end
      {:error, reason} ->
        IO.puts("  ❌ Integration check failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 8: Verify World Model was updated with collaborative results
    if length(updated_world_model.beliefs) > length(world_model.beliefs) do
      IO.puts("  ✅ World Model updated with collaborative insights")
    else
      IO.puts("  ❌ World Model not updated - collaboration integration broken!")
      return :fail
    end
    
    # Test 9: Verify domain team can handle conflicts
    conflict_result = DomainCortex.resolve_domain_conflicts(
      selected_domains,
      outputs,
      world_model
    )
    
    case conflict_result do
      {:ok, resolved_outputs} ->
        IO.puts("  ✅ Domain conflicts resolved successfully")
        
        if length(resolved_outputs) > 0 do
          IO.puts("  ✅ Resolved outputs produced")
        else
          IO.puts("  ❌ No resolved outputs - conflict resolution failed!")
          return :fail
        end
      {:error, reason} ->
        IO.puts("  ❌ Conflict resolution failed: #{inspect(reason)}")
        return :fail
    end
    
    # Test 10: Verify collaborative output can be used by AEO
    aeo_ready = DomainCortex.check_aeo_readiness(resolved_outputs)
    
    case aeo_ready do
      {:ok, _} ->
        IO.puts("  ✅ Collaborative output AEO-ready")
      {:error, reason} ->
        IO.puts("  ❌ Collaborative output not AEO-ready: #{inspect(reason)}")
        return :fail
    end
    
    IO.puts("  ✅ Domain Collaboration verified")
    :pass
  end
end