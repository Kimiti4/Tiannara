defmodule Tiannara.Omega.DryRunTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.DryRun
  alias Tiannara.SelfImprovement.Sandbox.{TestSpec, BenchmarkSpec}

  @moduletag :omega_dry_run

  defp scenario do
    %{
      claims: [
        %{subject: :x, value: 10, evidence: [:obs_a], timestamp: 1, source: :sensor_a},
        %{subject: :x, value: 20, evidence: [:obs_b], timestamp: 1, source: :sensor_b}
      ],
      # baseline embodies the ERRONEOUS reading (source B's 20)
      baseline_files: %{"value.txt" => "20"},
      # patch embodies the winning hypothesis's correction (true value 10)
      patch_files: %{"value.txt" => "10"},
      test_spec: %TestSpec{
        command: "sh",
        args: ["-c", "grep -q 10 value.txt"],
        timeout: 5_000
      },
      benchmark_spec: %BenchmarkSpec{
        command: "sh",
        args: ["-c", "cat value.txt"],
        metric: :value,
        direction: :lower_better,
        parse: fn out -> out |> String.trim() |> String.to_integer() end,
        tolerance: 0.1
      }
    }
  end

  test "end-to-end Ω dry-run resolves a contradiction through the full chain" do
    {:ok, dry_run} = DryRun.run(scenario())

    # 1. contradiction detected
    assert dry_run.contradiction.type == :value_conflict
    assert dry_run.event.type == :contradiction_detected

    # 2. evidence-driven investigation
    assert dry_run.investigation.evidence_assessment.sufficiency == :contradicted
    assert length(dry_run.investigation.hypotheses) == 3

    # 3. top proposal selected
    assert dry_run.top_proposal.rank == 1
    assert dry_run.top_proposal.status == :proposed

    # 4. sandbox validated the embodied experiment
    assert {:ok, %{verdict: :pass}} = dry_run.sandbox_outcome

    # 5. certified across all critical dimensions
    assert dry_run.certificate.verdict == :certified

    # 6. overall verdict
    assert dry_run.verdict == :hypothesis_supported_and_certified

    # lineage preserved
    assert length(dry_run.lineage) == 2
  end

  test "a patch that fails the test is NOT certified" do
    bad_scenario = %{scenario() | patch_files: %{"value.txt" => "20"}}
    {:ok, dry_run} = DryRun.run(bad_scenario)

    assert {:ok, %{verdict: {:fail, {:tests_failed, _}}}} = dry_run.sandbox_outcome
    refute dry_run.certificate.verdict == :certified
    assert elem(dry_run.verdict, 0) == :hypothesis_not_supported
  end

  test "no contradiction -> dry-run reports no_contradiction_detected" do
    no_conflict = %{
      scenario()
      | claims: [
          %{subject: :x, value: 10, evidence: [:a], timestamp: 1, source: :s1},
          %{subject: :x, value: 10, evidence: [:b], timestamp: 1, source: :s2}
        ]
    }

    assert {:error, :no_contradiction_detected} = DryRun.run(no_conflict)
  end

  test "render produces a full auditable report" do
    {:ok, dry_run} = DryRun.run(scenario())
    text = DryRun.render(dry_run)

    assert text =~ "Ω END-TO-END DRY-RUN"
    assert text =~ "Contradiction"
    assert text =~ "OVERALL VERDICT"
    assert text =~ "nothing deployed"
  end
end