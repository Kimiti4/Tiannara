defmodule Tiannara.Omega.SoakEvidenceExtendedTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.{SoakEvidence, YieldMetrics}

  test "enriched lines: crash hour bucket counts only timestamped lines" do
    lines = [
      "2026-08-14T23:20:00|** (ArgumentError) could not put/update key \"step_execute\" on a nil value",
      "** (ArgumentError) could not put/update key \"step_execute\" on a nil value"
    ]

    e = SoakEvidence.extract(lines)

    assert e.workflow_crashes == 2
    assert e.workflow_crash_signatures == %{
             "could not put/update key \"step_execute\" on a nil value" => 2
           }

    trajectory = SoakEvidence.trajectory(e)
    assert Enum.find(trajectory, &(&1.hour == "2026-08-14T23")).crashes_per_hour == 1
    assert Enum.find(trajectory, &(&1.hour == :unknown)).crashes_per_hour == 1
  end

  test "agency loop warnings with embedded digits do not poison loop count or monotonicity" do
    lines = [
      "[debug] [AgencyLoop] Loop 1 completed.",
      "[warning] [AgencyLoop] Elixir.Tiannara.Research.ResearchDirector call failed: exit {{:timeout, {GenServer, :call, [Tiannara.Research.KnowledgeIntegrator, {:integrate, %{id: \"67a62ef7-e373-4175-a502-24b29fe7a0e3\"", "}, 5000]}}",
      "[debug] [AgencyLoop] Loop 2 completed."
    ]

    e = SoakEvidence.extract(lines)
    assert e.agency_loops == 2
    assert e.loop_monotonic
    assert e.loop_series == [1, 2]
  end

  test "recovery pattern matches the same tokens as the reference audit" do
    lines = [
      "[info] recovering from crash",
      "[info] Recovered the scheduler",
      "[info] execution resumed",
      "[info] Recovery phase begins",
      "[info] recovery_certificate: term(),"
    ]

    e = SoakEvidence.extract(lines)
    assert e.recoveries == 3
    assert e.total_lines == 5
    assert e.unmatched_lines == 2
  end

  test "restraint pattern excludes plain reject chatter" do
    lines = [
      "[info] GATE CLOSED: blocked",
      "[info] REJECTED BY FALSIFICATION: no",
      "[info] rejected the proposal",
      "[info] REJECTED BY FALSIFICATION CHECK: no"
    ]

    e = SoakEvidence.extract(lines)
    assert e.restraints == 3
    assert e.rejects == 1
  end

  test "trajectory sorted by hour and covers all buckets" do
    lines = [
      "2026-08-15T02:00:00|[info]   MINTED: \"X\" (Confidence: 0.5, Support: 1)",
      "2026-08-14T23:00:00|[info]   MINTED: \"Y\" (Confidence: 0.5, Support: 1)"
    ]

    e = SoakEvidence.extract(lines)
    trajectory = SoakEvidence.trajectory(e)
    hours = Enum.map(trajectory, & &1.hour)
    assert hours == Enum.sort(hours)
    assert Enum.all?(trajectory, &(&1.mints_per_hour == 1))
  end

  test "yield metrics compute labeled proxies over evidence" do
    lines = [
      "[debug] [AgencyLoop] Loop 1 completed.",
      "[debug] [AgencyLoop] Loop 2 completed.",
      "[debug] [AgencyLoop] Loop 3 completed.",
      "[debug] [AgencyLoop] Loop 4 completed.",
      "[info] recovering from crash",
      "[info] improvement cycle started",
      "[info]   MINTED: \"A\" (Confidence: 0.5, Support: 1)",
      "** (ArgumentError) could not put/update key \"step_execute\" on a nil value"
    ]

    e = SoakEvidence.extract(lines)
    m = YieldMetrics.compute(e)

    assert m.vay.measured
    assert m.vay.proxy
    assert m.vay.value == (1 + 1 + 1) / 4
    assert m.ey.value == 1.0
    assert m.rlr.value == 1.0
    assert m.rlr.formula =~ "recoveries / workflow_crashes"
  end

  test "yield metrics report :not_measured when denominator absent" do
    e = SoakEvidence.extract([])
    m = YieldMetrics.compute(e)

    refute m.vay.measured
    refute m.ey.measured
    refute m.rlr.measured
    assert m.vay.note =~ "no agency loops"
    assert m.rlr.note =~ "undefined"
  end
end