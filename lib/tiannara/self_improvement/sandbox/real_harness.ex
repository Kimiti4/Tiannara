defmodule Tiannara.SelfImprovement.Sandbox.RealHarness do
  @moduledoc """
  Drives a real-code sandbox backend through the full evaluation cycle, with
  optional STATISTICAL benchmarking (N iterations + significance testing).
  Emits a `Sandbox.Result` compatible with `Harness.to_gate_results/2`.

  Constitutional basis: Verification First, "Capability must never outpace
  verification", "Evidence Before Confidence", "Support reproducibility".
  """

  alias Tiannara.SelfImprovement.Sandbox.{Result, BenchmarkSpec, StatisticalBenchmark}

  def run(backend, baseline, patch, specs, opts \\ []) do
    build_spec = Map.get(specs, :build)
    test_spec = Map.fetch!(specs, :tests)
    bench_spec = Map.fetch!(specs, :benchmark)

    case backend.prepare(baseline, opts) do
      {:ok, env} ->
        try do
          do_run(backend, env, patch, build_spec, test_spec, bench_spec)
        after
          backend.teardown(env)
        end

      {:error, _} = e ->
        e
    end
  end

  defp do_run(backend, env, patch, build_spec, test_spec, bench_spec) do
    with {:ok, baseline_bench} <- measure_benchmark(backend, env, bench_spec),
         {:ok, env} <- backend.apply_patch(env, patch),
         {:ok, _} <- backend.build(env, build_spec),
         {:ok, test_result} <- backend.run_tests(env, test_spec),
         {:ok, patched_bench} <- measure_benchmark(backend, env, bench_spec) do
      bench_result = compare_benchmarks(baseline_bench, patched_bench, bench_spec)

      verdict =
        cond do
          not test_result.all_passed -> {:fail, {:tests_failed, test_result}}
          bench_result.regressed -> {:fail, :benchmark_regression}
          true -> :pass
        end

      {:ok,
       %Result{
         patch_id: patch.id,
         tests: %{all_passed: test_result.all_passed, details: test_result},
         benchmark: bench_result,
         verdict: verdict
       }}
    end
  end

  # Statistical benchmarking when iterations > 1; single-shot otherwise.
  defp measure_benchmark(backend, env, %BenchmarkSpec{iterations: it} = spec) when it > 1 do
    Enum.each(1..max(spec.warmup, 0), fn _ -> backend.run_benchmark(env, spec) end)

    samples =
      for _ <- 1..it do
        case backend.run_benchmark(env, spec) do
          {:ok, %{metric: m}} -> m
          _ -> nil
        end
      end
      |> Enum.reject(&is_nil/1)

    if length(samples) >= 2 do
      {:ok, StatisticalBenchmark.from_samples(samples, spec.direction)}
    else
      {:error, :insufficient_benchmark_samples}
    end
  end

  defp measure_benchmark(backend, env, spec) do
    case backend.run_benchmark(env, spec) do
      {:ok, %{metric: m}} -> {:ok, %{single: m}}
      {:error, _} = e -> e
    end
  end

  defp compare_benchmarks(%{single: b}, %{single: p}, spec) do
    regressed? = regressed?(b, p, spec.direction, spec.tolerance)

    %{mode: :single, baseline: b, patched: p, direction: spec.direction,
      regressed: regressed?, no_regression: not regressed?}
  end

  defp compare_benchmarks(%StatisticalBenchmark{} = b, %StatisticalBenchmark{} = p, spec) do
    comparison =
      StatisticalBenchmark.compare(b, p,
        direction: spec.direction, tolerance: spec.tolerance)

    %{mode: :statistical, comparison: comparison, direction: spec.direction,
      regressed: comparison.regressed, no_regression: not comparison.regressed,
      baseline: b.stats, patched: p.stats}
  end

  defp regressed?(baseline, patched, :lower_better, tol),
    do: patched > baseline * (1 + tol)

  defp regressed?(baseline, patched, :higher_better, tol),
    do: patched < baseline * (1 - tol)
end