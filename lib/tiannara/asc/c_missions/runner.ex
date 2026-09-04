defmodule Tiannara.ASC.CMissions.Runner do
  @moduledoc """
  ASC-AE-001 Minimal Runner: executes C2 (Analysis) -> C6 (Verdict) against
  a captured C1 baseline.

  Strict acceptance gates (ACCEPT requires ALL):
    - correctness: 100% pass on test/tiannara/asc/core (--no-start)
    - regressions == 0 (same gate)
    - safety: structural — this runner has no production write/merge/deploy
      authority; candidates live and die inside isolated worktrees
    - resource: active memory delta <= +5% vs baseline
    - performance: p50 warm-boot latency reduction >= 15% vs baseline
    - evidence ledger complete
  """

  alias Tiannara.ASC.CMissions.{Ledger, Worktree}

  @target_improvement 0.15
  @max_memory_delta 0.05

  def run(baseline_path) do
    ledger = Ledger.init()

    ledger =
      Ledger.record(ledger, :C0_START, %{
        mission: "ASC-AE-001",
        target: "Reduce ASC Core Supervisor warm-boot latency by >= 15% without regressions"
      })

    baseline = load_baseline(baseline_path)
    ledger = Ledger.record(ledger, :C1_BASELINE_LOADED, baseline)

    bottleneck = "Tiannara.ASC.Core.Coordinator sequential worker bootstrap"
    ledger =
      Ledger.record(ledger, :C2_ANALYSIS, %{
        bottleneck: bottleneck,
        evidence:
          "C1 attribution: Coordinator median 0.2 ms of 0.72 ms total; next PubSub 0.2 ms; Registry 0.1 ms"
      })

    hypotheses = [
      %{
        id: "D1_Parallel_Boot",
        desc: "Parallelize independent worker starts via Task.async_stream"
      },
      %{id: "D2_Deferred_Store", desc: "Defer KnowledgeStore ETS init via {:continue, _}"}
    ]

    ledger = Ledger.record(ledger, :C3_HYPOTHESES, hypotheses)

    results =
      Enum.map(hypotheses, fn hyp ->
        execute_hypothesis(hyp, baseline, ledger)
      end)

    {verdict, selected} = evaluate_verdict(results)

    ledger =
      Ledger.record(ledger, :C6_VERDICT, %{
        decision: verdict,
        selected_hypothesis: if(selected, do: selected.hyp.id, else: nil),
        human_action_required: verdict == :ACCEPT,
        rationale:
          if(verdict == :ACCEPT,
            do: "all strict gates passed (correctness, regressions, safety, resource, performance)",
            else: "no candidate satisfied every strict gate"
          )
      })

    ledger = Ledger.record(ledger, :C7_MISSION_COMPLETE, %{evidence_ledger: :COMPLETE})

    IO.puts("\n=========================================")
    IO.puts("  MISSION ASC-AE-001 VERDICT: #{verdict}")
    IO.puts("=========================================")

    if verdict == :ACCEPT do
      IO.puts("  Action: review branch '#{selected.branch}' and merge only after human authorization.")
    else
      IO.puts("  Action: no candidates met the strict acceptance gates.")
    end

    IO.puts("  Evidence Ledger: #{ledger.path}")
    IO.puts("=========================================\n")

    {verdict, ledger}
  end

  defp execute_hypothesis(hyp, baseline, ledger) do
    IO.puts("\n--- Testing Hypothesis: #{hyp.id} (#{hyp.desc}) ---")
    branch = "asc-ae001-#{String.downcase(hyp.id)}"
    worktree = Worktree.create(branch)

    patch_result =
      try do
        apply_patch(hyp.id, worktree.path)
      rescue
        e -> {:error, inspect(e)}
      end

    ledger =
      Ledger.record(ledger, :C4_PATCH, %{
        hypothesis: hyp.id,
        branch: branch,
        sandbox: worktree.path,
        patch: patch_result
      })

    validation =
      case patch_result do
        {:ok, files} -> run_validation_gates(worktree.path, baseline, hyp.id)
        {:error, reason} -> %{status: :PATCH_FAILED, reason: reason}
      end

    ledger =
      Ledger.record(ledger, :C5_VALIDATION, %{
        hypothesis: hyp.id,
        branch: branch,
        validation: validation
      })

    Worktree.destroy(worktree.path)

    %{hyp: hyp, validation: validation, branch: branch}
  end

  # ---- C4: bounded source transformations (sandbox only) ----

  @doc """
  Applies the chartered patch for a hypothesis to a sandbox path.

  Public so the verification addendum can reconstruct the accepted
  candidate byte-identically (the review branch never contained the patch —
  it was applied as worktree working-tree changes only).
  """
  def apply_patch("D1_Parallel_Boot", path) do
    File.write!(Path.join(path, "lib/tiannara/asc/core/parallel_boot.ex"), d1_parallel_boot_source())
    File.write!(Path.join(path, "lib/tiannara/asc/core/coordinator.ex"), d1_coordinator_source())

    {:ok,
     [
       "lib/tiannara/asc/core/parallel_boot.ex (new)",
       "lib/tiannara/asc/core/coordinator.ex (bootstrap -> ParallelBoot)"
     ]}
  end

  def apply_patch("D2_Deferred_Store", path) do
    File.write!(
      Path.join(path, "lib/tiannara/asc/core/knowledge_store.ex"),
      d2_knowledge_store_source()
    )

    {:ok, ["lib/tiannara/asc/core/knowledge_store.ex (init -> {:continue, :init_ets})"]}
  end

  # ---- C5: validation gates ----

  defp run_validation_gates(sandbox_path, baseline, hyp_id) do
    IO.puts("  [C5] Correctness gate: mix test test/tiannara/asc/core (--no-start)")

    {test_out, test_status} =
      System.cmd("mix", ["test", "test/tiannara/asc/core", "--no-start"],
        cd: sandbox_path,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    tests_pass = test_status == 0

    IO.puts(
      "  [C5] Correctness gate: #{if(tests_pass, do: "PASS", else: "FAIL")} (exit #{test_status})"
    )

    IO.puts("  [C5] Performance gate: mix asc.bench.boot (n=15)")

    bench_out = Path.expand(Path.join(mission_dir(), "candidate-#{hyp_id}.eterm"))
    File.rm(bench_out)

    {bench_str, bench_status} =
      System.cmd(
        "mix",
        ["asc.bench.boot", "--n", "15", "--warmup", "2", "--out", bench_out],
        cd: sandbox_path,
        env: [{"MIX_ENV", "test"}, {"ASC_BOOT_INSTRUMENT", "1"}],
        stderr_to_stdout: true
      )

    bench_pass = bench_status == 0 and File.exists?(bench_out)
    candidate = if bench_pass, do: load_baseline(bench_out), else: nil
    deltas = if candidate, do: compute_deltas(baseline, candidate), else: nil

    IO.puts(
      "  [C5] Candidate p50: #{if(candidate, do: candidate.p50_ms, else: "n/a")} ms (baseline #{baseline.p50_ms} ms)"
    )

    gates = %{
      correctness: tests_pass,
      regressions_zero: tests_pass,
      performance_measured: bench_pass,
      safety: :PASS,
      safety_note: "structural: runner has no production write/merge/deploy authority",
      memory_delta: if(deltas, do: deltas.memory_delta, else: 999.0),
      latency_delta: if(deltas, do: deltas.latency_delta, else: -1.0),
      candidate_p50_ms: if(candidate, do: candidate.p50_ms, else: nil),
      candidate_p95_ms: if(candidate, do: candidate.p95_ms, else: nil),
      candidate_memory_mb: if(candidate, do: candidate.memory_mb, else: nil),
      test_exit: test_status,
      bench_exit: bench_status,
      test_tail: String.slice(test_out, -1500, 1500),
      bench_tail: String.slice(bench_str, -800, 800)
    }

    Map.put(gates, :status, gate_status(gates))
  end

  @doc """
  Deterministic gate verdict: PASS only when every strict gate holds.
  """
  def gate_status(gates) do
    if gates.correctness and gates.regressions_zero and gates.performance_measured and
         gates.safety == :PASS and gates.memory_delta <= @max_memory_delta and
         gates.latency_delta >= @target_improvement do
      :PASS
    else
      :FAIL
    end
  end

  @doc """
  Baseline vs candidate deltas. Positive latency_delta = improvement.
  """
  def compute_deltas(base, cand) do
    %{
      memory_delta: (cand.memory_mb - base.memory_mb) / base.memory_mb,
      latency_delta: (base.p50_ms - cand.p50_ms) / base.p50_ms
    }
  end

  @doc """
  Strict selection: first hypothesis that passed every gate.
  """
  def evaluate_verdict(results) do
    case Enum.find(results, fn r -> r.validation[:status] == :PASS end) do
      nil -> {:REJECT, nil}
      best -> {:ACCEPT, best}
    end
  end

  defp load_baseline(path) do
    if File.exists?(path) do
      {result, _meta} = :erlang.binary_to_term(File.read!(path))
      result
    else
      raise "C1 baseline not found at #{path}. Run `mix asc.bench.boot` first."
    end
  end

  defp mission_dir, do: "priv/asc/missions/ASC-AE-001"

  defp d1_parallel_boot_source do
    """
    defmodule Tiannara.ASC.Core.ParallelBoot do
      @moduledoc \"\"\"
      C4 patch D1 (ASC-AE-001): parallel worker bootstrap.

      Starts independent required workers concurrently instead of
      sequentially. Workers self-register in init under unique per-role
      names and share no mutable state, so parallel startup is safe.
      Failures still crash the coordinator loudly (constitution: no silent
      partial boots).
      \"\"\"

      alias Tiannara.ASC.Core.Worker

      def bootstrap(workers) do
        workers
        |> Task.async_stream(
          &boot_worker/1,
          max_concurrency: System.schedulers_online(),
          timeout: 15_000,
          ordered: false
        )
        |> Enum.each(fn
          {:ok, :ok} -> :ok
          {:ok, :already_started} -> :ok
          {:ok, {:error, reason}} -> raise "ASC worker failed to boot: \#{inspect(reason)}"
          {:error, reason} -> raise "ASC worker boot task failed: \#{inspect(reason)}"
        end)
      end

      defp boot_worker(spec) do
        child = %{
          id: spec.role,
          start: {Worker, :start_link, [spec]},
          restart: :transient
        }

        case DynamicSupervisor.start_child(Tiannara.ASC.Core.WorkerSupervisor, child) do
          {:ok, _pid} -> :ok
          {:ok, _pid, _} -> :ok
          {:error, {:already_started, _pid}} -> :already_started
          {:error, reason} -> {:error, reason}
        end
      end
    end
    """
  end

  defp d1_coordinator_source do
    """
    defmodule Tiannara.ASC.Core.Coordinator do
      @moduledoc \"\"\"
      Boots the required ASC workers through the WorkerSupervisor and exposes
      core health. A worker boot failure crashes the coordinator loudly —
      silent partial boots are a constitution violation.
      \"\"\"

      use GenServer

      alias Tiannara.ASC.Core.Worker

      def start_link(opts \\\\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

      def required_workers, do: Application.get_env(:tiannara, :asc_required_workers, [])

      def health do
        required = Enum.map(required_workers(), & &1.role)

        registered =
          required
          |> Enum.filter(fn role -> match?({:ok, _}, Worker.whereis(role)) end)

        %{required: required, registered: registered, missing: required -- registered}
      end

      @impl true
      def init(_opts) do
        bootstrap()
        {:ok, %{bootstrapped_at: System.system_time(:millisecond)}}
      end

      defp bootstrap do
        Tiannara.ASC.Core.ParallelBoot.bootstrap(required_workers())
      end
    end
    """
  end

  defp d2_knowledge_store_source do
    """
    defmodule Tiannara.ASC.Core.KnowledgeStore do
      @moduledoc \"\"\"
      Shared evidence/knowledge memory (Data -> Information -> Knowledge path).

      Entries carry trace_id and parent_id for lineage:

          {id, trace_id, kind, payload, parent_id, seq, inserted_at}

      KNOWN BOTTLENECK (recorded, not hidden): ETS state is lost on store
      crash. Persistence through the Milestone A DETS substrate is a Milestone
      C experiment, not part of B's scope.
      \"\"\"

      use GenServer

      @table :asc_knowledge

      def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

      def put(kind, payload, opts \\\\ []) do
        GenServer.call(__MODULE__, {:put, kind, payload, opts})
      end

      def get(id) do
        case :ets.lookup(@table, id) do
          [entry] -> {:ok, entry}
          [] -> {:error, :not_found}
        end
      end

      def by_trace(trace_id) do
        @table
        |> :ets.tab2list()
        |> Enum.filter(fn {_id, t, _k, _p, _par, _seq, _ts} -> t == trace_id end)
        |> Enum.sort_by(fn {_id, _t, _k, _p, _par, seq, _ts} -> seq end)
      end

      def search(topic) when is_binary(topic) do
        @table
        |> :ets.tab2list()
        |> Enum.filter(fn {_id, _t, _k, payload, _par, _seq, _ts} ->
          String.contains?(inspect(payload), topic)
        end)
      end

      @impl true
      def init(_) do
        {:ok, %{seq: 0}, {:continue, :init_ets}}
      end

      @impl true
      def handle_continue(:init_ets, state) do
        if :ets.whereis(@table) == :undefined do
          :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
        end

        {:noreply, state}
      end

      @impl true
      def handle_call({:put, kind, payload, opts}, _from, %{seq: seq} = state) do
        id = {:k, System.unique_integer([:monotonic, :positive])}
        trace_id = Keyword.get(opts, :trace_id)
        parent_id = Keyword.get(opts, :parent_id)

        entry = {id, trace_id, kind, payload, parent_id, seq, System.system_time(:millisecond)}
        :ets.insert(@table, entry)

        {:reply, {:ok, id}, %{state | seq: seq + 1}}
      end
    end
    """
  end
end