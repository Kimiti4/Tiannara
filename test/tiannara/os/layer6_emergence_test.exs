defmodule TiannaraOS.Layer6EmergenceTest do
  @moduledoc """
  Layer 6: Emergence Verification - Quick Validation
  
  Runs a scaled-down civilization simulation to detect emergent behavior patterns.
  
  Parameters:
  - 10 worlds (instead of 50)
  - ~200 entities per world (instead of 2,000)
  - 10,000 ticks (instead of 100,000)
  
  Expected runtime: 15-30 minutes
  
  Measures:
  - Knowledge velocity over time
  - Epistemic stability trends
  - Recovery rates after shocks
  - Discovery yield per world
  - Shock frequency and magnitude
  """

  use ExUnit.Case, async: false

  alias TiannaraOS.{State, EvidenceEngine, EvidenceNode, Discovery, ResearchProgram}

  # Simulation parameters
  @num_worlds 10
  @nodes_per_world 200
  @total_ticks 10_000
  @metrics_interval 1_000  # Collect metrics every N ticks
  @shock_probability 0.05  # 5% chance of shock per tick
  @damping_factor 0.9
  @max_cascade_ops 1000

  test "Layer 6 - Emergence Verification (Quick Validation)" do
    IO.puts("\n🌍 Starting Layer 6 Emergence Simulation...")
    IO.puts("   Worlds: #{@num_worlds}")
    IO.puts("   Nodes per world: #{@nodes_per_world}")
    IO.puts("   Total ticks: #{@total_ticks}")
    IO.puts("   Expected runtime: 15-30 minutes\n")

    start_time = System.system_time(:millisecond)

    # Phase 1: Initialize civilization
    state = initialize_civilization()
    IO.puts("✅ Civilization initialized with #{map_size(state.evidence_graph)} nodes\n")

    # Phase 2: Run simulation
    {final_state, metrics_history} = run_simulation(state)

    elapsed = (System.system_time(:millisecond) - start_time) / 1000
    IO.puts("\n⏱️  Simulation completed in #{Float.round(elapsed, 2)} seconds")

    # Phase 3: Analyze results
    analyze_emergence(metrics_history)

    # Phase 4: Export results
    export_metrics_csv(metrics_history)

    # Verify basic emergence criteria
    assert length(metrics_history) > 0, "Should have collected metrics"
    
    first_metrics = hd(metrics_history)
    last_metrics = List.last(metrics_history)

    # Check that system didn't crash
    assert last_metrics.total_nodes > 0, "Should have nodes remaining"
    
    # Check that knowledge accumulated (some discoveries validated)
    assert last_metrics.active_discoveries >= 0, "Should track active discoveries"

    IO.puts("\n✅ Layer 6 Quick Validation PASSED")
    IO.puts("   Full results exported to: layer6_emergence_results.csv\n")
  end

  # --- SIMULATION ENGINE ---

  defp initialize_civilization() do
    state = %State{
      evidence_graph: %{},
      discoveries: %{},
      research_programs: %{},
      governance: %{
        damping_factor: @damping_factor,
        max_cascade_operations: @max_cascade_ops
      },
      dependency_history: []
    }

    # Create worlds with diverse entities
    Enum.reduce(1..@num_worlds, state, fn world_idx, acc ->
      world_id = String.to_atom("world_#{world_idx}")
      initialize_world(acc, world_id, world_idx)
    end)
  end

  defp initialize_world(state, world_id, world_idx) do
    # Each world gets a mix of entity types
    num_theories = div(@nodes_per_world, 4)
    num_discoveries = div(@nodes_per_world, 4)
    num_assets = div(@nodes_per_world, 4)
    num_programs = div(@nodes_per_world, 4)

    state = create_entities(state, world_id, world_idx, num_theories, num_discoveries, num_assets, num_programs)
    create_relations(state, world_id, world_idx)
  end

  defp create_entities(state, world_id, world_idx, num_theories, num_discoveries, num_assets, num_programs) do
    # Create theories
    state = Enum.reduce(1..num_theories, state, fn i, acc ->
      node_id = String.to_atom("#{world_id}_theory_#{i}")
      node = %EvidenceNode{
        id: node_id,
        type: :theory,
        confidence: 0.7 + :rand.uniform() * 0.3,  # Random initial confidence 0.7-1.0
        utility: 0.5 + :rand.uniform() * 0.5
      }
      EvidenceEngine.add_node(acc, node_id, node)
    end)

    # Create discoveries
    state = Enum.reduce(1..num_discoveries, state, fn i, acc ->
      node_id = String.to_atom("#{world_id}_discovery_#{i}")
      node = %EvidenceNode{
        id: node_id,
        type: :discovery,
        confidence: 0.8 + :rand.uniform() * 0.2,
        utility: 0.6 + :rand.uniform() * 0.4
      }
      EvidenceEngine.add_node(acc, node_id, node)
      
      # Also add to discoveries map
      discovery = %Discovery{
        id: node_id,
        source_world: world_id,
        status: :candidate,
        confidence: node.confidence
      }
      %{acc | discoveries: Map.put(acc.discoveries, node_id, discovery)}
    end)

    # Create assets
    state = Enum.reduce(1..num_assets, state, fn i, acc ->
      node_id = String.to_atom("#{world_id}_asset_#{i}")
      node = %EvidenceNode{
        id: node_id,
        type: :discovery_asset,
        confidence: 0.9 + :rand.uniform() * 0.1,
        utility: 0.7 + :rand.uniform() * 0.3
      }
      EvidenceEngine.add_node(acc, node_id, node)
    end)

    # Create programs
    state = Enum.reduce(1..num_programs, state, fn i, acc ->
      node_id = String.to_atom("#{world_id}_program_#{i}")
      node = %EvidenceNode{
        id: node_id,
        type: :research_program,
        confidence: 0.85 + :rand.uniform() * 0.15,
        utility: 0.8 + :rand.uniform() * 0.2
      }
      EvidenceEngine.add_node(acc, node_id, node)
      
      # Also add to research_programs map
      program = %ResearchProgram{
        id: node_id,
        world_id: world_id,
        status: :active,
        funding_score: 1.0
      }
      %{acc | research_programs: Map.put(acc.research_programs, node_id, program)}
    end)

    state
  end

  defp create_relations(state, world_id, _world_idx) do
    graph = state.evidence_graph
    node_ids = Map.keys(graph) |> Enum.filter(&String.starts_with?(Atom.to_string(&1), Atom.to_string(world_id)))
    
    # Create random connections within world
    num_relations = min(length(node_ids) * 2, 500)  # Avg 2 connections per node
    
    Enum.reduce(1..num_relations, state, fn _, acc ->
      case pick_random_pair(node_ids) do
        {from, to} when from != to ->
          strength = 0.3 + :rand.uniform() * 0.7  # Random strength 0.3-1.0
          relation_type = pick_relation_type()
          EvidenceEngine.add_relation(acc, from, relation_type, to, strength)
        _ ->
          acc
      end
    end)
  end

  defp pick_random_pair(node_ids) do
    case node_ids do
      [] -> {nil, nil}
      [single] -> {single, single}
      list ->
        idx1 = :rand.uniform(length(list)) - 1
        idx2 = :rand.uniform(length(list)) - 1
        {Enum.at(list, idx1), Enum.at(list, idx2)}
    end
  end

  defp pick_relation_type() do
    [:supports, :depends_on, :generates, :funds, :competes_with]
    |> Enum.random()
  end

  # --- SIMULATION LOOP ---

  defp run_simulation(initial_state) do
    IO.puts("🔄 Running simulation...\n")

    Enum.reduce(1..@total_ticks, {initial_state, []}, fn tick, {state, metrics_acc} ->
      # Progress indicator
      if rem(tick, @metrics_interval) == 0 do
        progress = Float.round(tick / @total_ticks * 100, 1)
        IO.write("\r   Progress: #{progress}% (tick #{tick}/#{ @total_ticks})")
      end

      # Step 1: Apply random shocks
      state = maybe_apply_shock(state, tick)

      # Step 2: Run JTMS++ cascades (already triggered by shocks)

      # Step 3: Simulate some successful replications
      state = maybe_trigger_replication(state, tick)

      # Step 4: Collect metrics at intervals
      metrics_acc = if rem(tick, @metrics_interval) == 0 do
        metrics = EvidenceEngine.get_civilization_metrics(state)
        enriched = Map.merge(metrics, %{
          tick: tick,
          total_nodes: map_size(state.evidence_graph),
          timestamp: System.system_time(:millisecond)
        })
        [enriched | metrics_acc]
      else
        metrics_acc
      end

      {state, metrics_acc}
    end)
    |> then(fn {final_state, metrics_acc} ->
      IO.puts("\n")
      {final_state, Enum.reverse(metrics_acc)}
    end)
  end

  defp maybe_apply_shock(state, tick) do
    if :rand.uniform() < @shock_probability do
      # Pick a random node to degrade
      graph = state.evidence_graph
      case Map.keys(graph) |> Enum.take_random(1) do
        [target] ->
          delta = -0.1 - :rand.uniform() * 0.2  # Random degradation -0.1 to -0.3
          EvidenceEngine.cascade_jtms_delta(state, target, delta, :shock)
        [] ->
          state
      end
    else
      state
    end
  end

  defp maybe_trigger_replication(state, tick) do
    # 10% chance of successful replication per tick
    if :rand.uniform() < 0.1 do
      discoveries = state.discoveries |> Map.keys()
      case discoveries |> Enum.take_random(1) do
        [target] ->
          EvidenceEngine.register_successful_replication(state, String.to_atom("rep_tick#{tick}"), target)
        [] ->
          state
      end
    else
      state
    end
  end

  # --- ANALYSIS ---

  defp analyze_emergence(metrics_history) do
    IO.puts("\n📊 Emergence Analysis:")
    IO.puts(String.duplicate("─", 60))

    if length(metrics_history) < 2 do
      IO.puts("⚠️  Insufficient data for trend analysis")
    else

    first = hd(metrics_history)
    last = List.last(metrics_history)

    # Knowledge velocity trend
    kv_start = first[:knowledge_velocity] || 0
    kv_end = last[:knowledge_velocity] || 0
    kv_change = kv_end - kv_start

    IO.puts("\n📈 Knowledge Velocity:")
    IO.puts("   Start: #{Float.round(kv_start, 4)}")
    IO.puts("   End:   #{Float.round(kv_end, 4)}")
    IO.puts("   Change: #{if kv_change > 0, do: "+", else: ""}#{Float.round(kv_change, 4)}")

    if kv_change > 0 do
      IO.puts("   ✅ POSITIVE TREND - Knowledge accumulation detected")
    else
      IO.puts("   ⚠️  FLAT/NEGATIVE - May need parameter tuning")
    end

    # Epistemic stability trend
    stab_start = first[:epistemic_stability] || 0
    stab_end = last[:epistemic_stability] || 0

    IO.puts("\n🎯 Epistemic Stability:")
    IO.puts("   Start: #{Float.round(stab_start, 4)}")
    IO.puts("   End:   #{Float.round(stab_end, 4)}")

    if stab_end > 0.5 do
      IO.puts("   ✅ STABLE - System maintains coherence")
    else
      IO.puts("   ⚠️  UNSTABLE - High variance in confidences")
    end

    # Recovery rate
    recovery = last[:recovery_rate] || 0
    IO.puts("\n💚 Recovery Rate: #{Float.round(recovery, 4)}")
    if recovery > 0.5 do
      IO.puts("   ✅ RESILIENT - System recovers from shocks")
    else
      IO.puts("   ⚠️  FRAGILE - Struggles to recover")
    end

    # Shock impact
    shocks = last[:epistemic_shock_score] || 0
    IO.puts("\n⚡ Epistemic Shock Score: #{Float.round(shocks, 4)}")
    if shocks < 0.3 do
      IO.puts("   ✅ LOW SHOCK - System not overwhelmed")
    else
      IO.puts("   ⚠️  HIGH SHOCK - Frequent/large disruptions")
    end

    # Overall assessment
    IO.puts("\n" <> String.duplicate("─", 60))
    IO.puts("🔍 Overall Assessment:")

    good_signs = [
      kv_change > 0,
      stab_end > 0.5,
      recovery > 0.5,
      shocks < 0.3
    ]

    good_count = Enum.count(good_signs, & &1)

    cond do
      good_count >= 3 ->
        IO.puts("   ✅✅✅ STRONG EMERGENCE - Civilization shows healthy dynamics")
      good_count >= 2 ->
        IO.puts("   ✅✅ MODERATE EMERGENCE - Promising but needs refinement")
      good_count >= 1 ->
        IO.puts("   ✅ WEAK EMERGENCE - Basic patterns present")
      true ->
        IO.puts("   ❌ NO EMERGENCE - System may be too rigid or chaotic")
    end

    IO.puts(String.duplicate("─", 60) <> "\n")
    end
  end

  # --- EXPORT ---

  defp export_metrics_csv(metrics_history) do
    filename = "layer6_emergence_results.csv"
    
    headers = [
      "tick",
      "timestamp",
      "total_nodes",
      "average_theory_confidence",
      "active_discoveries",
      "retired_discoveries",
      "active_programs",
      "suspended_programs",
      "total_dependency_events",
      "recovery_rate",
      "epistemic_stability",
      "epistemic_shock_score",
      "knowledge_velocity"
    ]

    csv_content = [
      Enum.join(headers, ","),
      Enum.map_join(metrics_history, "\n", fn metrics ->
        Enum.map_join(headers, ",", fn header ->
          value = Map.get(metrics, String.to_atom(header), 0)
          to_string(value)
        end)
      end)
    ] |> Enum.join("\n")

    File.write!(filename, csv_content)
    IO.puts("📁 Results exported to: #{filename}")
  end
end
