defmodule Tiannara.Omega.SoakEvidenceTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.SoakEvidence

  @basic_lines [
    "[info] [AgencyLoop] Loop 1 completed.",
    "[info] [AgencyLoop] Loop 2 completed.",
    "[debug] [AgencyLoop] Loop 3 completed.",
    "[info] ControlCenter: recovering from failure",
    "[info] control resumed",
    "[info] GATE CLOSED: unauthorized write blocked",
    "[info] REJECTED BY FALSIFICATION: claim failed",
    "[info] improvement cycle started",
    "[info] systemic bottleneck detected",
    "[info] bottleneck detected in pipeline",
    "** (ArgumentError) could not put/update key \"step_execute\" on a nil value",
    "2026-08-14T23:20:00|** (ArgumentError) could not put/update key \"step_execute\" on a nil value",
    "[info]   MINTED: \"A\" (Confidence: 0.5, Support: 1)",
    "[info]   MINTED: \"A\" (Confidence: 0.5, Support: 1)",
    "[info]   MINTED: \"B\" (Confidence: 0.3, Support: 2)",
    "[info] pipeline bypass detected",
    "[info] REJECTED BY FALSIFICATION CHECK: nope",
    "[info] plain operational chatter"
  ]

  test "extracts totals from synthetic lines" do
    e = SoakEvidence.extract(@basic_lines)

    assert e.agency_loops == 3
    assert e.loop_monotonic
    assert e.recoveries == 2
    assert e.restraints == 3
    assert e.improvement_cycles == 1
    assert e.self_diagnoses == 2
    assert e.workflow_crashes == 2
    assert e.mints == 3
    assert e.pipeline_bypasses == 1
    assert e.rejects == 1
    assert e.unmatched_lines == 1
    assert e.total_lines == length(@basic_lines)
  end

  test "loop series is recorded in order and detects regression" do
    e = SoakEvidence.extract(@basic_lines)
    assert e.loop_series == [1, 2, 3]

    regressed = SoakEvidence.extract([
      "[info] [AgencyLoop] Loop 5 completed.",
      "[info] [AgencyLoop] Loop 4 completed."
    ])

    refute regressed.loop_monotonic
    assert regressed.agency_loops == 5
  end

  test "mint diversity tracks unique vs duplicate" do
    e = SoakEvidence.extract(@basic_lines)
    div = SoakEvidence.mint_diversity(e)

    assert div.total_mints == 3
    assert div.unique_mints == 2
    assert div.duplicate_mint_rate == 1 / 3
    assert e.duplicate_mint_groups == [{"\"A\" (Confidence: 0.5, Support: 1)", 2}]
  end

  test "first mint timestamp is captured" do
    e = SoakEvidence.extract([
      "2026-08-14T23:43:11.005|[info]   MINTED: \"X\" (Confidence: 0.5, Support: 1)",
      "2026-08-14T23:43:12.000|[info]   MINTED: \"Y\" (Confidence: 0.5, Support: 1)"
    ])

    assert e.first_mint_at == "2026-08-14T23:43:11"
  end

  test "hourly buckets split timestamped lines by hour" do
    lines = [
      "2026-08-14T23:20:00|** (ArgumentError) could not put/update key \"step_execute\" on a nil value",
      "2026-08-15T00:05:00|** (ArgumentError) could not put/update key \"step_execute\" on a nil value",
      "2026-08-15T00:06:00|[info]   MINTED: \"X\" (Confidence: 0.5, Support: 1)"
    ]

    e = SoakEvidence.extract(lines)
    trajectory = SoakEvidence.trajectory(e)

    h23 = Enum.find(trajectory, &(&1.hour == "2026-08-14T23"))
    h00 = Enum.find(trajectory, &(&1.hour == "2026-08-15T00"))

    assert h23.crashes_per_hour == 1
    assert h00.crashes_per_hour == 1
    assert h00.mints_per_hour == 1
  end

  test "cross_check matches an independent reference" do
    e = SoakEvidence.extract(@basic_lines)

    ref = %{
      agency_loops: 3, recoveries: 2, restraints: 3, improvement_cycles: 1,
      self_diagnoses: 2, workflow_crashes: 2, mints: 3
    }

    %{status: :match, checks: checks} = SoakEvidence.cross_check(e, ref, 0)
    assert checks[:recoveries].match
    assert checks[:workflow_crashes].delta == 0
  end

  test "cross_check tolerates string-keyed JSON references and flags mismatch" do
    e = SoakEvidence.extract(@basic_lines)

    ref = %{
      "agency_loops" => 99, "recoveries" => 2, "restraints" => 3,
      "improvement_cycles" => 1, "self_diagnoses" => 2,
      "workflow_crashes" => 2, "mints" => 3
    }

    %{status: :mismatch, checks: checks} = SoakEvidence.cross_check(e, ref, 0)
    refute checks[:agency_loops].match
    assert checks[:recoveries].match
  end

  test "cross_check with tolerance passes small deltas" do
    e = SoakEvidence.extract(@basic_lines)

    ref = %{
      agency_loops: 3, recoveries: 3, restraints: 3, improvement_cycles: 1,
      self_diagnoses: 2, workflow_crashes: 2, mints: 3
    }

    %{status: :match} = SoakEvidence.cross_check(e, ref, 1)
  end

  test "empty log extracts zeroed evidence" do
    e = SoakEvidence.extract([])
    assert e.total_lines == 0
    assert e.agency_loops == 0
    assert SoakEvidence.mint_diversity(e).unique_ratio == 0.0
  end
end