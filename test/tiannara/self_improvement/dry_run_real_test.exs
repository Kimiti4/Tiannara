defmodule Tiannara.SelfImprovement.DryRunRealTest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.DryRun
  alias Tiannara.SelfImprovement.DryRun.Observation
  alias Tiannara.SelfImprovement.Sandbox.{CodePatch, TestSpec, BenchmarkSpec}
  alias Tiannara.SelfImprovement.Sandbox.Backend.Local
  alias Tiannara.SelfImprovement.GateResult
  alias Tiannara.Certification.MultiCertificate

  @moduletag :omega4_dry_run_real

  defp obs(id),
    do: %Observation{id: id, description: "real-code improvement opportunity", bottleneck: :latency}

  defp human(passed), do: %GateResult{gate: :human_approval, passed: passed, source: :human}

  defp bench_spec do
    %BenchmarkSpec{command: "sh", args: ["-c", "cat value.txt"], metric: :value,
                   direction: :lower_better,
                   parse: fn out -> out |> String.trim() |> String.to_integer() end,
                   tolerance: 0.1, timeout: 5_000}
  end

  setup do
    base = Path.join(System.tmp_dir!(), "dryrun_real_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    File.write!(Path.join(base, "value.txt"), "10")
    on_exit(fn -> File.rm_rf!(base) end)
    {:ok, base: base}
  end

  test "a real code patch that passes tests + improves benchmark is certified, never deployed",
       %{base: base} do
    patch = %CodePatch{id: :rcp1, targets: [:compute], files: %{"value.txt" => "5"}}
    test_spec = %TestSpec{command: "sh", args: ["-c", "grep -q 5 value.txt"], timeout: 5_000}

    config = %{patch: patch, backend: Local, baseline: base,
               specs: %{tests: test_spec, benchmark: bench_spec()},
               human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:rc_obs1), config)

    refute run.deployed?
    assert run.deployment_decision == {:ok, :deployment_authorized}
    assert MultiCertificate.certified?(run.certificate)
  end

  test "a real code patch that fails tests is not certified", %{base: base} do
    patch = %CodePatch{id: :rcp2, targets: [:compute], files: %{"value.txt" => "7"}}
    test_spec = %TestSpec{command: "sh", args: ["-c", "grep -q 5 value.txt"], timeout: 5_000}

    config = %{patch: patch, backend: Local, baseline: base,
               specs: %{tests: test_spec, benchmark: bench_spec()},
               human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:rc_obs2), config)

    refute MultiCertificate.certified?(run.certificate)
    assert {:not_certified, {:dimensions_failed, failed}} = run.certificate.verdict
    assert :tests in failed
  end

  test "a real code patch that regresses the benchmark is not certified", %{base: base} do
    patch = %CodePatch{id: :rcp3, targets: [:compute], files: %{"value.txt" => "50"}}
    test_spec = %TestSpec{command: "sh", args: ["-c", "true"], timeout: 5_000}

    config = %{patch: patch, backend: Local, baseline: base,
               specs: %{tests: test_spec, benchmark: bench_spec()},
               human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:rc_obs3), config)

    refute MultiCertificate.certified?(run.certificate)
    assert {:not_certified, {:dimensions_failed, failed}} = run.certificate.verdict
    assert :benchmark in failed
  end

  test "a real protected-core patch without independent verification is blocked", %{base: base} do
    patch = %CodePatch{id: :rcp4, targets: [:authorization], files: %{"value.txt" => "5"}}
    test_spec = %TestSpec{command: "sh", args: ["-c", "true"], timeout: 5_000}

    config = %{patch: patch, backend: Local, baseline: base,
               specs: %{tests: test_spec, benchmark: bench_spec()},
               human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:rc_obs4), config)

    refute MultiCertificate.certified?(run.certificate)
    refute run.deployment_decision == {:ok, :deployment_authorized}
  end

  test "the real-code dry-run preserves lineage and never mutates the baseline", %{base: base} do
    patch = %CodePatch{id: :rcp5, targets: [:compute], files: %{"value.txt" => "5"}}
    test_spec = %TestSpec{command: "sh", args: ["-c", "grep -q 5 value.txt"], timeout: 5_000}

    config = %{patch: patch, backend: Local, baseline: base,
               specs: %{tests: test_spec, benchmark: bench_spec()},
               human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:rc_obs5), config)

    assert run.lineage == [:rc_obs5, run.proposal.id, :rcp5]
    refute run.deployed?
    assert File.read!(Path.join(base, "value.txt")) == "10"
  end
end