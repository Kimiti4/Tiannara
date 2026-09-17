defmodule Tiannara.SelfImprovement.SandboxTest do
  use ExUnit.Case, async: true

  alias Tiannara.SelfImprovement.Sandbox.{Patch, TestCase, Benchmark, Harness}
  alias Tiannara.SelfImprovement.{Pipeline, Proposal, GateResult}

  @moduletag :omega4_sandbox

  defp bench(direction \\ :lower_better) do
    %Benchmark{id: :b1, metric: :cost, direction: direction,
               measure: fn _ -> 10 end, tolerance: 0.1}
  end

  test "a clean patch passes tests and benchmark" do
    baseline = %{factor: 2}
    patch = %Patch{id: :p1, targets: [:compute], transform: fn s -> %{s | factor: 2} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.factor == 2, do: :ok, else: {:error, :wrong} end}]

    {:ok, result} = Harness.run(baseline, patch, tests, bench())

    assert result.verdict == :pass
    assert result.tests.all_passed
    assert result.benchmark.no_regression
  end

  test "a failing test fails the sandbox" do
    baseline = %{factor: 2}
    patch = %Patch{id: :p2, targets: [:compute], transform: fn s -> %{s | factor: 3} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.factor == 2, do: :ok, else: {:error, :changed} end}]

    {:ok, result} = Harness.run(baseline, patch, tests, bench())
    assert {:fail, {:tests_failed, [:t1]}} = result.verdict
  end

  test "a benchmark regression fails the sandbox" do
    baseline = %{work: 10}
    patch = %Patch{id: :p3, targets: [:compute], transform: fn s -> %{s | work: 50} end}
    tests = [%TestCase{id: :t1, assertion: fn _ -> :ok end}]

    bench = %Benchmark{id: :b1, metric: :work, direction: :lower_better,
                       measure: fn s -> s.work end, tolerance: 0.1}

    {:ok, result} = Harness.run(baseline, patch, tests, bench)
    assert {:fail, :benchmark_regression} = result.verdict
    assert result.benchmark.regressed
  end

  test "a raising patch is rejected" do
    patch = %Patch{id: :p4, targets: [:compute], transform: fn _ -> raise "boom" end}
    assert {:error, {:patch_failed, _}} = Harness.run(%{}, patch, [], bench())
  end

  test "the sandbox does not mutate the baseline" do
    baseline = %{value: 1}
    patch = %Patch{id: :p5, targets: [:compute], transform: fn s -> %{s | value: 999} end}
    tests = [%TestCase{id: :t1, assertion: fn _ -> :ok end}]

    bench = %Benchmark{id: :b1, metric: :value, direction: :higher_better,
                       measure: fn s -> s.value end, tolerance: 0.1}

    {:ok, _result} = Harness.run(baseline, patch, tests, bench)
    assert baseline.value == 1
  end

  test "a protected-core patch requires independent verification" do
    patch = %Patch{id: :p6, targets: [:authorization], transform: fn s -> s end}

    assert {:error, :protected_core_requires_independent_verification} =
             Harness.run(%{}, patch, [], bench())

    assert {:ok, _} = Harness.run(%{}, patch, [], bench(), independent_verification: true)
  end

  test "sandbox result converts to pipeline gate results" do
    baseline = %{factor: 2}
    patch = %Patch{id: :p7, targets: [:compute], transform: fn s -> s end}
    tests = [%TestCase{id: :t1, assertion: fn _ -> :ok end}]

    {:ok, result} = Harness.run(baseline, patch, tests, bench())
    gates = Harness.to_gate_results(result)

    assert %GateResult{gate: :tests, passed: true} = gates.tests
    assert %GateResult{gate: :benchmark, passed: true} = gates.benchmark
  end

  test "a failing sandbox blocks deployment via the self-improvement pipeline" do
    baseline = %{factor: 2}
    patch = %Patch{id: :pf, targets: [:compute], transform: fn s -> %{s | factor: 3} end}
    tests = [%TestCase{id: :t1, assertion: fn s -> if s.factor == 2, do: :ok, else: {:error, :bad} end}]

    {:ok, result} = Harness.run(baseline, patch, tests, bench())
    sandbox_gates = Harness.to_gate_results(result)

    passing = %{
      adversarial_validation: %GateResult{gate: :adversarial_validation, passed: true, source: :lab},
      constitutional_review: %GateResult{gate: :constitutional_review, passed: true, source: :reviewer},
      human_approval: %GateResult{gate: :human_approval, passed: true, source: :human}
    }

    gates = Map.merge(passing, sandbox_gates)
    proposal = %Proposal{id: :prop, targets: [:compute]}

    assert {:error, {:gates_failed, [:tests]}} =
             Pipeline.request_deployment(proposal, gates, deployment_enabled: true)
  end
end