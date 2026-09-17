defmodule TiannaraOS.DependencyResolverTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.{State, EvidenceNode, EvidenceEngine}

  defp setup_state do
    %State{evidence_graph: %{}}
    |> EvidenceEngine.add_node(:a, %EvidenceNode{id: :a, type: :evidence, confidence: 1.0, utility: 1.0})
    |> EvidenceEngine.add_node(:b, %EvidenceNode{id: :b, type: :evidence, confidence: 1.0, utility: 1.0})
    |> EvidenceEngine.add_relation(:a, :supports, :b, 0.8)
  end

  test "Propagation Damping" do
    state = setup_state()
    damping_factor = 0.9
    initial_delta = 0.5
    effective_delta = initial_delta * 0.8 * damping_factor

    new_state = EvidenceEngine.cascade_jtms_delta(state, :a, effective_delta, :recovery)
    node_b = Map.get(new_state.evidence_graph, :b)
    assert node_b.confidence > 1.0
  end

  test "Recovery Propagation" do
    state = setup_state()
    new_state = EvidenceEngine.register_successful_replication(state, :rep1, :a)
    node_a = Map.get(new_state.evidence_graph, :a)
    assert node_a.confidence > 1.0
  end

  test "Civilization Metrics" do
    state = setup_state()
    metrics = EvidenceEngine.get_civilization_metrics(state)
    assert is_map(metrics)
    assert metrics.average_theory_confidence == 1.0
    assert metrics.active_discoveries == 0
    assert metrics.epistemic_shock_score == 0.0
  end
end