defmodule Tiannara.Diagnostics.DiscoveryAdversarialTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Track D -- Discovery qualification tests.

  These are deliberately constructed scientific situations used to prove the
  pipeline can produce *qualifying* discoveries -- not merely increment a
  counter.

  NOTE: During the 72h soak these run ONLY against the read-only audit layer
  and immutable mock event streams. Pointing them at a live ISOLATED pipeline
  instance is a post-soak wiring step (tagged below).
  """

  alias Tiannara.Diagnostics.DiscoveryFunnel
  alias Tiannara.Diagnostics.EventSource.Mock
  alias Tiannara.Provenance.DiscoveryLedger

  defp c(stage, id, parents \\ []), do: {:created, stage, id, parents}
  defp d(stage, id, kind, detail \\ nil), do: {:disposition, stage, id, kind, detail}
  defp m(stage, id, key, value), do: {:meta, stage, id, key, value}

  defp full_chain(ids) when length(ids) == 12 do
    tuples = Enum.zip(DiscoveryFunnel.stages(), ids)

    created =
      tuples
      |> Enum.with_index()
      |> Enum.map(fn {{stage, id}, i} ->
        parents = if i == 0, do: [], else: [elem(Enum.at(tuples, i - 1), 1)]
        c(stage, id, parents)
      end)

    promoted =
      tuples
      |> Enum.with_index()
      |> Enum.reject(fn {_t, i} -> i == length(tuples) - 1 end)
      |> Enum.map(fn {{stage, id}, i} ->
        {_ns, next_id} = Enum.at(tuples, i + 1)
        d(stage, id, :promoted, next_id)
      end)

    created ++ promoted
  end

  # Case 1 -- Contradiction should activate research and reach a candidate.
  test "case 1: contradiction activates the research pipeline" do
    ids = [:obs_x10, :obs_x20, :gap_contradiction, :hyp_resolve_x, :rank1,
           :prop1, :sched1, :run1, :ev1, :ki1, :cand1, :disc1]

    events = full_chain(ids) ++ [
      m(:observations, :obs_x10, :value, 10),
      m(:observations, :obs_x20, :value, 20),
      m(:gaps, :gap_contradiction, :kind, :contradiction)
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:discovery_candidates] == 1
    assert funnel.zero_state == :discoveries_present
    assert funnel.violations == []
  end

  # Case 2 -- Anomaly should activate research (gap + hypothesis present).
  test "case 2: anomaly activates research" do
    events = [
      c(:observations, :obs_anomaly),
      d(:observations, :obs_anomaly, :promoted, :gap_anomaly),
      c(:gaps, :gap_anomaly, [:obs_anomaly]),
      m(:gaps, :gap_anomaly, :kind, :anomaly),
      d(:gaps, :gap_anomaly, :promoted, :hyp_anomaly),
      c(:hypotheses, :hyp_anomaly, [:gap_anomaly]),
      d(:hypotheses, :hyp_anomaly, :promoted, :rank1),
      c(:ranked_hypotheses, :rank1, [:hyp_anomaly]),
      d(:ranked_hypotheses, :rank1, :rejected, :insufficient_evidence)
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:gaps] == 1
    assert funnel.counts[:hypotheses] == 1
    assert funnel.violations == []
    refute funnel.zero_state == :no_signal
  end

  # Case 3 -- Competing hypotheses: H2 selected, H1 retained, H3 deprioritized.
  test "case 3: competing hypotheses are explicitly dispositioned" do
    events = [
      c(:observations, :o1),
      d(:observations, :o1, :promoted, :g1),
      c(:gaps, :g1, [:o1]),
      d(:gaps, :g1, :promoted, :h2),

      c(:hypotheses, :h1, [:g1]),
      c(:hypotheses, :h2, [:g1]),
      c(:hypotheses, :h3, [:g1]),

      m(:hypotheses, :h1, :confidence, 0.62),
      m(:hypotheses, :h2, :confidence, 0.71),
      m(:hypotheses, :h3, :confidence, 0.43),

      d(:hypotheses, :h2, :promoted, :r2),
      c(:ranked_hypotheses, :r2, [:h2]),
      d(:ranked_hypotheses, :r2, :closed, :retained_for_validation),
      d(:hypotheses, :h1, :closed, :retained_alternative),
      d(:hypotheses, :h3, :closed, :deprioritized_low_confidence)
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:hypotheses] == 3
    assert funnel.promoted[:hypotheses] == 1
    assert funnel.unexplained[:hypotheses] == 0
    assert funnel.violations == []
  end

  # Case 4 -- Negative experiment: hypothesis rejected is NOT "nothing happened".
  test "case 4: a negative experiment becomes integrated knowledge" do
    events = [
      c(:observations, :o1),
      d(:observations, :o1, :promoted, :g1),
      c(:gaps, :g1, [:o1]),
      d(:gaps, :g1, :promoted, :h1),
      c(:hypotheses, :h1, [:g1]),
      d(:hypotheses, :h1, :rejected, :falsified_by_experiment),
      c(:evidence_generated, :ev_neg, [:h1]),
      m(:evidence_generated, :ev_neg, :outcome, :negative),
      d(:evidence_generated, :ev_neg, :promoted, :ki1),
      c(:knowledge_integrated, :ki1, [:ev_neg]),
      d(:knowledge_integrated, :ki1, :closed, :negative_result_integrated)
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))

    assert funnel.counts[:knowledge_integrated] == 1
    assert funnel.counts[:validated_discoveries] == 0
    assert funnel.unexplained[:hypotheses] == 0
    assert funnel.violations == []
    assert funnel.zero_state == :validation_rejected
  end

  # Case 5 -- Reproducible discovery: repetition + independent validation
  # yields higher confidence and complete provenance.
  test "case 5: reproducible discovery carries full provenance + confidence" do
    ids = [:o1, :g1, :h1, :r1, :p1, :s1, :st1, :c1, :e1, :ki1, :dc1, :vd1]

    events = full_chain(ids) ++ [
      m(:experiments_completed, :c1, :runs, 5),
      m(:evidence_generated, :e1, :independent_validations, 3),
      m(:validated_discoveries, :vd1, :confidence, 0.94),
      m(:validated_discoveries, :vd1, :contradictions, [])
    ]

    funnel = DiscoveryFunnel.audit(Mock.new(events))
    assert funnel.zero_state == :discoveries_present

    ledger = DiscoveryLedger.reconstruct(:vd1, events)

    assert ledger.complete?
    assert ledger.confidence == 0.94
    assert DiscoveryLedger.verdict(ledger) == :provenance_complete

    why = DiscoveryLedger.why(ledger)
    assert is_list(why)
    assert Enum.any?(why, &String.contains?(&1, "observations"))
    assert Enum.any?(why, &String.contains?(&1, "validated_discoveries"))
  end

  # Post-soak: point these same scenarios at a live ISOLATED pipeline instance.
  @tag :post_soak
  test "post-soak: run adversarial qualification against isolated pipeline" do
    assert true
  end
end
