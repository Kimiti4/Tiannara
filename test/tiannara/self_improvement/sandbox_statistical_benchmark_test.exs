defmodule Tiannara.SelfImprovement.SandboxStatisticalBenchmarkTest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.Sandbox.{StatisticalBenchmark, RealHarness,
                                          CodePatch, TestSpec, BenchmarkSpec}
  alias Tiannara.SelfImprovement.Sandbox.Backend.Local

  @moduletag :statistical_benchmark

  test "compute_stats computes mean, std_dev, median, and CI" do
    stats = StatisticalBenchmark.compute_stats([10.0, 12.0, 11.0, 13.0, 9.0, 11.0])

    assert stats.n == 6
    assert_in_delta stats.mean, 11.0, 0.01
    assert stats.median == 11.0
    assert stats.std_dev > 0

    {lo, hi} = stats.ci95
    assert lo < stats.mean and stats.mean < hi
  end

  test "compare detects a significant regression (lower_better)" do
    baseline = StatisticalBenchmark.from_samples([10.0, 10.1, 9.9, 10.0, 10.2], :lower_better)
    patched = StatisticalBenchmark.from_samples([20.0, 20.1, 19.9, 20.0, 20.2], :lower_better)

    result = StatisticalBenchmark.compare(baseline, patched,
               direction: :lower_better, tolerance: 0.05)

    assert result.regressed
    assert result.significant
  end

  test "compare does not flag a difference that is within noise" do
    baseline = StatisticalBenchmark.from_samples([10.0, 20.0, 10.0, 20.0, 10.0, 20.0], :lower_better)
    patched = StatisticalBenchmark.from_samples([11.0, 21.0, 11.0, 21.0, 11.0, 21.0], :lower_better)

    result = StatisticalBenchmark.compare(baseline, patched,
               direction: :lower_better, tolerance: 0.01)

    refute result.regressed
    refute result.significant
  end

  test "compare respects higher_better direction" do
    baseline = StatisticalBenchmark.from_samples([100.0, 101.0, 99.0, 100.0, 102.0], :higher_better)
    patched = StatisticalBenchmark.from_samples([50.0, 51.0, 49.0, 50.0, 52.0], :higher_better)

    result = StatisticalBenchmark.compare(baseline, patched,
               direction: :higher_better, tolerance: 0.05)

    assert result.regressed
  end

  test "real harness uses statistical benchmarking when iterations > 1" do
    base = Path.join(System.tmp_dir!(), "sb_stat_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    File.write!(Path.join(base, "value.txt"), "10")
    on_exit(fn -> File.rm_rf!(base) end)

    patch = %CodePatch{id: :sp1, files: %{"value.txt" => "20"}}

    test_spec = %TestSpec{command: "sh", args: ["-c", "true"], timeout: 5_000}

    bench_spec = %BenchmarkSpec{
      command: "sh", args: ["-c", "cat value.txt"], metric: :value,
      direction: :lower_better,
      parse: fn out -> out |> String.trim() |> String.to_integer() end,
      tolerance: 0.05, iterations: 5, warmup: 1, timeout: 5_000
    }

    {:ok, result} = RealHarness.run(Local, base, patch,
                        %{tests: test_spec, benchmark: bench_spec})

    assert {:fail, :benchmark_regression} = result.verdict
    assert result.benchmark.mode == :statistical
    assert result.benchmark.regressed
  end
end