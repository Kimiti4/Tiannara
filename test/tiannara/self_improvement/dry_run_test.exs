defmodule Tiannara.SelfImprovement.DryRunTest do
  use ExUnit.Case, async: true

  alias Tiannara.SelfImprovement.DryRun
  alias Tiannara.SelfImprovement.DryRun.Observation
  alias Tiannara.SelfImprovement.Sandbox.{Patch, TestCase, Benchmark}
  alias Tiannara.SelfImprovement.GateResult
  alias Tiannara.Certification.MultiCertificate

  @moduletag :omega4_dry_run

  defp obs(id),
    do: %Observation{id: id, description: "observed improvement opportunity", bottleneck: :latency}

  defp human(passed), do: %GateResult{gate: :human_approval, passed: passed, source: :human}

  defp bench do
    %Benchmark{id: :b1, metric: :cost, direction: :lower_better,
               measure: fn s -> Map.get(s, :cost, 10) end, tolerance: 0.1}
  end

  test "a clean improvement is authorized and certified, but never deployed" do
    patch = %Patch{id: :patch1, targets: [:compute],
                   transform: fn s -> %{s | cost: 5, improved: true} end}

    tests = [%TestCase{id: :t1,
                       assertion: fn s -> if s.improved, do: :ok, else: {:error, :not_improved} end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{cost: 10, improved: false}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs1), config)

    refute run.deployed?
    assert run.deployment_decision == {:ok, :deployment_authorized}
    assert MultiCertificate.certified?(run.certificate)
    assert run.lineage == [:obs1, run.proposal.id, :patch1]
  end

  test "a failing sandbox test blocks certification" do
    patch = %Patch{id: :patch2, targets: [:compute], transform: fn s -> s end}

    tests = [%TestCase{id: :t1,
                       assertion: fn s ->
                         if Map.get(s, :improved), do: :ok, else: {:error, :not_improved}
                       end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{cost: 10}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs2), config)

    refute MultiCertificate.certified?(run.certificate)
    assert {:not_certified, {:dimensions_failed, failed}} = run.certificate.verdict
    assert :tests in failed
  end

  test "missing human approval blocks certification" do
    patch = %Patch{id: :patch3, targets: [:compute], transform: fn s -> %{s | improved: true} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.improved, do: :ok, else: {:error, :x} end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{cost: 10, improved: false}, human_approval: human(false)}

    {:ok, run} = DryRun.execute(obs(:obs3), config)

    refute MultiCertificate.certified?(run.certificate)
    assert {:not_certified, {:dimensions_failed, failed}} = run.certificate.verdict
    assert :human_approval in failed
  end

  test "protected-core patch without independent verification is not authorized" do
    patch = %Patch{id: :patch4, targets: [:authorization], transform: fn s -> s end}
    tests = [%TestCase{id: :t1, assertion: fn _ -> :ok end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs4), config)

    refute MultiCertificate.certified?(run.certificate)
    refute run.deployment_decision == {:ok, :deployment_authorized}
  end

  test "protected-core patch WITH independent verification proceeds" do
    patch = %Patch{id: :patch5, targets: [:safety],
                   transform: fn s -> Map.put(s, :audited, true) end}

    tests = [%TestCase{id: :t1,
                       assertion: fn s -> if s.audited, do: :ok, else: {:error, :x} end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{}, human_approval: human(true),
               independent_verification: true}

    {:ok, run} = DryRun.execute(obs(:obs5), config)

    assert MultiCertificate.certified?(run.certificate)
    assert run.deployment_decision == {:ok, :deployment_authorized}
    refute run.deployed?
  end

  test "a patch targeting the evaluator fails adversarial validation (anti-gaming)" do
    patch = %Patch{id: :patch6, targets: [:evaluator], transform: fn s -> s end}
    tests = [%TestCase{id: :t1, assertion: fn _ -> :ok end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs6), config)

    refute MultiCertificate.certified?(run.certificate)
    assert {:not_certified, {:dimensions_failed, failed}} = run.certificate.verdict
    assert :adversarial_validation in failed
  end

  test "the dry-run never executes deployment even when authorized" do
    patch = %Patch{id: :patch7, targets: [:compute], transform: fn s -> %{s | improved: true} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.improved, do: :ok, else: {:error, :x} end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{cost: 10, improved: false}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs7), config)

    assert run.deployment_decision == {:ok, :deployment_authorized}
    refute run.deployed?
  end

  test "every step is recorded for traceability" do
    patch = %Patch{id: :patch8, targets: [:compute], transform: fn s -> %{s | improved: true} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.improved, do: :ok, else: {:error, :x} end}]

    config = %{patch: patch, tests: tests, benchmark: bench(),
               baseline_state: %{cost: 10}, human_approval: human(true)}

    {:ok, run} = DryRun.execute(obs(:obs8), config)

    step_names = Enum.map(run.steps, & &1.step)

    assert step_names == [
             :observation, :proposal_generated, :code_analysis, :patch_generated,
             :sandbox, :adversarial_validation, :constitutional_review,
             :human_approval, :deployment_decision
           ]
  end
end