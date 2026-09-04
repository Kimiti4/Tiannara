defmodule Tiannara.Constitution.Registry do
  @moduledoc """
  The default registry of constitutional invariants. Each probe re-executes a
  live enforcement mechanism so the suite fails if any guarantee is weakened.

  Constitutional basis: "Capability must never outpace verification",
  "Never optimize for appearing correct. Optimize for being correct."
  """

  alias Tiannara.Constitution.Invariant

  alias Tiannara.SelfImprovement.{Pipeline, Proposal, GateResult}
  alias Tiannara.Graph.{InMemory, Persistent, Audit}
  alias Tiannara.Communication.Director, as: CommDirector
  alias Tiannara.Communication.DedupLedger
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Sentinel.Authority, as: SentinelAuthority
  alias Tiannara.Sentinel.Reference, as: SentinelReference
  alias Tiannara.Research.Authority, as: ResearchAuthority
  alias Tiannara.Research.Director, as: ResearchDirector

  def default_invariants do
    [
      Invariant.new(:no_deployment_without_validation,
        "No deployment occurs without validation", :self_improvement,
        &probe_no_deployment_without_validation/0),

      Invariant.new(:no_self_governed_constitutional_change,
        "No constitutional rule is modified by the subsystem it governs", :self_improvement,
        &probe_no_self_governed_constitutional_change/0),

      Invariant.new(:no_autonomous_bypass_of_human_authorization,
        "No autonomous proposal bypasses human authorization", :self_improvement,
        &probe_no_autonomous_bypass_of_human_authorization/0),

      Invariant.new(:protected_core_immutable_without_independent_verification,
        "Protected core is immutable without independent verification", :self_improvement,
        &probe_protected_core_immutable/0),

      Invariant.new(:no_contradiction_silently_discarded,
        "No contradiction is silently discarded", :knowledge,
        &probe_no_contradiction_silently_discarded/0),

      Invariant.new(:no_lineage_orphaned_from_audit_log,
        "No lineage mutation is orphaned from the audit log", :knowledge,
        &probe_no_lineage_orphaned/0),

      Invariant.new(:constitutional_concerns_reach_human_awareness,
        "Constitutional concerns always reach human awareness", :communication,
        &probe_constitutional_concerns_reach_human/0),

      Invariant.new(:no_communication_spam,
        "Communication never spams duplicates", :communication,
        &probe_no_communication_spam/0),

      Invariant.new(:sentinel_never_executes,
        "The Sentinel never executes actions", :authority,
        &probe_sentinel_never_executes/0),

      Invariant.new(:research_director_never_executes,
        "The Research Director never executes experiments", :authority,
        &probe_research_director_never_executes/0)
    ]
  end

  # --- probes -------------------------------------------------------------

  defp probe_no_deployment_without_validation do
    p = %Proposal{targets: [:inference_module]}
    gates = Map.delete(passing_gates(), :adversarial_validation)

    case Pipeline.request_deployment(p, gates, deployment_enabled: true) do
      {:error, {:gates_failed, _}} -> :ok
      other -> {:error, {:expected_block, other}}
    end
  end

  defp probe_no_self_governed_constitutional_change do
    p = %Proposal{targets: [:constitutional]}

    gates =
      Map.put(passing_gates(), :independent_verification,
        gr(:independent_verification, true, :self_improvement))

    case Pipeline.request_deployment(p, gates, deployment_enabled: true) do
      {:error, :protected_core_requires_independent_verification} -> :ok
      other -> {:error, {:expected_block, other}}
    end
  end

  defp probe_no_autonomous_bypass_of_human_authorization do
    p = %Proposal{targets: [:inference_module]}
    gates = Map.delete(passing_gates(), :human_approval)

    case Pipeline.request_deployment(p, gates, deployment_enabled: true) do
      {:error, {:gates_failed, [:human_approval]}} -> :ok
      other -> {:error, {:expected_block, other}}
    end
  end

  defp probe_protected_core_immutable do
    p = %Proposal{targets: [:safety]}

    case Pipeline.request_deployment(p, passing_gates(), deployment_enabled: true) do
      {:error, :protected_core_requires_independent_verification} -> :ok
      other -> {:error, {:expected_block, other}}
    end
  end

  defp probe_no_contradiction_silently_discarded do
    g = InMemory.new()
    g = InMemory.add_node(g, :s1, %{})
    g = InMemory.add_node(g, :s2, %{})
    g = InMemory.add_node(g, :x, %{})
    {:ok, g} = InMemory.add_edge(g, :c1, :s1, :x, :claims, %{quantity: :x, value: 1})
    {:ok, g} = InMemory.add_edge(g, :c2, :s2, :x, :claims, %{quantity: :x, value: 2})

    if Audit.find_contradictions(g) != [],
      do: :ok,
      else: {:error, :contradiction_not_detected}
  end

  defp probe_no_lineage_orphaned do
    {:ok, pid} = Persistent.start_link([])
    Persistent.add_node(pid, :a, %{})
    Persistent.add_edge(pid, :e1, :a, :a, :rel, %{})
    log = Persistent.event_log(pid)
    GenServer.stop(pid)

    has_node = Enum.any?(log, &match?({:add_node, :a, _}, &1))
    has_edge = Enum.any?(log, &match?({:add_edge, :e1, :a, :a, :rel, _}, &1))

    if has_node and has_edge and length(log) == 2,
      do: :ok,
      else: {:error, :mutation_orphaned}
  end

  defp probe_constitutional_concerns_reach_human do
    e = EpistemicEvent.new(:constitutional_concern, severity: :low, payload: %{}, confidence: 0.1)

    if CommDirector.decide(e, %{significance_threshold: 0.99}).notify,
      do: :ok,
      else: {:error, :constitutional_concern_suppressed}
  end

  defp probe_no_communication_spam do
    e = EpistemicEvent.new(:anomaly_detected, severity: :high, payload: %{k: 1}, confidence: 0.8)
    d1 = CommDirector.decide(e, %{})
    ledger = DedupLedger.record(DedupLedger.new(), d1.dedup_key)
    d2 = CommDirector.decide(e, %{ledger: ledger})

    if d1.notify and not d2.notify,
      do: :ok,
      else: {:error, :spam_not_suppressed}
  end

  defp probe_sentinel_never_executes do
    try do
      SentinelAuthority.assert_no_action_authority!(SentinelReference)
      :ok
    rescue
      _ -> {:error, :sentinel_has_action_authority}
    end
  end

  defp probe_research_director_never_executes do
    try do
      ResearchAuthority.assert_no_execution_authority!(ResearchDirector)
      :ok
    rescue
      _ -> {:error, :research_director_has_execution_authority}
    end
  end

  # --- helpers ------------------------------------------------------------

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
end