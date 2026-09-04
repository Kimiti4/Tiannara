defmodule Tiannara.ASC.CMissions.Verification do
  @moduledoc """
  Post-verdict statistical verification addendum for ASC-AE-001 (D1).

  Method (pre-registered in the evidence ledger before measurement):
    * Paired A/B rounds: baseline worktree (HEAD + working-tree mirror) vs
      candidate worktree (same mirror + the D1 C4 patch), order
      counterbalanced across rounds to absorb machine drift.
    * Candidate provenance note: the review branch is a bare HEAD pointer —
      the C4 patch was applied as sandbox working-tree changes and never
      committed. The candidate worktree is therefore reconstructed with the
      identical mirror + `Runner.apply_patch/2` source, byte-identical to
      what C5 measured. Branch lineage is preserved untouched.
    * Each measured run: 1 discarded warm run per side per round, then the
      bench task runs n=15 boots (its own warmup=2 discarded internally).
    * Statistic: percentile bootstrap 95% CI (fixed seed, 10k iterations)
      over the MEDIAN of per-round relative latency improvement.
    * Measurement-tool integrity: bench task file must hash identically in
      both worktrees, else the run aborts.

  Append-only: this module never rewrites the C6 verdict. It appends
  :D1_VERIFICATION_* entries to the same evidence ledger.
  """

  alias Tiannara.ASC.CMissions.{Ledger, Runner, Worktree}

  @gate_latency 0.15
  @gate_memory 0.05
  @n_per_run 15
  @bootstrap_iterations 10_000
  @seed {12_345, 67_890, 24_680}
  @bench_task_rel "lib/mix/tasks/asc.bench.boot.ex"
  @artifact_dir "priv/asc/missions/ASC-AE-001/verification"

  def run(opts \\ []) do
    rounds = Keyword.get(opts, :rounds, 15)
    candidate_branch = Keyword.get(opts, :candidate_branch, "asc-ae001-d1_parallel_boot")

    File.mkdir_p!(@artifact_dir)
    ledger = Ledger.init()

    root = File.cwd!()
    base_wt = Worktree.create("asc-verify-baseline")
    cand_wt = Worktree.create("asc-verify-d1")
    {:ok, _} = Runner.apply_patch("D1_Parallel_Boot", cand_wt.path)

    protocol = build_protocol(root, base_wt, cand_wt, candidate_branch, rounds)
    ledger = Ledger.record(ledger, :D1_VERIFICATION_PROTOCOL, protocol)
    IO.puts("[verify] Protocol pre-registered. Gate=#{@gate_latency}, rounds=#{rounds}, n=#{@n_per_run}")

    if tool_hash(base_wt.path) != tool_hash(cand_wt.path) do
      ledger =
        Ledger.record(ledger, :D1_VERIFICATION_ABORT, %{
          reason: :measurement_tool_divergence
        })

      finalize(root, ledger, base_wt, cand_wt, %{verdict: :ABORT_MEASUREMENT_TOOL_DIVERGENCE}, [])
    else
      base_tests = run_tests(base_wt.path)
      cand_tests = run_tests(cand_wt.path)

      ledger =
        Ledger.record(ledger, :D1_VERIFICATION_CORRECTNESS, %{
          baseline: base_tests,
          candidate: cand_tests
        })

      if base_tests.status != :pass or cand_tests.status != :pass do
        finalize(
          root,
          ledger,
          base_wt,
          cand_wt,
          %{
            verdict: :FAIL_CORRECTNESS,
            tests: %{baseline: base_tests, candidate: cand_tests}
          },
          []
        )
      else
        IO.puts("[verify] Running #{rounds} paired rounds (#{rounds * 4} bench invocations)...")

        results =
          Enum.map(1..rounds, fn r ->
            order = if rem(r, 2) == 1, do: [:baseline, :candidate], else: [:candidate, :baseline]

            IO.write("  round #{r}/#{rounds} (#{inspect(order)}) ...")
            row = measure_round(r, order, base_wt.path, cand_wt.path)
            IO.puts(" base=#{Float.round(row.baseline.p50_ms, 3)}ms cand=#{Float.round(row.candidate.p50_ms, 3)}ms")
            row
          end)

        stats = compute_statistics(results)
        verdict = decide(stats)
        finalize(root, ledger, base_wt, cand_wt, %{verdict: verdict, statistics: stats}, results)
      end
    end
  end

  # ---- measurement ---------------------------------------------------------

  defp measure_round(r, order, base_wt, cand_wt) do
    Enum.reduce(order, %{round: r, order: order}, fn side, acc ->
      wt = if side == :baseline, do: base_wt, else: cand_wt
      _warm = bench!(wt, Path.join(System.tmp_dir!(), "asc_verify_warm_#{r}_#{side}.eterm"))
      out = Path.expand(Path.join(@artifact_dir, "round_#{String.pad_leading("#{r}", 2, "0")}_#{side}.eterm"))
      m = bench!(wt, out)
      Map.put(acc, side, Map.put(m, :artifact, out))
    end)
  end

  defp bench!(wt, out_path) do
    args = ["asc.bench.boot", "--n", "#{@n_per_run}", "--out", out_path]

    {output, status} =
      System.cmd("mix", args,
        cd: wt,
        env: [{"MIX_ENV", "test"}, {"ASC_BOOT_INSTRUMENT", "1"}],
        stderr_to_stdout: true
      )

    if status != 0 do
      raise "bench failed in #{wt}:\n#{String.slice(output, 0, 800)}"
    end

    {result, _meta} = :erlang.binary_to_term(File.read!(out_path))
    result
  end

  defp run_tests(wt) do
    {output, status} =
      System.cmd("mix", ["test", "test/tiannara/asc/core", "--no-start"],
        cd: wt,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    summary =
      case Regex.run(~r/(\d+) tests?, (\d+) failures?/, output) do
        [_, p, f] -> %{passed: String.to_integer(p), failed: String.to_integer(f)}
        _ -> %{passed: 0, failed: -1}
      end

    %{
      status: if(status == 0 and summary.failed == 0, do: :pass, else: :fail),
      exit_code: status,
      summary: summary
    }
  end

  # ---- statistics -----------------------------------------------------------

  defp compute_statistics(results) do
    rel =
      Enum.map(results, fn row ->
        (row.baseline.p50_ms - row.candidate.p50_ms) / row.baseline.p50_ms
      end)

    base_p50s = Enum.map(results, & &1.baseline.p50_ms)
    cand_p50s = Enum.map(results, & &1.candidate.p50_ms)
    base_p95s = Enum.map(results, & &1.baseline.p95_ms)
    cand_p95s = Enum.map(results, & &1.candidate.p95_ms)
    base_mems = Enum.map(results, & &1.baseline.memory_mb)
    cand_mems = Enum.map(results, & &1.candidate.memory_mb)
    {ci_low, ci_high} = bootstrap_ci(rel)

    %{
      rounds: length(results),
      relative_improvements: Enum.map(rel, &Float.round(&1, 5)),
      median_improvement: Float.round(median(rel), 5),
      ci_95_low: Float.round(ci_low, 5),
      ci_95_high: Float.round(ci_high, 5),
      baseline_p50_median_ms: Float.round(median(base_p50s), 4),
      candidate_p50_median_ms: Float.round(median(cand_p50s), 4),
      baseline_p95_median_ms: Float.round(median(base_p95s), 4),
      candidate_p95_median_ms: Float.round(median(cand_p95s), 4),
      memory_baseline_median_mb: Float.round(median(base_mems) * 1.0, 2),
      memory_candidate_median_mb: Float.round(median(cand_mems) * 1.0, 2),
      method: "percentile bootstrap, fixed seed #{inspect(@seed)}, #{@bootstrap_iterations} iterations"
    }
  end

  @doc """
  Pre-registered decision rule: verdict from computed statistics.
  FAIL_MEMORY overrides all latency-based outcomes.
  """
  def decide(stats) do
    mem_delta =
      (stats.memory_candidate_median_mb - stats.memory_baseline_median_mb) /
        max(stats.memory_baseline_median_mb, 0.0001)

    stats = Map.put(stats, :memory_delta, Float.round(mem_delta, 5))

    cond do
      mem_delta > @gate_memory -> :FAIL_MEMORY
      stats.ci_95_low >= @gate_latency -> :ROBUST_PASS
      stats.ci_95_high < @gate_latency -> :FAIL_BELOW_GATE
      true -> :INSUFFICIENT_EVIDENCE
    end
  end

  @doc """
  Percentile bootstrap 95% CI over the median of the given per-round
  relative improvements. Fixed seed, deterministic.
  """
  def bootstrap_ci(deltas) do
    :rand.seed(:exsplus, @seed)
    n = length(deltas)
    arr = List.to_tuple(deltas)

    medians =
      for _ <- 1..@bootstrap_iterations do
        sample = for i <- 1..n, do: elem(arr, :rand.uniform(n) - 1)
        median(sample)
      end

    sorted = Enum.sort(medians)
    lo = Enum.at(sorted, trunc(0.025 * @bootstrap_iterations))
    hi = Enum.at(sorted, trunc(0.975 * @bootstrap_iterations) - 1)
    {lo, hi}
  end

  defp median(list) do
    s = Enum.sort(list)
    n = length(s)

    case rem(n, 2) do
      1 -> Enum.at(s, div(n, 2))
      0 -> (Enum.at(s, div(n, 2) - 1) + Enum.at(s, div(n, 2))) / 2
    end
  end

  # ---- protocol / provenance ------------------------------------------------

  defp build_protocol(root, base_wt, cand_wt, candidate_branch, rounds) do
    %{
      gate_latency_improvement: @gate_latency,
      gate_memory_delta: @gate_memory,
      rounds: rounds,
      n_per_run: @n_per_run,
      warmups_discarded_per_side_per_round: 1,
      order: "counterbalanced (baseline-first on odd rounds)",
      environment_locked: %{mix_env: "test", asc_boot_instrument: "1", set_by: "harness (not shell)"},
      elixir: System.version(),
      otp: to_string(:erlang.system_info(:otp_release)),
      os: inspect(:os.type()),
      baseline_ref: "HEAD",
      baseline_commit: git_rev(root, "HEAD"),
      candidate_branch: candidate_branch,
      candidate_branch_commit: git_rev(root, candidate_branch),
      candidate_provenance:
        "review branch is a bare HEAD pointer; candidate reconstructed via identical mirror + C4 patch (byte-identical to C5 measurement)",
      bench_task_sha256: tool_hash(base_wt.path),
      statistic: "percentile bootstrap 95% CI over median of paired per-round relative improvement",
      decision_rule: %{
        robust_pass: "ci_low >= 0.15",
        insufficient_evidence: "ci straddles 0.15",
        fail_below_gate: "ci_high < 0.15",
        fail_memory: "memory_delta > 0.05 (overrides)"
      }
    }
  end

  defp git_rev(root, ref) do
    case System.cmd("git", ["-C", root, "rev-parse", ref], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> :unknown
    end
  end

  defp tool_hash(wt) do
    content = File.read!(Path.join(wt, @bench_task_rel))
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
  end

  # ---- finalization -----------------------------------------------------------

  defp finalize(root, ledger, base_wt, cand_wt, conclusion, results) do
    ledger = Ledger.record(ledger, :D1_VERIFICATION_RESULT, conclusion)
    report_path = Path.join(@artifact_dir, "verification_d1.md")
    File.write!(report_path, render_report(conclusion, results))

    Worktree.destroy(base_wt.path)
    Worktree.destroy(cand_wt.path)

    System.cmd("git", ["branch", "-D", "asc-verify-baseline"], cd: root, stderr_to_stdout: true)
    System.cmd("git", ["branch", "-D", "asc-verify-d1"], cd: root, stderr_to_stdout: true)

    IO.puts("\n=====================================================")
    IO.puts("  D1 VERIFICATION VERDICT: #{conclusion.verdict}")
    IO.puts("=====================================================")
    IO.puts("  Report:   #{report_path}")
    IO.puts("  Ledger:   #{ledger.path} (append-only; C6 verdict untouched)")
    IO.puts("  Branches: asc-ae001-d1_parallel_boot, asc-ae001-d2_deferred_store (preserved)")
    IO.puts("=====================================================\n")

    {conclusion.verdict, conclusion}
  end

  defp render_report(%{verdict: verdict, statistics: s}, results) do
    rounds_md =
      Enum.map_join(results, "\n", fn r ->
        "| #{r.round} | #{inspect(r.order)} | #{r.baseline.p50_ms} | #{r.candidate.p50_ms} | " <>
          "#{Float.round((r.baseline.p50_ms - r.candidate.p50_ms) / r.baseline.p50_ms * 100, 2)}% |"
      end)

    stats_md =
      if s do
        """
        - Median improvement: **#{s.median_improvement * 100}%**
        - 95% CI: [#{s.ci_95_low * 100}%, #{s.ci_95_high * 100}%]
        - Baseline p50 median: #{s.baseline_p50_median_ms} ms | Candidate p50 median: #{s.candidate_p50_median_ms} ms
        - p95 (median of per-run p95): baseline #{s.baseline_p95_median_ms} ms | candidate #{s.candidate_p95_median_ms} ms
        - Memory: #{s.memory_baseline_median_mb} MB -> #{s.memory_candidate_median_mb} MB (delta #{(s[:memory_delta] || 0) * 100}%)
        """
      else
        "_not computed_"
      end

    """
    # ASC-AE-001 — D1 Statistical Verification Addendum

    **Verdict: #{verdict}**

    The original C6 verdict (ACCEPT, first-PASS rule) is preserved unchanged.
    This addendum answers one question: *Does D1 reliably satisfy the declared
    gate under repeated measurement?*

    ## Statistics
    #{stats_md}

    ## Paired rounds
    | Round | Order | Baseline p50 (ms) | Candidate p50 (ms) | Improvement |
    |---|---|---|---|---|
    #{rounds_md}

    ## Interpretation
    - ROBUST_PASS -> eligible for human merge review (human authorizes merge; ASC never merges).
    - INSUFFICIENT_EVIDENCE -> merge held; recorded as "passed original gate, insufficient statistical evidence for adoption."
    - FAIL_BELOW_GATE / FAIL_MEMORY / FAIL_CORRECTNESS -> candidate rejected under repeated measurement; lineage preserved.
    """
  end
end