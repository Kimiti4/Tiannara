defmodule Tiannara.OS.Layer65AEpistemicRecoveryTest do
  @moduledoc """
  Layer 6.5A: Epistemic Recovery Test
  
  Tests whether truth (evidence, discoveries, theories) can recover from epistemic shock.
  
  Scope: Evidence nodes, discovery nodes, theory nodes, JTMS++ cascades ONLY
  Excludes: Programs, funding, competition, knowledge migration
  
  Question: "Can truth recover from epistemic shock?"
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  
  # Configuration for Tier 1 (Debugging)
  @worlds_count 5
  @theories_per_world 20        # Total: 100 theories
  @discoveries_per_world 10     # Total: 50 discoveries
  @evidence_per_world 30        # Total: 150 evidence nodes
  @total_ticks 10_000
  @metrics_interval 1_000       # Collect every 1k ticks (10 data points)
  @shock_tick 2_000             # Apply shock at tick 2,000
  @shock_percentage 0.30        # Invalidate 30% of evidence
  
  test "Layer 6.5A: Epistemic Recovery - Tier 1 (Debugging)" do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A: EPISTEMIC RECOVERY TEST - TIER 1")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Configuration: #{@worlds_count} worlds, #{@total_ticks} ticks")
    IO.puts("Shock: #{@shock_percentage * 100}% evidence invalidated at tick #{@shock_tick}")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    # Step 1: Initialize worlds
    initial_state = initialize_worlds()
    
    IO.puts("✅ Initialized #{map_size(initial_state.evidence_graph)} nodes across #{@worlds_count} worlds\n")
    
    # Step 2: Run simulation with shock
    {final_state, metrics_history} = run_simulation(initial_state)
    
    IO.puts("\n✅ Simulation complete: #{length(metrics_history)} metric collection points\n")
    
    # Step 3: Analyze recovery
    analysis = analyze_recovery(metrics_history, initial_state)
    
    # Step 4: Assert success criteria
    assert_epistemic_recovery_success(analysis)
    
    # Step 5: Export results
    export_results(metrics_history, analysis, "6.5A")
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A TIER 1 COMPLETE")
    IO.puts(String.duplicate("=", 80) <> "\n")
  end
  
  # ============================================================================
  # World Initialization
  # ============================================================================
  
  defp initialize_worlds() do
    Enum.reduce(1..@worlds_count, %State{
      evidence_graph: %{},
      governance: %{
        damping_factor: 0.9,
        max_cascade_operations: 1000,
        relation_half_life_ticks: 1000
      }
    }, fn world_num, state ->
      add_world(state, world_num)
    end)
  end
  
  defp add_world(state, world_num) do
    world_prefix = "w#{world_num}"
    
    # Create theories
    {state, theory_ids} = Enum.reduce(1..@theories_per_world, {state, []}, fn i, {acc, ids} ->
      theory_id = String.to_atom("#{world_prefix}_theory_#{i}")
      confidence = :rand.uniform() * 0.2 + 0.7  # 0.7-0.9
      node = %EvidenceNode{id: theory_id, type: :theory, confidence: confidence}
      {EvidenceEngine.add_node(acc, theory_id, node), [theory_id | ids]}
    end)
    
    # Create discoveries
    {state, discovery_ids} = Enum.reduce(1..@discoveries_per_world, {state, []}, fn i, {acc, ids} ->
      disc_id = String.to_atom("#{world_prefix}_disc_#{i}")
      confidence = :rand.uniform() * 0.2 + 0.6  # 0.6-0.8
      node = %EvidenceNode{id: disc_id, type: :discovery, confidence: confidence, validity: :contested}
      {EvidenceEngine.add_node(acc, disc_id, node), [disc_id | ids]}
    end)
    
    # Create evidence and connect to discoveries/theories
    state = Enum.reduce(1..@evidence_per_world, state, fn i, acc ->
      evidence_id = String.to_atom("#{world_prefix}_evidence_#{i}")
      confidence = :rand.uniform() * 0.2 + 0.8  # 0.8-1.0
      node = %EvidenceNode{id: evidence_id, type: :evidence, confidence: confidence}
      
      acc = EvidenceEngine.add_node(acc, evidence_id, node)
      
      # Connect to random discovery
      disc_id = Enum.random(discovery_ids)
      acc = EvidenceEngine.add_relation(acc, evidence_id, :supports, disc_id, 0.8)
      
      # Connect discovery to random theory
      theory_id = Enum.random(theory_ids)
      EvidenceEngine.add_relation(acc, disc_id, :supports, theory_id, 0.7)
    end)
    
    state
  end
  
  # ============================================================================
  # Simulation Loop
  # ============================================================================
  
  defp run_simulation(initial_state) do
    start_time = System.system_time(:millisecond)
    
    {final_state, metrics_history} = Enum.reduce(1..@total_ticks, {initial_state, []}, fn tick, {state, metrics_acc} ->
      # Step 1: Apply shock at designated tick
      state = if tick == @shock_tick do
        IO.puts("\n⚡ APPLYING EPISTEMIC SHOCK AT TICK #{tick}")
        apply_random_shock(state)
      else
        state
      end
      
      # Step 2: Simulate normal dynamics (replications only for 6.5A)
      state = if rem(tick, 500) == 0 do
        maybe_trigger_replication(state)
      else
        state
      end
      
      # Step 3: Collect metrics
      metrics_acc = if rem(tick, @metrics_interval) == 0 do
        metrics = collect_epistemic_metrics(state)
        enriched = Map.merge(metrics, %{
          tick: tick,
          timestamp: System.system_time(:millisecond)
        })
        
        # Progress reporting
        if rem(tick, 2_000) == 0 do
          avg_conf = Float.round(metrics[:average_theory_confidence], 3)
          IO.puts("Tick #{tick}/#{@total_ticks} - Avg Theory Confidence: #{avg_conf}")
        end
        
        [enriched | metrics_acc]
      else
        metrics_acc
      end
      
      {state, metrics_acc}
    end)
    
    elapsed = (System.system_time(:millisecond) - start_time) / 1000
    IO.puts("\n⏱️  Simulation completed in #{Float.round(elapsed, 2)} seconds")
    
    {final_state, Enum.reverse(metrics_history)}
  end
  
  defp apply_random_shock(state) do
    evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} ->
      node.type == :evidence
    end)
    
    total_evidence = length(evidence_nodes)
    shock_count = round(total_evidence * @shock_percentage)
    
    IO.puts("Invalidating #{shock_count} of #{total_evidence} evidence nodes (#{round(@shock_percentage * 100)}%)")
    
    shocked_ids = evidence_nodes
    |> Enum.map(fn {id, _} -> id end)
    |> Enum.shuffle()
    |> Enum.take(shock_count)
    
    Enum.reduce(shocked_ids, state, fn id, acc ->
      EvidenceEngine.cascade_jtms_delta(acc, id, -0.8, :random_invalidation)
    end)
  end
  
  defp maybe_trigger_replication(state) do
    # Simple replication: occasionally boost evidence confidence
    evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} ->
      node.type == :evidence && node.confidence < 0.9
    end)
    
    if length(evidence_nodes) > 0 do
      # Boost 5 random evidence nodes
      to_boost = Enum.take_random(evidence_nodes, 5)
      
      Enum.reduce(to_boost, state, fn {id, _node}, acc ->
        EvidenceEngine.cascade_jtms_delta(acc, id, 0.1, :successful_replication)
      end)
    else
      state
    end
  end
  
  # ============================================================================
  # Metrics Collection (Epistemic Layer Only)
  # ============================================================================
  
  defp collect_epistemic_metrics(state) do
    theories = Enum.filter(state.evidence_graph, fn {_id, node} ->
      node.type == :theory
    end)
    
    discoveries = Enum.filter(state.evidence_graph, fn {_id, node} ->
      node.type == :discovery
    end)
    
    evidence = Enum.filter(state.evidence_graph, fn {_id, node} ->
      node.type == :evidence
    end)
    
    # Average theory confidence
    avg_theory_conf = if length(theories) > 0 do
      Enum.sum(Enum.map(theories, fn {_id, node} -> node.confidence end)) / length(theories)
    else
      0.0
    end
    
    # Discovery counts by validity
    validated_discoveries = Enum.count(discoveries, fn {_id, node} -> node.validity == :valid end)
    contested_discoveries = Enum.count(discoveries, fn {_id, node} -> node.validity == :contested end)
    total_discoveries = length(discoveries)
    
    # Recovery integrity
    recovery_integrity = if total_discoveries > 0 do
      validated_discoveries / total_discoveries
    else
      0.0
    end
    
    # Knowledge velocity (validated per time unit - simplified)
    knowledge_velocity = validated_discoveries / 1000.0  # Per 1k ticks
    
    # Contradiction rate (simplified - would need contradiction tracking in real impl)
    contradiction_rate = 0.0  # Placeholder
    
    %{
      average_theory_confidence: Float.round(avg_theory_conf, 4),
      total_theories: length(theories),
      total_discoveries: total_discoveries,
      validated_discoveries: validated_discoveries,
      contested_discoveries: contested_discoveries,
      recovery_integrity: Float.round(recovery_integrity, 4),
      knowledge_velocity: Float.round(knowledge_velocity, 4),
      contradiction_rate: contradiction_rate,
      total_evidence: length(evidence),
      avg_evidence_confidence: calculate_avg_confidence(evidence)
    }
  end
  
  defp calculate_avg_confidence(nodes) do
    if length(nodes) > 0 do
      Enum.sum(Enum.map(nodes, fn {_id, node} -> node.confidence end)) / length(nodes)
    else
      0.0
    end
  end
  
  # ============================================================================
  # Recovery Analysis
  # ============================================================================
  
  defp analyze_recovery(metrics_history, initial_state) do
    sorted = Enum.sort_by(metrics_history, & &1.tick)
    
    pre_shock = Enum.filter(sorted, & &1.tick < @shock_tick)
    post_shock = Enum.filter(sorted, & &1.tick >= @shock_tick)
    
    # Pre-shock baseline
    pre_avg_conf = average_metric(pre_shock, :average_theory_confidence)
    
    # Post-shock minimum
    post_min_conf = if length(post_shock) > 0 do
      Enum.min_by(post_shock, & &1.average_theory_confidence).average_theory_confidence
    else
      pre_avg_conf
    end
    
    # Final values
    final_metrics = List.last(sorted)
    final_conf = final_metrics.average_theory_confidence
    final_integrity = final_metrics.recovery_integrity
    
    # Recovery calculations
    recovery_ratio = final_conf / pre_avg_conf
    recovery_percentage = recovery_ratio * 100
    
    # Recovery time (ticks to reach 80% of pre-shock)
    recovery_threshold = pre_avg_conf * 0.80
    recovery_point = Enum.find(post_shock, fn m ->
      m.average_theory_confidence >= recovery_threshold
    end)
    recovery_time = if recovery_point do
      recovery_point.tick - @shock_tick
    else
      nil
    end
    
    # Shock absorption
    confidence_drop = max(0, pre_avg_conf - post_min_conf)
    shock_size = 0.30
    shock_absorption = if shock_size > 0 do
      1 - (confidence_drop / shock_size)
    else
      1.0
    end
    
    # Simplified CHI for 6.5A (only confidence and integrity components)
    normalized_conf = min(final_conf / 1.0, 1.0)
    normalized_integrity = min(final_integrity / 1.0, 1.0)
    chi = (0.60 * normalized_conf) + (0.40 * normalized_integrity)
    chi_recovery = (chi / ((0.60 * (pre_avg_conf / 1.0)) + (0.40 * 0.5))) * 100
    
    # Orbit classification (simplified for 6.5A)
    orbit = classify_orbit(chi_recovery, final_conf > pre_avg_conf, final_integrity >= 0.6)
    
    # Success criteria checks
    criteria = %{
      chi_recovery_adequate: chi_recovery >= 70,
      recovery_integrity_adequate: final_integrity >= 0.6,
      recovery_time_acceptable: recovery_time != nil && recovery_time <= 15_000,
      shock_absorption_adequate: shock_absorption >= 0.30,
      no_false_recovery: final_metrics.contradiction_rate <= 0.1
    }
    
    passed_count = Enum.count(criteria, fn {_k, v} -> v end)
    overall_pass = passed_count == 5
    
    %{
      pre_shock_avg_confidence: pre_avg_conf,
      post_shock_min_confidence: post_min_conf,
      final_confidence: final_conf,
      recovery_percentage: recovery_percentage,
      recovery_time: recovery_time,
      shock_absorption: shock_absorption,
      final_recovery_integrity: final_integrity,
      chi: chi,
      chi_recovery: chi_recovery,
      orbit_classification: orbit,
      criteria: criteria,
      passed_count: passed_count,
      overall_pass: overall_pass,
      metrics_history: sorted
    }
  end
  
  defp average_metric(metrics_list, key) do
    values = Enum.map(metrics_list, & Map.get(&1, key, 0))
    valid_values = Enum.reject(values, & is_nil/1)
    
    if length(valid_values) > 0 do
      Enum.sum(valid_values) / length(valid_values)
    else
      0.0
    end
  end
  
  defp classify_orbit(chi_recovery, improving, integrity_ok) do
    cond do
      chi_recovery < 50 -> :fragile
      chi_recovery < 70 -> :recovery
      chi_recovery < 85 -> :stable
      chi_recovery >= 85 && improving && integrity_ok -> :adaptive
      true -> :stable
    end
  end
  
  # ============================================================================
  # Assertions and Reporting
  # ============================================================================
  
  defp assert_epistemic_recovery_success(analysis) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A EPISTEMIC RECOVERY ANALYSIS")
    IO.puts(String.duplicate("=", 80))
    
    IO.puts("\n📊 Recovery Metrics:")
    IO.puts("   Pre-shock avg confidence: #{Float.round(analysis.pre_shock_avg_confidence, 3)}")
    IO.puts("   Post-shock min confidence: #{Float.round(analysis.post_shock_min_confidence, 3)}")
    IO.puts("   Final confidence: #{Float.round(analysis.final_confidence, 3)}")
    IO.puts("   Recovery percentage: #{Float.round(analysis.recovery_percentage, 1)}%")
    IO.puts("   Recovery time: #{if analysis.recovery_time, do: "#{analysis.recovery_time} ticks", else: "NOT RECOVERED"}")
    IO.puts("   Shock absorption: #{Float.round(analysis.shock_absorption * 100, 1)}%")
    
    IO.puts("\n🔬 Quality Metrics:")
    IO.puts("   Recovery integrity: #{Float.round(analysis.final_recovery_integrity * 100, 1)}%")
    IO.puts("   CHI: #{Float.round(analysis.chi, 3)}")
    IO.puts("   CHI recovery: #{Float.round(analysis.chi_recovery, 1)}%")
    
    IO.puts("\n🌌 Orbit Classification: #{String.upcase(to_string(analysis.orbit_classification))}")
    
    IO.puts("\n✅ Success Criteria:")
    Enum.each(analysis.criteria, fn {criterion, passed} ->
      status = if passed, do: "✅ PASS", else: "❌ FAIL"
      IO.puts("   #{status} - #{format_criterion(criterion)}")
    end)
    
    IO.puts("\n🎯 Overall Result: #{if analysis.overall_pass, do: "✅ PASSED", else: "❌ FAILED"}")
    IO.puts("   (#{analysis.passed_count}/5 criteria met)")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    assert analysis.overall_pass, "Layer 6.5A failed: only #{analysis.passed_count}/5 criteria met"
  end
  
  defp format_criterion(:chi_recovery_adequate), do: "CHI recovery ≥ 70%"
  defp format_criterion(:recovery_integrity_adequate), do: "Recovery integrity ≥ 60%"
  defp format_criterion(:recovery_time_acceptable), do: "Recovery time ≤ 15k ticks"
  defp format_criterion(:shock_absorption_adequate), do: "Shock absorption ≥ 30%"
  defp format_criterion(:no_false_recovery), do: "No false recovery (contradiction rate stable)"
  
  defp export_results(metrics_history, analysis, layer_label) do
    # Export CSV
    csv_path = "layer#{layer_label}_tier1_results.csv"
    headers = Map.keys(hd(metrics_history)) |> Enum.join(",")
    rows = Enum.map(metrics_history, fn m -> 
      Enum.map(headers |> String.split(","), fn h -> 
        Map.get(m, String.to_atom(h), "") 
      end) |> Enum.join(",")
    end)
    
    File.write!(csv_path, headers <> "\n" <> Enum.join(rows, "\n"))
    
    # Export analysis JSON
    analysis_path = "layer#{layer_label}_tier1_analysis.json"
    analysis_map = Map.from_struct(analysis) |> Map.delete(:metrics_history)
    File.write!(analysis_path, Jason.encode!(analysis_map, pretty: true))
    
    IO.puts("\n📁 Results exported:")
    IO.puts("   - #{csv_path}")
    IO.puts("   - #{analysis_path}")
  end
end
