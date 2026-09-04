defmodule Tiannara.ASC.Campaign.Phase5C6Validation do
  @moduledoc """
  Phase 5C.6 — Validation Sprint
  
  Scientific objective: Prove that ecological fitness predicts future representation.
  
  Tests:
  1. Do fitness scores change over time?
  2. Do budgets adapt based on fitness?
  3. Can species go extinct or dominate?
  4. Does entropy respond to selection pressure?
  
  Configuration:
  - 3 projects (reduced from 10 for faster iteration)
  - 10 generations (reduced from 20 for focused validation)
  - Full species telemetry per generation
  - Forced poor repairability for dependency species (extinction test)
  """

  alias Tiannara.ASC.Interface.Genome
  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer}
  alias Tiannara.ASC.Crucible.Observatory
  alias Tiannara.ASC.Crucible.TransferEcology
  alias Tiannara.ASC.Crucible.FailureSpecies
  alias Tiannara.ASC.Crucible.SpeciesFitness

  # Reduced project set for rapid validation
  @project_configs [
    %{genome_id: "web_app_001", project_id: "simple_web_app", deployment_target: "docker-compose"},
    %{genome_id: "api_001", project_id: "rest_api", deployment_target: "kubernetes"},
    %{genome_id: "store_001", project_id: "kv_store", deployment_target: "distributed"}
  ]

  @generations 10
  @initial_budgets FailureSpecies.species_budgets()

  def run_validation do
    IO.puts("\n" <> String.duplicate("=", 100))
    IO.puts("🧬 PHASE 5C.6 — VALIDATION SPRINT")
    IO.puts(String.duplicate("=", 100))
    IO.puts("\nMission: Prove ecological fitness predicts future representation\n")
    
    display_validation_plan()
    
    # Initialize genomes
    IO.puts("\n📦 Initializing #{@project_configs |> length()} genomes...\n")
    
    genomes = Enum.map(@project_configs, fn config ->
      genome = %Genome{
        genome_id: config.genome_id,
        generation: 0,
        fitness: 0.5,
        contracts: [],
        events: [],
        protocols: [],
        schemas: [],
        interfaces: [],
        deployment_target: config.deployment_target
      }
      
      {config.project_id, genome}
    end)
    |> Enum.into(%{})
    
    # Run validation with full telemetry
    IO.puts("\n🔬 Starting validation sprint (#{length(Map.keys(genomes))} projects × #{@generations} generations)\n")
    
    telemetry_data = run_validation_with_telemetry(genomes, @initial_budgets, _generation = 1, [])
    
    # Analyze results
    analyze_validation_results(telemetry_data)
  end

  defp run_validation_with_telemetry(genomes, current_budgets, generation, telemetry_acc) when generation <= @generations do
    IO.puts("\n" <> String.duplicate("-", 100))
    IO.puts("🔄 Generation #{generation}/#{@generations}")
    IO.puts(String.duplicate("-", 100))
    
    # Record pre-generation state
    pre_generation_state = record_generation_state(generation, current_budgets, :pre)
    
    # Evolve all projects
    evolved_genomes = evolve_all_projects(genomes, generation, current_budgets)
    
    # Get ecology metrics
    ecology_metrics = get_ecology_metrics()
    
    # Calculate species fitness
    species_fitness_map = calculate_species_fitness(ecology_metrics)
    
    # Adjust budgets based on fitness
    new_budgets = SpeciesFitness.adjust_budget(current_budgets, species_fitness_map)
    
    # Check for extinction/dominance events
    events = check_species_events(species_fitness_map, generation)
    
    # Record post-generation state
    post_generation_state = record_generation_state(generation, new_budgets, :post, species_fitness_map, events)
    
    # Display generation summary
    display_generation_summary(generation, ecology_metrics, species_fitness_map, new_budgets, events)
    
    # Accumulate telemetry
    updated_telemetry = telemetry_acc ++ [post_generation_state]
    
    # Continue to next generation
    run_validation_with_telemetry(evolved_genomes, new_budgets, generation + 1, updated_telemetry)
  end

  defp run_validation_with_telemetry(_genomes, _final_budgets, _generation, telemetry_acc) do
    telemetry_acc
  end

  defp evolve_all_projects(genomes, generation, current_budgets) do
    Enum.map(genomes, fn {project_id, genome} ->
      case evolve_generation(genome, project_id, generation, current_budgets) do
        {:ok, new_genome} -> {project_id, new_genome}
        {:error, error} ->
          IO.puts("   ⚠️  Project #{project_id} failed: #{inspect(error)}")
          {project_id, genome}
      end
    end)
    |> Enum.into(%{})
  end

  defp evolve_generation(genome, project_id, generation, current_budgets) do
    artifact_path = "/tmp/#{project_id}_gen_#{generation}"
    
    try do
      # Step 1: Build
      {:ok, build_result} = Builder.build(genome, project_id)
      
      build_obs = Tiannara.ASC.Crucible.Observation.from_builder_result(
        build_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(build_obs)
      
      # Step 2: Validate
      {:ok, validation_result} = Validator.validate(genome, artifact_path)
      
      validation_obs = Tiannara.ASC.Crucible.Observation.from_validator_result(
        validation_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(validation_obs)
      
      # Step 3: Break (with adaptive species budgets)
      break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id, species_budgets: current_budgets) do
        {:ok, result} -> result
        {:error, error} -> %{failure_discovered?: false, failure_type: :unknown, failure_severity: :low, failure_description: inspect(error)}
      end
      
      break_obs = Tiannara.ASC.Crucible.Observation.from_breaker_result(
        break_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(break_obs)
      
      # Step 4: Attack
      attack_result = case Attacker.attack_system(genome, artifact_path, project_id: project_id) do
        {:ok, result} -> result
        {:error, error} -> %{exploit_found?: false, exploit_severity: :low, exploit_description: inspect(error), reproducible_exploits: 0}
      end
      
      attack_obs = Tiannara.ASC.Crucible.Observation.from_attacker_result(
        attack_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(attack_obs)
      
      # Step 5: Repair (if failure discovered)
      repair_result = if break_result.failure_discovered? do
        case Repairer.repair(break_obs, artifact_path, project_id: project_id) do
          {:ok, result} -> result
          {:error, _error} -> %{repair_successful?: false, repair_description: "Repair failed", patch_stable?: false, repair_severity: :low}
        end
      else
        %{repair_successful?: false, repair_description: "No failure to repair", patch_stable?: false, repair_severity: :low}
      end
      
      repair_obs = Tiannara.ASC.Crucible.Observation.from_repairer_result(
        repair_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(repair_obs)
      
      # Calculate fitness
      fitness = calculate_fitness(build_result, validation_result, break_result, attack_result, repair_result)
      
      {:ok, %{genome | generation: generation, fitness: fitness}}
      
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  defp calculate_fitness(build_result, validation_result, break_result, attack_result, repair_result) do
    # Simplified fitness calculation
    build_score = if Map.get(build_result, :success?, false), do: 1.0, else: 0.0
    validation_score = if Map.get(validation_result, :valid?, false), do: 1.0, else: 0.0
    
    # Reward discovering failures (shows system is being tested)
    break_score = if break_result.failure_discovered?, do: 0.8, else: 0.3
    
    # Reward successful repairs
    repair_score = if Map.get(repair_result, :repair_successful?, false), do: 1.0, else: 0.2
    
    # Weighted average
    (build_score * 0.25 + validation_score * 0.25 + break_score * 0.25 + repair_score * 0.25)
    |> Float.round(3)
  end

  defp get_ecology_metrics do
    case GenServer.call(TransferEcology, :get_metrics) do
      {:ok, metrics} -> metrics
      _ -> %{
        source_entropy: 0.0,
        domain_entropy: 0.0,
        unique_domains: 0,
        matrix_cells_populated: 0,
        cross_class_rate: 0.0,
        cross_class_success_rate: 0.0,
        species_births: %{},
        species_survivals: %{},
        species_transfers_attempted: %{},
        species_transfers_successful: %{}
      }
    end
  end

  defp calculate_species_fitness(ecology_metrics) do
    # Extract species data from ecology metrics
    species_ids = Map.keys(ecology_metrics.species_births || %{})
    
    Enum.map(species_ids, fn species_id ->
      births = Map.get(ecology_metrics.species_births, species_id, 0)
      survivals = Map.get(ecology_metrics.species_survivals, species_id, 0)
      transfers_attempted = Map.get(ecology_metrics.species_transfers_attempted, species_id, 0)
      transfers_successful = Map.get(ecology_metrics.species_transfers_successful, species_id, 0)
      
      # Create simplified species data for fitness calculation
      species_data = %{
        species_id: species_id,
        generation: 1,
        births: births,
        survivals: survivals,
        extinctions: 0,
        repairs_attempted: transfers_attempted,
        repairs_successful: transfers_successful,
        transfers_attempted: transfers_attempted,
        transfers_successful: transfers_successful,
        average_recovery_latency_ms: 0.0
      }
      
      fitness_record = SpeciesFitness.calculate_fitness(species_data)
      {species_id, fitness_record.fitness_score}
    end)
    |> Enum.into(%{})
  end

  defp check_species_events(species_fitness_map, generation) do
    events = []
    
    # Check for dominance events (fitness > 0.75)
    dominant = SpeciesFitness.get_dominant_species(species_fitness_map)
    if elem(dominant, 1) > 0.75 do
      event = SpeciesFitness.create_dominance_event(elem(dominant, 0), elem(dominant, 1), 1)
      events = [event | events]
      IO.puts("   🏆 DOMINANCE EVENT: #{event.species_id} (fitness: #{Float.round(event.fitness, 2)})")
    end
    
    # Check for extinction watch (fitness < 0.05)
    extinction_watch = SpeciesFitness.get_extinction_watch_species(species_fitness_map)
    if length(extinction_watch) > 0 do
      Enum.each(extinction_watch, fn {species_id, fitness} ->
        event = SpeciesFitness.create_extinction_event(species_id, generation, fitness, :low_fitness)
        events = [event | events]
        IO.puts("   ☠️  EXTINCTION WATCH: #{species_id} (fitness: #{Float.round(fitness, 2)})")
      end)
    end
    
    events
  end

  defp record_generation_state(generation, budgets, phase, species_fitness \\ nil, events \\ []) do
    %{
      generation: generation,
      phase: phase,
      budgets: budgets,
      species_fitness: species_fitness,
      events: events,
      timestamp: DateTime.utc_now()
    }
  end

  defp display_validation_plan do
    IO.puts("📋 Validation Plan:")
    IO.puts(String.duplicate("-", 80))
    IO.puts("   Projects: #{length(@project_configs)}")
    IO.puts("   Generations: #{@generations}")
    IO.puts("   Total Evolution Steps: #{length(@project_configs) * @generations}")
    IO.puts("")
    IO.puts("   Questions to Answer:")
    IO.puts("     1. Do fitness scores change over time?")
    IO.puts("     2. Do budgets adapt based on fitness?")
    IO.puts("     3. Can species go extinct or dominate?")
    IO.puts("     4. Does entropy respond to selection pressure?")
    IO.puts(String.duplicate("-", 80) <> "\n")
  end

  defp display_generation_summary(generation, ecology_metrics, species_fitness_map, new_budgets, events) do
    IO.puts("\n📊 Generation #{generation} Summary:")
    IO.puts(String.duplicate("-", 80))
    
    # Ecology metrics
    IO.puts("   Ecological Diversity:")
    IO.puts("     Source Entropy: #{Float.round(ecology_metrics.source_entropy, 3)}")
    IO.puts("     Domain Entropy: #{Float.round(ecology_metrics.domain_entropy, 3)}")
    IO.puts("     Unique Domains: #{ecology_metrics.unique_domains}")
    IO.puts("     Matrix Cells: #{ecology_metrics.matrix_cells_populated}")
    
    # Species fitness
    IO.puts("\n   Species Fitness:")
    species_fitness_map
    |> Enum.sort_by(fn {_species, fitness} -> -fitness end)
    |> Enum.each(fn {species_id, fitness} ->
      status = SpeciesFitness.determine_status(%{fitness_score: fitness})
      status_icon = case status do
        :dominant -> "👑"
        :thriving -> "✅"
        :stable -> "➡️"
        :declining -> "⚠️"
        :extinction_watch -> "☠️"
      end
      IO.puts("     #{status_icon} #{String.pad_trailing(to_string(species_id), 15)} #{Float.round(fitness, 3)} (#{status})")
    end)
    
    # Budget allocation
    IO.puts("\n   Next Generation Budgets:")
    new_budgets
    |> Enum.sort_by(fn {_species, budget} -> -budget end)
    |> Enum.each(fn {species_id, budget} ->
      bar_length = round(budget / 2)
      bar = String.duplicate("█", max(1, bar_length))
      IO.puts("     #{String.pad_trailing(to_string(species_id), 15)} #{budget}% #{bar}")
    end)
    
    # Events
    if length(events) > 0 do
      IO.puts("\n   Events:")
      Enum.each(events, fn event ->
        case event.event_type do
          :species_dominance ->
            IO.puts("     🏆 Dominance: #{event.species_id} (fitness: #{Float.round(event.fitness, 2)})")
          :species_extinction ->
            IO.puts("     ☠️  Extinction Watch: #{event.species_id} (fitness: #{Float.round(event.fitness, 2)})")
        end
      end)
    end
    
    IO.puts(String.duplicate("-", 80))
  end

  defp analyze_validation_results(telemetry_data) do
    IO.puts("\n" <> String.duplicate("=", 100))
    IO.puts("🎯 PHASE 5C.6 VALIDATION ANALYSIS")
    IO.puts(String.duplicate("=", 100))
    
    # Question 1: Do fitness scores change over time?
    analyze_fitness_changes(telemetry_data)
    
    # Question 2: Do budgets adapt based on fitness?
    analyze_budget_adaptation(telemetry_data)
    
    # Question 3: Can species go extinct or dominate?
    analyze_extinction_dynamics(telemetry_data)
    
    # Question 4: Does entropy respond to selection pressure?
    analyze_entropy_response(telemetry_data)
    
    # Final verdict
    display_final_verdict(telemetry_data)
  end

  defp analyze_fitness_changes(telemetry_data) do
    IO.puts("\n❓ Question 1: Do fitness scores change over time?")
    IO.puts(String.duplicate("-", 80))
    
    # Extract fitness time series for each species
    species_ids = get_all_species_ids(telemetry_data)
    
    Enum.each(species_ids, fn species_id ->
      fitness_values = extract_fitness_time_series(telemetry_data, species_id)
      
      if length(fitness_values) >= 2 do
        first_fitness = List.first(fitness_values)
        last_fitness = List.last(fitness_values)
        change = last_fitness - first_fitness
        
        direction = cond do
          change > 0.05 -> "↑ INCREASED"
          change < -0.05 -> "↓ DECREASED"
          true -> "→ STABLE"
        end
        
        IO.puts("   #{species_id}: #{Float.round(first_fitness, 3)} → #{Float.round(last_fitness, 3)} (#{direction}, Δ=#{Float.round(change, 3)})")
      end
    end)
    
    # Check if any species changed significantly
    any_changed = Enum.any?(species_ids, fn species_id ->
      fitness_values = extract_fitness_time_series(telemetry_data, species_id)
      if length(fitness_values) >= 2 do
        abs(List.last(fitness_values) - List.first(fitness_values)) > 0.05
      else
        false
      end
    end)
    
    if any_changed do
      IO.puts("\n   ✅ PASS - Fitness scores change over time")
    else
      IO.puts("\n   ❌ FAIL - Fitness scores remain constant (selection pressure not functioning)")
    end
  end

  defp analyze_budget_adaptation(telemetry_data) do
    IO.puts("\n❓ Question 2: Do budgets adapt based on fitness?")
    IO.puts(String.duplicate("-", 80))
    
    # Extract budget time series for each species
    species_ids = get_all_species_ids(telemetry_data)
    
    budget_changes = Enum.map(species_ids, fn species_id ->
      budget_values = extract_budget_time_series(telemetry_data, species_id)
      
      if length(budget_values) >= 2 do
        first_budget = List.first(budget_values)
        last_budget = List.last(budget_values)
        change = last_budget - first_budget
        
        {species_id, first_budget, last_budget, change}
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
    
    # Display changes
    Enum.each(budget_changes, fn {species_id, first, last, change} ->
      direction = if change >= 0, do: "+#{Float.round(change, 1)}", else: "#{Float.round(change, 1)}"
      IO.puts("   #{species_id}: #{Float.round(first, 1)}% → #{Float.round(last, 1)}% (#{direction})")
    end)
    
    # Count species with significant budget changes (>2%)
    significant_changes = Enum.count(budget_changes, fn {_species_id, _first, _last, change} ->
      abs(change) > 2.0
    end)
    
    if significant_changes >= 3 do
      IO.puts("\n   ✅ PASS - #{significant_changes} species changed budget by >2%")
    else
      IO.puts("\n   ❌ FAIL - Only #{significant_changes} species changed budget significantly (need ≥3)")
    end
  end

  defp analyze_extinction_dynamics(telemetry_data) do
    IO.puts("\n❓ Question 3: Can species go extinct or dominate?")
    IO.puts(String.duplicate("-", 80))
    
    # Collect all events
    all_events = Enum.flat_map(telemetry_data, fn state ->
      state.events || []
    end)
    
    dominance_events = Enum.filter(all_events, fn event ->
      event.event_type == :species_dominance
    end)
    
    extinction_events = Enum.filter(all_events, fn event ->
      event.event_type == :species_extinction
    end)
    
    # Display events
    if length(dominance_events) > 0 do
      IO.puts("   Dominance Events:")
      Enum.each(dominance_events, fn event ->
        IO.puts("     🏆 #{event.species_id} at generation #{event.generation} (fitness: #{Float.round(event.fitness, 2)})")
      end)
    else
      IO.puts("   Dominance Events: None observed")
    end
    
    if length(extinction_events) > 0 do
      IO.puts("\n   Extinction Watch Events:")
      Enum.each(extinction_events, fn event ->
        IO.puts("     ☠️  #{event.species_id} at generation #{event.generation} (fitness: #{Float.round(event.fitness, 2)})")
      end)
    else
      IO.puts("\n   Extinction Watch Events: None observed")
    end
    
    # Verdict
    has_either = length(dominance_events) > 0 or length(extinction_events) > 0
    
    if has_either do
      IO.puts("\n   ✅ PASS - Observed #{length(dominance_events)} dominance and #{length(extinction_events)} extinction events")
    else
      IO.puts("\n   ❌ FAIL - No extinction or dominance events observed")
    end
  end

  defp analyze_entropy_response(telemetry_data) do
    IO.puts("\n❓ Question 4: Does entropy respond to selection pressure?")
    IO.puts(String.duplicate("-", 80))
    
    # Extract entropy time series
    entropy_values = Enum.map(telemetry_data, fn state ->
      {state.generation, state.budgets}
    end)
    
    # Calculate species entropy for each generation
    entropy_time_series = Enum.map(entropy_values, fn {generation, budgets} ->
      species_fitness = budgets
      |> Enum.map(fn {species_id, budget} ->
        # Use budget as proxy for fitness in this analysis
        {species_id, budget}
      end)
      |> Enum.into(%{})
      
      entropy = SpeciesFitness.calculate_species_entropy(species_fitness)
      {generation, entropy}
    end)
    
    # Display entropy changes
    IO.puts("   Entropy Time Series:")
    Enum.each(entropy_time_series, fn {generation, entropy} ->
      IO.puts("     Generation #{generation}: #{Float.round(entropy, 3)}")
    end)
    
    # Check if entropy changed
    if length(entropy_time_series) >= 2 do
      first_entropy = elem(List.first(entropy_time_series), 1)
      last_entropy = elem(List.last(entropy_time_series), 1)
      change = last_entropy - first_entropy
      
      IO.puts("\n   Change: #{Float.round(first_entropy, 3)} → #{Float.round(last_entropy, 3)} (Δ=#{Float.round(change, 3)})")
      
      if abs(change) > 0.1 do
        IO.puts("\n   ✅ PASS - Entropy changed significantly (Δ=#{Float.round(abs(change), 3)})")
      else
        IO.puts("\n   ❌ FAIL - Entropy remained stable (Δ=#{Float.round(abs(change), 3)} < 0.1)")
      end
    else
      IO.puts("\n   ❌ FAIL - Insufficient data to measure entropy change")
    end
  end

  defp display_final_verdict(telemetry_data) do
    IO.puts("\n" <> String.duplicate("=", 100))
    IO.puts("🎯 FINAL VERDICT")
    IO.puts(String.duplicate("=", 100))
    
    # Check all four questions
    q1_pass = check_fitness_changes(telemetry_data)
    q2_pass = check_budget_adaptation(telemetry_data)
    q3_pass = check_extinction_dynamics(telemetry_data)
    q4_pass = check_entropy_response(telemetry_data)
    
    IO.puts("\n   Question 1 (Fitness Changes): #{if q1_pass, do: "✅ PASS", else: "❌ FAIL"}")
    IO.puts("   Question 2 (Budget Adaptation): #{if q2_pass, do: "✅ PASS", else: "❌ FAIL"}")
    IO.puts("   Question 3 (Extinction/Dominance): #{if q3_pass, do: "✅ PASS", else: "❌ FAIL"}")
    IO.puts("   Question 4 (Entropy Response): #{if q4_pass, do: "✅ PASS", else: "❌ FAIL"}")
    
    all_pass = q1_pass and q2_pass and q3_pass and q4_pass
    
    IO.puts("\n" <> String.duplicate("-", 100))
    if all_pass do
      IO.puts("🎉 PHASE 5C.6 VALIDATION SUCCESSFUL!")
      IO.puts("\nASC has crossed from 'Failure Species' to 'Failure Ecology'.")
      IO.puts("Ecological fitness DOES predict future representation.")
      IO.puts("\nPhase 5D (Knowledge Fitness & Adaptive Selection) is now scientifically justified.")
    else
      IO.puts("⚠️  PHASE 5C.6 VALIDATION INCOMPLETE")
      IO.puts("\nSome evolutionary dynamics are not yet functioning correctly.")
      IO.puts("Additional refinement needed before advancing to Phase 5D.")
    end
    IO.puts(String.duplicate("-", 100) <> "\n")
  end

  # Helper functions
  defp get_all_species_ids(telemetry_data) do
    telemetry_data
    |> Enum.flat_map(fn state ->
      if state.species_fitness do
        Map.keys(state.species_fitness)
      else
        []
      end
    end)
    |> Enum.uniq()
  end

  defp extract_fitness_time_series(telemetry_data, species_id) do
    telemetry_data
    |> Enum.map(fn state ->
      if state.species_fitness do
        Map.get(state.species_fitness, species_id)
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_budget_time_series(telemetry_data, species_id) do
    telemetry_data
    |> Enum.map(fn state ->
      Map.get(state.budgets, species_id)
    end)
    |> Enum.filter(& &1)
  end

  defp check_fitness_changes(telemetry_data) do
    species_ids = get_all_species_ids(telemetry_data)
    
    Enum.any?(species_ids, fn species_id ->
      fitness_values = extract_fitness_time_series(telemetry_data, species_id)
      if length(fitness_values) >= 2 do
        abs(List.last(fitness_values) - List.first(fitness_values)) > 0.05
      else
        false
      end
    end)
  end

  defp check_budget_adaptation(telemetry_data) do
    species_ids = get_all_species_ids(telemetry_data)
    
    significant_changes = Enum.count(species_ids, fn species_id ->
      budget_values = extract_budget_time_series(telemetry_data, species_id)
      if length(budget_values) >= 2 do
        abs(List.last(budget_values) - List.first(budget_values)) > 2.0
      else
        false
      end
    end)
    
    significant_changes >= 3
  end

  defp check_extinction_dynamics(telemetry_data) do
    all_events = Enum.flat_map(telemetry_data, fn state ->
      state.events || []
    end)
    
    dominance_events = Enum.filter(all_events, fn event ->
      event.event_type == :species_dominance
    end)
    
    extinction_events = Enum.filter(all_events, fn event ->
      event.event_type == :species_extinction
    end)
    
    length(dominance_events) > 0 or length(extinction_events) > 0
  end

  defp check_entropy_response(telemetry_data) do
    entropy_values = Enum.map(telemetry_data, fn state ->
      species_fitness = state.species_fitness || %{}
      SpeciesFitness.calculate_species_entropy(species_fitness)
    end)
    
    if length(entropy_values) >= 2 do
      abs(List.last(entropy_values) - List.first(entropy_values)) > 0.1
    else
      false
    end
  end
end
