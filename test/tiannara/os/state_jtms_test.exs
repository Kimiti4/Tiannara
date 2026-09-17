defmodule TiannaraOS.StateJTMSTest do
  use ExUnit.Case, async: false
  require Logger

  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.EvidenceEngine

  setup do
    initial_state = %State{
      evidence_graph: %{}
    }

    # Verify if PubSub is running to subscribe
    pubsub_active = Process.whereis(Tiannara.PubSub) != nil
    if pubsub_active do
      Phoenix.PubSub.subscribe(Tiannara.PubSub, "tiannara_events")
    end

    {:ok, %{state: initial_state, pubsub_active: pubsub_active}}
  end

  test "Graph Construction: adds nodes and sets bidirectional relation links", %{state: state} do
    theory = %EvidenceNode{id: :theory_1, type: :theory, name: "Specialized Theory A", value: 1.0, validity: :valid}
    claim = %EvidenceNode{id: :claim_1, type: :claim, name: "Specialized Claim A", value: 1.0, validity: :valid}
    hypothesis = %EvidenceNode{id: :hyp_1, type: :hypothesis, name: "Specialized Hypothesis A", validity: :valid}
    experiment = %EvidenceNode{id: :exp_1, type: :experiment, name: "Specialized Experiment A", value: 1.0, validity: :valid}
    evidence = %EvidenceNode{id: :ev_1, type: :evidence, name: "Specialized Evidence A", validity: :valid}

    # Add all nodes
    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim)
      |> EvidenceEngine.add_node(hypothesis)
      |> EvidenceEngine.add_node(experiment)
      |> EvidenceEngine.add_node(evidence)

    # Establish bidirectional relations
    state =
      state
      |> EvidenceEngine.add_relation(:theory_1, :predicts, :claim_1)
      |> EvidenceEngine.add_relation(:claim_1, :predicts, :hyp_1)
      |> EvidenceEngine.add_relation(:hyp_1, :tested_by, :exp_1)
      |> EvidenceEngine.add_relation(:exp_1, :generates, :ev_1)
      |> EvidenceEngine.add_relation(:ev_1, :supports, :claim_1)

    # Assert relations
    theory_node = Map.get(state.evidence_graph, :theory_1)
    claim_node = Map.get(state.evidence_graph, :claim_1)
    hyp_node = Map.get(state.evidence_graph, :hyp_1)
    exp_node = Map.get(state.evidence_graph, :exp_1)
    ev_node = Map.get(state.evidence_graph, :ev_1)

    # Predictions (Downstream dependents)
    assert :claim_1 in theory_node.dependents
    assert :hyp_1 in claim_node.dependents
    assert :exp_1 in hyp_node.dependents
    assert :ev_1 in exp_node.dependents
    assert :claim_1 in ev_node.dependents

    # Justifications (Upstream justifications)
    assert :theory_1 in claim_node.justifications
    assert :claim_1 in hyp_node.justifications
    assert :hyp_1 in exp_node.justifications
    assert :exp_1 in ev_node.justifications
    assert :ev_1 in claim_node.justifications
  end

  test "Belief degradation: partial evidence refutation degrades claim and theory confidence", %{state: state} do
    # Set up theory with 1.0 confidence, claim with 0.8 confidence
    theory = %EvidenceNode{id: :theory_1, type: :theory, name: "Theory 1", value: 1.0, validity: :valid}
    claim = %EvidenceNode{id: :claim_1, type: :claim, name: "Claim 1", value: 0.8, validity: :valid}
    evidence = %EvidenceNode{id: :ev_1, type: :evidence, name: "Evidence 1", validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim)
      |> EvidenceEngine.add_node(evidence)
      |> EvidenceEngine.add_relation(:theory_1, :predicts, :claim_1)
      |> EvidenceEngine.add_relation(:ev_1, :supports, :claim_1)

    # Refute evidence
    state = EvidenceEngine.refute_evidence(state, :ev_1)

    # Assert claim degrades confidence (0.8 * 0.7 = 0.56)
    claim_node = Map.get(state.evidence_graph, :claim_1)
    assert_in_delta claim_node.value, 0.56, 0.001
    assert claim_node.validity == :valid # not invalid since >= 0.25

    # Assert theory degrades confidence (average of active claims, which is 0.56)
    theory_node = Map.get(state.evidence_graph, :theory_1)
    assert_in_delta theory_node.value, 0.56, 0.001
    assert theory_node.validity == :valid
  end

  test "Cascade Invalidation: theory dropping below 0.25 is retired and invalidates predictions", %{state: state} do
    theory = %EvidenceNode{id: :theory_1, type: :theory, name: "Theory 1", value: 0.3, validity: :valid}
    claim = %EvidenceNode{id: :claim_1, type: :claim, name: "Claim 1", value: 0.3, validity: :valid}
    hyp = %EvidenceNode{id: :hyp_1, type: :hypothesis, name: "Hyp 1", validity: :valid}
    exp = %EvidenceNode{id: :exp_1, type: :experiment, name: "Exp 1", value: 1.0, validity: :valid}
    evidence = %EvidenceNode{id: :ev_1, type: :evidence, name: "Evidence 1", validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim)
      |> EvidenceEngine.add_node(hyp)
      |> EvidenceEngine.add_node(exp)
      |> EvidenceEngine.add_node(evidence)
      |> EvidenceEngine.add_relation(:theory_1, :predicts, :claim_1)
      |> EvidenceEngine.add_relation(:claim_1, :predicts, :hyp_1)
      |> EvidenceEngine.add_relation(:hyp_1, :tested_by, :exp_1)
      |> EvidenceEngine.add_relation(:exp_1, :generates, :ev_1)
      |> EvidenceEngine.add_relation(:ev_1, :supports, :claim_1)

    # Refute evidence -> claim confidence drops below 0.25 (0.3 * 0.7 = 0.21)
    # Claim validity becomes :invalid, Theory average drops to 0.21, Theory becomes :invalid (retired)
    state = EvidenceEngine.refute_evidence(state, :ev_1)

    # Assert Claim is invalid
    claim_node = Map.get(state.evidence_graph, :claim_1)
    assert claim_node.validity == :invalid

    # Assert Theory is invalid
    theory_node = Map.get(state.evidence_graph, :theory_1)
    assert theory_node.validity == :invalid
    assert theory_node.value < 0.25

    # Assert Hyp and Exp are cascade-invalidated
    hyp_node = Map.get(state.evidence_graph, :hyp_1)
    assert hyp_node.validity == :invalid

    exp_node = Map.get(state.evidence_graph, :exp_1)
    assert exp_node.validity == :invalid
    assert exp_node.value == 0.0 # priority deprecated
  end

  test "Replication threshold: 3 failed replications invalidates evidence", %{state: state} do
    theory = %EvidenceNode{id: :theory_1, type: :theory, name: "Theory 1", value: 0.3, validity: :valid}
    claim = %EvidenceNode{id: :claim_1, type: :claim, name: "Claim 1", value: 0.3, validity: :valid}
    evidence = %EvidenceNode{id: :ev_1, type: :evidence, name: "Evidence 1", value: 1.0, validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim)
      |> EvidenceEngine.add_node(evidence)
      |> EvidenceEngine.add_relation(:theory_1, :predicts, :claim_1)
      |> EvidenceEngine.add_relation(:ev_1, :supports, :claim_1)

    # 1. First failed replication
    state = EvidenceEngine.register_failed_replication(state, :rep_1, :ev_1)
    ev_node = Map.get(state.evidence_graph, :ev_1)
    assert_in_delta ev_node.value, 0.8, 0.001
    assert ev_node.validity == :valid

    # 2. Second failed replication
    state = EvidenceEngine.register_failed_replication(state, :rep_2, :ev_1)
    ev_node = Map.get(state.evidence_graph, :ev_1)
    assert_in_delta ev_node.value, 0.4, 0.001 # 0.8 * 0.5
    assert ev_node.validity == :contested

    # 3. Third failed replication triggers full refutation cascade (claim drops below 0.25)
    state = EvidenceEngine.register_failed_replication(state, :rep_3, :ev_1)
    ev_node = Map.get(state.evidence_graph, :ev_1)
    assert ev_node.validity == :invalid

    claim_node = Map.get(state.evidence_graph, :claim_1)
    assert claim_node.validity == :invalid

    theory_node = Map.get(state.evidence_graph, :theory_1)
    assert theory_node.validity == :invalid
  end

  test "Event-driven updates: emits PubSub events during refutations and retirements", %{pubsub_active: pubsub_active, state: state} do
    if pubsub_active do
      theory = %EvidenceNode{id: :theory_1, type: :theory, name: "Theory 1", value: 0.3, validity: :valid}
      claim = %EvidenceNode{id: :claim_1, type: :claim, name: "Claim 1", value: 0.3, validity: :valid}
      evidence = %EvidenceNode{id: :ev_1, type: :evidence, name: "Evidence 1", validity: :valid}
      discovery = %EvidenceNode{id: :disc_1, type: :discovery, name: "Discovery 1", validity: :valid}

      state =
        state
        |> EvidenceEngine.add_node(theory)
        |> EvidenceEngine.add_node(claim)
        |> EvidenceEngine.add_node(evidence)
        |> EvidenceEngine.add_node(discovery)
        |> EvidenceEngine.add_relation(:theory_1, :predicts, :claim_1)
        |> EvidenceEngine.add_relation(:ev_1, :supports, :claim_1)
        # discovery depends on theory_1
        |> EvidenceEngine.add_relation(:theory_1, :justifies, :disc_1)

      # Trigger refutation
      _state = EvidenceEngine.refute_evidence(state, :ev_1)

      # Assert all event types are broadcasted
      assert_receive {:evidence_refuted, :ev_1}
      assert_receive {:theory_confidence_changed, :theory_1, _new_conf}
      assert_receive {:theory_retired, :theory_1}
      assert_receive {:discovery_retired, :disc_1}
    else
      Logger.info("Skipping PubSub event emission verification because PubSub is not active.")
    end
  end

  test "Stress Test 1: Circular Dependency Survival", %{state: state} do
    # Theory A -> Claim A -> Exp A -> Ev A -> Theory B -> Claim B -> Exp B -> Ev B -> Theory A
    t_a = %EvidenceNode{id: :theory_a, type: :theory, name: "Theory A", value: 0.8, validity: :valid}
    c_a = %EvidenceNode{id: :claim_a, type: :claim, name: "Claim A", value: 0.8, validity: :valid}
    e_a = %EvidenceNode{id: :exp_a, type: :experiment, name: "Exp A", validity: :valid}
    ev_a = %EvidenceNode{id: :ev_a, type: :evidence, name: "Ev A", validity: :valid}

    t_b = %EvidenceNode{id: :theory_b, type: :theory, name: "Theory B", value: 0.8, validity: :valid}
    c_b = %EvidenceNode{id: :claim_b, type: :claim, name: "Claim B", value: 0.8, validity: :valid}
    e_b = %EvidenceNode{id: :exp_b, type: :experiment, name: "Exp B", validity: :valid}
    ev_b = %EvidenceNode{id: :ev_b, type: :evidence, name: "Ev B", validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(t_a)
      |> EvidenceEngine.add_node(c_a)
      |> EvidenceEngine.add_node(e_a)
      |> EvidenceEngine.add_node(ev_a)
      |> EvidenceEngine.add_node(t_b)
      |> EvidenceEngine.add_node(c_b)
      |> EvidenceEngine.add_node(e_b)
      |> EvidenceEngine.add_node(ev_b)
      |> EvidenceEngine.add_relation(:theory_a, :predicts, :claim_a)
      |> EvidenceEngine.add_relation(:claim_a, :predicts, :exp_a)
      |> EvidenceEngine.add_relation(:exp_a, :generates, :ev_a)
      |> EvidenceEngine.add_relation(:ev_a, :supports, :theory_b)
      |> EvidenceEngine.add_relation(:theory_b, :predicts, :claim_b)
      |> EvidenceEngine.add_relation(:claim_b, :predicts, :exp_b)
      |> EvidenceEngine.add_relation(:exp_b, :generates, :ev_b)
      |> EvidenceEngine.add_relation(:ev_b, :supports, :theory_a)

    # Invalidate Ev A - propagation should terminate successfully
    assert %State{} = updated_state = EvidenceEngine.refute_evidence(state, :ev_a)

    # Verify that Ev A is invalid
    assert Map.get(updated_state.evidence_graph, :ev_a).validity == :invalid
  end

  test "Stress Test 2: Event Storm Resistance (Scale propagation)", %{state: state} do
    # Add 1 theory, 20 claims, 50 hypotheses, 100 experiments, 200 evidence nodes
    theory = %EvidenceNode{id: :theory_scale, type: :theory, name: "Theory Scale", value: 0.9, validity: :valid}
    state = EvidenceEngine.add_node(state, theory)

    # 1. Spawn claims
    state =
      Enum.reduce(1..20, state, fn i, acc ->
        claim_id = String.to_atom("claim_s_#{i}")
        claim = %EvidenceNode{id: claim_id, type: :claim, name: "Claim #{i}", value: 0.9, validity: :valid}
        acc
        |> EvidenceEngine.add_node(claim)
        |> EvidenceEngine.add_relation(:theory_scale, :predicts, claim_id)
      end)

    # 2. Spawn hypotheses and link to claims
    state =
      Enum.reduce(1..50, state, fn i, acc ->
        hyp_id = String.to_atom("hyp_s_#{i}")
        hyp = %EvidenceNode{id: hyp_id, type: :hypothesis, name: "Hyp #{i}", validity: :valid}
        claim_index = rem(i, 20) + 1
        claim_id = String.to_atom("claim_s_#{claim_index}")
        acc
        |> EvidenceEngine.add_node(hyp)
        |> EvidenceEngine.add_relation(claim_id, :predicts, hyp_id)
      end)

    # 3. Spawn experiments and link to hypotheses
    state =
      Enum.reduce(1..100, state, fn i, acc ->
        exp_id = String.to_atom("exp_s_#{i}")
        exp = %EvidenceNode{id: exp_id, type: :experiment, name: "Exp #{i}", value: 1.0, validity: :valid}
        hyp_index = rem(i, 50) + 1
        hyp_id = String.to_atom("hyp_s_#{hyp_index}")
        acc
        |> EvidenceEngine.add_node(exp)
        |> EvidenceEngine.add_relation(hyp_id, :tested_by, exp_id)
      end)

    # 4. Spawn evidence and link to experiments + claims (to close loop)
    state =
      Enum.reduce(1..200, state, fn i, acc ->
        ev_id = String.to_atom("ev_s_#{i}")
        ev = %EvidenceNode{id: ev_id, type: :evidence, name: "Ev #{i}", validity: :valid}
        exp_index = rem(i, 100) + 1
        exp_id = String.to_atom("exp_s_#{exp_index}")
        claim_index = rem(i, 20) + 1
        claim_id = String.to_atom("claim_s_#{claim_index}")
        acc
        |> EvidenceEngine.add_node(ev)
        |> EvidenceEngine.add_relation(exp_id, :generates, ev_id)
        |> EvidenceEngine.add_relation(ev_id, :supports, claim_id)
      end)

    # Refute 1 evidence node
    start_time = System.monotonic_time(:millisecond)
    updated_state = EvidenceEngine.refute_evidence(state, :ev_s_1)
    end_time = System.monotonic_time(:millisecond)

    duration = end_time - start_time
    Logger.info("⚡ JTMS Scale Test: propagation of 370+ node graph completed in #{duration}ms.")

    # Invalidation should have happened to target claim/experiments recursively
    refuted_node = Map.get(updated_state.evidence_graph, :ev_s_1)
    assert refuted_node.validity == :invalid
    assert duration < 200 # Must complete very quickly
  end

  test "Stress Test 3: Contradictory Evidence balance", %{state: state} do
    # Theory has 2 claims.
    # Claim A is supported by Ev A (valid).
    # Claim B is refuted by Ev B (invalidated).
    theory = %EvidenceNode{id: :theory_t, type: :theory, name: "Theory T", value: 1.0, validity: :valid}
    claim_a = %EvidenceNode{id: :claim_a, type: :claim, name: "Claim A", value: 0.9, validity: :valid}
    claim_b = %EvidenceNode{id: :claim_b, type: :claim, name: "Claim B", value: 0.9, validity: :valid}
    ev_a = %EvidenceNode{id: :ev_a, type: :evidence, name: "Ev A", validity: :valid}
    ev_b = %EvidenceNode{id: :ev_b, type: :evidence, name: "Ev B", validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim_a)
      |> EvidenceEngine.add_node(claim_b)
      |> EvidenceEngine.add_node(ev_a)
      |> EvidenceEngine.add_node(ev_b)
      |> EvidenceEngine.add_relation(:theory_t, :predicts, :claim_a)
      |> EvidenceEngine.add_relation(:theory_t, :predicts, :claim_b)
      |> EvidenceEngine.add_relation(:ev_a, :supports, :claim_a)
      |> EvidenceEngine.add_relation(:ev_b, :supports, :claim_b)

    # Refute Ev B
    state = EvidenceEngine.refute_evidence(state, :ev_b)

    # Verify claim_b degraded (0.9 * 0.7 = 0.63)
    assert_in_delta Map.get(state.evidence_graph, :claim_b).value, 0.63, 0.001

    # Verify claim_a remained unaffected (0.9)
    assert Map.get(state.evidence_graph, :claim_a).value == 0.9

    # Verify Theory T average confidence is (0.9 + 0.63)/2 = 0.765
    theory_node = Map.get(state.evidence_graph, :theory_t)
    assert_in_delta theory_node.value, 0.765, 0.001
    assert theory_node.validity == :valid # Since 0.765 >= 0.25, not retired!
  end

  test "Metadata updates: records provenance, confidence history, and last_updated_at", %{state: state} do
    theory = %EvidenceNode{id: :theory_t, type: :theory, name: "Theory T", value: 1.0, validity: :valid}
    claim = %EvidenceNode{id: :claim_c, type: :claim, name: "Claim C", value: 1.0, validity: :valid}
    evidence = %EvidenceNode{id: :ev_e, type: :evidence, name: "Ev E", validity: :valid}

    state =
      state
      |> EvidenceEngine.add_node(theory)
      |> EvidenceEngine.add_node(claim)
      |> EvidenceEngine.add_node(evidence)
      |> EvidenceEngine.add_relation(:theory_t, :predicts, :claim_c)
      |> EvidenceEngine.add_relation(:ev_e, :supports, :claim_c)

    # Refute Ev E
    state = EvidenceEngine.refute_evidence(state, :ev_e)

    # Verify evidence metadata
    ev_node = Map.get(state.evidence_graph, :ev_e)
    assert "refuted" in ev_node.metadata.provenance
    assert ev_node.metadata.last_updated_at != nil

    # Verify claim metadata
    claim_node = Map.get(state.evidence_graph, :claim_c)
    assert Enum.any?(claim_node.metadata.provenance, &String.contains?(&1, "degraded_by_evidence:ev_e"))
    assert length(claim_node.metadata.confidence_history) > 0
    [first_history_entry | _] = claim_node.metadata.confidence_history
    assert_in_delta first_history_entry.value, 0.7, 0.001

    # Verify theory metadata
    theory_node = Map.get(state.evidence_graph, :theory_t)
    assert Enum.any?(theory_node.metadata.provenance, &String.contains?(&1, "recalculated_from_claim:claim_c"))
    assert length(theory_node.metadata.confidence_history) > 0
    [theory_history_entry | _] = theory_node.metadata.confidence_history
    assert_in_delta theory_history_entry.value, 0.7, 0.001
  end
end
