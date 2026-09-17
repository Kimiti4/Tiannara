defmodule Tiannara.OS.Layer65A2ScalingTest do
  @moduledoc """
  Layer 6.5A Tier 2: Scaling Test
  
  Scales up the epistemic recovery test to validate behavior at larger scale.
  
  Configuration:
  - 10 worlds (doubled from Tier 1)
  - 25,000 ticks (2.5x Tier 1)
  - 30% shock at tick 5,000
  
  Questions:
  - Does propagation work consistently at scale?
  - Are cascade statistics stable across multiple worlds?
  - Does recovery improve with more nodes?
  - What emergent behaviors appear at scale?
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  
  # Tier 2 configuration
  @worlds_count 10
  @theories_per_world 20        # Total: 200 theories
  @discoveries_per_world 10     # Total: 100 discoveries
  @evidence_per_world 30        # Total: 300 evidence nodes
  @total_ticks 25_000
  @metrics_interval 2_500       # Collect every 2.5k ticks (10 data points)
  @shock_tick 5_000             # Apply shock at tick 5,000
  @shock_percentage 0.30        # Invalidate 30% of evidence
  
  test "Layer 6.5A Tier 2: Scaling Test" do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A TIER 2: SCALING TEST")
    IO.puts(String.duplicate("=", 80))
    
    # Initialize worlds
    initial_state = initialize_worlds()
    
    IO.puts("\n📊 Configuration:")
    IO.puts("   Worlds: #{@worlds_count}")
    IO.puts("   Total nodes: #{count_nodes(initial_state)}")
    IO.puts("   Total theories: #{@worlds_count * @theories_per_world}")
    IO.puts("   Total discoveries: #{@worlds_count * @discoveries_per_world}")
    IO.puts("   Total evidence: #{@worlds_count * @evidence_per_world}")
    IO.puts("   Shock at tick: #{@shock_tick}")
    IO.puts("   Shock percentage: #{@shock_percentage * 100}%")
    
    # Verify relations were created
    relation_count = count_relations(initial_state)
    IO.puts("   Total relations: #{relation_count}")
    
    if relation_count > 0 do
      IO.puts("   ✅ Relations created successfully")
    else
      IO.puts("   ❌ WARNING: No relations found!")
    end
    
    # Run simulation
    {final_state, metrics} = run_simulation(initial_state)
    
    # Analyze results
    analyze_results(metrics)
    
    # Export data
    export_tier2_data(metrics)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("✅ TIER 2 SCALING TEST COMPLETE")
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
      # FIXED: Properly captures state updates from add_relation
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
        # Use add_relation with :supports relation type - CAPTURE returned state!
        EvidenceEngine.add_relation(inner_acc_state, disc_id, :supports, theory_id, 0.8, nil, current_tick)
      end)
    end)
  end
  
  defp count_nodes(state) do
    map_size(state.evidence_graph)
  end
  
  defp count_relations(state) do
    # Count total relations across all nodes
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
      pre_shock_confidence: nil,
      post_shock_confidence: nil,
      min_confidence: nil,
      final_confidence: nil,
      recovery_time: nil,
      dependency_events: []
    }
    
    # Calculate pre-shock baseline
    pre_shock_conf = calculate_avg_confidence(initial_state)
    metrics_log = Map.put(metrics_log, :pre_shock_confidence, pre_shock_conf)
    
    IO.puts("\n⏳ Running simulation...")
    
    # Run ticks
    {final_state, updated_log} = Enum.reduce(1..@total_ticks, {initial_state, metrics_log}, fn tick, {state, log} ->
      # Apply shock at designated tick
      state = if tick == @shock_tick do
        apply_shock(state)
      else
        state
      end
      
      # Simulate recovery (confidence restoration)
      state = simulate_recovery(state, tick)
      
      # Track metrics at intervals
      log = if rem(tick, @metrics_interval) == 0 do
        current_conf = calculate_avg_confidence(state)
        IO.puts("   Tick #{tick}: avg_confidence=#{Float.round(current_conf, 3)}")
        
        log
        |> Map.put(:final_confidence, current_conf)
        |> update_min_confidence(current_conf)
        |> Map.update!(:dependency_events, &(&1 ++ [%{tick: tick, confidence: current_conf, events: length(state.dependency_history)}]))
      else
        log
      end
      
      {state, log}
    end)
    
    # Calculate recovery metrics
    updated_log = calculate_recovery_metrics(updated_log)
    
    {final_state, updated_log}
  end
  
  defp apply_shock(state) do
    IO.puts("\n⚡ Applying shock at tick #{@shock_tick}...")
    
    # Get all evidence nodes
    evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} -> node.type == :evidence end)
    
    # Select random subset to invalidate
    num_to_shock = round(length(evidence_nodes) * @shock_percentage)
    shocked_nodes = Enum.take_random(evidence_nodes, num_to_shock)
    
    IO.puts("   Shocking #{num_to_shock} evidence nodes (#{length(evidence_nodes)} total)")
    
    # Apply shocks
    Enum.reduce(shocked_nodes, state, fn {node_id, _node}, acc_state ->
      new_node = %EvidenceNode{
        id: node_id,
        type: :evidence,
        confidence: 0.1,  # Near-zero confidence
        validity: :invalidated
      }
      
      state_with_shock = EvidenceEngine.add_node(acc_state, node_id, new_node)
      
      # Trigger JTMS++ cascade
      EvidenceEngine.cascade_jtms_delta(state_with_shock, node_id, -0.8, :shock)
    end)
  end
  
  defp simulate_recovery(state, _tick) do
    # TUNED recovery mechanism - only validated nodes recover passively
    # Unvalidated nodes require active replication to recover
    Enum.reduce(state.evidence_graph, state, fn {node_id, node}, acc ->
      if node.confidence < 0.9 and node.validity != :invalidated do
        # Passive recovery ONLY for validated nodes (slower)
        # Unvalidated nodes don't recover automatically - need replication events
        recovery_rate = if node.validity == :valid do
          0.0005  # Very slow passive recovery for validated nodes
        else
          0.0     # No passive recovery for contested/unvalidated nodes
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
  
  defp update_min_confidence(log, current_conf) do
    current_min = Map.get(log, :min_confidence, 1.0)
    Map.put(log, :min_confidence, min(current_min, current_conf))
  end
  
  defp calculate_recovery_metrics(log) do
    pre_shock = log.pre_shock_confidence
    post_shock = log.min_confidence
    final_conf = log.final_confidence
    
    if pre_shock && post_shock && final_conf do
      recovery_percentage = ((final_conf - post_shock) / (pre_shock - post_shock)) * 100
      shock_absorption = ((pre_shock - post_shock) / pre_shock) * 100
      
      Map.merge(log, %{
        recovery_percentage: Float.round(recovery_percentage, 1),
        shock_absorption: Float.round(shock_absorption, 1)
      })
    else
      log
    end
  end
  
  defp analyze_results(metrics) do
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("📊 TIER 2 RESULTS")
    IO.puts(String.duplicate("-", 80))
    
    IO.puts("\n   Confidence Metrics:")
    IO.puts("     Pre-shock: #{Float.round(metrics.pre_shock_confidence, 3)}")
    IO.puts("     Post-shock minimum: #{Float.round(metrics.min_confidence, 3)}")
    IO.puts("     Final: #{Float.round(metrics.final_confidence, 3)}")
    
    if Map.has_key?(metrics, :recovery_percentage) do
      IO.puts("\n   Recovery Metrics:")
      IO.puts("     Recovery percentage: #{metrics.recovery_percentage}%")
      IO.puts("     Shock absorption: #{metrics.shock_absorption}%")
    end
    
    # Dependency events analysis
    total_events = List.last(metrics.dependency_events || []).events || 0
    IO.puts("\n   Dependency Events:")
    IO.puts("     Total events: #{total_events}")
    
    if total_events > 0 do
      IO.puts("     ✅ Cascades propagated (#{total_events} events recorded)")
    else
      IO.puts("     ❌ No cascades detected")
    end
    
    # Classification
    IO.puts("\n   🎯 TIER 2 CLASSIFICATION:")
    cond do
      metrics.recovery_percentage >= 80 && metrics.shock_absorption >= 30 ->
        IO.puts("     ✅ EXCELLENT: Strong recovery and shock absorption")
        
      metrics.recovery_percentage >= 70 ->
        IO.puts("     ✅ GOOD: Reasonable recovery")
        
      metrics.recovery_percentage >= 50 ->
        IO.puts("     ⚠️  PARTIAL: Moderate recovery")
        
      true ->
        IO.puts("     ❌ WEAK: Poor recovery")
    end
  end
  
  defp export_tier2_data(metrics) do
    File.write!("layer6_5a_tier2_results.json", Jason.encode!(metrics, pretty: true))
    
    IO.puts("\n💾 Tier 2 data exported to layer6_5a_tier2_results.json")
  end
end
