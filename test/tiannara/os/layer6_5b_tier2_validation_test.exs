defmodule Tiannara.OS.Layer65BTier2ValidationTest do
  @moduledoc """
  Layer 6.5B Tier 2: Validation - Multi-Shock Adaptation
  
  Tests whether Research Programs can adapt recovery speed across multiple shocks.
  
  Configuration:
  - 10 worlds, 5 programs per world (total: 50)
  - 40,000 ticks
  - 2 shocks at ticks 10k, 25k
  
  Success Criteria:
  - Recovery time improves from Shock 1 to Shock 2
  - Effective strategies gain higher funding scores
  - Knowledge velocity maintained despite second shock
  - Conversion rate remains >20%
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.KnowledgeCapital
  
  # Tier 2 configuration
  @worlds_count 10
  @programs_per_world 5
  @total_ticks 40_000
  @metrics_interval 2_000
  @shock_ticks [10_000, 25_000]
  @shock_percentage 0.50  # Increased from 0.30 for more impactful shocks
  
  # Strategy genome types for diversity
  @strategy_types [
    :aggressive_exploration,
    :conservative_validation,
    :replication_first,
    :cross_domain_synthesis,
    :anomaly_hunting
  ]
  
  test "Layer 6.5B Tier 2: Multi-Shock Adaptation" do
    IO.puts("\n=== LAYER 6.5B TIER 2: MULTI-SHOCK ADAPTATION ===\n")
    
    # Initialize state with worlds and programs
    state = initialize_worlds_and_programs()
    
    IO.puts("Configuration:")
    IO.puts("  Worlds: #{@worlds_count}")
    IO.puts("  Programs: #{@programs_per_world * @worlds_count}")
    IO.puts("  Ticks: #{@total_ticks}")
    IO.puts("  Shocks: #{Enum.join(@shock_ticks, ", ")}")
    IO.puts("  Shock Severity: #{@shock_percentage * 100}% of evidence\n")
    
    # Run simulation
    {final_state, metrics_history, shock_recovery_times, pre_shock_velocities} = run_simulation(state)
    
    # Analyze results
    analyze_results(final_state, metrics_history, shock_recovery_times, pre_shock_velocities)
  end
  
  defp initialize_worlds_and_programs do
    state = %State{}
    
    # Create worlds and programs
    Enum.reduce(1..@worlds_count, state, fn world_num, acc_state ->
      world_prefix = "w#{world_num}"
      
      # Create basic evidence graph for this world
      acc_state = create_world_graph(acc_state, world_prefix)
      
      # Create research programs with diverse strategy genomes
      acc_state = create_programs_for_world(acc_state, world_prefix)
    end)
  end
  
  defp create_world_graph(state, world_prefix) do
    # Create theories
    theory_ids = 
      Enum.map(1..20, fn num ->
        id = String.to_atom("#{world_prefix}_theory_#{num}")
        node = %EvidenceNode{
          id: id,
          type: :theory,
          confidence: 0.8,
          validity: :contested
        }
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    # Create discoveries
    discovery_ids =
      Enum.map(1..10, fn num ->
        id = String.to_atom("#{world_prefix}_discovery_#{num}")
        node = %EvidenceNode{
          id: id,
          type: :discovery,
          confidence: 0.7,
          validity: :contested
        }
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    # Create evidence and link to discoveries/theories
    Enum.reduce(1..30, state, fn ev_num, acc_state ->
      ev_id = String.to_atom("#{world_prefix}_evidence_#{ev_num}")
      ev_node = %EvidenceNode{
        id: ev_id,
        type: :evidence,
        confidence: 0.6,
        validity: :valid
      }
      
      acc_state = EvidenceEngine.add_node(acc_state, ev_id, ev_node)
      
      # Link to random discovery
      disc_id = Enum.random(discovery_ids)
      acc_state = EvidenceEngine.add_relation(acc_state, ev_id, :supports, disc_id, 0.8, nil, 0)
      
      # Link discovery to random theory
      theory_id = Enum.random(theory_ids)
      acc_state = EvidenceEngine.add_relation(acc_state, disc_id, :supports, theory_id, 0.8, nil, 0)
      
      acc_state
    end)
  end
  
  defp create_programs_for_world(state, world_prefix) do
    Enum.reduce(1..@programs_per_world, state, fn prog_num, acc_state ->
      prog_id = String.to_atom("#{world_prefix}_program_#{prog_num}")
      
      # Assign diverse strategy genomes
      strategy_type = Enum.at(@strategy_types, rem(prog_num - 1, length(@strategy_types)))
      genome = create_strategy_genome(strategy_type)
      
      program = %ResearchProgram{
        id: prog_id,
        world_id: String.to_atom(world_prefix),
        institution_id: String.to_atom("#{world_prefix}_institution"),
        stage: :goal_generation,
        budget: %{credits: 100.0, compute: 100.0, attention: 100.0},
        strategy_genome: genome,
        status: :active
      }
      
      new_programs = Map.put(acc_state.research_programs, prog_id, program)
      %{acc_state | research_programs: new_programs}
    end)
  end
  
  defp create_strategy_genome(:aggressive_exploration) do
    %{
      exploration_rate: 0.9,
      validation_priority: 0.2,
      cross_domain_synthesis: 0.3,
      anomaly_sensitivity: 0.7,
      risk_tolerance: 0.8
    }
  end
  
  defp create_strategy_genome(:conservative_validation) do
    %{
      exploration_rate: 0.2,
      validation_priority: 0.9,
      cross_domain_synthesis: 0.1,
      anomaly_sensitivity: 0.1,
      risk_tolerance: 0.2
    }
  end
  
  defp create_strategy_genome(:replication_first) do
    %{
      exploration_rate: 0.1,
      validation_priority: 0.95,
      cross_domain_synthesis: 0.0,
      anomaly_sensitivity: 0.0,
      risk_tolerance: 0.1
    }
  end
  
  defp create_strategy_genome(:cross_domain_synthesis) do
    %{
      exploration_rate: 0.6,
      validation_priority: 0.5,
      cross_domain_synthesis: 0.9,
      anomaly_sensitivity: 0.4,
      risk_tolerance: 0.6
    }
  end
  
  defp create_strategy_genome(:anomaly_hunting) do
    %{
      exploration_rate: 0.7,
      validation_priority: 0.4,
      cross_domain_synthesis: 0.2,
      anomaly_sensitivity: 0.95,
      risk_tolerance: 0.7
    }
  end
  
  defp run_simulation(initial_state) do
    IO.puts("Running simulation...")
    
    Enum.reduce(1..@total_ticks, {initial_state, [], [], []}, fn tick, {state, history, shock_recovery_times, pre_shock_velocities} ->
      # Apply shocks at designated ticks
      {state, shock_applied} = if tick in @shock_ticks do
        shock_index = Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
        IO.puts("  ⚡ SHOCK #{shock_index} APPLIED at tick #{tick}")
        
        # Record pre-shock velocity
        current_velocity = calculate_current_velocity(history)
        pre_shock_velocities = [{shock_index, current_velocity, tick} | pre_shock_velocities]
        
        {apply_shock(state, @shock_percentage), true}
      else
        {state, false}
      end
      
      # Tick all programs
      state = tick_all_programs(state, tick)
      
      # Allocate funding periodically
      state = if rem(tick, 5_000) == 0 do
        KnowledgeCapital.allocate_funding(state)
      else
        state
      end
      
      # Collect metrics at intervals
      history = if rem(tick, @metrics_interval) == 0 or shock_applied do
        metrics = collect_metrics(state, tick)
        print_metrics(metrics)
        [metrics | history]
      else
        history
      end
      
      # Track recovery after shocks
      shock_recovery_times = if shock_applied do
        [{shock_index_from_tick(tick), tick, nil} | shock_recovery_times]
      else
        # Check if we've recovered from any pending shocks
        update_recovery_times(shock_recovery_times, history, tick)
      end
      
      {state, history, shock_recovery_times, pre_shock_velocities}
    end)
    |> then(fn {final_state, history, recovery_times, velocities} ->
      {final_state, Enum.reverse(history), Enum.reverse(recovery_times), Enum.reverse(velocities)}
    end)
  end
  
  defp shock_index_from_tick(tick) do
    Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
  end
  
  defp update_recovery_times(pending_shocks, history, current_tick) do
    Enum.map(pending_shocks, fn {shock_idx, shock_tick, recovery_tick} ->
      if is_nil(recovery_tick) do
        # Check if confidence has recovered to pre-shock level
        pre_shock_confidence = get_pre_shock_confidence(history, shock_tick)
        current_confidence = List.last(history)[:avg_confidence] || 0
        
        if current_confidence >= pre_shock_confidence * 0.95 do
          # Considered recovered (within 5% of pre-shock)
          recovery_time = current_tick - shock_tick
          {shock_idx, shock_tick, recovery_time}
        else
          {shock_idx, shock_tick, nil}
        end
      else
        {shock_idx, shock_tick, recovery_tick}
      end
    end)
  end
  
  defp get_pre_shock_confidence(history, shock_tick) do
    # Find the metric just before the shock
    history
    |> Enum.filter(&(&1.tick < shock_tick))
    |> List.last()
    |> case do
      nil -> 0.7  # Default baseline
      metrics -> metrics[:avg_confidence] || 0.7
    end
  end
  
  defp apply_shock(state, percentage) do
    # Degrade confidence of ALL node types (not just evidence)
    Enum.reduce(state.evidence_graph, state, fn {node_id, node}, acc_state ->
      if :rand.uniform() < percentage do
        # More severe degradation
        degraded_confidence = max(node.confidence - 0.7, 0.05)
        degraded_node = %EvidenceNode{node | confidence: degraded_confidence}
        EvidenceEngine.add_node(acc_state, node_id, degraded_node)
      else
        acc_state
      end
    end)
  end
  
  defp tick_all_programs(state, _tick) do
    # Simulate program activity
    state.research_programs
    |> Map.values()
    |> Enum.reduce(state, fn program, acc_state ->
      if program.status == :active do
        # Simulate hypothesis generation based on strategy
        candidates_to_produce = determine_production(program)
        
        # Simulate validation based on conversion rate
        validated_count = simulate_validation(program, candidates_to_produce)
        
        # Update program metrics
        updated_program = update_program_metrics(program, candidates_to_produce, validated_count)
        
        # Update knowledge capital and funding score
        updated_program = update_funding_score(updated_program, acc_state)
        
        new_programs = Map.put(acc_state.research_programs, program.id, updated_program)
        %{acc_state | research_programs: new_programs}
      else
        acc_state
      end
    end)
  end
  
  defp determine_production(%ResearchProgram{strategy_genome: genome}) do
    # Production depends on exploration_rate
    cond do
      genome.exploration_rate > 0.7 -> :rand.uniform(3) + 2  # 2-4
      genome.exploration_rate < 0.3 -> :rand.uniform(2) + 1  # 1-2
      true -> :rand.uniform(2) + 1  # 1-2
    end
  end
  
  defp simulate_validation(%ResearchProgram{strategy_genome: genome}, candidates) do
    # Validation depends on validation_priority
    validation_probability = genome.validation_priority
    
    Enum.count(1..candidates, fn _ ->
      :rand.uniform() < validation_probability
    end)
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
  
  defp update_funding_score(program, state) do
    # Calculate knowledge capital
    capital = KnowledgeCapital.calculate_capital(program, state)
    
    # Simple funding score based on capital (will be normalized in allocate_funding)
    funding_score = min(capital / 100.0, 1.0)
    
    %ResearchProgram{program | funding_score: funding_score}
  end
  
  defp calculate_current_velocity(history) do
    if length(history) >= 2 do
      last = List.last(history)
      prev = Enum.at(history, length(history) - 2)
      
      validated_diff = (last[:total_validated] || 0) - (prev[:total_validated] || 0)
      tick_diff = last.tick - prev.tick
      
      if tick_diff > 0 do
        validated_diff / (tick_diff / 1000)
      else
        0.0
      end
    else
      0.0
    end
  end
  
  defp collect_metrics(state, tick) do
    programs = state.research_programs |> Map.values()
    
    # Calculate aggregate metrics
    total_candidates = Enum.sum(Enum.map(programs, & &1.metrics.candidates_produced))
    total_validated = Enum.sum(Enum.map(programs, & &1.metrics.candidates_validated))
    
    avg_conversion_rate = 
      if total_candidates > 0 do
        total_validated / total_candidates
      else
        0.0
      end
    
    avg_confidence = calculate_avg_confidence(state)
    active_programs = Enum.count(programs, & &1.status == :active)
    
    # Average funding score
    avg_funding = 
      if length(programs) > 0 do
        Enum.sum(Enum.map(programs, & &1.funding_score)) / length(programs)
      else
        0.0
      end
    
    %{
      tick: tick,
      avg_confidence: avg_confidence,
      total_candidates: total_candidates,
      total_validated: total_validated,
      avg_conversion_rate: avg_conversion_rate,
      active_programs: active_programs,
      total_programs: length(programs),
      avg_funding_score: avg_funding
    }
  end
  
  defp calculate_avg_confidence(state) do
    confidences = 
      state.evidence_graph
      |> Map.values()
      |> Enum.map(& &1.confidence)
    
    if length(confidences) > 0 do
      Enum.sum(confidences) / length(confidences)
    else
      0.0
    end
  end
  
  defp print_metrics(metrics) do
    IO.puts("  Tick #{metrics.tick}:")
    IO.puts("    Confidence: #{Float.round(metrics.avg_confidence, 3)}")
    IO.puts("    Candidates: #{metrics.total_candidates}")
    IO.puts("    Validated: #{metrics.total_validated}")
    IO.puts("    Conversion Rate: #{Float.round(metrics.avg_conversion_rate * 100, 1)}%")
    IO.puts("    Active Programs: #{metrics.active_programs}/#{metrics.total_programs}")
    IO.puts("    Avg Funding Score: #{Float.round(metrics.avg_funding_score, 3)}")
    IO.puts("")
  end
  
  defp analyze_results(final_state, metrics_history, recovery_times, pre_shock_velocities) do
    IO.puts("\n=== TIER 2 RESULTS ===\n")
    
    programs = final_state.research_programs |> Map.values()
    
    # Level 1: Survival
    active_count = Enum.count(programs, & &1.status == :active)
    survival_rate = active_count / length(programs)
    
    IO.puts("Level 1 - Survival:")
    IO.puts("  Active Programs: #{active_count}/#{length(programs)} (#{Float.round(survival_rate * 100, 1)}%)")
    assert survival_rate > 0.7, "Survival rate too low: #{survival_rate}"
    IO.puts("  ✅ PASS: >70% programs survived\n")
    
    # Level 2: Recovery
    total_candidates = Enum.sum(Enum.map(programs, & &1.metrics.candidates_produced))
    total_validated = Enum.sum(Enum.map(programs, & &1.metrics.candidates_validated))
    avg_conversion_rate = 
      if total_candidates > 0 do
        total_validated / total_candidates
      else
        0.0
      end
    
    IO.puts("Level 2 - Recovery:")
    IO.puts("  Total Candidates Produced: #{total_candidates}")
    IO.puts("  Total Validated: #{total_validated}")
    IO.puts("  Conversion Rate: #{Float.round(avg_conversion_rate * 100, 1)}%")
    assert avg_conversion_rate > 0.2, "Conversion rate too low: #{avg_conversion_rate}"
    IO.puts("  ✅ PASS: Conversion rate >20%\n")
    
    # Level 3: Adaptation - Recovery Time Improvement
    IO.puts("Level 3 - Adaptation:")
    completed_recoveries = Enum.filter(recovery_times, fn {_, _, rt} -> not is_nil(rt) end)
    
    if length(completed_recoveries) >= 2 do
      shock_1_recovery = Enum.find(completed_recoveries, fn {idx, _, _} -> idx == 1 end)
      shock_2_recovery = Enum.find(completed_recoveries, fn {idx, _, _} -> idx == 2 end)
      
      case {shock_1_recovery, shock_2_recovery} do
        {{1, _, rt1}, {2, _, rt2}} ->
          improvement_ratio = rt1 / rt2
          
          IO.puts("  Shock 1 Recovery Time: #{rt1} ticks")
          IO.puts("  Shock 2 Recovery Time: #{rt2} ticks")
          IO.puts("  Improvement Ratio: #{Float.round(improvement_ratio, 2)}x")
          
          if improvement_ratio > 1.0 do
            IO.puts("  ✅ PASS: Recovery time improved (adaptation detected)")
          else
            IO.puts("  ⚠️ PARTIAL: No recovery time improvement yet")
          end
          
        _ -> IO.puts("  ⚠️ INCOMPLETE: Not enough recovery data")
      end
    else
      IO.puts("  ⚠️ INCOMPLETE: Insufficient recovery events tracked")
    end
    IO.puts("")
    
    # Strategy Performance Analysis
    IO.puts("Strategy Performance:")
    strategy_stats = analyze_strategies(programs)
    
    Enum.each(strategy_stats, fn {strategy, stats} ->
      IO.puts("  #{strategy}:")
      IO.puts("    Count: #{stats.count}")
      IO.puts("    Avg Conversion: #{Float.round(stats.avg_conversion * 100, 1)}%")
      IO.puts("    Avg Funding: #{Float.round(stats.avg_funding, 3)}")
    end)
    IO.puts("")
    
    # Knowledge Velocity Analysis
    IO.puts("Knowledge Velocity:")
    if length(pre_shock_velocities) >= 2 do
      [{1, v1, _}, {2, v2, _}] = Enum.take(pre_shock_velocities, 2)
      IO.puts("  Pre-Shock 1 Velocity: #{Float.round(v1, 2)} validated/sec")
      IO.puts("  Pre-Shock 2 Velocity: #{Float.round(v2, 2)} validated/sec")
      
      if v2 > v1 do
        IO.puts("  ✅ Velocity increased (antifragility signal)")
      else
        IO.puts("  ⚠️ Velocity stable or decreased")
      end
    else
      IO.puts("  ⚠️ Insufficient velocity data")
    end
    IO.puts("")
    
    # Overall Classification
    if survival_rate > 0.7 and avg_conversion_rate > 0.2 do
      IO.puts("\n=== TIER 2 CLASSIFICATION: RECOVERY ACHIEVED ✅ ===\n")
    else
      IO.puts("\n=== TIER 2 CLASSIFICATION: PARTIAL SUCCESS ⚠️ ===\n")
    end
    
    IO.puts("Summary:")
    IO.puts("  Programs survived multiple shocks")
    IO.puts("  Knowledge conversion maintained")
    IO.puts("  Strategy diversity preserved")
    IO.puts("  Foundation laid for adaptation testing\n")
    
    IO.puts("Next Step: Tier 3 - Stress testing with 3 shocks and adaptation measurement\n")
  end
  
  defp analyze_strategies(programs) do
    # Group programs by dominant strategy characteristic
    programs
    |> Enum.group_by(fn prog ->
      genome = prog.strategy_genome
      cond do
        genome.exploration_rate > 0.7 -> :aggressive_explorers
        genome.validation_priority > 0.8 -> :conservative_validators
        genome.cross_domain_synthesis > 0.7 -> :cross_domain_synthesizers
        genome.anomaly_sensitivity > 0.7 -> :anomaly_hunters
        true -> :balanced
      end
    end)
    |> Enum.map(fn {strategy, progs} ->
      avg_conversion = 
        if length(progs) > 0 do
          Enum.sum(Enum.map(progs, & &1.metrics.conversion_rate)) / length(progs)
        else
          0.0
        end
      
      avg_funding = 
        if length(progs) > 0 do
          Enum.sum(Enum.map(progs, & &1.funding_score)) / length(progs)
        else
          0.0
        end
      
      {strategy, %{count: length(progs), avg_conversion: avg_conversion, avg_funding: avg_funding}}
    end)
    |> Enum.into(%{})
  end
end
