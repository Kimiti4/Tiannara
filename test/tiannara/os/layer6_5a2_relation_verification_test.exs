defmodule Tiannara.OS.Layer65A2RelationVerification do
  @moduledoc """
  Layer 6.5A.2: Relation Verification Test
  
  Verifies that support relations are properly created and populated in the evidence graph.
  
  Questions:
  - Are relations being created between evidence → discoveries → theories?
  - Are dependents lists populated correctly?
  - Do justifications lists contain the right nodes?
  - Can a single cascade propagate at least one hop?
  """
  
  use ExUnit.Case, async: false
  
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  
  test "Layer 6.5A.2: Relation Verification" do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAYER 6.5A.2: RELATION VERIFICATION")
    IO.puts(String.duplicate("=", 80))
    
    # Create minimal test case: 1 evidence → 1 discovery → 1 theory
    state = create_minimal_graph()
    
    IO.puts("\n📊 Graph Structure:")
    IO.puts("   Total nodes: #{map_size(state.evidence_graph)}")
    
    # Verify node creation
    verify_nodes_exist(state)
    
    # Verify relations
    verify_relations(state)
    
    # Test single cascade
    test_cascade_propagation(state)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("✅ RELATION VERIFICATION COMPLETE")
    IO.puts(String.duplicate("=", 80) <> "\n")
  end
  
  defp create_minimal_graph do
    IO.puts("\n🔧 Creating minimal test graph...")
    
    state = %State{}
    
    # Create theory
    theory_id = :test_theory_1
    theory_node = %EvidenceNode{
      id: theory_id,
      type: :theory,
      confidence: 0.8,
      validity: :contested
    }
    state = EvidenceEngine.add_node(state, theory_id, theory_node)
    IO.puts("   ✓ Created theory: #{theory_id} (confidence: 0.8)")
    
    # Create discovery
    discovery_id = :test_discovery_1
    discovery_node = %EvidenceNode{
      id: discovery_id,
      type: :discovery,
      confidence: 0.7,
      validity: :contested
    }
    state = EvidenceEngine.add_node(state, discovery_id, discovery_node)
    IO.puts("   ✓ Created discovery: #{discovery_id} (confidence: 0.7)")
    
    # Create evidence
    evidence_id = :test_evidence_1
    evidence_node = %EvidenceNode{
      id: evidence_id,
      type: :evidence,
      confidence: 0.6,
      validity: :valid
    }
    state = EvidenceEngine.add_node(state, evidence_id, evidence_node)
    IO.puts("   ✓ Created evidence: #{evidence_id} (confidence: 0.6)")
    
    # Link evidence → discovery (evidence supports discovery)
    state = EvidenceEngine.add_relation(state, evidence_id, :supports, discovery_id, 0.8, nil, 0)
    IO.puts("   ✓ Linked evidence → discovery (:supports, strength=0.8)")
    
    # Link discovery → theory (discovery supports theory)
    state = EvidenceEngine.add_relation(state, discovery_id, :supports, theory_id, 0.8, nil, 0)
    IO.puts("   ✓ Linked discovery → theory (:supports, strength=0.8)")
    
    state
  end
  
  defp verify_nodes_exist(state) do
    IO.puts("\n🔍 Verifying nodes exist...")
    
    [:test_evidence_1, :test_discovery_1, :test_theory_1]
    |> Enum.each(fn node_id ->
      case Map.get(state.evidence_graph, node_id) do
        nil ->
          IO.puts("   ❌ Node NOT found: #{node_id}")
          
        node ->
          IO.puts("   ✓ Node found: #{node_id}")
          IO.puts("      Type: #{node.type}")
          IO.puts("      Confidence: #{node.confidence}")
          IO.puts("      Validity: #{node.validity}")
          IO.puts("      Dependents: #{inspect(node.dependents)}")
          IO.puts("      Justifications: #{inspect(node.justifications)}")
      end
    end)
  end
  
  defp verify_relations(state) do
    IO.puts("\n🔍 Verifying relations...")
    
    # Check evidence node
    evidence = Map.get(state.evidence_graph, :test_evidence_1)
    if evidence do
      IO.puts("\n   Evidence Node (:test_evidence_1):")
      IO.puts("     Dependents: #{inspect(evidence.dependents)}")
      
      if length(evidence.dependents || []) > 0 do
        IO.puts("     ✅ HAS dependents (should include :test_discovery_1)")
      else
        IO.puts("     ❌ NO dependents (PROBLEM!)")
      end
      
      relations = get_in(evidence.metadata, [:relations]) || %{}
      IO.puts("     Relations metadata: #{inspect(Map.keys(relations))}")
    end
    
    # Check discovery node
    discovery = Map.get(state.evidence_graph, :test_discovery_1)
    if discovery do
      IO.puts("\n   Discovery Node (:test_discovery_1):")
      IO.puts("     Dependents: #{inspect(discovery.dependents)}")
      IO.puts("     Justifications: #{inspect(discovery.justifications)}")
      
      if length(discovery.dependents || []) > 0 do
        IO.puts("     ✅ HAS dependents (should include :test_theory_1)")
      else
        IO.puts("     ❌ NO dependents (PROBLEM!)")
      end
      
      if length(discovery.justifications || []) > 0 do
        IO.puts("     ✅ HAS justifications (should include :test_evidence_1)")
      else
        IO.puts("     ❌ NO justifications (PROBLEM!)")
      end
      
      relations = get_in(discovery.metadata, [:relations]) || %{}
      IO.puts("     Relations metadata: #{inspect(Map.keys(relations))}")
      
      # Check relation details
      if Map.has_key?(relations, :test_theory_1) do
        rel_meta = Map.get(relations, :test_theory_1)
        IO.puts("     Relation to theory: direction=#{rel_meta.direction}, strength=#{rel_meta.strength}")
      end
      
      if Map.has_key?(relations, :test_evidence_1) do
        rel_meta = Map.get(relations, :test_evidence_1)
        IO.puts("     Relation to evidence: direction=#{rel_meta.direction}, strength=#{rel_meta.strength}")
      end
    end
    
    # Check theory node
    theory = Map.get(state.evidence_graph, :test_theory_1)
    if theory do
      IO.puts("\n   Theory Node (:test_theory_1):")
      IO.puts("     Dependents: #{inspect(theory.dependents)}")
      IO.puts("     Justifications: #{inspect(theory.justifications)}")
      
      if length(theory.justifications || []) > 0 do
        IO.puts("     ✅ HAS justifications (should include :test_discovery_1)")
      else
        IO.puts("     ❌ NO justifications (PROBLEM!)")
      end
    end
  end
  
  defp test_cascade_propagation(state) do
    IO.puts("\n⚡ Testing cascade propagation...")
    
    # Record pre-cascade confidences
    pre_confidences = %{
      evidence: Map.get(state.evidence_graph, :test_evidence_1).confidence,
      discovery: Map.get(state.evidence_graph, :test_discovery_1).confidence,
      theory: Map.get(state.evidence_graph, :test_theory_1).confidence
    }
    
    IO.puts("   Pre-cascade confidences:")
    IO.puts("     Evidence: #{pre_confidences.evidence}")
    IO.puts("     Discovery: #{pre_confidences.discovery}")
    IO.puts("     Theory: #{pre_confidences.theory}")
    
    # Apply shock to evidence
    IO.puts("\n   Applying shock to evidence (-0.5 delta)...")
    shocked_state = EvidenceEngine.cascade_jtms_delta(state, :test_evidence_1, -0.5, :test_shock)
    
    # Record post-cascade confidences
    post_confidences = %{
      evidence: Map.get(shocked_state.evidence_graph, :test_evidence_1).confidence,
      discovery: Map.get(shocked_state.evidence_graph, :test_discovery_1).confidence,
      theory: Map.get(shocked_state.evidence_graph, :test_theory_1).confidence
    }
    
    IO.puts("   Post-cascade confidences:")
    IO.puts("     Evidence: #{post_confidences.evidence} (Δ=#{Float.round(post_confidences.evidence - pre_confidences.evidence, 3)})")
    IO.puts("     Discovery: #{post_confidences.discovery} (Δ=#{Float.round(post_confidences.discovery - pre_confidences.discovery, 3)})")
    IO.puts("     Theory: #{post_confidences.theory} (Δ=#{Float.round(post_confidences.theory - pre_confidences.theory, 3)})")
    
    # Analyze propagation
    IO.puts("\n   🎯 PROPAGATION ANALYSIS:")
    
    evidence_changed = post_confidences.evidence != pre_confidences.evidence
    discovery_changed = post_confidences.discovery != pre_confidences.discovery
    theory_changed = post_confidences.theory != pre_confidences.theory
    
    cond do
      evidence_changed and discovery_changed and theory_changed ->
        IO.puts("     ✅ EXCELLENT: Full propagation (evidence → discovery → theory)")
        IO.puts("     Cascade propagated through entire chain!")
        
      evidence_changed and discovery_changed ->
        IO.puts("     ⚠️  PARTIAL: Propagated one hop (evidence → discovery)")
        IO.puts("     But did NOT reach theory")
        
      evidence_changed ->
        IO.puts("     ❌ FAILED: No propagation beyond shocked node")
        IO.puts("     Only evidence changed, discovery and theory unchanged")
        
      true ->
        IO.puts("     ❌ CRITICAL: Even shocked node didn't change!")
    end
    
    # Check dependency history
    dep_history_length = length(shocked_state.dependency_history)
    IO.puts("\n   Dependency History:")
    IO.puts("     Total entries: #{dep_history_length}")
    
    if dep_history_length > 0 do
      IO.puts("     ✅ Dependency history populated")
      
      # Show first few entries
      shocked_state.dependency_history
      |> Enum.take(3)
      |> Enum.with_index()
      |> Enum.each(fn {entry, idx} ->
        IO.puts("       [#{idx}] source=#{entry.source_node}, target=#{entry.target_node}, delta=#{entry.delta}, depth=#{entry.cascade_depth}")
      end)
    else
      IO.puts("     ❌ Dependency history EMPTY (no cascade recorded)")
    end
    
    # Export results
    File.write!("layer6_5a2_relation_verification.json", Jason.encode!(%{
      pre_confidences: pre_confidences,
      post_confidences: post_confidences,
      changes: %{
        evidence: Float.round(post_confidences.evidence - pre_confidences.evidence, 4),
        discovery: Float.round(post_confidences.discovery - pre_confidences.discovery, 4),
        theory: Float.round(post_confidences.theory - pre_confidences.theory, 4)
      },
      dependency_history_count: dep_history_length,
      propagation_reached: %{
        evidence: evidence_changed,
        discovery: discovery_changed,
        theory: theory_changed
      }
    }, pretty: true))
    
    IO.puts("\n💾 Results exported to layer6_5a2_relation_verification.json")
  end
end
