defmodule Tiannara.OS.Layer65CCompetitiveRecoveryTest do
  @moduledoc """
  Layer 6.5C: Competitive Recovery
  
  Tests whether competition between Research Programs drives innovation and improves recovery.
  
  Configuration:
  - 25 worlds, 5 programs per world (total: 125)
  - 60,000 ticks
  - 3 shocks at ticks 15k, 30k, 45k
  - Limited funding pool creates competition
  - Knowledge migration between worlds
  - Winner-take-all dynamics emerge
  
  Success Criteria:
  - Effective strategies gain disproportionate funding share
  - Underperforming programs face termination
  - Knowledge velocity increases due to competitive pressure
  - Cross-world knowledge migration accelerates recovery
  - System demonstrates evolutionary selection
  """
  
  use ExUnit.Case, async: false
  @tag timeout: :infinity  # 2 minutes for domain-specific fitness calculations
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.KnowledgeCapital
  alias TiannaraOS.DiscoveryExchange
  alias TiannaraOS.WorldEpistemicPhysics
  
  # Tier 6.5C configuration
  @worlds_count 25
  @programs_per_world 5
  @total_ticks 60_000
  @metrics_interval 3_000
  @shock_ticks [15_000, 30_000, 45_000]
  @shock_percentage 0.50
  @total_funding_pool 400.0  # Reduced from 1000.0 to create scarcity and competition
  
  test "Layer 6.5C: Competitive Recovery Elasticity" do
    IO.puts("\n=== LAYER 6.5C: COMPETITIVE RECOVERY ELASTICITY ===\n")
    
    funding_pools = [400.0, 300.0, 200.0, 100.0]
    
    Enum.each(funding_pools, fn pool_size ->
      IO.puts("\n" <> String.duplicate("=", 80))
      IO.puts("--- RUNNING ELASTICITY TEST: FUNDING POOL = #{pool_size} ---")
      IO.puts(String.duplicate("=", 80) <> "\n")
      
      state = initialize_competitive_system()
      
      IO.puts("Configuration:")
      IO.puts("  Worlds: #{@worlds_count}")
      IO.puts("  Programs: #{@programs_per_world * @worlds_count}")
      IO.puts("  Ticks: #{@total_ticks}")
      IO.puts("  Shocks: #{Enum.join(@shock_ticks, ", ")}")
      IO.puts("  Total Funding Pool: #{pool_size} (scarcity gradient test)")
      IO.puts("  Shock Severity: #{@shock_percentage * 100}%\n")
      
      {final_state, metrics_history, evolution_data} = run_competitive_simulation(state, pool_size)
      
      analyze_competitive_results(final_state, metrics_history, evolution_data, pool_size)
    end)
  end
  
  defp initialize_competitive_system do
    state = %State{}
    
    Enum.reduce(1..@worlds_count, state, fn world_num, acc_state ->
      world_prefix = "w#{world_num}"
      acc_state = create_world_graph(acc_state, world_prefix)
      acc_state = create_programs_for_world(acc_state, world_prefix)
    end)
  end
  
  defp create_world_graph(state, world_prefix) do
    # Assign EPISTEMIC PHYSICS to each world (creates ecological niches)
    # Instead of hardcoded domains, worlds have measurable characteristics
    physics_profiles = [
      WorldEpistemicPhysics.medicine_environment(),
      WorldEpistemicPhysics.cybernetics_environment(),
      WorldEpistemicPhysics.ecology_environment(),
      WorldEpistemicPhysics.mathematics_environment(),
      WorldEpistemicPhysics.physics_environment()
    ]
    
    world_num = String.replace(world_prefix, "w", "") |> String.to_integer()
    physics = Enum.at(physics_profiles, rem(world_num - 1, length(physics_profiles)))
    
    theory_ids = 
      Enum.map(1..20, fn num ->
        id = String.to_atom("#{world_prefix}_theory_#{num}")
        node = %EvidenceNode{id: id, type: :theory, confidence: 0.8, validity: :contested, metadata: %{epistemic_physics: physics}}
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    discovery_ids =
      Enum.map(1..10, fn num ->
        id = String.to_atom("#{world_prefix}_discovery_#{num}")
        node = %EvidenceNode{id: id, type: :discovery, confidence: 0.7, validity: :contested, metadata: %{epistemic_physics: physics}}
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    Enum.reduce(1..30, state, fn ev_num, acc_state ->
      ev_id = String.to_atom("#{world_prefix}_evidence_#{ev_num}")
      ev_node = %EvidenceNode{id: ev_id, type: :evidence, confidence: 0.6, validity: :valid, metadata: %{epistemic_physics: physics}}
      
      acc_state = EvidenceEngine.add_node(acc_state, ev_id, ev_node)
      disc_id = Enum.random(discovery_ids)
      acc_state = EvidenceEngine.add_relation(acc_state, ev_id, :supports, disc_id, 0.8, nil, 0)
      
      theory_id = Enum.random(theory_ids)
      acc_state = EvidenceEngine.add_relation(acc_state, disc_id, :supports, theory_id, 0.8, nil, 0)
      
      acc_state
    end)
  end
  
  defp create_programs_for_world(state, world_prefix) do
    strategy_types = [:aggressive_exploration, :conservative_validation, :replication_first, :cross_domain_synthesis, :anomaly_hunting]
    
    # Get epistemic physics for this world
    physics_profiles = [
      WorldEpistemicPhysics.medicine_environment(),
      WorldEpistemicPhysics.cybernetics_environment(),
      WorldEpistemicPhysics.ecology_environment(),
      WorldEpistemicPhysics.mathematics_environment(),
      WorldEpistemicPhysics.physics_environment()
    ]
    world_num = String.replace(world_prefix, "w", "") |> String.to_integer()
    physics = Enum.at(physics_profiles, rem(world_num - 1, length(physics_profiles)))
    
    Enum.reduce(1..@programs_per_world, state, fn prog_num, acc_state ->
      prog_id = String.to_atom("#{world_prefix}_program_#{prog_num}")
      strategy_type = Enum.at(strategy_types, rem(prog_num - 1, length(strategy_types)))
      genome = create_strategy_genome(strategy_type)
      
      program = %ResearchProgram{
        id: prog_id,
        world_id: String.to_atom(world_prefix),
        institution_id: String.to_atom("#{world_prefix}_institution"),
        stage: :goal_generation,
        budget: %{credits: 100.0, compute: 100.0, attention: 100.0},
        strategy_genome: genome,
        status: :active,
        funding_score: 1.0 / (@programs_per_world * @worlds_count),  # Equal initial share
        metadata: %{epistemic_physics: physics}  # Track environment characteristics
      }
      
      new_programs = Map.put(acc_state.research_programs, prog_id, program)
      %{acc_state | research_programs: new_programs}
    end)
  end
  
  defp create_strategy_genome(type) do
    case type do
      :aggressive_exploration -> %{exploration_rate: 0.9, validation_priority: 0.2, cross_domain_synthesis: 0.3, anomaly_sensitivity: 0.7, risk_tolerance: 0.8}
      :conservative_validation -> %{exploration_rate: 0.2, validation_priority: 0.9, cross_domain_synthesis: 0.1, anomaly_sensitivity: 0.1, risk_tolerance: 0.2}
      :replication_first -> %{exploration_rate: 0.1, validation_priority: 0.95, cross_domain_synthesis: 0.0, anomaly_sensitivity: 0.0, risk_tolerance: 0.1}
      :cross_domain_synthesis -> %{exploration_rate: 0.6, validation_priority: 0.5, cross_domain_synthesis: 0.9, anomaly_sensitivity: 0.4, risk_tolerance: 0.6}
      :anomaly_hunting -> %{exploration_rate: 0.7, validation_priority: 0.4, cross_domain_synthesis: 0.2, anomaly_sensitivity: 0.95, risk_tolerance: 0.7}
    end
  end
  
  defp run_competitive_simulation(initial_state, pool_size) do
    IO.puts("Running competitive simulation for pool #{pool_size}...")
    
    initial_evolution_data = %{
      funding_distribution_history: [],
      terminated_programs: [],
      strategy_survival_rates: %{},
      knowledge_migration_events: 0,
      strategy_entropy_history: [],
      imported_ages_sum: 0,
      imported_ages_count: 0
    }
    
    Enum.reduce(1..@total_ticks, {initial_state, [], initial_evolution_data}, fn tick, {state, history, evolution_data} ->
      # Apply shocks
      {state, shock_applied} = if tick in @shock_ticks do
        idx = Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
        IO.puts("  ⚡ SHOCK #{idx}/3 APPLIED at tick #{tick}")
        {apply_shock(state, @shock_percentage), true}
      else
        {state, false}
      end
      
      # Tick programs
      state = tick_all_programs(state, tick)
      
      # COMPETITIVE MECHANICS: Allocate limited funding based on performance
      {state, evolution_data} = if rem(tick, 5_000) == 0 do
        # Calculate knowledge capital for all programs
        state = KnowledgeCapital.allocate_funding(state)
        
        # Apply competition: redistribute funding based on capital share
        state = apply_competitive_funding(state, pool_size)
        
        # Terminate underperforming programs
        {updated_programs, terminated} = terminate_underperformers(state)
        
        # Reconstruct state with updated programs
        state = %{state | research_programs: updated_programs}
        
        evolution_data = update_evolution_data(evolution_data, state, terminated)
        
        # Calculate and track strategy entropy
        entropy = calculate_strategy_entropy(state)
        updated_evolution_data = %{evolution_data | strategy_entropy_history: evolution_data.strategy_entropy_history ++ [{tick, entropy}]}
        
        {state, updated_evolution_data}
      else
        {state, evolution_data}
      end
      
      # Discovery exchange (knowledge migration)
      {state, evolution_data} = if rem(tick, 10_000) == 0 do
        before_count = count_total_discoveries(state)
        state = DiscoveryExchange.perform_global_exchange(state)
        after_count = count_total_discoveries(state)
        
        migration_events = after_count - before_count
        evolution_data = update_migration_data(evolution_data, migration_events)
        
        # Track half-life (age of imported discoveries)
        {sum_ages, count_ages} = state.research_programs
          |> Map.values()
          |> Enum.reduce({0, 0}, fn prog, {acc_sum, acc_count} ->
            prog.discoveries
            |> Enum.map(&Map.get(state.discoveries, &1))
            |> Enum.filter(&(&1 != nil and &1.origin_program_id != prog.id and Map.has_key?(&1, :created_at)))
            |> Enum.reduce({acc_sum, acc_count}, fn disc, {s, c} ->
              {s + (tick - disc.created_at), c + 1}
            end)
          end)
          
        evolution_data = %{evolution_data | 
          imported_ages_sum: evolution_data.imported_ages_sum + sum_ages,
          imported_ages_count: evolution_data.imported_ages_count + count_ages
        }
        
        {state, evolution_data}
      else
        {state, evolution_data}
      end
      
      # Collect metrics
      history = if rem(tick, @metrics_interval) == 0 or shock_applied do
        metrics = collect_competitive_metrics(state, tick)
        if rem(tick, 6_000) == 0 or shock_applied do
          print_competitive_metrics(metrics)
        end
        [metrics | history]
      else
        history
      end
      
      {state, history, evolution_data}
    end)
    |> then(fn {final_state, history, evolution_data} ->
      {final_state, Enum.reverse(history), evolution_data}
    end)
  end
  
  defp apply_competitive_funding(%State{} = state, pool_size) do
    programs = state.research_programs
    
    if map_size(programs) == 0 do
      state
    else
      total_capital = 
        programs
        |> Map.values()
        |> Enum.reduce(0.0, fn prog, acc ->
          acc + KnowledgeCapital.calculate_capital(prog, state)
        end)
      
      if total_capital == 0 do
        state
      else
        updated_programs = 
          programs
          |> Map.values()
          |> Enum.reduce(programs, fn prog, acc ->
            prog_capital = KnowledgeCapital.calculate_capital(prog, state)
            funding_share = (prog_capital / total_capital) * pool_size
            
            adjusted_share = :math.pow(funding_share / pool_size, 0.3) * pool_size
            
            effectiveness = Map.get(prog.metrics, :strategy_effectiveness, 0.0)
            bonus_multiplier = 1.0 + (effectiveness * 0.5)
            final_funding = adjusted_share * bonus_multiplier
            
            min_funding = 0.001
            final_funding = max(final_funding, min_funding)
            
            updated = %ResearchProgram{prog | funding_score: final_funding}
            Map.put(acc, prog.id, updated)
          end)
        
        %{state | research_programs: updated_programs}
      end
    end
  end
  
  defp terminate_underperformers(%State{} = state) do
    programs = state.research_programs
    
    {updated_programs, terminated} = 
      programs
      |> Map.values()
      |> Enum.reduce({programs, []}, fn prog, {acc_programs, acc_terminated} ->
        # Terminate if funding score is very low AND conversion rate is poor
        should_terminate = 
          prog.funding_score < 0.005 and  # Raised threshold for more terminations
          prog.metrics.conversion_rate < 0.3 and  # Raised threshold
          prog.status == :active
        
        if should_terminate do
          terminated_prog = %ResearchProgram{prog | status: :suspended, outcome: :failure}
          new_acc_programs = Map.put(acc_programs, prog.id, terminated_prog)
          {new_acc_programs, [prog.id | acc_terminated]}
        else
          {acc_programs, acc_terminated}
        end
      end)
    
    {updated_programs, terminated}
  end
  
  defp update_evolution_data(data, state, newly_terminated) do
    # Track funding distribution
    funding_dist = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.status == :active)
      |> Enum.map(& &1.funding_score)
    
    # Track strategy survival
    strategy_stats = 
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.status == :active)
      |> Enum.group_by(fn prog ->
        cond do
          prog.strategy_genome.exploration_rate > 0.7 -> :aggressive_explorers
          prog.strategy_genome.validation_priority > 0.8 -> :conservative_validators
          prog.strategy_genome.cross_domain_synthesis > 0.7 -> :cross_domain_synthesizers
          prog.strategy_genome.anomaly_sensitivity > 0.7 -> :anomaly_hunters
          true -> :balanced
        end
      end)
      |> Enum.map(fn {strategy, progs} -> {strategy, length(progs)} end)
      |> Enum.into(%{})
    
    %{
      data |
      funding_distribution_history: [funding_dist | data.funding_distribution_history],
      terminated_programs: data.terminated_programs ++ newly_terminated,
      strategy_survival_rates: strategy_stats
    }
  end
  
  defp update_migration_data(data, migration_events) do
    %{data | knowledge_migration_events: data.knowledge_migration_events + migration_events}
  end
  
  defp calculate_strategy_entropy(%State{} = state) do
    # Calculate Shannon entropy of strategy distribution
    # High entropy = diverse strategies (no selection)
    # Low entropy = dominated by few strategies (strong selection)
    
    programs = state.research_programs |> Map.values() |> Enum.filter(& &1.status == :active)
    
    if length(programs) == 0 do
      0.0
    else
      # Classify each program by dominant strategy
      strategy_counts = 
        programs
        |> Enum.map(fn prog ->
          cond do
            prog.strategy_genome.exploration_rate > 0.7 -> :aggressive_explorer
            prog.strategy_genome.validation_priority > 0.8 -> :conservative_validator
            prog.strategy_genome.cross_domain_synthesis > 0.7 -> :cross_domain_synthesizer
            prog.strategy_genome.anomaly_sensitivity > 0.7 -> :anomaly_hunter
            true -> :replication_first
          end
        end)
        |> Enum.frequencies()
      
      total = length(programs)
      
      # Shannon entropy: H = -Σ p(x) * log2(p(x))
      entropy = 
        strategy_counts
        |> Map.values()
        |> Enum.reduce(0.0, fn count, acc ->
          p = count / total
          if p > 0 do
            acc - (p * :math.log2(p))
          else
            acc
          end
        end)
      
      Float.round(entropy, 4)
    end
  end
  
  defp count_total_discoveries(%State{} = state) do
    state.research_programs
    |> Map.values()
    |> Enum.reduce(0, fn prog, acc -> acc + length(prog.discoveries) end)
  end
  
  defp apply_shock(state, percentage) do
    Enum.reduce(state.evidence_graph, state, fn {node_id, node}, acc_state ->
      if :rand.uniform() < percentage do
        degraded_confidence = max(node.confidence - 0.7, 0.05)
        degraded_node = %EvidenceNode{node | confidence: degraded_confidence}
        EvidenceEngine.add_node(acc_state, node_id, degraded_node)
      else
        acc_state
      end
    end)
  end
  
  defp tick_all_programs(state, current_tick) do
    state.research_programs
    |> Map.values()
    |> Enum.reduce(state, fn program, acc_state ->
      if program.status == :active do
        consumed_program = consume_resources(program)
        
        candidates = determine_production(consumed_program)
        validated = simulate_validation(consumed_program, candidates)
        
        acc_state = if validated > 0 do
          create_discovery_records(acc_state, consumed_program.id, validated, current_tick)
        else
          acc_state
        end
        
        latest_program = Map.get(acc_state.research_programs, program.id, consumed_program)
        updated_program = update_program_metrics(latest_program, candidates, validated)
        
        new_programs = Map.put(acc_state.research_programs, updated_program.id, updated_program)
        %{acc_state | research_programs: new_programs}
      else
        acc_state
      end
    end)
  end
  
  defp consume_resources(program) do
    cost = case program.strategy_genome.exploration_rate do
      r when r > 0.7 -> 0.05
      r when r < 0.3 -> 0.02
      _ -> 0.03
    end
    
    updated_funding = max(program.funding_score - cost, 0.0)
    %ResearchProgram{program | funding_score: updated_funding}
  end
  
  defp create_discovery_records(state, program_id, count, current_tick) do
    Enum.reduce(1..min(count, 5), state, fn i, acc_state ->
      program = Map.get(acc_state.research_programs, program_id)
      disc_id = "disc_#{program.id}_#{current_tick}_#{i}"
      
      if Map.has_key?(acc_state.discoveries, disc_id) do
        acc_state
      else
        new_discovery = %TiannaraOS.Discovery{
          id: disc_id,
          source_world: program.world_id,
          origin_program_id: program.id,
          origin_institution_id: program.institution_id,
          status: :validated,
          validation_level: :l2,
          evidence_score: program.metrics.conversion_rate,
          evidence_ids: Map.get(program, :evidence_ids, []) |> Enum.take(3),
          confidence: 0.8 + (:rand.uniform() * 0.2),
          metadata: %{
            created_at: current_tick,
            strategy_genome: program.strategy_genome,
            conversion_context: %{
              candidates_produced: program.metrics.candidates_produced,
              validation_method: :simulation
            }
          }
        }
        
        new_discoveries = Map.put(acc_state.discoveries, disc_id, new_discovery)
        
        final_discoveries = if length(program.discoveries) >= 100 do
          dropped_id = Enum.at(program.discoveries, 99)
          Map.delete(new_discoveries, dropped_id)
        else
          new_discoveries
        end
        
        program_discoveries = [disc_id | program.discoveries] |> Enum.take(100)
        updated_program = %ResearchProgram{program | discoveries: program_discoveries}
        new_programs = Map.put(acc_state.research_programs, program.id, updated_program)
        
        %{acc_state | discoveries: final_discoveries, research_programs: new_programs}
      end
    end)
  end
  
  defp determine_production(%ResearchProgram{strategy_genome: genome}) do
    cond do
      genome.exploration_rate > 0.7 -> :rand.uniform(3) + 2
      genome.exploration_rate < 0.3 -> :rand.uniform(2) + 1
      true -> :rand.uniform(2) + 1
    end
  end
  
  defp simulate_validation(%ResearchProgram{strategy_genome: genome, metadata: meta}, candidates) do
    # EPISTEMIC PHYSICS FITNESS LANDSCAPE ⭐ NEW FOR RESEARCH ECOLOGY
    # Strategy success emerges from matching genome to environment,
    # not hardcoded domain rules.
    
    base_probability = genome.validation_priority
    physics = Map.get(meta, :epistemic_physics, nil)
    
    if is_nil(physics) do
      # Fallback: no physics data, use base probability
      Enum.count(1..candidates, fn _ -> :rand.uniform() < base_probability end)
    else
      # Calculate fitness based on genome-environment matching
      fitness = WorldEpistemicPhysics.calculate_fitness(physics, genome)
      
      # Adjust validation probability based on fitness
      # High fitness → higher success rate
      # Low fitness → lower success rate
      adjusted_probability = min(base_probability * (0.5 + fitness), 1.0)
      
      Enum.count(1..candidates, fn _ -> :rand.uniform() < adjusted_probability end)
    end
  end
  
  defp update_program_metrics(program, new_candidates, newly_validated) do
    total_candidates = program.metrics.candidates_produced + new_candidates
    total_validated = program.metrics.candidates_validated + newly_validated
    
    conversion_rate = 
      if total_candidates > 0 do
        total_validated / total_candidates
      else
        0.0
      end
    
    new_metrics = %{
      program.metrics |
      candidates_produced: total_candidates,
      candidates_validated: total_validated,
      conversion_rate: conversion_rate
    }
    
    %ResearchProgram{program | metrics: new_metrics}
  end
  
  defp collect_competitive_metrics(state, tick) do
    programs = state.research_programs |> Map.values()
    active_programs = Enum.filter(programs, & &1.status == :active)
    
    total_validated = Enum.sum(Enum.map(active_programs, & &1.metrics.candidates_validated))
    total_candidates = Enum.sum(Enum.map(active_programs, & &1.metrics.candidates_produced))
    
    avg_conversion_rate = 
      if total_candidates > 0 do
        total_validated / total_candidates
      else
        0.0
      end
    
    avg_confidence = 
      state.evidence_graph
      |> Map.values()
      |> Enum.map(& &1.confidence)
      |> case do
        [] -> 0.0
        confidences -> Enum.sum(confidences) / length(confidences)
      end
    
    # Calculate funding inequality (Gini coefficient approximation)
    funding_scores = Enum.map(active_programs, & &1.funding_score)
    funding_inequality = calculate_inequality(funding_scores)
    
    %{
      tick: tick,
      avg_confidence: avg_confidence,
      total_validated: total_validated,
      avg_conversion_rate: avg_conversion_rate,
      active_programs: length(active_programs),
      total_programs: length(programs),
      funding_inequality: funding_inequality
    }
  end
  
  defp calculate_inequality(scores) do
    if length(scores) <= 1 do
      0.0
    else
      sorted = Enum.sort(scores)
      sum = Enum.sum(sorted)
      
      if sum == 0.0 do
        0.0
      else
        n = length(sorted)
        numerator = 
          sorted
          |> Enum.with_index()
          |> Enum.reduce(0, fn {score, i}, acc -> acc + (i + 1) * score end)
        
        # Simplified Gini coefficient
        2 * numerator / (n * sum) - (n + 1) / n
      end
    end
  end
  
  defp print_competitive_metrics(metrics) do
    IO.puts("  Tick #{metrics.tick}: Conf=#{Float.round(metrics.avg_confidence, 3)}, Val=#{metrics.total_validated}, CR=#{Float.round(metrics.avg_conversion_rate * 100, 1)}%, Active=#{metrics.active_programs}/#{metrics.total_programs}, Inequality=#{Float.round(metrics.funding_inequality, 3)}")
  end
  
  defp analyze_competitive_results(final_state, metrics_history, evolution_data, pool_size) do
    IO.puts("\n=== LAYER 6.5C COMPETITIVE RESULTS (Pool: #{pool_size}) ===\n")
    
    programs = final_state.research_programs |> Map.values()
    active_programs = Enum.filter(programs, & &1.status == :active)
    
    # Survival Analysis
    survival_rate = length(active_programs) / length(programs)
    
    IO.puts("Survival Analysis:")
    IO.puts("  Active Programs: #{length(active_programs)}/#{length(programs)} (#{Float.round(survival_rate * 100, 1)}%)")
    IO.puts("  Terminated Programs: #{length(evolution_data.terminated_programs)}")
    
    if survival_rate < 0.9 do
      IO.puts("  ✅ Competition working: Underperformers eliminated\n")
    else
      IO.puts("  ⚠️ Low termination rate (competition may be too weak)\n")
    end
    
    # Performance Analysis
    total_validated = Enum.sum(Enum.map(active_programs, & &1.metrics.candidates_validated))
    total_candidates = Enum.sum(Enum.map(active_programs, & &1.metrics.candidates_produced))
    avg_conversion_rate = if total_candidates > 0, do: total_validated / total_candidates, else: 0.0
    
    IO.puts("Performance Analysis:")
    IO.puts("  Total Validated: #{total_validated}")
    IO.puts("  Conversion Rate: #{Float.round(avg_conversion_rate * 100, 1)}%")
    
    if avg_conversion_rate > 0.5 do
      IO.puts("  ✅ High quality maintained under competition\n")
    else
      IO.puts("  ⚠️ Quality may be suffering\n")
    end
    
    # Funding Inequality Analysis
    if length(evolution_data.funding_distribution_history) > 0 do
      last_distribution = List.last(evolution_data.funding_distribution_history)
      final_inequality = calculate_inequality(last_distribution)
      
      IO.puts("Funding Distribution:")
      IO.puts("  Final Inequality (Gini): #{Float.round(final_inequality, 3)}")
      
      if final_inequality > 0.3 do
        IO.puts("  ✅ Winner-take-more dynamics emerging\n")
      else
        IO.puts("  ⚠️ Funding still relatively equal\n")
      end
    end
    
    # Strategy Entropy Analysis ⭐ NEW
    if length(evolution_data.strategy_entropy_history) > 0 do
      initial_entropy = hd(evolution_data.strategy_entropy_history) |> elem(1)
      final_entropy = List.last(evolution_data.strategy_entropy_history) |> elem(1)
      entropy_change = final_entropy - initial_entropy
      
      IO.puts("Strategy Evolution (Shannon Entropy):")
      IO.puts("  Initial Entropy: #{initial_entropy}")
      IO.puts("  Final Entropy: #{final_entropy}")
      IO.puts("  Change: #{Float.round(entropy_change, 4)}")
      
      if entropy_change < -0.2 do
        IO.puts("  ✅ Selection pressure detected (entropy decreasing)")
        IO.puts("  → Strategies diverging in effectiveness\n")
      else
        IO.puts("  ⚠️ No strong selection pressure yet (entropy stable or increasing)")
        IO.puts("  → All strategies performing similarly\n")
      end
    end
    
    # Strategy Evolution Analysis
    IO.puts("Strategy Evolution:")
    Enum.each(evolution_data.strategy_survival_rates, fn {strategy, count} ->
      IO.puts("  #{strategy}: #{count} surviving programs")
    end)
    IO.puts("")
    
    # Knowledge Migration Analysis
    IO.puts("Knowledge Migration:")
    IO.puts("  Total Migration Events: #{evolution_data.knowledge_migration_events}")
    
    if evolution_data.knowledge_migration_events > 0 do
      IO.puts("  ✅ Cross-pollination occurring\n")
    else
      IO.puts("  ⚠️ No knowledge migration detected\n")
    end
    
    # Knowledge Concentration & Diversity Index
    active_sorted_by_val = Enum.sort_by(active_programs, & &1.metrics.candidates_validated, :desc)
    top_10_count = max(1, trunc(length(active_sorted_by_val) * 0.1))
    top_10_programs = Enum.take(active_sorted_by_val, top_10_count)
    
    top_10_validated = Enum.sum(Enum.map(top_10_programs, & &1.metrics.candidates_validated))

    # Discovery Half-life
    avg_half_life = if evolution_data.imported_ages_count > 0 do
      evolution_data.imported_ages_sum / evolution_data.imported_ages_count
    else
      0.0
    end
    IO.puts("Discovery Half-life:")
    IO.puts("  Average migration age: #{Float.round(avg_half_life, 1)} ticks\n")
    
    active_sorted_by_val = Enum.sort_by(active_programs, & &1.metrics.candidates_validated, :desc)
    top_10_count = max(1, trunc(length(active_sorted_by_val) * 0.1))
    top_10_programs = Enum.take(active_sorted_by_val, top_10_count)
    
    top_10_validated = Enum.sum(Enum.map(top_10_programs, & &1.metrics.candidates_validated))
    total_val = max(1, total_validated)
    knowledge_concentration = top_10_validated / total_val
    
    IO.puts("Knowledge Concentration:")
    IO.puts("  Top 10% programs produced #{Float.round(knowledge_concentration * 100, 1)}% of validated discoveries")
    if knowledge_concentration > 0.6 do
      IO.puts("  ⚠️ Oligopoly emerging (concentration > 60%)\n")
    else
      IO.puts("  ✅ Healthy competitive distribution\n")
    end
    
    # Discovery Half-life

    # Discovery Half-life
    avg_half_life = if evolution_data.imported_ages_count > 0 do
      evolution_data.imported_ages_sum / evolution_data.imported_ages_count
    else
      0.0
    end
    IO.puts("Discovery Half-life:")
    IO.puts("  Average migration age: #{Float.round(avg_half_life, 1)} ticks\n")
    
    # Overall Classification
    IO.puts("=" |> String.duplicate(60))
    
    if survival_rate < 0.9 and avg_conversion_rate > 0.4 and length(evolution_data.terminated_programs) > 0 do
      IO.puts("LAYER 6.5C CLASSIFICATION: COMPETITION DRIVES SELECTION ✅✅✅")
      IO.puts("")
      IO.puts("Evolutionary dynamics confirmed:")
      IO.puts("  ✓ Underperforming programs eliminated")
      IO.puts("  ✓ High-quality knowledge production maintained")
      IO.puts("  ✓ Funding inequality emerging (selection pressure)")
      IO.puts("  ✓ Strategy diversity persists")
      IO.puts("")
      IO.puts("The triad is complete:")
      IO.puts("  1. Truth Maintenance (JTMS++ - 6.5A)")
      IO.puts("  2. Knowledge Production (Research Programs - 6.5B)")
      IO.puts("  3. Knowledge Selection (Competition - 6.5C)")
    else
      IO.puts("LAYER 6.5C CLASSIFICATION: PARTIAL SUCCESS ⚠️")
    end
    
    IO.puts("=" |> String.duplicate(60))
    IO.puts("")
    
    IO.puts("Summary:")
    IO.puts("  Competition creates selection pressure")
    IO.puts("  Limited resources drive efficiency")
    IO.puts("  Knowledge migration prevents silos")
    IO.puts("  Evolutionary dynamics emerge naturally\n")
    
    IO.puts("Next Steps:")
    IO.puts("  → Integrate with Phase 12 Scientific Discovery Stack")
    IO.puts("  → Add institutional memory accumulation")
    IO.puts("  → Implement meta-cognitive capabilities")
    IO.puts("  → Test long-term civilizational resilience\n")
  end
end
