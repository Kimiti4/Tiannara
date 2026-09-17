defmodule Tiannara.OS.Layer65A1PropagationAudit do
  @moduledoc """
  Layer 6.5A.1: Propagation Audit
  
  Adds telemetry to measure cascade behavior and identify over-propagation.
  
  Questions:
  - Are cascades amplifying damage instead of damping it?
  - What is the average/max cascade size and depth?
  - How many nodes are affected per shock?
  - What's the ratio of positive vs negative deltas?
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  
  # Minimal configuration for audit
  @worlds_count 5
  @theories_per_world 20
  @discoveries_per_world 10
  @evidence_per_world 30
  @total_ticks 2_000          # Short run for audit
  @shock_tick 500             # Early shock
  @shock_percentage 0.30
  
  test "Layer 6.5A.1: Propagation Audit" do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A.1: PROPAGATION AUDIT")
    IO.puts(String.duplicate("=", 80))
    
    # Initialize worlds
    initial_state = initialize_worlds()
    
    IO.puts("\n📊 Configuration:")
    IO.puts("   Worlds: #{@worlds_count}")
    IO.puts("   Total nodes: #{count_nodes(initial_state)}")
    IO.puts("   Shock at tick: #{@shock_tick}")
    IO.puts("   Shock percentage: #{@shock_percentage * 100}%")
    
    # Run simulation with cascade tracking
    {final_state, metrics} = run_simulation_with_audit(initial_state)
    
    # Analyze propagation patterns
    analyze_cascades(metrics, final_state)
    
    # Export detailed data
    export_audit_data(metrics)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("✅ PROPAGATION AUDIT COMPLETE")
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
      # FIXED: Now properly captures state updates from add_relation
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
  
  defp run_simulation_with_audit(initial_state) do
    # Track cascade statistics
    cascade_log = %{
      cascades: [],
      pre_shock_confidence: nil,
      post_shock_confidence: nil,
      min_confidence: nil
    }
    
    # Calculate pre-shock baseline
    pre_shock_conf = calculate_avg_confidence(initial_state)
    cascade_log = Map.put(cascade_log, :pre_shock_confidence, pre_shock_conf)
    
    IO.puts("\n⏳ Running simulation...")
    
    # Run ticks
    {final_state, updated_log} = Enum.reduce(1..@total_ticks, {initial_state, cascade_log}, fn tick, {state, log} ->
      # Apply shock at designated tick
      {state, log} = if tick == @shock_tick do
        updated_log = apply_shock_with_tracking(state, log)
        {state, updated_log}
      else
        {state, log}
      end
      
      # Simulate recovery (confidence restoration)
      state = simulate_recovery(state, tick)
      
      # Track minimum confidence
      current_conf = calculate_avg_confidence(state)
      log = update_min_confidence(log, current_conf)
      
      if rem(tick, 500) == 0 do
        IO.puts("   Tick #{tick}: avg_confidence=#{Float.round(current_conf, 3)}")
      end
      
      {state, log}
    end)
    
    {final_state, updated_log}
  end
  
  defp apply_shock_with_tracking(state, log) do
    IO.puts("\n⚡ Applying shock at tick #{@shock_tick}...")
    
    # Get all evidence nodes
    evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} -> node.type == :evidence end)
    
    # Select random subset to invalidate
    num_to_shock = round(length(evidence_nodes) * @shock_percentage)
    shocked_nodes = Enum.take_random(evidence_nodes, num_to_shock)
    
    IO.puts("   Shocking #{num_to_shock} evidence nodes (#{length(evidence_nodes)} total)")
    
    # Apply shocks and track cascades - use map_reduce to accumulate state
    {cascades, final_state} = Enum.map_reduce(shocked_nodes, state, fn {node_id, _node}, current_state ->
      # Record pre-shock state
      pre_confidence = get_node_confidence(current_state, node_id)
      
      # Invalidate evidence
      new_node = %EvidenceNode{
        id: node_id,
        type: :evidence,
        confidence: 0.1,  # Near-zero confidence
        validity: :invalidated
      }
      
      state_with_shock = EvidenceEngine.add_node(current_state, node_id, new_node)
      
      # Trigger JTMS++ cascade using cascade_jtms_delta
      state_after_cascade = EvidenceEngine.cascade_jtms_delta(
        state_with_shock,
        node_id,
        -0.8,  # Large negative change
        :shock  # Event type
      )
      
      # Extract cascade telemetry from dependency_history
      cascade_stats = extract_cascade_telemetry(state_after_cascade.dependency_history, node_id, pre_confidence)
      
      {cascade_stats, state_after_cascade}
    end)
    
    # Update log with cascade data
    updated_log = Map.update!(log, :cascades, &(&1 ++ cascades))
    
    # Calculate post-shock confidence using final_state
    post_conf = calculate_avg_confidence(final_state)
    updated_log = Map.put(updated_log, :post_shock_confidence, post_conf)
    
    IO.puts("   Post-shock confidence: #{Float.round(post_conf, 3)}")
    
    updated_log
  end
  
  defp extract_cascade_telemetry(dep_history, root_node, pre_confidence) do
    # Find all entries related to this cascade
    cascade_entries = Enum.filter(dep_history, fn entry ->
      entry.source_node == root_node or entry.target_node == root_node
    end)
    
    # Calculate cascade statistics
    affected_nodes = cascade_entries
      |> Enum.flat_map(fn e -> [e.source_node, e.target_node] end)
      |> Enum.uniq()
      |> length()
    
    positive_deltas = Enum.count(cascade_entries, fn e -> e.delta > 0 end)
    negative_deltas = Enum.count(cascade_entries, fn e -> e.delta < 0 end)
    
    max_depth = if length(cascade_entries) > 0 do
      Enum.max_by(cascade_entries, fn e -> e.cascade_depth end).cascade_depth
    else
      0
    end
    
    total_propagated_delta = Enum.sum_by(cascade_entries, fn e -> abs(e.delta) end)
    
    # Get final confidence of root node
    post_confidence = case Enum.find(cascade_entries, fn e -> e.target_node == root_node end) do
      nil -> pre_confidence
      entry -> entry.delta + pre_confidence
    end
    
    %{
      root_node: root_node,
      cascade_size: affected_nodes,
      cascade_depth: max_depth,
      affected_nodes: cascade_entries,
      positive_deltas: positive_deltas,
      negative_deltas: negative_deltas,
      pre_confidence: pre_confidence,
      post_confidence: Float.round(post_confidence, 3),
      amplification_factor: calculate_amplification(total_propagated_delta)
    }
  end
  
  defp calculate_amplification(total_propagated_delta) do
    # Amplification = total propagated delta / initial shock delta
    initial_shock = 0.8  # The delta we applied
    
    if initial_shock > 0 do
      Float.round(total_propagated_delta / initial_shock, 2)
    else
      0
    end
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
  
  defp get_node_confidence(state, node_id) do
    case Map.get(state.evidence_graph, node_id) do
      nil -> 0
      node -> node.confidence
    end
  end
  
  defp update_min_confidence(log, current_conf) do
    current_min = Map.get(log, :min_confidence, 1.0)
    Map.put(log, :min_confidence, min(current_min, current_conf))
  end
  
  defp analyze_cascades(metrics, state) do
    cascades = metrics.cascades
    
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("📈 CASCADE STATISTICS")
    IO.puts(String.duplicate("-", 80))
    
    if length(cascades) > 0 do
      avg_size = Enum.sum_by(cascades, fn c -> c.cascade_size end) / length(cascades)
      max_size = Enum.max_by(cascades, fn c -> c.cascade_size end).cascade_size
      min_size = Enum.min_by(cascades, fn c -> c.cascade_size end).cascade_size
      
      avg_depth = Enum.sum_by(cascades, fn c -> c.cascade_depth end) / length(cascades)
      max_depth = Enum.max_by(cascades, fn c -> c.cascade_depth end).cascade_depth
      
      avg_amplification = Enum.sum_by(cascades, fn c -> c.amplification_factor end) / length(cascades)
      max_amplification = Enum.max_by(cascades, fn c -> c.amplification_factor end).amplification_factor
      
      total_positive = Enum.sum_by(cascades, fn c -> c.positive_deltas end)
      total_negative = Enum.sum_by(cascades, fn c -> c.negative_deltas end)
      
      IO.puts("   Total cascades analyzed: #{length(cascades)}")
      IO.puts("")
      IO.puts("   Cascade Size:")
      IO.puts("     Average: #{Float.round(avg_size, 1)} nodes")
      IO.puts("     Maximum: #{max_size} nodes")
      IO.puts("     Minimum: #{min_size} nodes")
      IO.puts("")
      IO.puts("   Cascade Depth:")
      IO.puts("     Average: #{Float.round(avg_depth, 1)} levels")
      IO.puts("     Maximum: #{max_depth} levels")
      IO.puts("")
      IO.puts("   Damage Amplification:")
      IO.puts("     Average: #{Float.round(avg_amplification, 2)}x")
      IO.puts("     Maximum: #{Float.round(max_amplification, 2)}x")
      IO.puts("")
      IO.puts("   Delta Distribution:")
      IO.puts("     Positive deltas: #{total_positive}")
      IO.puts("     Negative deltas: #{total_negative}")
      IO.puts("     Ratio: #{Float.round(total_negative / max(total_positive, 1), 2)}:1")
      
      # Network coverage analysis
      total_graph_size = count_nodes(state)
      unique_affected = cascades
        |> Enum.flat_map(fn c -> c.affected_nodes end)
        |> Enum.uniq()
        |> length()
      
      coverage_pct = (unique_affected / total_graph_size) * 100
      
      IO.puts("")
      IO.puts("   Network Coverage:")
      IO.puts("     Unique nodes affected: #{unique_affected} / #{total_graph_size}")
      IO.puts("     Coverage: #{Float.round(coverage_pct, 1)}%")
      
      # Classification
      IO.puts("")
      IO.puts("   🎯 PROPAGATION CLASSIFICATION:")
      cond do
        avg_amplification > 1.5 ->
          IO.puts("     ⚠️  CRITICAL: Severe amplification detected!")
          IO.puts("     Cascades are magnifying damage by #{Float.round(avg_amplification, 1)}x")
          IO.puts("     Recommendation: Investigate network structure and damping mechanisms")
        
        avg_amplification > 1.0 ->
          IO.puts("     ⚠️  WARNING: Moderate amplification")
          IO.puts("     Cascades amplify damage slightly (#{Float.round(avg_amplification, 1)}x)")
          IO.puts("     Recommendation: Monitor and consider structural adjustments")
        
        true ->
          IO.puts("     ✅ GOOD: Damping effective")
          IO.puts("     Cascades reduce damage (#{Float.round(avg_amplification, 1)}x)")
      end
      
      # Store analysis results
      File.write!("layer6_5a1_cascade_analysis.json", Jason.encode!(%{
        cascade_count: length(cascades),
        avg_size: Float.round(avg_size, 1),
        max_size: max_size,
        avg_depth: Float.round(avg_depth, 1),
        max_depth: max_depth,
        avg_amplification: Float.round(avg_amplification, 2),
        max_amplification: Float.round(max_amplification, 2),
        total_positive_deltas: total_positive,
        total_negative_deltas: total_negative,
        unique_nodes_affected: unique_affected,
        network_coverage_pct: Float.round(coverage_pct, 1)
      }, pretty: true))
      
    else
      IO.puts("   No cascades recorded (unexpected)")
    end
  end
  
  defp export_audit_data(metrics) do
    # Export full cascade details for deeper analysis
    File.write!("layer6_5a1_cascade_details.json", Jason.encode!(metrics.cascades, pretty: true))
    
    IO.puts("\n💾 Audit data exported:")
    IO.puts("   - layer6_5a1_cascade_analysis.json (summary)")
    IO.puts("   - layer6_5a1_cascade_details.json (full details)")
  end
end
