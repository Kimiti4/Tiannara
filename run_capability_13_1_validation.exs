defmodule Capability13_1Validation do
  @moduledoc """
  Validation script for Capability 13.1 — Institution Self-Model Formation
  
  Tests seven constitutional scenarios demonstrating institution self-model construction.
  """
  
  alias TiannaraOS.ResearchInstitution
  alias TiannaraOS.InstitutionKernel
  alias TiannaraOS.InstitutionSelfModel
  alias TiannaraOS.DomainProfile
  
  def run_all_scenarios do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Capability 13.1 — Institution Self-Model Formation Validation")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    results = [
      scenario_1_recent_self_model(),
      scenario_2_full_history_self_model(),
      scenario_3_limitation_detection(),
      scenario_4_strength_recognition(),
      scenario_5_methodological_tendencies(),
      scenario_6_comparative_analysis(),
      scenario_7_constitutional_traceability()
    ]
    
    passed = Enum.count(results, & &1)
    total = length(results)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Results: #{passed}/#{total} scenarios passed")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    if passed == total do
      IO.puts("🎉 CAPABILITY 13.1 PASSED - Institution Self-Model Formation Validated")
      IO.puts("✅ ALL SCENARIOS PASSED - Capability 13.1 is constitutionally complete\n")
    else
      IO.puts("❌ CAPABILITY 13.1 FAILED - Some scenarios did not pass\n")
    end
    
    passed == total
  end
  
  # Scenario 1: Recent self-model construction
  def scenario_1_recent_self_model do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 1: Recent Self-Model Construction")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s1
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :recent
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Model Scope: #{model.model_scope}")
    IO.puts("  Episodes Observed: #{model.episodes_observed}")
    IO.puts("  Theories Observed: #{model.theories_observed}")
    IO.puts("  Programs Observed: #{model.research_programs_observed}")
    IO.puts("  Model Confidence: #{Float.round(model.model_confidence || 0, 3)}")
    IO.puts("  Self-Understanding Quality: #{Float.round(model.self_understanding_quality || 0, 3)}")
    
    scenario_1_pass = model.status == :constructed and
                      model.model_scope == :recent and
                      model.episodes_observed > 0 and
                      model.theories_observed > 0 and
                      model.model_confidence != nil and
                      model.self_understanding_quality != nil
    
    if scenario_1_pass do
      IO.puts("\n✅ Scenario 1 PASSED - Recent self-model constructed successfully")
    else
      IO.puts("\n❌ Scenario 1 FAILED")
    end
    
    scenario_1_pass
  end
  
  # Scenario 2: Full history self-model
  def scenario_2_full_history_self_model do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 2: Full History Self-Model")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s2
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :full
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Model Scope: #{model.model_scope}")
    IO.puts("  Episodes Observed: #{model.episodes_observed}")
    IO.puts("  Theories Observed: #{model.theories_observed}")
    IO.puts("  Programs Observed: #{model.research_programs_observed}")
    
    # Full scope should observe more episodes than recent scope
    full_episodes = model.episodes_observed
    
    scenario_2_pass = model.status == :constructed and
                      model.model_scope == :full and
                      full_episodes >= 10  # Should be more than recent scope
    
    if scenario_2_pass do
      IO.puts("\n✅ Scenario 2 PASSED - Full history self-model analyzed extensive data")
    else
      IO.puts("\n❌ Scenario 2 FAILED")
    end
    
    scenario_2_pass
  end
  
  # Scenario 3: Limitation detection
  def scenario_3_limitation_detection do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 3: Limitation Detection")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s3
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :recent
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Limitations Found: #{length(model.reasoning_limitations)}")
    IO.puts("  Limitation Categories: #{inspect(Enum.map(model.reasoning_limitations, & &1.category))}")
    IO.puts("  All Have Evidence: #{Enum.all?(model.reasoning_limitations, fn l -> length(l.evidence || []) > 0 end)}")
    
    # Check that limitations have proper structure
    limitations_valid = Enum.all?(model.reasoning_limitations, fn l ->
      Map.has_key?(l, :limitation_id) and
      Map.has_key?(l, :category) and
      Map.has_key?(l, :description) and
      Map.has_key?(l, :severity) and
      Map.has_key?(l, :potential_improvement) and
      length(l.evidence || []) > 0
    end)
    
    scenario_3_pass = model.status == :constructed and
                      length(model.reasoning_limitations) > 0 and
                      limitations_valid
    
    if scenario_3_pass do
      IO.puts("\n✅ Scenario 3 PASSED - Limitations correctly identified with evidence")
    else
      IO.puts("\n❌ Scenario 3 FAILED")
    end
    
    scenario_3_pass
  end
  
  # Scenario 4: Strength recognition
  def scenario_4_strength_recognition do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 4: Strength Recognition")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s4
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :recent
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Strengths Found: #{length(model.reasoning_strengths)}")
    IO.puts("  Strength Categories: #{inspect(Enum.map(model.reasoning_strengths, & &1.category))}")
    IO.puts("  All Have Confidence: #{Enum.all?(model.reasoning_strengths, fn s -> s.confidence != nil end)}")
    
    # Check that strengths have proper structure
    strengths_valid = Enum.all?(model.reasoning_strengths, fn s ->
      Map.has_key?(s, :strength_id) and
      Map.has_key?(s, :category) and
      Map.has_key?(s, :description) and
      Map.has_key?(s, :confidence) and
      Map.has_key?(s, :reuse_potential) and
      length(s.evidence || []) > 0
    end)
    
    scenario_4_pass = model.status == :constructed and
                      length(model.reasoning_strengths) > 0 and
                      strengths_valid
    
    if scenario_4_pass do
      IO.puts("\n✅ Scenario 4 PASSED - Strengths correctly recognized with confidence levels")
    else
      IO.puts("\n❌ Scenario 4 FAILED")
    end
    
    scenario_4_pass
  end
  
  # Scenario 5: Methodological tendencies
  def scenario_5_methodological_tendencies do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 5: Methodological Tendencies")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s5
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :recent
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Tendencies Identified: #{length(model.methodological_tendencies)}")
    IO.puts("  Tendency Areas: #{inspect(Enum.map(model.methodological_tendencies, & &1.area))}")
    
    # Check that tendencies have proper structure
    tendencies_valid = Enum.all?(model.methodological_tendencies, fn t ->
      Map.has_key?(t, :tendency_id) and
      Map.has_key?(t, :area) and
      Map.has_key?(t, :description) and
      Map.has_key?(t, :frequency) and
      Map.has_key?(t, :impact) and
      length(t.evidence || []) > 0
    end)
    
    scenario_5_pass = model.status == :constructed and
                      length(model.methodological_tendencies) > 0 and
                      tendencies_valid
    
    if scenario_5_pass do
      IO.puts("\n✅ Scenario 5 PASSED - Methodological tendencies identified with evidence")
    else
      IO.puts("\n❌ Scenario 5 FAILED")
    end
    
    scenario_5_pass
  end
  
  # Scenario 6: Comparative analysis (different institutions produce different self-models)
  def scenario_6_comparative_analysis do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 6: Comparative Analysis - Institutional Individuality")
    IO.puts(String.duplicate("-", 80))
    
    # Use different domains to test institutional individuality
    domains = [:medicine, :engineering, :mathematics, :physics, :biology]
    
    models = Enum.map(Enum.zip(1..5, domains), fn {i, domain} ->
      institution_id = String.to_atom("self_model_inst_#{i}_13_1_s6")
      institution = ResearchInstitution.new(institution_id, :world_001, 0)
      {:ok, profile} = DomainProfile.load(domain)
      configured = DomainProfile.apply(institution, {:ok, profile})
      {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
      
      {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
        model_scope: :recent
      })
      
      GenServer.stop(kernel)
      
      {domain, model}
    end)
    
    all_constructed = Enum.all?(models, fn {_domain, m} -> m.status == :constructed end)
    all_have_limitations = Enum.all?(models, fn {_domain, m} -> length(m.reasoning_limitations) > 0 end)
    all_have_strengths = Enum.all?(models, fn {_domain, m} -> length(m.reasoning_strengths) > 0 end)
    
    # Check that different domains produce different limitation patterns (institutional individuality)
    limitation_categories_by_domain = Enum.map(models, fn {domain, m} ->
      {domain, Enum.map(m.reasoning_limitations, & &1.category)}
    end)
    
    unique_limitation_patterns = limitation_categories_by_domain
      |> Enum.map(fn {_domain, categories} -> MapSet.new(categories) end)
      |> Enum.uniq()
    
    different_models = length(unique_limitation_patterns) > 1
    
    IO.puts("\nValidation Results:")
    IO.puts("  All Constructed: #{all_constructed}")
    IO.puts("  All Have Limitations: #{all_have_limitations}")
    IO.puts("  All Have Strengths: #{all_have_strengths}")
    IO.puts("  Different Models (by domain): #{different_models}")
    IO.puts("  Unique Limitation Patterns: #{length(unique_limitation_patterns)}")
    IO.puts("\nDomain-Specific Self-Models:")
    Enum.each(limitation_categories_by_domain, fn {domain, categories} ->
      IO.puts("  #{domain}: #{inspect(categories)}")
    end)
    
    scenario_6_pass = all_constructed and all_have_limitations and all_have_strengths and different_models
    
    if scenario_6_pass do
      IO.puts("\n✅ Scenario 6 PASSED - Independent institutions produce diverse self-models")
    else
      IO.puts("\n❌ Scenario 6 FAILED")
    end
    
    scenario_6_pass
  end
  
  # Scenario 7: Constitutional traceability
  def scenario_7_constitutional_traceability do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("Scenario 7: Constitutional Traceability")
    IO.puts(String.duplicate("-", 80))
    
    institution_id = :self_model_inst_13_1_s7
    institution = ResearchInstitution.new(institution_id, :world_001, 0)
    {:ok, profile} = DomainProfile.load(:science)
    configured = DomainProfile.apply(institution, {:ok, profile})
    {:ok, kernel} = InstitutionKernel.start_link(institution_id, configured)
    
    {:ok, model} = InstitutionKernel.construct_self_model(kernel, %{
      model_scope: :recent
    })
    
    GenServer.stop(kernel)
    
    IO.puts("\nValidation Results:")
    IO.puts("  Status: #{model.status}")
    IO.puts("  Constitutional Compliance: #{model.constitutional_compliance != nil}")
    IO.puts("  Used Only Frozen Primitives: #{model.constitutional_compliance.used_only_frozen_primitives}")
    IO.puts("  No Architectural Drift: #{model.constitutional_compliance.no_architectural_drift}")
    IO.puts("  Primitives Used: #{length(model.constitutional_compliance.primitives_used)}")
    IO.puts("  Lifecycle Events: #{length(model.lifecycle_events)}")
    IO.puts("  Semantic Events: #{length(model.semantic_events)}")
    IO.puts("  Traceability Verified: #{InstitutionSelfModel.verify_traceability(model)}")
    
    scenario_7_pass = model.status == :constructed and
                      model.constitutional_compliance != nil and
                      model.constitutional_compliance.used_only_frozen_primitives == true and
                      model.constitutional_compliance.no_architectural_drift == true and
                      length(model.constitutional_compliance.primitives_used) > 0 and
                      length(model.lifecycle_events) > 0 and
                      InstitutionSelfModel.verify_traceability(model) == true
    
    if scenario_7_pass do
      IO.puts("\n✅ Scenario 7 PASSED - Full constitutional traceability maintained")
    else
      IO.puts("\n❌ Scenario 7 FAILED")
    end
    
    scenario_7_pass
  end
end

# Run validation
case Capability13_1Validation.run_all_scenarios() do
  true ->
    IO.puts("\n✅ ALL SCENARIOS PASSED - Capability 13.1 is constitutionally complete\n")
    System.halt(0)
  false ->
    IO.puts("\n❌ SOME SCENARIOS FAILED - Capability 13.1 needs fixes\n")
    System.halt(1)
end
