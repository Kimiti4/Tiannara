defmodule Tiannara.SelfImprovement.Sandbox.Patch do
  @moduledoc "A candidate modification to be evaluated in isolation."
  @enforce_keys [:id, :transform]
  defstruct [:id, :description, :transform, :provenance, targets: []]
end

defmodule Tiannara.SelfImprovement.Sandbox.TestCase do
  @moduledoc "A test assertion run against the sandboxed state."
  @enforce_keys [:id, :assertion]
  defstruct [:id, :description, :assertion]
end

defmodule Tiannara.SelfImprovement.Sandbox.Benchmark do
  @moduledoc """
  A benchmark measuring a metric on the sandboxed vs baseline state. `direction`
  is `:lower_better` (e.g. latency) or `:higher_better` (e.g. throughput).
  """
  @enforce_keys [:id, :measure, :direction]
  defstruct [:id, :metric, :measure, :direction, tolerance: 0.1]
end

defmodule Tiannara.SelfImprovement.Sandbox.Result do
  @moduledoc "Outcome of a sandbox run: tests, benchmark, and overall verdict."
  @enforce_keys [:patch_id, :tests, :benchmark, :verdict]
  defstruct [:patch_id, :tests, :benchmark, :verdict]
end

defmodule Tiannara.SelfImprovement.Sandbox.Harness do
  @moduledoc """
  The Ω.4 sandbox harness: apply patch in isolation → run tests → run benchmark
  → verdict. It produces the `:tests` and `:benchmark` gate evidence the
  self-improvement pipeline requires; it NEVER deploys.

  Isolation: the patch transforms a copy of the baseline state; the baseline is
  never mutated. Patches targeting the protected core require independent
  verification before the harness will run them.

  Constitutional basis: "Capability must never outpace verification",
  Verification First, "Security by design", "Preserve previous stable states",
  "Avoid designs dependent on any single ... platform" (behind a pure
  state-transform contract).
  """

  alias Tiannara.SelfImprovement.Sandbox.{Patch, TestCase, Benchmark, Result}
  alias Tiannara.SelfImprovement.{ProtectedCore, GateResult}

  @doc """
  Run the sandbox. Returns `{:ok, %Result{}}`, or `{:error, reason}` if the
  patch is blocked (protected core) or fails to apply.
  """
  def run(baseline_state, %Patch{} = patch, test_cases, %Benchmark{} = benchmark, opts \\ []) do
    with :ok <- check_protected_core(patch, opts),
         {:ok, sandboxed} <- apply_patch(baseline_state, patch) do
      test_result = run_tests(sandboxed, test_cases)
      bench_result = run_benchmark(sandboxed, baseline_state, benchmark)
      verdict = compute_verdict(test_result, bench_result)

      {:ok,
       %Result{patch_id: patch.id, tests: test_result, benchmark: bench_result, verdict: verdict}}
    end
  end

  @doc """
  Convert a sandbox result into the `:tests` and `:benchmark` gate results the
  self-improvement pipeline consumes.
  """
  def to_gate_results(%Result{} = result, source \\ :sandbox) do
    %{
      tests: %GateResult{
        gate: :tests,
        passed: result.tests.all_passed,
        source: source,
        evidence: result.tests
      },
      benchmark: %GateResult{
        gate: :benchmark,
        passed: result.benchmark.no_regression,
        source: source,
        evidence: result.benchmark
      }
    }
  end

  # --- internals ----------------------------------------------------------

  defp check_protected_core(%Patch{targets: targets}, opts) do
    if targets != [] and ProtectedCore.touches_protected?(targets) do
      if Keyword.get(opts, :independent_verification),
        do: :ok,
        else: {:error, :protected_core_requires_independent_verification}
    else
      :ok
    end
  end

  defp apply_patch(state, %Patch{transform: transform}) do
    try do
      {:ok, transform.(state)}
    rescue
      e -> {:error, {:patch_failed, Exception.message(e)}}
    end
  end

  defp run_tests(state, test_cases) do
    results =
      Enum.map(test_cases, fn %TestCase{} = tc ->
        outcome =
          try do
            tc.assertion.(state)
          rescue
            e -> {:error, {:raised, Exception.message(e)}}
          end

        {tc.id, outcome == :ok, detail(outcome)}
      end)

    failed = for {id, false, _} <- results, do: id

    %{all_passed: failed == [], results: results, failed: failed}
  end

  defp run_benchmark(sandboxed, baseline, %Benchmark{} = bench) do
    baseline_metric = bench.measure.(baseline)
    patched_metric = bench.measure.(sandboxed)

    regressed? =
      regressed?(baseline_metric, patched_metric, bench.direction, bench.tolerance)

    %{
      metric: bench.metric,
      baseline: baseline_metric,
      patched: patched_metric,
      direction: bench.direction,
      regressed: regressed?,
      no_regression: not regressed?
    }
  end

  defp regressed?(baseline, patched, :lower_better, tol),
    do: patched > baseline * (1 + tol)

  defp regressed?(baseline, patched, :higher_better, tol),
    do: patched < baseline * (1 - tol)

  defp compute_verdict(test_result, bench_result) do
    cond do
      not test_result.all_passed -> {:fail, {:tests_failed, test_result.failed}}
      bench_result.regressed -> {:fail, :benchmark_regression}
      true -> :pass
    end
  end

  defp detail(:ok), do: :ok
  defp detail({:error, reason}), do: reason
  defp detail(other), do: {:unexpected, other}
end