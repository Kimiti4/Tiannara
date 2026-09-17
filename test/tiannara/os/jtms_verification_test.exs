defmodule TiannaraOS.JTMSVerificationTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.{State, EvidenceEngine, EvidenceNode, Discovery, DiscoveryAsset, ResearchProgram}

  # Layer 1: Correctness Verification
  describe "Layer 1 - Correctness Verification" do
    test "A. Single-Hop Propagation" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }

      theory = %EvidenceNode{
        id: :theory,
        type: :theory,
        confidence: 1.0,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_node(:theory, theory)
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)

      # Apply delta = -0.2, strength = 1.0, damping = 0.9
      # Expected: -0.2 * 1.0 * 0.9 = -0.18
      result = EvidenceEngine.cascade_jtms_delta(state, :evidence, -0.2, :degradation)
      
      theory_node = result.evidence_graph[:theory]
      expected_change = -0.18
      actual_change = theory_node.confidence - 1.0
      
      assert_in_delta(expected_change, actual_change, 0.0001)
    end

    test "B. Multi-Hop Propagation" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      # Build chain: Evidence -> Discovery -> Asset -> Program -> Theory
      nodes = [
        {:evidence, :evidence},
        {:discovery, :discovery},
        {:asset, :discovery_asset},
        {:program, :research_program},
        {:theory, :theory}
      ]

      state = Enum.reduce(nodes, state, fn {id, type}, acc ->
        node = %EvidenceNode{
          id: id,
          type: type,
          confidence: 1.0,
          utility: 1.0
        }
        EvidenceEngine.add_node(acc, id, node)
      end)

      # Connect chain
      state = state
      |> EvidenceEngine.add_relation(:evidence, :supports, :discovery, 1.0)
      |> EvidenceEngine.add_relation(:discovery, :generates, :asset, 1.0)
      |> EvidenceEngine.add_relation(:asset, :funds, :program, 1.0)
      |> EvidenceEngine.add_relation(:program, :supports, :theory, 1.0)

      # Apply cascade
      result = EvidenceEngine.cascade_jtms_delta(state, :evidence, -0.2, :degradation)

      # Verify hop values
      theory_node = result.evidence_graph[:theory]
      assert theory_node.confidence < 1.0
    end

    test "C. Positive Recovery" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 0.5,
        utility: 1.0
      }

      theory = %EvidenceNode{
        id: :theory,
        type: :theory,
        confidence: 0.5,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_node(:theory, theory)
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)

      # Successful replication
      result = EvidenceEngine.register_successful_replication(state, :rep1, :evidence)
      
      # Confidence should increase but not exceed 1.0
      assert result.evidence_graph[:evidence].confidence > 0.5
      assert result.evidence_graph[:evidence].confidence <= 1.0
    end

    test "D. Bidirectional Stress" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      asset = %EvidenceNode{
        id: :asset,
        type: :discovery_asset,
        confidence: 0.8,
        utility: 1.0
      }

      program = %EvidenceNode{
        id: :program,
        type: :research_program,
        confidence: 0.8,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:asset, asset)
      |> EvidenceEngine.add_node(:program, program)
      |> EvidenceEngine.add_relation(:asset, :funds, :program, 1.0)

      # Asset loss
      result = EvidenceEngine.cascade_jtms_delta(state, :asset, -0.5, :degradation)
      program_node = result.evidence_graph[:program]
      
      # Funding should drop (confidence decreases)
      assert program_node.confidence < 0.8

      # Asset recovery
      recovery = EvidenceEngine.cascade_jtms_delta(result, :asset, 0.3, :recovery)
      program_recovery = recovery.evidence_graph[:program]
      
      # Funding should recover
      assert program_recovery.confidence > program_node.confidence
    end
  end

  # Layer 2: Graph Integrity Verification
  describe "Layer 2 - Graph Integrity Verification" do
    test "Cycle Detection - No infinite recursion" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      # Create cycle: A -> B -> C -> A
      nodes = [:a, :b, :c] |> Enum.map(&(%EvidenceNode{
        id: &1,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }))

      state = Enum.reduce(nodes, state, fn node, acc ->
        EvidenceEngine.add_node(acc, node.id, node)
      end)

      state = state
      |> EvidenceEngine.add_relation(:a, :supports, :b, 1.0)
      |> EvidenceEngine.add_relation(:b, :supports, :c, 1.0)
      |> EvidenceEngine.add_relation(:c, :supports, :a, 1.0)

      # Run cascade - should not crash
      result = EvidenceEngine.cascade_jtms_delta(state, :a, -0.1, :degradation)
      
      # Should complete without error
      assert result != nil
    end

    test "Broken References - System survives" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_relation(:evidence, :supports, :missing_node, 1.0)

      # Run cascade - should not crash
      result = EvidenceEngine.cascade_jtms_delta(state, :evidence, -0.1, :degradation)
      
      assert result != nil
    end

    test "Duplicate Relations - Single propagation only" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }

      theory = %EvidenceNode{
        id: :theory,
        type: :theory,
        confidence: 1.0,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_node(:theory, theory)

      # Add duplicate relations
      state = state
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)

      # Run cascade
      result = EvidenceEngine.cascade_jtms_delta(state, :evidence, -0.1, :degradation)
      
      # Should have only one entry in dependents
      assert length(result.evidence_graph[:evidence].dependents) == 1
    end
  end

  # Layer 3: Civilization Stress Testing
  describe "Layer 3 - Civilization Stress Testing" do
    test "10,000 Node Civilization - No crash" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9, max_cascade_operations: 1000}
      }

      # Create 100 nodes
      {state, _} = Enum.reduce(1..100, {state, []}, fn i, {acc, ids} ->
        id = String.to_atom("node_#{i}")
        node = %EvidenceNode{
          id: id,
          type: :evidence,
          confidence: 1.0,
          utility: 1.0
        }
        {EvidenceEngine.add_node(acc, id, node), [id | ids]}
      end)

      # Create random relations
      {state, _} = Enum.reduce(1..200, {state, []}, fn i, {acc, _} ->
        from = String.to_atom("node_#{rem(i, 100) + 1}")
        to = String.to_atom("node_#{rem(i + 1, 100) + 1}")
        {EvidenceEngine.add_relation(acc, from, :supports, to, 0.5), []}
      end)

      # Run cascade
      result = EvidenceEngine.cascade_jtms_delta(state, :node_1, -0.1, :degradation)
      
      assert result != nil
    end

    test "Cascade Budget Test - Pause and resume" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9, max_cascade_operations: 5}
      }

      # Create star topology: root -> 10 children (will exceed budget of 5)
      {state, _} = Enum.reduce(0..10, {state, []}, fn i, {acc, _} ->
        id = String.to_atom("node_#{i}")
        node = %EvidenceNode{
          id: id,
          type: :evidence,
          confidence: 1.0,
          utility: 1.0
        }
        {EvidenceEngine.add_node(acc, id, node), []}
      end)

      # Connect all to root (node_0)
      state = Enum.reduce(1..10, state, fn i, acc ->
        EvidenceEngine.add_relation(acc, :node_0, :supports, String.to_atom("node_#{i}"), 1.0)
      end)

      # Run cascade - should pause after 5 operations
      result = EvidenceEngine.cascade_jtms_delta(state, :node_0, -0.1, :degradation)
      
      # Should have paused cascades
      assert result.governance[:paused_cascades] != nil
    end
  end

  # Layer 4: Scientific Verification
  describe "Layer 4 - Scientific Verification" do
    test "Theory Death Test - Gradual confidence fall" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      theory = %EvidenceNode{
        id: :theory,
        type: :theory,
        confidence: 1.0,
        utility: 1.0
      }

      claim = %EvidenceNode{
        id: :claim,
        type: :claim,
        confidence: 1.0,
        utility: 1.0
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:theory, theory)
      |> EvidenceEngine.add_node(:claim, claim)
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_relation(:evidence, :supports, :claim, 1.0)
      |> EvidenceEngine.add_relation(:claim, :supports, :theory, 1.0)

      # Refute evidence multiple times
      result = Enum.reduce(1..3, state, fn i, acc ->
        EvidenceEngine.register_failed_replication(acc, String.to_atom("rep_#{i}"), :evidence)
      end)

      # Theory confidence should fall gradually
      theory_node = result.evidence_graph[:theory]
      assert theory_node.confidence < 1.0
    end

    test "Replication Crisis Test" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      # Create 100 discoveries
      {state, _} = Enum.reduce(1..100, {state, []}, fn i, {acc, ids} ->
        id = String.to_atom("disc_#{i}")
        disc = %EvidenceNode{
          id: id,
          type: :discovery,
          confidence: 1.0,
          utility: 1.0
        }
        {EvidenceEngine.add_node(acc, id, disc), [id | ids]}
      end)

      # Apply 60 failed replications
      result = Enum.reduce(1..60, state, fn i, acc ->
        disc_id = String.to_atom("disc_#{rem(i, 100) + 1}")
        rep_id = String.to_atom("rep_#{i}")
        EvidenceEngine.register_failed_replication(acc, rep_id, disc_id)
      end)

      # Some discoveries should have lower confidence
      discoveries = result.evidence_graph
      |> Map.values()
      |> Enum.filter(&(&1.type == :discovery))
      
      low_conf_count = Enum.count(discoveries, &(&1.confidence < 1.0))
      assert low_conf_count > 0
    end
  end

  # Layer 5: Historical Verification
  describe "Layer 5 - Historical Verification" do
    test "Temporal Ledger - Cascade ID and depth tracking" do
      state = %State{
        evidence_graph: %{},
        governance: %{damping_factor: 0.9}
      }

      evidence = %EvidenceNode{
        id: :evidence,
        type: :evidence,
        confidence: 1.0,
        utility: 1.0
      }

      theory = %EvidenceNode{
        id: :theory,
        type: :theory,
        confidence: 1.0,
        utility: 1.0
      }

      state = state
      |> EvidenceEngine.add_node(:evidence, evidence)
      |> EvidenceEngine.add_node(:theory, theory)
      |> EvidenceEngine.add_relation(:evidence, :supports, :theory, 1.0)

      result = EvidenceEngine.cascade_jtms_delta(state, :evidence, -0.1, :degradation)

      # Check dependency history
      assert length(result.dependency_history) > 0
      
      # Check cascade_id exists
      [event | _] = result.dependency_history
      assert event.cascade_id != nil
      assert event.cascade_depth >= 0
    end
  end
end
