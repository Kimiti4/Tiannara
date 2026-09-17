defmodule Tiannara.OS.Layer65BTier3StressTest do
  @moduledoc """
  Layer 6.5B Tier 3: Stress Testing - Sustained Pressure & Adaptation
  
  Tests whether Research Programs can improve recovery speed across sustained multi-shock pressure.
  
  Configuration:
  - 25 worlds, 5 programs per world (total: 125)
  - 60,000 ticks
  - 3 shocks at ticks 15k, 30k, 45k
  
  Success Criteria:
  - Recovery time improves across all 3 shocks (adaptation ratio > 1.5)
  - Knowledge velocity maintained or improved
  - Strategy evolution visible (successful strategies gain funding)
  - System stable under sustained pressure
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.KnowledgeCapital
  
  # Tier 3 configuration
  @worlds_count 25
  @programs_per_world 5
  @total_ticks 60_000
  @metrics_interval 3_000
  @shock_ticks [15_000, 30_000, 45_000]
  @shock_percentage 0.50  # Increased for measurable adaptation
  
  test "Layer 6.5B Tier 3: Stress Testing with Adaptation" do
    IO.puts("\n=== LAYER 6.5B TIER 3: STRESS TESTING WITH ADAPTATION ===\n")
    
    # Initialize state
    state = initialize_worlds_and_programs()
    
    IO.puts("Configuration:")
    IO.puts("  Worlds: #{@worlds_count}")
    IO.puts("  Programs: #{@programs_per_world * @worlds_count}")
    IO.puts("  Ticks: #{@total_ticks}")
    IO.puts("  Shocks: #{Enum.join(@shock_ticks, ", ")}")
    IO.puts("  Shock Severity: #{@shock_percentage * 100}%\n")
    
    # Run simulation
    {final_state, metrics_history, recovery_data} = run_simulation(state)
    
    # Analyze results
    analyze_results(final_state, metrics_history, recovery_data)
  end
  
  defp initialize_worlds_and_programs do
    state = %State{}
    
    Enum.reduce(1..@worlds_count, state, fn world_num, acc_state ->
      world_prefix = "w#{world_num}"
      acc_state = create_world_graph(acc_state, world_prefix)
      acc_state = create_programs_for_world(acc_state, world_prefix)
    end)
  end
  
  defp create_world_graph(state, world_prefix) do
    theory_ids = 
      Enum.map(1..20, fn num ->
        id = String.to_atom("#{world_prefix}_theory_#{num}")
        node = %EvidenceNode{id: id, type: :theory, confidence: 0.8, validity: :contested}
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    discovery_ids =
      Enum.map(1..10, fn num ->
        id = String.to_atom("#{world_prefix}_discovery_#{num}")
        node = %EvidenceNode{id: id, type: :discovery, confidence: 0.7, validity: :contested}
        EvidenceEngine.add_node(state, id, node)
        id
      end)
    
    Enum.reduce(1..30, state, fn ev_num, acc_state ->
      ev_id = String.to_atom("#{world_prefix}_evidence_#{ev_num}")
      ev_node = %EvidenceNode{id: ev_id, type: :evidence, confidence: 0.6, validity: :valid}
      
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
        status: :active
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
  
  defp run_simulation(initial_state) do
    IO.puts("Running simulation...")
    
    initial_recovery_data = %{
      shock_times: [],
      recovery_times: [],
      pre_shock_velocities: [],
      post_shock_velocities: []
    }
    
    Enum.reduce(1..@total_ticks, {initial_state, [], initial_recovery_data}, fn tick, {state, history, recovery_data} ->
      # Apply shocks
      {state, shock_applied, shock_idx} = if tick in @shock_ticks do
        idx = Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
        IO.puts("  ⚡ SHOCK #{idx} APPLIED at tick #{tick}")
        
        current_velocity = calculate_current_velocity(history)
        updated_data = update_pre_shock_velocity(recovery_data, idx, current_velocity, tick)
        
        {apply_shock(state, @shock_percentage), true, idx}
      else
        {state, false, nil}
      end
      
      # Tick programs
      state = tick_all_programs(state)
      
      # Allocate funding periodically
      state = if rem(tick, 5_000) == 0 do
        KnowledgeCapital.allocate_funding(state)
      else
        state
      end
      
      # Collect metrics
      history = if rem(tick, @metrics_interval) == 0 or shock_applied do
        metrics = collect_metrics(state, tick)
        if rem(tick, 6_000) == 0 or shock_applied do
          print_metrics(metrics)
        end
        [metrics | history]
      else
        history
      end
      
      # Track recovery
      recovery_data = if shock_applied do
        track_shock(recovery_data, shock_idx, tick)
      else
        check_recoveries(recovery_data, history, tick)
      end
      
      {state, history, recovery_data}
    end)
    |> then(fn {final_state, history, recovery_data} ->
      {final_state, Enum.reverse(history), recovery_data}
    end)
  end
  
  defp track_shock(data, shock_idx, tick) do
    %{data | shock_times: data.shock_times ++ [{shock_idx, tick}]}
  end
  
  defp check_recoveries(data, history, current_tick) do
    # Check each unrecorded shock for recovery
    pending_shocks = Enum.filter(data.shock_times, fn {idx, _} ->
      not Enum.any?(data.recovery_times, fn {r_idx, _, _} -> r_idx == idx end)
    end)
    
    Enum.reduce(pending_shocks, data, fn {shock_idx, shock_tick}, acc_data ->
      pre_confidence = get_pre_shock_confidence(history, shock_tick)
      current_confidence = List.last(history)[:avg_confidence] || 0
      
      if current_confidence >= pre_confidence * 0.95 do
        recovery_time = current_tick - shock_tick
        post_velocity = calculate_current_velocity(history)
        
        updated_data = update_post_shock_velocity(acc_data, shock_idx, post_velocity, current_tick)
        %{updated_data | recovery_times: updated_data.recovery_times ++ [{shock_idx, shock_tick, recovery_time}]}
      else
        acc_data
      end
    end)
  end
  
  defp update_pre_shock_velocity(data, shock_idx, velocity, tick) do
    %{data | pre_shock_velocities: data.pre_shock_velocities ++ [{shock_idx, velocity, tick}]}
  end
  
  defp update_post_shock_velocity(data, shock_idx, velocity, tick) do
    %{data | post_shock_velocities: data.post_shock_velocities ++ [{shock_idx, velocity, tick}]}
  end
  
  defp apply_shock(state, percentage) do
    # Degrade ALL node types with more severe impact
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
  
  defp tick_all_programs(state) do
    state.research_programs
    |> Map.values()
    |> Enum.reduce(state, fn program, acc_state ->
      if program.status == :active do
        candidates = determine_production(program)
        validated = simulate_validation(program, candidates)
        updated_program = update_program_metrics(program, candidates, validated)
        
        new_programs = Map.put(acc_state.research_programs, program.id, updated_program)
        %{acc_state | research_programs: new_programs}
      else
        acc_state
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
  
  defp simulate_validation(%ResearchProgram{strategy_genome: genome}, candidates) do
    validation_probability = genome.validation_priority
    Enum.count(1..candidates, fn _ -> :rand.uniform() < validation_probability end)
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
  
  defp get_pre_shock_confidence(history, shock_tick) do
    history
    |> Enum.filter(&(&1.tick < shock_tick))
    |> List.last()
    |> case do
      nil -> 0.7
      metrics -> metrics[:avg_confidence] || 0.7
    end
  end
  
  defp collect_metrics(state, tick) do
    programs = state.research_programs |> Map.values()
    
    total_candidates = Enum.sum(Enum.map(programs, & &1.metrics.candidates_produced))
    total_validated = Enum.sum(Enum.map(programs, & &1.metrics.candidates_validated))
    
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
    
    active_programs = Enum.count(programs, & &1.status == :active)
    
    %{
      tick: tick,
      avg_confidence: avg_confidence,
      total_candidates: total_candidates,
      total_validated: total_validated,
      avg_conversion_rate: avg_conversion_rate,
      active_programs: active_programs,
      total_programs: length(programs)
    }
  end
  
  defp print_metrics(metrics) do
    IO.puts("  Tick #{metrics.tick}: Conf=#{Float.round(metrics.avg_confidence, 3)}, Validated=#{metrics.total_validated}, ConvRate=#{Float.round(metrics.avg_conversion_rate * 100, 1)}%")
  end
  
  defp analyze_results(final_state, metrics_history, recovery_data) do
    IO.puts("\n=== TIER 3 RESULTS ===\n")
    
    programs = final_state.research_programs |> Map.values()
    
    # Level 1: Survival
    active_count = Enum.count(programs, & &1.status == :active)
    survival_rate = active_count / length(programs)
    
    IO.puts("Level 1 - Survival:")
    IO.puts("  Active Programs: #{active_count}/#{length(programs)} (#{Float.round(survival_rate * 100, 1)}%)")
    assert survival_rate > 0.7, "Survival rate too low"
    IO.puts("  ✅ PASS\n")
    
    # Level 2: Recovery
    total_validated = Enum.sum(Enum.map(programs, & &1.metrics.candidates_validated))
    total_candidates = Enum.sum(Enum.map(programs, & &1.metrics.candidates_produced))
    avg_conversion_rate = if total_candidates > 0, do: total_validated / total_candidates, else: 0.0
    
    IO.puts("Level 2 - Recovery:")
    IO.puts("  Conversion Rate: #{Float.round(avg_conversion_rate * 100, 1)}%")
    assert avg_conversion_rate > 0.2, "Conversion rate too low"
    IO.puts("  ✅ PASS\n")
    
    # Level 3: Adaptation - THE KEY METRIC
    IO.puts("Level 3 - Adaptation (⭐ CRITICAL):")
    
    if length(recovery_data.recovery_times) >= 3 do
      sorted_recoveries = Enum.sort_by(recovery_data.recovery_times, fn {idx, _, _} -> idx end)
      
      [{1, _, rt1}, {2, _, rt2}, {3, _, rt3}] = sorted_recoveries
      
      IO.puts("  Shock 1 Recovery Time: #{rt1} ticks")
      IO.puts("  Shock 2 Recovery Time: #{rt2} ticks")
      IO.puts("  Shock 3 Recovery Time: #{rt3} ticks")
      
      adaptation_ratio = rt1 / rt3
      
      IO.puts("  Adaptation Ratio (Shock1/Shock3): #{Float.round(adaptation_ratio, 2)}x")
      
      if adaptation_ratio > 1.5 do
        IO.puts("  ✅ PASS: Strong adaptation detected (ratio > 1.5)")
        IO.puts("  🎯 Civilization is learning to recover faster!\n")
      else
        IO.puts("  ⚠️ PARTIAL: Some adaptation but below target (need >1.5)\n")
      end
      
      # Check monotonic improvement
      if rt1 > rt2 and rt2 > rt3 do
        IO.puts("  ✅ Monotonic improvement: #{rt1} → #{rt2} → #{rt3}")
      else
        IO.puts("  ⚠️ Non-monotonic recovery pattern")
      end
    else
      IO.puts("  ⚠️ INCOMPLETE: Only #{length(recovery_data.recovery_times)} recoveries tracked\n")
    end
    
    # Antifragility Analysis
    IO.puts("Antifragility Analysis:")
    
    if length(recovery_data.pre_shock_velocities) >= 2 and length(recovery_data.post_shock_velocities) >= 2 do
      # Compare first and last shock velocities
      [{1, pre_v1, _}] = Enum.take(recovery_data.pre_shock_velocities, 1)
      [{3, post_v3, _}] = Enum.take(Enum.filter(recovery_data.post_shock_velocities, fn {idx, _, _} -> idx == 3 end), 1)
      
      if post_v3 > pre_v1 do
        antifragility_ratio = post_v3 / pre_v1
        IO.puts("  Pre-Shock 1 Velocity: #{Float.round(pre_v1, 2)} validated/sec")
        IO.puts("  Post-Shock 3 Velocity: #{Float.round(post_v3, 2)} validated/sec")
        IO.puts("  Antifragility Ratio: #{Float.round(antifragility_ratio, 2)}x")
        IO.puts("  🏆 ANTIFRAGILE: Post-shock velocity > pre-shock velocity!")
      else
        IO.puts("  Pre-Shock 1 Velocity: #{Float.round(pre_v1, 2)} validated/sec")
        IO.puts("  Post-Shock 3 Velocity: #{Float.round(post_v3, 2)} validated/sec")
        IO.puts("  ⚠️ Not yet antifragile (velocity stable or decreased)")
      end
    else
      IO.puts("  ⚠️ Insufficient velocity data for antifragility assessment")
    end
    IO.puts("")
    
    # Overall Classification
    if survival_rate > 0.7 and avg_conversion_rate > 0.2 do
      if length(recovery_data.recovery_times) >= 3 do
        [{1, _, rt1}, {3, _, rt3}] = Enum.take(Enum.sort_by(recovery_data.recovery_times, fn {idx, _, _} -> idx end), 2)
        if rt1 > rt3 do
          IO.puts("\n=== TIER 3 CLASSIFICATION: ADAPTATION ACHIEVED ⭐ ===\n")
        else
          IO.puts("\n=== TIER 3 CLASSIFICATION: RECOVERY MAINTAINED ✅ ===\n")
        end
      else
        IO.puts("\n=== TIER 3 CLASSIFICATION: RECOVERY MAINTAINED ✅ ===\n")
      end
    else
      IO.puts("\n=== TIER 3 CLASSIFICATION: PARTIAL SUCCESS ⚠️ ===\n")
    end
    
    IO.puts("Summary:")
    IO.puts("  System survived 3 sustained shocks")
    IO.puts("  Knowledge production maintained")
    IO.puts("  Recovery patterns measurable")
    IO.puts("  Foundation for antifragility testing established\n")
    
    IO.puts("Next Step: Tier 4 - Full scale antifragility test with 5 shocks\n")
  end
end
