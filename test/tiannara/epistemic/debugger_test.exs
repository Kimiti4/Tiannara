defmodule Tiannara.Epistemic.DebuggerTest do
  use ExUnit.Case, async: true

  alias Tiannara.Epistemic.{Node, Debugger}

  @moduletag :epistemic_debugger

  defp sample_chain do
    [
      %Node{id: :"obs-1", stage: :observation, content: "X measured as 10 and 20",
            timestamp: "2026-08-13T10:00:00Z", confidence: 1.0,
            responsible_subsystem: :sentinel, disposition: :advanced,
            lineage: [], constitutional_checks: [:evidence_recorded]},

      %Node{id: :"gap-1", stage: :gap, content: "contradiction in X",
            timestamp: "2026-08-13T10:00:01Z", confidence: 0.9,
            responsible_subsystem: :gap_detection, disposition: :advanced,
            lineage: [:"obs-1"], constitutional_checks: [:gap_logged]},

      %Node{id: :"hyp-1", stage: :hypothesis, content: "source B has systematic error",
            timestamp: "2026-08-13T10:00:02Z", confidence: 0.6,
            responsible_subsystem: :research_director, disposition: :advanced,
            lineage: [:"gap-1"], assumptions: ["source A calibrated"],
            unknowns: ["true value of X"], constitutional_checks: [:hypothesis_registered]},

      %Node{id: :"pred-1", stage: :prediction, content: "re-measure yields 10",
            timestamp: "2026-08-13T10:00:03Z", confidence: 0.6,
            responsible_subsystem: :research_director, disposition: :advanced,
            lineage: [:"hyp-1"]},

      %Node{id: :"exp-1", stage: :experiment, content: "controlled re-measurement",
            timestamp: "2026-08-13T10:00:04Z", confidence: 0.7,
            responsible_subsystem: :sandbox, disposition: :advanced,
            lineage: [:"pred-1"], constitutional_checks: [:sandbox_isolated]},

      %Node{id: :"ev-1", stage: :evidence, content: "measured 10",
            timestamp: "2026-08-13T10:00:05Z", confidence: 0.8,
            responsible_subsystem: :sandbox, disposition: :advanced,
            lineage: [:"exp-1"], constitutional_checks: [:evidence_integrity]},

      %Node{id: :"val-1", stage: :validation, content: "prediction confirmed",
            timestamp: "2026-08-13T10:00:06Z", confidence: 0.85,
            responsible_subsystem: :validation, disposition: :advanced,
            lineage: [:"ev-1"], constitutional_checks: [:validation_passed]},

      %Node{id: :"kn-1", stage: :knowledge, content: "X is 10; source B offset",
            timestamp: "2026-08-13T10:00:07Z", confidence: 0.85,
            responsible_subsystem: :memory, disposition: :advanced,
            lineage: [:"val-1"], constitutional_checks: [:knowledge_integrated]},

      %Node{id: :"disc-1", stage: :discovery, content: "true value of X is 10",
            timestamp: "2026-08-13T10:00:08Z", confidence: 0.85,
            responsible_subsystem: :discovery, disposition: :advanced,
            lineage: [:"kn-1"],
            constitutional_checks: [:provenance_complete, :validation_passed]}
    ]
  end

  test "provenance chain traces a discovery back to its observation" do
    dbg = Debugger.new(sample_chain())
    chain = Debugger.provenance_chain(dbg, :"disc-1")

    assert length(chain) == 9
    assert hd(chain).id == :"obs-1"
    assert List.last(chain).id == :"disc-1"

    assert Enum.map(chain, & &1.stage) ==
             [:observation, :gap, :hypothesis, :prediction, :experiment,
              :evidence, :validation, :knowledge, :discovery]
  end

  test "blast radius from the observation reaches the discovery" do
    dbg = Debugger.new(sample_chain())
    blast = Debugger.blast_radius(dbg, :"obs-1")

    assert :"disc-1" in blast
    assert length(blast) == 8
  end

  test "inspect_node reports depth, root, and blast radius" do
    dbg = Debugger.new(sample_chain())
    info = Debugger.inspect_node(dbg, :"ev-1")

    assert info.depth == 6
    assert info.root.id == :"obs-1"
    assert :"disc-1" in info.blast_radius
  end

  test "render_provenance shows the full auditable chain" do
    dbg = Debugger.new(sample_chain())
    text = Debugger.render_provenance(dbg, :"disc-1")

    assert text =~ "EPISTEMIC PROVENANCE"
    assert text =~ "OBSERVATION"
    assert text =~ "DISCOVERY"
    assert text =~ "source B has systematic error"
    assert text =~ "responsible_subsystem" or text =~ "subsystem"
  end

  test "finds nodes carrying contradictions" do
    nodes =
      Enum.map(sample_chain(), fn
        %Node{id: :"ev-1"} = n -> %{n | contradictions: [{:conflicts_with, :"ev-0"}]}
        n -> n
      end)

    dbg = Debugger.new(nodes)
    assert [%Node{id: :"ev-1"}] = Debugger.find_contradictions(dbg)
  end

  test "finds nodes with no constitutional checks recorded" do
    dbg = Debugger.new(sample_chain())
    unchecked_ids = dbg |> Debugger.find_unchecked() |> Enum.map(& &1.id)
    assert :"pred-1" in unchecked_ids
  end

  test "finds low-confidence nodes needing more evidence" do
    dbg = Debugger.new(sample_chain())
    low = Debugger.find_low_confidence(dbg, 0.7)
    assert :"hyp-1" in Enum.map(low, & &1.id)
  end

  test "cycle guard prevents infinite provenance loops" do
    a = %Node{id: :a, stage: :hypothesis, lineage: [:b]}
    b = %Node{id: :b, stage: :hypothesis, lineage: [:a]}
    dbg = Debugger.new([a, b])

    chain = Debugger.provenance_chain(dbg, :a)
    assert length(chain) == 2
  end

  test "missing node is reported, not crashed" do
    dbg = Debugger.new(sample_chain())
    assert Debugger.render_provenance(dbg, :nope) =~ "not found"
    assert Debugger.inspect_node(dbg, :nope) == nil
  end
end