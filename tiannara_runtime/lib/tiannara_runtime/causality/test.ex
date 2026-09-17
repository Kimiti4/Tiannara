defmodule TiannaraRuntime.Causality.Test do
  @moduledoc """
  PHASE 4C: Test Module for Causal Tracing System
  
  Usage:
    iex -S mix
    iex> TiannaraRuntime.Causality.Test.run_full_test()
  """
  
  require Logger
  
  def run_full_test() do
    Logger.info("🧪 Starting Phase 4C Causal Tracing Test...")
    
    # Test 1: TraceID Propagation
    test_trace_propagation()
    
    # Test 2: Causal Graph Construction
    test_causal_graph()
    
    # Test 3: Trace Query API
    test_trace_queries()
    
    # Test 4: Full Integration (Trace → Graph → Query)
    test_full_integration()
    
    Logger.info("✅ All Phase 4C tests completed!")
  end
  
  def test_trace_propagation() do
    Logger.info("\n🔗 TEST 1: TraceID Propagation")
    
    # Start new trace (root event)
    root_trace_id = TiannaraRuntime.Causality.TracePropagation.start_trace(
      "cal_decision",
      %{coalition_id: "C1", action: "select"}
    )
    
    Logger.info("   ✓ Root trace created: #{root_trace_id}")
    
    # Continue trace (child events)
    child1_id = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      root_trace_id,
      "cis_intervention",
      %{type: "damping", target: "C1"}
    )
    
    Logger.info("   ✓ Child 1 created: #{child1_id}")
    
    child2_id = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      child1_id,
      "coalition_update",
      %{coherence: 0.85}
    )
    
    Logger.info("   ✓ Child 2 created: #{child2_id}")
    
    # Get trace chain
    {:ok, chain} = TiannaraRuntime.Causality.TracePropagation.get_trace_chain(root_trace_id)
    Logger.info("   ✓ Trace chain length: #{length(chain)}")
    Logger.info("   ✓ Chain depths: #{Enum.map(chain, fn c -> c.depth end) |> Enum.join(", ")}")
    
    # Verify ancestry
    ancestry = TiannaraRuntime.Causality.TracePropagation.get_ancestry(child2_id)
    Logger.info("   ✓ Ancestry length: #{length(ancestry)}")
    Logger.info("   ✓ Ancestors: #{Enum.join(ancestry, " → ")}")
    
    :ok
  end
  
  def test_causal_graph() do
    Logger.info("\n🕸️ TEST 2: Causal Graph Construction")
    
    # Add nodes
    TiannaraRuntime.Causality.CausalGraph.add_node("event_1", "cal_decision", %{score: 0.9})
    TiannaraRuntime.CausalGraph.add_node("event_2", "cis_intervention", %{type: "damping"})
    TiannaraRuntime.CausalGraph.add_node("event_3", "coalition_update", %{coherence: 0.85})
    TiannaraRuntime.CausalGraph.add_node("event_4", "entropy_spike", %{value: 0.72})
    
    Logger.info("   ✓ Added 4 nodes to graph")
    
    # Add edges (causal relationships)
    TiannaraRuntime.Causality.CausalGraph.add_edge("event_1", "event_2", "influenced_by")
    TiannaraRuntime.Causality.CausalGraph.add_edge("event_2", "event_3", "intervened_by")
    TiannaraRuntime.CausalGraph.add_edge("event_4", "event_2", "caused_by")
    
    Logger.info("   ✓ Added 3 causal edges")
    
    # Get causal chain for event_3
    {:ok, chain} = TiannaraRuntime.Causality.CausalGraph.get_causal_chain("event_3")
    Logger.info("   ✓ Causal chain for event_3:")
    Logger.info("     - Nodes: #{length(chain.nodes)}")
    Logger.info("     - Edges: #{length(chain.edges)}")
    
    # Get ancestors only
    {:ok, ancestors} = TiannaraRuntime.Causality.CausalGraph.get_ancestors("event_3")
    Logger.info("   ✓ Ancestors of event_3: #{length(ancestors)}")
    
    # Get interventions affecting event_3
    {:ok, interventions} = TiannaraRuntime.Causality.CausalGraph.get_interventions("event_3")
    Logger.info("   ✓ CIS interventions: #{length(interventions)}")
    
    # Get graph stats
    {:ok, stats} = TiannaraRuntime.Causality.CausalGraph.get_stats()
    Logger.info("   ✓ Graph statistics:")
    Logger.info("     - Total nodes: #{stats.node_count}")
    Logger.info("     - Total edges: #{stats.edge_count}")
    Logger.info("     - Root nodes: #{stats.root_count}")
    Logger.info("     - Leaf nodes: #{stats.leaf_count}")
    
    :ok
  end
  
  def test_trace_queries() do
    Logger.info("\n🔍 TEST 3: Trace Query API")
    
    # Create a trace with multiple levels
    root_id = TiannaraRuntime.Causality.TracePropagation.start_trace(
      "cal_arbitration",
      %{context: "multi_coalition"}
    )
    
    child1 = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      root_id,
      "cal_decision",
      %{selected: "C1"}
    )
    
    child2 = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      child1,
      "cis_intervention",
      %{action: "stabilize"}
    )
    
    _child3 = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      child2,
      "coalition_stable",
      %{coherence: 0.92}
    )
    
    # Test decision tree query
    {:ok, tree} = TiannaraRuntime.Causality.TraceQuery.get_decision_tree(root_id)
    Logger.info("   ✓ Decision tree retrieved")
    Logger.info("     - Root type: #{tree.root.event_type}")
    Logger.info("     - Children count: #{length(tree.children)}")
    
    # Test ancestry query
    {:ok, ancestors} = TiannaraRuntime.Causality.TraceQuery.get_event_ancestry(child2)
    Logger.info("   ✓ Event ancestry: #{length(ancestors)} ancestors")
    
    # Test causality explanation
    {:ok, explanation} = TiannaraRuntime.Causality.TraceQuery.explain_causality(child2)
    Logger.info("   ✓ Causal explanation generated (#{String.length(explanation)} chars)")
    Logger.debug("     Preview: #{String.slice(explanation, 0, 100)}...")
    
    # Test replay chain
    {:ok, replay} = TiannaraRuntime.Causality.TraceQuery.replay_chain(root_id)
    Logger.info("   ✓ Replay chain: #{length(replay)} steps")
    Enum.each(replay, fn step ->
      Logger.debug("     Step #{step.step}: #{step.event_type}")
    end)
    
    # Test trace stats
    {:ok, stats} = TiannaraRuntime.Causality.TraceQuery.get_trace_stats(root_id)
    Logger.info("   ✓ Trace statistics:")
    Logger.info("     - Chain length: #{stats.chain_length}")
    Logger.info("     - Max depth: #{stats.max_depth}")
    
    :ok
  end
  
  def test_full_integration() do
    Logger.info("\n🔄 TEST 4: Full Integration (Trace → Graph → Query)")
    
    # Simulate realistic cognitive event chain
    Logger.info("   Step 1: Creating trace chain...")
    
    # Root: CAL arbitration event
    root_trace = TiannaraRuntime.Causality.TracePropagation.start_trace(
      "cal_arbitration",
      %{
        coalitions: ["C1", "C2", "C3"],
        context: "resource_competition"
      }
    )
    
    # Child 1: CAL selects winning coalition
    decision_trace = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      root_trace,
      "cal_decision",
      %{
        selected_coalition: "C1",
        score: 0.87,
        reasoning: "highest_coherence"
      }
    )
    
    # Child 2: CIS detects entropy spike in losing coalition
    intervention_trace = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      decision_trace,
      "cis_intervention",
      %{
        target: "C2",
        type: "entropy_damping",
        strength: 0.6
      }
    )
    
    # Child 3: Coalition state update after intervention
    _update_trace = TiannaraRuntime.Causality.TracePropagation.continue_trace(
      intervention_trace,
      "coalition_update",
      %{
        coalition_id: "C2",
        old_entropy: 0.75,
        new_entropy: 0.42,
        coherence: 0.78
      }
    )
    
    Logger.info("   ✓ Created 4-event trace chain")
    
    # Add to causal graph
    Logger.info("   Step 2: Building causal graph...")
    
    TiannaraRuntime.Causality.CausalGraph.add_node(root_trace, "cal_arbitration", %{})
    TiannaraRuntime.Causality.CausalGraph.add_node(decision_trace, "cal_decision", %{})
    TiannaraRuntime.Causality.CausalGraph.add_node(intervention_trace, "cis_intervention", %{})
    
    TiannaraRuntime.Causality.CausalGraph.add_edge(root_trace, decision_trace, "caused_by")
    TiannaraRuntime.Causality.CausalGraph.add_edge(decision_trace, intervention_trace, "triggered")
    
    Logger.info("   ✓ Graph constructed with 3 nodes and 2 edges")
    
    # Query the system
    Logger.info("   Step 3: Running queries...")
    
    # Get decision tree
    {:ok, tree} = TiannaraRuntime.Causality.TraceQuery.get_decision_tree(root_trace)
    Logger.info("   ✓ Decision tree: #{tree.root.event_type} → #{length(tree.children)} children")
    
    # Get causal explanation
    {:ok, explanation} = TiannaraRuntime.Causality.TraceQuery.explain_causality(intervention_trace)
    Logger.info("   ✓ Generated causal explanation")
    Logger.debug("     #{explanation}")
    
    # Get graph causal chain
    {:ok, graph_chain} = TiannaraRuntime.Causality.CausalGraph.get_causal_chain(intervention_trace)
    Logger.info("   ✓ Graph causal chain: #{length(graph_chain.nodes)} nodes, #{length(graph_chain.edges)} edges")
    
    Logger.info("   ✅ Full integration test complete!")
    
    :ok
  end
  
  def test_edge_cases() do
    Logger.info("\n⚠️ TEST 5: Edge Cases")
    
    # Test orphan trace (no parent)
    orphan_id = TiannaraRuntime.Causality.TracePropagation.start_trace("orphan_event", %{})
    {:ok, chain} = TiannaraRuntime.Causality.TracePropagation.get_trace_chain(orphan_id)
    Logger.info("   ✓ Orphan trace chain length: #{length(chain)} (expected: 1)")
    
    # Test missing trace
    result = TiannaraRuntime.Causality.TracePropagation.get_trace_chain("nonexistent_trace")
    case result do
      {:error, reason} ->
        Logger.info("   ✓ Missing trace handled: #{reason}")
      _ ->
        Logger.warning("   ⚠ Expected error for missing trace")
    end
    
    # Test empty graph queries
    {:ok, ancestors} = TiannaraRuntime.Causality.CausalGraph.get_ancestors("nonexistent_node")
    Logger.info("   ✓ Empty ancestor query: #{length(ancestors)} (expected: 0)")
    
    :ok
  end
end
