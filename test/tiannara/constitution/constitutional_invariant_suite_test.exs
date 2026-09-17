defmodule Tiannara.Constitution.InvariantSuiteTest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.{Pipeline, Proposal, GateResult}
  alias Tiannara.Communication.Director, as: CommDirector
  alias Tiannara.Communication.DedupLedger
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Sentinel.Authority, as: SentinelAuthority
  alias Tiannara.Sentinel.Reference, as: SentinelReference
  alias Tiannara.Research.Authority, as: ResearchAuthority
  alias Tiannara.Research.Director, as: ResearchDirector
  alias Tiannara.Graph.{Persistent, InMemory, Audit}

  @moduletag :constitutional_invariants

  defp gr(gate, passed, source),
    do: %GateResult{gate: gate, passed: passed, source: source, evidence: []}

  defp passing_gates do
    %{
      tests: gr(:tests, true, :ci),
      benchmark: gr(:benchmark, true, :ci),
      adversarial_validation: gr(:adversarial_validation, true, :adversarial_lab),
      constitutional_review: gr(:constitutional_review, true, :constitutional_reviewer),
      human_approval: gr(:human_approval, true, :human)
    }
  end

  test "INVARIANT: no deployment occurs without validation" do
    p = %Proposal{targets: [:inference_module]}
    gates = Map.delete(passing_gates(), :adversarial_validation)

    assert {:error, {:gates_failed, _}} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "INVARIANT: no constitutional rule is modified by the subsystem it governs" do
    p = %Proposal{targets: [:constitutional]}

    gates =
      Map.put(passing_gates(), :independent_verification,
        gr(:independent_verification, true, :self_improvement))

    assert {:error, :protected_core_requires_independent_verification} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "INVARIANT: no autonomous proposal bypasses human authorization" do
    p = %Proposal{targets: [:inference_module]}
    gates = Map.delete(passing_gates(), :human_approval)

    assert {:error, {:gates_failed, [:human_approval]}} =
             Pipeline.request_deployment(p, gates, deployment_enabled: true)
  end

  test "INVARIANT: protected core is immutable without independent verification" do
    p = %Proposal{targets: [:safety]}

    assert {:error, :protected_core_requires_independent_verification} =
             Pipeline.request_deployment(p, passing_gates(), deployment_enabled: true)
  end

  test "INVARIANT: no contradiction is silently discarded" do
    g = InMemory.new()
    g = InMemory.add_node(g, :s1, %{})
    g = InMemory.add_node(g, :s2, %{})
    g = InMemory.add_node(g, :x, %{})
    {:ok, g} = InMemory.add_edge(g, :c1, :s1, :x, :claims, %{quantity: :x, value: 1})
    {:ok, g} = InMemory.add_edge(g, :c2, :s2, :x, :claims, %{quantity: :x, value: 2})

    assert Audit.find_contradictions(g) != []
  end

  test "INVARIANT: no lineage mutation is orphaned from the audit log" do
    {:ok, pid} = Persistent.start_link([])
    Persistent.add_node(pid, :a, %{})
    Persistent.add_edge(pid, :e1, :a, :a, :rel, %{})

    log = Persistent.event_log(pid)
    assert length(log) == 2
    assert Enum.any?(log, &match?({:add_node, :a, _}, &1))
    assert Enum.any?(log, &match?({:add_edge, :e1, :a, :a, :rel, _}, &1))
    GenServer.stop(pid)
  end

  test "INVARIANT: constitutional concerns always reach human awareness" do
    e = EpistemicEvent.new(:constitutional_concern, severity: :low, payload: %{}, confidence: 0.1)
    assert CommDirector.decide(e, %{significance_threshold: 0.99}).notify
  end

  test "INVARIANT: communication never spams duplicates" do
    e = EpistemicEvent.new(:anomaly_detected, severity: :high, payload: %{k: 1}, confidence: 0.8)
    d1 = CommDirector.decide(e, %{})
    ledger = DedupLedger.record(DedupLedger.new(), d1.dedup_key)

    refute CommDirector.decide(e, %{ledger: ledger}).notify
  end

  test "INVARIANT: the Sentinel never executes actions" do
    assert :ok = SentinelAuthority.assert_no_action_authority!(SentinelReference)
  end

  test "INVARIANT: the Research Director never executes experiments" do
    assert :ok = ResearchAuthority.assert_no_execution_authority!(ResearchDirector)
  end
end