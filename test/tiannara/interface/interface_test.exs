defmodule Tiannara.Interface.InterfaceTest do
  use ExUnit.Case, async: true

  alias Tiannara.Diagnostics.DiscoveryFunnel
  alias Tiannara.Diagnostics.EventSource.Mock, as: FunnelMock
  alias Tiannara.Repro.Manifest
  alias Tiannara.Soak.{TimeAccounting, RecoveryGate}
  alias Tiannara.Memory.IncidentDistiller
  alias Tiannara.Interface.{ViewModel, PipelinePanel}
  alias Tiannara.Interface.Renderer.Console

  defp c(stage, id), do: {:created, stage, id, []}
  defp d(stage, id, kind, detail \\ nil), do: {:disposition, stage, id, kind, detail}

  defp funnel_fixture do
    obs = Enum.map(1..10, &:"o#{&1}")
    gaps = Enum.map(1..5, &:"g#{&1}")
    hyps = Enum.map(1..7, &:"h#{&1}")
    ranked = Enum.map(1..4, &:"r#{&1}")
    proposed = Enum.map(1..4, &:"p#{&1}")
    sched = Enum.map(1..3, &:"s#{&1}")
    started = Enum.map(1..3, &:"st#{&1}")
    completed = Enum.map(1..3, &:"c#{&1}")
    evidence = Enum.map(1..3, &:"e#{&1}")
    ki = Enum.map(1..3, &:"k#{&1}")
    cands = Enum.map(1..3, &:"dc#{&1}")
    disc = Enum.map(1..2, &:"vd#{&1}")

    events =
      Enum.map(obs, &c(:observations, &1)) ++
        Enum.map(obs, &d(:observations, &1, :promoted)) ++
        Enum.map(gaps, &c(:gaps, &1)) ++
        Enum.map(gaps, &d(:gaps, &1, :promoted)) ++
        Enum.map(hyps, &c(:hypotheses, &1)) ++
        [
          d(:hypotheses, :h1, :promoted),
          d(:hypotheses, :h2, :promoted),
          d(:hypotheses, :h3, :promoted),
          d(:hypotheses, :h4, :promoted),
          d(:hypotheses, :h5, :rejected, :insufficient_evidence),
          d(:hypotheses, :h6, :rejected, :insufficient_evidence),
          d(:hypotheses, :h7, :rejected, :duplicate)
        ] ++
        Enum.map(ranked, &c(:ranked_hypotheses, &1)) ++
        Enum.map(ranked, &d(:ranked_hypotheses, &1, :promoted)) ++
        Enum.map(proposed, &c(:experiments_proposed, &1)) ++
        [
          d(:experiments_proposed, :p1, :promoted),
          d(:experiments_proposed, :p2, :promoted),
          d(:experiments_proposed, :p3, :promoted),
          d(:experiments_proposed, :p4, :rejected, :resource_constraint)
        ] ++
        Enum.map(sched, &c(:experiments_scheduled, &1)) ++
        Enum.map(sched, &d(:experiments_scheduled, &1, :promoted)) ++
        Enum.map(started, &c(:experiments_started, &1)) ++
        Enum.map(started, &d(:experiments_started, &1, :promoted)) ++
        Enum.map(completed, &c(:experiments_completed, &1)) ++
        Enum.map(completed, &d(:experiments_completed, &1, :promoted)) ++
        Enum.map(evidence, &c(:evidence_generated, &1)) ++
        Enum.map(evidence, &d(:evidence_generated, &1, :promoted)) ++
        Enum.map(ki, &c(:knowledge_integrated, &1)) ++
        Enum.map(ki, &d(:knowledge_integrated, &1, :promoted)) ++
        Enum.map(cands, &c(:discovery_candidates, &1)) ++
        [
          d(:discovery_candidates, :dc1, :promoted),
          d(:discovery_candidates, :dc2, :promoted),
          d(:discovery_candidates, :dc3, :rejected, :constitutional_restriction)
        ] ++
        Enum.map(disc, &c(:validated_discoveries, &1))

    DiscoveryFunnel.audit(FunnelMock.new(events))
  end

  test "dashboard composes all panels and surfaces the full funnel" do
    funnel = funnel_fixture()

    t = TimeAccounting.compute(3 * 3600 + 52 * 60, 0, 3 * 3600 + 40 * 60, restarted?: true)
    manifest = Manifest.capture("exp-soak-ui", seed: 1) |> Manifest.with_recovery(:gate_open, t)

    dossier = %{
      observation: "valid compound DETS records flagged corrupt",
      context: "soak checkpoint validation",
      evidence: "395/398 misclassified",
      cause: "wrong storage-schema assumption",
      recurrence: "395 instances",
      mechanism: "validity derived from key-shape",
      validation: "regression suite passes",
      principle: "derive validity from the storage contract"
    }

    {:ok, principle} = IncidentDistiller.distill(dossier)
    chain = [principle]

    obs = %{
      bottlenecks: [%{interpretation: "discovery_cycle_latency exceeds causal threshold"}],
      watch: [],
      healthy: []
    }

    vm = ViewModel.build(funnel: funnel, manifest: manifest, observatory: obs, knowledge: chain)
    out = Console.render(vm)

    assert out =~ "SCIENTIFIC ACTIVITY"
    assert out =~ "Validated Discoveries"
    assert out =~ "state: discoveries_present"
    assert out =~ "RECOVERY VERIFIED"
    assert out =~ "BOTTLENECK OBSERVATORY"
    assert out =~ "bottlenecks: 1"
    assert out =~ "KNOWLEDGE (offline evolution)"
    assert out =~ "derive validity from the storage contract"
  end

  test "drill_down explains why hypotheses dropped" do
    funnel = funnel_fixture()
    dd = PipelinePanel.drill_down(funnel, :hypotheses)

    assert dd.upstream == 7
    assert dd.downstream == 4
    assert dd.promoted == 4
    assert dd.not_promoted == 3
    assert dd.reasons[:insufficient_evidence] == 2
    assert dd.reasons[:duplicate] == 1
    assert dd.unexplained == 0
    refute dd.silent_loss?

    text = PipelinePanel.render_drill_down(funnel, :hypotheses)
    assert text =~ "3 not promoted"
    assert text =~ "insufficient_evidence"
    assert text =~ "duplicate"
  end

  test "silent loss is surfaced, not hidden" do
    events = [
      c(:observations, :o1),
      d(:observations, :o1, :promoted),
      c(:gaps, :g1),
      d(:gaps, :g1, :promoted),
      c(:hypotheses, :h1)
    ]

    funnel = DiscoveryFunnel.audit(FunnelMock.new(events))
    dd = PipelinePanel.drill_down(funnel, :hypotheses)

    assert dd.silent_loss?
    assert dd.unexplained == 1
    assert PipelinePanel.render(funnel) =~ "⚠"
  end

  test "closed recovery gate is surfaced as unverified" do
    funnel = funnel_fixture()
    t = TimeAccounting.compute(100, 0, 100)
    {:gate_closed, _missing} = RecoveryGate.verdict([])

    manifest =
      Manifest.capture("exp-x", seed: 1)
      |> Manifest.with_recovery({:gate_closed, RecoveryGate.required_checks()}, t)

    vm = ViewModel.build(funnel: funnel, manifest: manifest)
    assert Console.render(vm) =~ "RECOVERY UNVERIFIED"
  end
end
