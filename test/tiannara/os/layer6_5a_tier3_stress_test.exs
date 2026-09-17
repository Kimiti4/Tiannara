defmodule Tiannara.OS.Layer65A3StressTest do
  @moduledoc """
  Layer 6.5A Tier 3: Stress Test
  
  Stresses the epistemic substrate with multiple shocks and larger scale.
  
  Configuration:
  - 25 worlds (2.5x Tier 2)
  - 50,000 ticks (2x Tier 2)
  - THREE shocks at ticks 10k, 25k, 40k
  - Tuned recovery mechanism (validated nodes only)
  
  Questions:
  - Can the system withstand sustained pressure?
  - Do multiple shocks cause cumulative damage?
  - Does recovery accelerate after first shock (learning)?
  - What's the breaking point?
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  
  # Tier 3 configuration
  @worlds_count 25
  @theories_per_world 20        # Total: 500 theories
  @discoveries_per_world 10     # Total: 250 discoveries
  @evidence_per_world 30        # Total: 750 evidence nodes
  @total_ticks 50_000
  @metrics_interval 5_000       # Collect every 5k ticks (10 data points)
  @shock_ticks [10_000, 25_000, 40_000]  # Three shocks
  @shock_percentage 0.30        # Invalidate 30% of evidence each time
  
  test "Layer 6.5A Tier 3: Stress Test" do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A TIER 3: STRESS TEST")
    IO.puts(String.duplicate("=", 80))
    
    # Initialize worlds
    initial_state = initialize_worlds()
    
    IO.puts("\n📊 Configuration:")
    IO.puts("   Worlds: #{@worlds_count}")
    IO.puts("   Total nodes: #{count_nodes(initial_state)}")
    IO.puts("   Total theories: #{@worlds_count * @theories_per_world}")
    IO.puts("   Total discoveries: #{@worlds_count * @discoveries_per_world}")
    IO.puts("   Total evidence: #{@worlds_count * @evidence_per_world}")
    IO.puts("   Shock ticks: #{inspect(@shock_ticks)}")
    IO.puts("   Shock percentage: #{@shock_percentage * 100}% each")
    
    # Verify relations were created
    relation_count = count_relations(initial_state)
    IO.puts("   Total relations: #{relation_count}")
    
    if relation_count > 0 do
      IO.puts("   ✅ Relations created successfully")
    else
      IO.puts("   ❌ WARNING: No relations found!")
    end
    
    # Run simulation with multiple shocks
    {final_state, metrics} = run_simulation(initial_state)
    
    # Analyze results
    analyze_stress_results(metrics)
    
    # Export data
    export_tier3_data(metrics)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("✅ TIER 3 STRESS TEST COMPLETE")
    IO.puts(String.duplicate("=", 80) <> "\n")
  end
  
  defp initialize_worlds do
    Enum.reduce(1..@worlds_count, %State{}, fn world_idx, state ->
      world_prefix = "w#{world_idx}"
      
      # Create theories
      {state, _theory_ids} = Enum.reduce(1..@theories_per_world, {state, []}, fn i, {acc, ids} ->
        theory_id = String.to_atom("#{world_prefix}_theory_#{i}")
        confidence = :rand.uniform() * 0.2 + 0.7  # 0.7-0.9
        node = %EvidenceNode{id: theory_id, type: :theory, confidence: confidence, validity: :contested}
        {EvidenceEngine.add_node(acc, theory_id, node), [theory_id | ids]}
      end)
      
      # Create discoveries
      {state, discovery_ids} = Enum.reduce(1..@discoveries_per_world, {state, []}, fn i, {acc, ids} ->
        disc_id = String.to_atom("#{world_prefix}_disc_#{i}")
        confidence = :rand.uniform() * 0.2 + 0.6  # 0.6-0.8
        node = %EvidenceNode{id: disc_id, type: :discovery, confidence: confidence, validity: :contested}
        {EvidenceEngine.add_node(acc, disc_id, node), [disc_id | ids]}
      end)
      
      # Create evidence
      {state, _evidence_ids} = Enum.reduce(1..@evidence_per_world, {state, []}, fn i, {acc, ids} ->
        ev_id = String.to_atom("#{world_prefix}_ev_#{i}")
        confidence = :rand.uniform() * 0.3 + 0.5  # 0.5-0.8
        node = %EvidenceNode{id: ev_id, type: :evidence, confidence: confidence, validity: :valid}
        {EvidenceEngine.add_node(acc, ev_id, node), [ev_id | ids]}
      end)
      
      # Link evidence → discoveries → theories (create support relationships)
      state = create_support_links(state, world_prefix, discovery_ids, 0)
    end)
  end
  
  defp create_support_links(state, world_prefix, discovery_ids, current_tick) do
    # Each discovery supports 2-4 theories - MUST capture state updates!
    Enum.reduce(discovery_ids, state, fn disc_id, acc_state ->
      num_theories = :rand.uniform(3) + 2  # 2-4
      theory_nums = 1..num_theories
        |> Enum.map(fn _ -> :rand.uniform(@theories_per_world) end)
        |> Enum.uniq
      
      Enum.reduce(theory_nums, acc_state, fn theory_num, inner_acc_state ->
        theory_id = String.to_atom("#{world_prefix}_theory_#{theory_num}")
        EvidenceEngine.add_relation(inner_acc_state, disc_id, :supports, theory_id, 0.8, nil, current_tick)
      end)
    end)
  end
  
  defp count_nodes(state) do
    map_size(state.evidence_graph)
  end
  
  defp count_relations(state) do
    state.evidence_graph
    |> Map.values()
    |> Enum.flat_map(fn node ->
      relations = get_in(node.metadata, [:relations]) || %{}
      Map.keys(relations)
    end)
    |> length()
  end
  
  defp run_simulation(initial_state) do
    # Track metrics over time
    metrics_log = %{
      confidence_timeline: [],
      shock_events: [],
      min_confidence: 1.0,
      max_confidence: 0.0,
      final_confidence: nil,
      dependency_events: []
    }
    
    IO.puts("\n⏳ Running stress test simulation...")
    
    # Run ticks with multiple shocks
    {final_state, updated_log} = Enum.reduce(1..@total_ticks, {initial_state, metrics_log}, fn tick, {state, log} ->
      # Apply shocks at designated ticks
      state = if tick in @shock_ticks do
        shock_number = Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
        apply_shock(state, shock_number)
      else
        state
      end
      
      # Simulate recovery (TUNED mechanism)
      state = simulate_recovery(state, tick)
      
      # Track metrics at intervals
      log = if rem(tick, @metrics_interval) == 0 or tick in @shock_ticks do
        current_conf = calculate_avg_confidence(state)
        
        if tick in @shock_ticks do
          shock_number = Enum.find_index(@shock_ticks, &(&1 == tick)) + 1
          IO.puts("   ⚡ Tick #{tick}: SHOCK #{shock_number} applied - confidence=#{Float.round(current_conf, 3)}")
        else
          IO.puts("   Tick #{tick}: avg_confidence=#{Float.round(current_conf, 3)}")
        end
        
        log
        |> Map.update!(:confidence_timeline, &(&1 ++ [%{tick: tick, confidence: current_conf}]))
        |> update_min_max_confidence(current_conf)
        |> Map.put(:final_confidence, current_conf)
        |> Map.update!(:dependency_events, &(&1 ++ [%{tick: tick, events: length(state.dependency_history)}]))
      else
        log
      end
      
      {state, log}
    end)
    
    {final_state, updated_log}
  end
  
  defp apply_shock(state, shock_number) do
    # Get all evidence nodes
    evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} -> node.type == :evidence end)
    
    # Select random subset to invalidate
    num_to_shock = round(length(evidence_nodes) * @shock_percentage)
    shocked_nodes = Enum.take_random(evidence_nodes, num_to_shock)
    
    # Apply shocks
    Enum.reduce(shocked_nodes, state, fn {node_id, _node}, acc_state ->
      new_node = %EvidenceNode{
        id: node_id,
        type: :evidence,
        confidence: 0.1,
        validity: :invalidated
      }
      
      state_with_shock = EvidenceEngine.add_node(acc_state, node_id, new_node)
      EvidenceEngine.cascade_jtms_delta(state_with_shock, node_id, -0.8, {:shock, shock_number})
    end)
  end
  
  defp simulate_recovery(state, _tick) do
    # TUNED recovery mechanism - only validated nodes recover passively
    Enum.reduce(state.evidence_graph, state, fn {node_id, node}, acc ->
      if node.confidence < 0.9 and node.validity != :invalidated do
        # Passive recovery ONLY for validated nodes (very slow)
        recovery_rate = if node.validity == :valid do
          0.0005  # Very slow passive recovery
        else
          0.0     # No passive recovery for contested nodes
        end
        
        new_confidence = min(node.confidence + recovery_rate, 0.9)
        new_node = %EvidenceNode{node | confidence: new_confidence}
        EvidenceEngine.add_node(acc, node_id, new_node)
      else
        acc
      end
    end)
  end
  
  defp calculate_avg_confidence(state) do
    nodes = Map.values(state.evidence_graph)
    if length(nodes) == 0 do
      0
    else
      Enum.sum_by(nodes, fn node -> node.confidence end) / length(nodes)
    end
  end
  
  defp update_min_max_confidence(log, current_conf) do
    log
    |> Map.update!(:min_confidence, &min(&1, current_conf))
    |> Map.update!(:max_confidence, &max(&1, current_conf))
  end
  
  defp analyze_stress_results(metrics) do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("📊 TIER 3 STRESS TEST RESULTS")
    IO.puts(String.duplicate("-", 80))
    
    # Confidence timeline analysis
    IO.puts("\n   Confidence Timeline:")
    metrics.confidence_timeline
    |> Enum.each(fn entry ->
      marker = if entry.tick in @shock_ticks do
        " ⚡ SHOCK"
      else
        ""
      end
      IO.puts("     Tick #{entry.tick}: #{Float.round(entry.confidence, 3)}#{marker}")
    end)
    
    IO.puts("\n   Confidence Range:")
    IO.puts("     Minimum: #{Float.round(metrics.min_confidence, 3)}")
    IO.puts("     Maximum: #{Float.round(metrics.max_confidence, 3)}")
    IO.puts("     Final: #{Float.round(metrics.final_confidence, 3)}")
    
    # Resilience analysis
    initial_conf = hd(metrics.confidence_timeline).confidence
    final_conf = metrics.final_confidence
    resilience = ((final_conf - metrics.min_confidence) / (initial_conf - metrics.min_confidence)) * 100
    
    IO.puts("\n   Resilience Metrics:")
    IO.puts("     Initial confidence: #{Float.round(initial_conf, 3)}")
    IO.puts("     Recovery from minimum: #{Float.round(resilience, 1)}%")
    
    # Dependency events
    total_events = List.last(metrics.dependency_events || []).events || 0
    IO.puts("\n   Dependency Events:")
    IO.puts("     Total events: #{total_events}")
    
    if total_events > 0 do
      IO.puts("     ✅ Cascades propagated throughout simulation")
    else
      IO.puts("     ❌ No cascades detected")
    end
    
    # Classification
    IO.puts("\n   🎯 TIER 3 CLASSIFICATION:")
    cond do
      resilience >= 80 && final_conf >= initial_conf * 0.9 ->
        IO.puts("     ✅ EXCELLENT: High resilience, maintained confidence")
        
      resilience >= 60 ->
        IO.puts("     ✅ GOOD: Moderate resilience")
        
      resilience >= 40 ->
        IO.puts("     ⚠️  PARTIAL: Some degradation under stress")
        
      true ->
        IO.puts("     ❌ WEAK: Significant degradation under sustained pressure")
    end
  end
  
  defp export_tier3_data(metrics) do
    File.write!("layer6_5a_tier3_stress_results.json", Jason.encode!(metrics, pretty: true))
    
    IO.puts("\n💾 Tier 3 data exported to layer6_5a_tier3_stress_results.json")
  end
end
