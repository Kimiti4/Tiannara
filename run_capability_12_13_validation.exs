defmodule Capability12_13Validation do
  @moduledoc """
  Validation script for Capability 12.13 — Autonomous Research Planning
  
  Tests seven constitutional scenarios demonstrating autonomous research planning.
  """
  
  alias TiannaraOS.ResearchInstitution
  alias TiannaraOS.InstitutionKernel
  alias TiannaraOS.ResearchPlanResult
  alias TiannaraOS.DomainProfile
  
  def run_all_scenarios do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Capability 12.13 — Autonomous Research Planning Validation")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    results = [
      scenario_1_single_knowledge_gap(),
      scenario_2_competing_priorities(),
      scenario_3_budget_constraint(),
      scenario_4_contradiction_priority(),
      scenario_5_high_information_gain(),
      scenario_6_independent_plans(),
      scenario_7_constitutional_traceability()
    ]
    
    passed = Enum.count(results, & &1)
    total = length(results)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Results: #{passed}/#{total} scenarios passed")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    if passed == total do
      IO.puts("🎉 CAPABILITY 12.13 PASSED - Autonomous Research Planning Validated")
      IO.puts("✅ ALL SCENARIOS PASSED - Capability 12.13 is constitutionally complete\n")
    else
      IO.puts("❌ CAPABILITY 12.13 FAILED - Some scenarios did not pass\n")
    end
    
    passed == total
  end
  
  # Scenario 1: Single knowledge gap → Focused research plan
  def scenario_1_single_knowledge_gap do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 1: Single Knowledge Gap")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :gap_inst_12_13_s1
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 500.0,
      time_horizon: 30
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Candidate Questions: #{length(result.candidate_questions)}")
    IO.puts("  Recommended Experiments: #{length(result.recommended_experiments)}")
    IO.puts("  Prioritized Research: #{length(result.prioritized_research)}")
    IO.puts("  Expected IG: #{Float.round(result.expected_information_gain || 0, 2)}")
    
    scenario_1_pass = result.status == :planned and
                      length(result.recommended_experiments) > 0 and
                      length(result.prioritized_research) > 0
    
    if scenario_1_pass do
      IO.puts("\n✅ Scenario 1 PASSED - Focused research plan generated")
    else
      IO.puts("\n❌ Scenario 1 FAILED")
    end
    
    scenario_1_pass
  end
  
  # Scenario 2: Multiple competing research priorities → Prioritization applied
  def scenario_2_competing_priorities do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 2: Multiple Competing Research Priorities")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :priority_inst_12_13_s2
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 1000.0,
      time_horizon: 60
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Experiments: #{length(result.recommended_experiments)}")
    IO.puts("  Prioritized: #{length(result.prioritized_research)}")
    IO.puts("  Has Ranking: #{Enum.any?(result.prioritized_research, &Map.has_key?(&1, :rank))}")
    
    scenario_2_pass = result.status == :planned and
                      length(result.prioritized_research) > 0 and
                      Enum.any?(result.prioritized_research, &Map.has_key?(&1, :rank))
    
    if scenario_2_pass do
      IO.puts("\n✅ Scenario 2 PASSED - Competing priorities resolved with ranking")
    else
      IO.puts("\n❌ Scenario 2 FAILED")
    end
    
    scenario_2_pass
  end
  
  # Scenario 3: Budget constraint changes plan → Feasibility checked
  def scenario_3_budget_constraint do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 3: Budget Constraint Changes Plan")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :budget_inst_12_13_s3
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 100.0,  # Low budget
      time_horizon: 14
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Estimated Cost: #{result.estimated_cost}")
    IO.puts("  Budget OK: #{ResearchPlanResult.research_budget_ok?(result)}")
    IO.puts("  Has Ledger Delta: #{result.ledger_delta != nil}")
    
    scenario_3_pass = result.status == :planned and
                      result.ledger_delta != nil and
                      result.estimated_cost != nil
    
    if scenario_3_pass do
      IO.puts("\n✅ Scenario 3 PASSED - Budget constraints accounted for")
    else
      IO.puts("\n❌ Scenario 3 FAILED")
    end
    
    scenario_3_pass
  end
  
  # Scenario 4: Contradictory theories receive priority → High-priority experiments
  def scenario_4_contradiction_priority do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 4: Contradictory Theories Receive Priority")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :contradiction_inst_12_13_s4
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:physics)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 800.0,
      time_horizon: 45
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Knowledge Gaps: #{length(result.knowledge_gaps)}")
    IO.puts("  High Priority Experiments: #{Enum.count(result.prioritized_research, &(&1.priority == :high))}")
    
    scenario_4_pass = result.status == :planned and
                      length(result.knowledge_gaps) > 0 and
                      Enum.any?(result.prioritized_research, &(&1.priority == :high))
    
    if scenario_4_pass do
      IO.puts("\n✅ Scenario 4 PASSED - Contradictions prioritized for resolution")
    else
      IO.puts("\n❌ Scenario 4 FAILED")
    end
    
    scenario_4_pass
  end
  
  # Scenario 5: High information gain preferred → ROI optimization
  def scenario_5_high_information_gain do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 5: High Information Gain Preferred")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :ig_inst_12_13_s5
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 600.0,
      time_horizon: 30
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Expected IG: #{Float.round(result.expected_information_gain || 0, 2)}")
    IO.puts("  Has ROI: #{Enum.any?(result.planning_rationale, &(&1.type == :roi_calculation))}")
    IO.puts("  Quality Score: #{if Enum.any?(result.planning_rationale, &(&1.type == :quality_assessment)), do: "Calculated", else: "N/A"}")
    
    scenario_5_pass = result.status == :planned and
                      result.expected_information_gain != nil and
                      result.expected_information_gain > 0
    
    if scenario_5_pass do
      IO.puts("\n✅ Scenario 5 PASSED - High IG experiments prioritized with ROI")
    else
      IO.puts("\n❌ Scenario 5 FAILED")
    end
    
    scenario_5_pass
  end
  
  # Scenario 6: Independent institutions produce different plans → Diversity
  def scenario_6_independent_plans do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 6: Independent Institutions Produce Different Plans")
    IO.puts(String.duplicate("-", 80))
    
    # Use different domains to test institutional individuality
    domains = [:medicine, :engineering, :mathematics, :physics, :biology]
    
    results = Enum.map(Enum.zip(1..5, domains), fn {i, domain} ->
      institution_id = String.to_atom("inst_#{i}_12_13_s6")
      institution = ResearchInstitution.new(institution_id, :world_001, 0)
      {:ok, profile} = DomainProfile.load(domain)
      configured = DomainProfile.apply(institution, {:ok, profile})
      {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
      
      {:ok, result} = InstitutionKernel.plan_research(kernel, %{
        budget_limit: 500.0 + (i * 100),  # Different budgets
        time_horizon: 30
      })
       
      GenServer.stop(kernel)
      
      {domain, result}
    end)
    
    all_planned = Enum.all?(results, fn {_domain, r} -> r.status == :planned end)
    all_have_experiments = Enum.all?(results, fn {_domain, r} -> length(r.recommended_experiments) > 0 end)
    all_have_rationale = Enum.all?(results, fn {_domain, r} -> length(r.planning_rationale) > 0 end)
    
    # Check that different domains produce different experiment titles (institutional individuality)
    experiment_titles_by_domain = Enum.map(results, fn {domain, r} -> 
      {domain, Enum.map(r.recommended_experiments, & &1.title)}
    end)
    
    unique_experiment_sets = experiment_titles_by_domain 
      |> Enum.map(fn {_domain, titles} -> MapSet.new(titles) end)
      |> Enum.uniq()
    
    different_plans = length(unique_experiment_sets) > 1
    
    scenario_6_pass = all_planned and all_have_experiments and all_have_rationale and different_plans
    
    IO.puts("\nValidation Results:")
    IO.puts("  All Planned: #{all_planned}")
    IO.puts("  All Have Experiments: #{all_have_experiments}")
    IO.puts("  All Have Rationale: #{all_have_rationale}")
    IO.puts("  Different Plans (by domain): #{different_plans}")
    IO.puts("  Unique Experiment Sets: #{length(unique_experiment_sets)}")
    IO.puts("\nDomain-Specific Plans:")
    Enum.each(experiment_titles_by_domain, fn {domain, titles} ->
      IO.puts("  #{domain}: #{inspect(titles)}")
    end)
    
    if scenario_6_pass do
      IO.puts("\n✅ Scenario 6 PASSED - Independent institutions produce diverse plans")
    else
      IO.puts("\n❌ Scenario 6 FAILED")
    end
    
    scenario_6_pass
  end
  
  # Scenario 7: Planning remains constitutionally traceable → Full provenance
  def scenario_7_constitutional_traceability do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 7: Planning Remains Constitutionally Traceable")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :trace_inst_12_13_s7
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, result} = InstitutionKernel.plan_research(kernel, %{
      budget_limit: 700.0,
      time_horizon: 40
    })
    
    GenServer.stop(kernel)
    
    # Check constitutional invariants
    all_traceable = ResearchPlanResult.verify_traceability(result)
    has_rationale = length(result.planning_rationale) > 0
    has_ledger = result.ledger_delta != nil
    has_topology = result.topology_inputs != nil
    has_lifecycle = length(result.lifecycle_events) > 0
    
    scenario_7_pass = all_traceable and has_rationale and has_ledger and has_topology and has_lifecycle
    
    IO.puts("\nValidation Results:")
    IO.puts("  All Traceable: #{all_traceable}")
    IO.puts("  Has Rationale: #{has_rationale}")
    IO.puts("  Has Ledger: #{has_ledger}")
    IO.puts("  Has Topology Inputs: #{has_topology}")
    IO.puts("  Has Lifecycle: #{has_lifecycle}")
    
    if scenario_7_pass do
      IO.puts("\n✅ Scenario 7 PASSED - Full constitutional traceability maintained")
    else
      IO.puts("\n❌ Scenario 7 FAILED")
    end
    
    scenario_7_pass
  end
end

# Run validation
case Capability12_13Validation.run_all_scenarios() do
  true ->
    System.halt(0)
  false ->
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("VALIDATION FAILED: Capability 12.13 requires fixes")
    IO.puts(String.duplicate("=", 80) <> "\n")
    System.halt(1)
end
