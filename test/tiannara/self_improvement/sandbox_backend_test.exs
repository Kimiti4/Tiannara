defmodule Tiannara.SelfImprovement.SandboxBackendTest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.Sandbox.{CodePatch, TestSpec, BenchmarkSpec, RealHarness, Harness}
  alias Tiannara.SelfImprovement.Sandbox.Backend.Local

  @moduletag :sandbox_backend

  setup do
    base = Path.join(System.tmp_dir!(), "sb_baseline_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    File.write!(Path.join(base, "value.txt"), "10")
    on_exit(fn -> File.rm_rf!(base) end)
    {:ok, base: base}
  end

  defp test_spec_expect_5 do
    %TestSpec{command: "sh", args: ["-c", "grep -q 5 value.txt"], timeout: 5_000}
  end

  defp bench_spec do
    %BenchmarkSpec{
      command: "sh",
      args: ["-c", "cat value.txt"],
      metric: :value,
      direction: :lower_better,
      parse: fn out -> out |> String.trim() |> String.to_integer() end,
      tolerance: 0.1,
      timeout: 5_000
    }
  end

  test "prepare creates an isolated workdir; teardown removes it", %{base: base} do
    {:ok, env} = Local.prepare(base, [])
    assert File.exists?(Path.join(env.workdir, "value.txt"))

    :ok = Local.teardown(env)
    refute File.exists?(env.workdir)
  end

  test "real patch + passing tests + improved benchmark => :pass", %{base: base} do
    patch = %CodePatch{id: :cp1, files: %{"value.txt" => "5"}}
    specs = %{tests: test_spec_expect_5(), benchmark: bench_spec()}

    {:ok, result} = RealHarness.run(Local, base, patch, specs)

    assert result.verdict == :pass
    assert result.tests.all_passed
    assert result.benchmark.no_regression
    assert result.benchmark.baseline == 10
    assert result.benchmark.patched == 5
  end

  test "a failing real test fails the sandbox", %{base: base} do
    patch = %CodePatch{id: :cp2, files: %{"value.txt" => "7"}}
    specs = %{tests: test_spec_expect_5(), benchmark: bench_spec()}

    {:ok, result} = RealHarness.run(Local, base, patch, specs)

    assert {:fail, {:tests_failed, _}} = result.verdict
    refute result.tests.all_passed
  end

  test "a benchmark regression fails the sandbox", %{base: base} do
    patch = %CodePatch{id: :cp3, files: %{"value.txt" => "50"}}

    specs = %{
      tests: %TestSpec{command: "sh", args: ["-c", "true"], timeout: 5_000},
      benchmark: bench_spec()
    }

    {:ok, result} = RealHarness.run(Local, base, patch, specs)

    assert {:fail, :benchmark_regression} = result.verdict
    assert result.benchmark.regressed
  end

  test "the baseline is never mutated", %{base: base} do
    patch = %CodePatch{id: :cp4, files: %{"value.txt" => "999"}}

    specs = %{
      tests: %TestSpec{command: "sh", args: ["-c", "true"], timeout: 5_000},
      benchmark: bench_spec()
    }

    {:ok, _} = RealHarness.run(Local, base, patch, specs)
    assert File.read!(Path.join(base, "value.txt")) == "10"
  end

  test "real sandbox results feed the Ω.4 gate results unchanged", %{base: base} do
    patch = %CodePatch{id: :cp5, files: %{"value.txt" => "5"}}
    specs = %{tests: test_spec_expect_5(), benchmark: bench_spec()}

    {:ok, result} = RealHarness.run(Local, base, patch, specs)
    gates = Harness.to_gate_results(result)

    assert gates.tests.passed
    assert gates.benchmark.passed
  end
end