defmodule TiannaraOS.MockAuditTest do
  use ExUnit.Case, async: false

  alias Tiannara.MockAudit
  alias TiannaraOS.MetricWithProvenance
  alias TiannaraOS.State
  alias TiannaraOS.World
  alias TiannaraOS.RepositoryTwin
  alias TiannaraOS.EvidenceNode

  test "MockAudit scanner recursively counts mock patterns and calculates grounding progress" do
    report = MockAudit.run_audit()

    assert %MockAudit{} = report
    assert report.modules_scanned > 0
    assert report.mock_occurrences >= 0
    assert report.grounded_occurrences >= 0
    assert report.grounding_percent >= 0.0
    assert report.grounding_percent <= 100.0
    assert is_list(report.mock_occurrences_details)
  end

  test "MetricWithProvenance correctly wraps dynamic state statistics to trace metric source counts" do
    # Construct a simulated State
    state = %State{
      theories: %{
        t1: %{id: :t1},
        t2: %{id: :t2}
      },
      evidence_graph: %{
        ev1: %EvidenceNode{id: :ev1, type: :evidence, metadata: %{}},
        ev2: %EvidenceNode{id: :ev2, type: :evidence, metadata: %{}},
        rep1: %EvidenceNode{id: :rep1, type: :evidence, metadata: %{source: :replication}}
      },
      worlds: %{
        w1: %World{id: :w1, twin: %RepositoryTwin{id: :twin1}},
        w2: %World{id: :w2, twin: nil}
      }
    }

    metric = MetricWithProvenance.from_state(0.85, state)

    assert metric.value == 0.85
    assert metric.provenance.theories_count == 2
    assert metric.provenance.evidence_nodes_count == 3
    assert metric.provenance.replication_events_count == 1
    assert metric.provenance.repository_worlds_count == 1
  end
end
