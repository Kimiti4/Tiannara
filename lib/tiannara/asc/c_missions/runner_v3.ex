defmodule Tiannara.ASC.CMissions.RunnerV3 do
  @moduledoc """
  Tradeoff-aware autonomous engineering runner (C-mission v3).

  Encodes the ASC-AE-002 lesson: a memory/latency tradeoff must be judged
  under a PRE-DECLARED value function, never invented after seeing results.

  Upgrades over v2:
    1. K-AE003 contract — pre-declared thresholds hashed into the PROTOCOL
       ledger entry before any measurement; the runner cannot alter the
       decision rule after seeing candidate evidence.
    2. Two-objective measurement — latency plus memory, with the transient
       peak (pre-GC) separated from retained memory (post-forced-GC).
    3. Pareto front over {latency, retained}; verdict by the Contract module
       (accept_eligible / review / reject_no_adoption).
    4. CONTRACT_FIDELITY — a sealed oracle (hash-registered in PROTOCOL,
       executed only after finalization) independently recomputes statuses,
       front, and verdict from the recorded statistics; any mismatch halts.

  Sandbox arms: v2 mirror worktrees (Infrastructure). Adoption remains
  human-authorized; no merge capability exists.
  """

  alias Tiannara.ASC.CMissions.{Contract, Infrastructure, Ledger, Stats}

  def run(mission) do
    ledger = Ledger.init("priv/asc/missions/#{mission.id}")
    root = File.cwd!()
    oracle_path = Path.expand(mission.oracle_path)

    contract_sha256 = Infrastructure.sha256_bytes(:erlang.term_to_binary(mission.contract))
    oracle_sha256 = Infrastructure.sha256_file(oracle_path)

    ledger =
      Ledger.record(
        ledger,
        :PROTOCOL,
        pre_registration(mission, contract_sha256, oracle_sha256)
      )

    IO.puts(
      "[AE-003] Protocol pre-registered. contract=#{String.slice(contract_sha256, 0, 12)} " <>
        "oracle=#{String.slice(oracle_sha256, 0, 12)}"
    )

    case build_arms(root, mission) do
      {:ok, arms, prep_notes} ->
        ledger = Ledger.record(ledger, :ARMS, prep_notes)

        with :ok <- verify_bench_integrity(arms, mission),
             {:ok, correctness, ledger} <- correctness_gate(arms, mission, ledger),
             {:ok, hard, ledger} <- hard_correctness_gate(arms, mission, ledger) do
          pass? = fn id -> correctness[id].status == :pass and hard[id].status == :pass end

          survivors = for c <- mission.candidates, pass?.(c.id), do: c
          eliminated = for c <- mission.candidates, not pass?.(c.id), do: c.id
          ledger = Ledger.record(ledger, :CORRECTNESS_ELIMINATED, eliminated)

          IO.puts(
            "[AE-003] Measuring #{mission.rounds} paired rounds over #{length(survivors) + 1} arms..."
          )

          results = paired_rounds(arms, mission, survivors)

          stats = per_candidate_stats(results, mission, survivors)

          statused =
            Enum.map(stats, &Map.put(&1, :status, Contract.candidate_status(&1, mission.contract)))

          ledger = Ledger.record(ledger, :STATISTICS, stats)
          ledger = Ledger.record(ledger, :STATUSES, Enum.map(statused, &{&1.candidate, &1.status}))

          {verdict, front} = Contract.final_decision(statused)
          ledger = Ledger.record(ledger, :FRONT, %{verdict: verdict, front: front})

          fals = falsifications(mission, statused, eliminated)
          ledger = Ledger.record(ledger, :FALSIFICATIONS, fals)
          ledger = Ledger.record(ledger, :VERDICT, %{verdict: verdict, front: front})

          knowledge = write_knowledge(mission, statused, verdict, front, fals)
          ledger = Ledger.record(ledger, :KNOWLEDGE, knowledge)

          fidelity =
            check_contract_fidelity(ledger, oracle_path, oracle_sha256)

          ledger = Ledger.record(ledger, :CONTRACT_FIDELITY, fidelity)

          finalize(root, arms, mission, ledger, verdict, front, fidelity)
        else
          {:error, stage, reason} ->
            Ledger.record(ledger, :ABORT, %{stage: stage, reason: inspect(reason)})
            IO.puts("[AE-003] ABORT at #{stage}: #{inspect(reason)}")
            {:error, stage, reason}
        end

      {:error, reason} ->
        Ledger.record(ledger, :ABORT, %{stage: :arm_preparation, reason: inspect(reason)})
        IO.puts("[AE-003] ABORT at arm preparation: #{inspect(reason)}")
        {:error, :arm_preparation, reason}
    end
  end

  # ---- pre-registration ------------------------------------------------------

  defp pre_registration(mission, contract_sha256, oracle_sha256) do
    %{
      mission: mission.id,
      objective: mission.objective,
      target: mission.target,
      contract: mission.contract,
      contract_sha256: contract_sha256,
      oracle_path: mission.oracle_path,
      oracle_sha256: oracle_sha256,
      decision_rule: %{
        candidate_status:
          "peak_ci.low > peak_ceiling => rejected_peak; " <>
            "retained_ci.low > retained_reject_floor => rejected_memory; " <>
            "latency_ci.high < latency_no_effect_ceiling => rejected_no_effect; " <>
            "retained_ci.high <= retained_ceiling AND latency_ci.low >= latency_adoption_floor => eligible; " <>
            "retained_ci.high <= review_band_retained_max AND latency_ci.low >= review_band_latency_min => review_band; " <>
            "else insufficient",
        front:
          "Pareto over {latency (higher better), retained (lower better)}: " <>
            "not-worse = CI overlap; better = CIs strictly separated; " <>
            "dominates = not-worse on all + better on at least one",
        final:
          "front == [lone eligible] => accept_eligible; front == [] => reject_no_adoption; else review"
      },
      rounds: mission.rounds,
      n_per_run: mission.n_per_run,
      warm_per_call: mission.warm_per_call,
      order: "interleaved, rotated per round (counterbalanced)",
      statistic:
        "bootstrap 95% CI over median of paired per-round relative deltas " <>
          "(latency, transient peak, retained)",
      measurement_basis:
        "VM :erlang.memory(:total); pre-GC = transient peak; " <>
          "post-forced-GC (all processes) = retained",
      seed: mission.seed,
      archive: mission.archive_rel,
      archive_sha256: Infrastructure.sha256_file(Path.expand(mission.archive_rel)),
      correctness_paths: mission.correctness_paths,
      environment_locked: %{
        mix_env: "test",
        set_by: "harness",
        bench_args: "env AE003_ARCHIVE/AE003_N/AE003_WARM/AE003_OUT"
      },
      elixir: System.version(),
      otp: to_string(:erlang.system_info(:otp_release))
    }
  end

  # ---- arm preparation -------------------------------------------------------

  defp build_arms(root, mission) do
    baseline_wt = Infrastructure.fresh_worktree("asc-ae003-baseline")

    cand_results =
      Enum.map(mission.candidates, fn cand ->
        branch = "asc-ae003-#{cand.id}"
        wt = Infrastructure.fresh_worktree(branch)

        bench_path = Path.join(wt.path, mission.bench_rel)
        File.mkdir_p!(Path.dirname(bench_path))
        File.write!(bench_path, mission.bench_script)

        case Infrastructure.apply_patch(wt.path, cand) do
          :ok ->
            Infrastructure.commit_candidate(wt.path, cand.id, mission.commit_paths, mission.id)
            {:ok, cand.id, wt.path, branch}

          {:error, reason} ->
            Infrastructure.destroy_worktree(wt.path)
            {:error, %{candidate: cand.id, stage: :patch, reason: reason}}
        end
      end)

    {failed, arms_cands} = Enum.split_with(cand_results, &match?({:error, _}, &1))

    prep_notes = %{
      baseline: %{path: baseline_wt.path, commit: Infrastructure.git_rev(root, "HEAD")},
      candidates:
        Enum.map(arms_cands, fn {:ok, id, wt, branch} ->
          %{id: id, path: wt, branch: branch}
        end),
      patch_failures: Enum.map(failed, fn {:error, e} -> e end)
    }

    arms =
      Map.merge(%{baseline: baseline_wt.path},
        Map.new(arms_cands, fn {:ok, id, wt, _} -> {id, wt} end)
      )

    # Identical measurement instrument injected into every arm (uncommitted copy)
    Enum.each(arms, fn {_id, wt} ->
      path = Path.join(wt, mission.bench_rel)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, mission.bench_script)
    end)

    # Compile all arms before measurement; one discarded warm call each
    Enum.each(arms, fn {_id, wt} ->
      Infrastructure.compile_arm(wt)
      _ = Infrastructure.bench!(wt, mission, Path.join(System.tmp_dir!(), "ae003_prep_warm.eterm"))
    end)

    {:ok, arms, prep_notes}
  end

  # ---- integrity + correctness gates -----------------------------------------

  defp verify_bench_integrity(arms, mission) do
    hashes =
      arms
      |> Enum.map(fn {_id, wt} -> Infrastructure.sha256_file(Path.join(wt, mission.bench_rel)) end)
      |> Enum.uniq()

    if length(hashes) == 1 and hd(hashes) == Infrastructure.sha256_bytes(mission.bench_script) do
      :ok
    else
      {:error, :bench_instrument_divergence}
    end
  end

  defp correctness_gate(arms, mission, ledger) do
    results =
      Map.new(arms, fn {id, wt} ->
        IO.puts("[AE-003] correctness gate: #{id}")
        {status, summary} = Infrastructure.correctness(wt, mission.correctness_paths)
        {id, %{status: status, summary: summary}}
      end)

    {:ok, results, Ledger.record(ledger, :CORRECTNESS, results)}
  end

  # Hard gate: boot each arm against the REAL mission archive and require the
  # same final bounded table (count + integrity) as the baseline arm.
  defp hard_correctness_gate(arms, mission, ledger) do
    script = hard_gate_script()

    results =
      Map.new(arms, fn {id, wt} ->
        IO.puts("[AE-003] hard correctness gate (real archive boot): #{id}")
        {count, integrity} = run_hard_gate(wt, mission, script)
        {id, %{status: if(integrity and count > 0, do: :pass, else: :fail), count: count, integrity: integrity}}
      end)

    reference = results[:baseline]

    statused =
      Map.new(results, fn {id, %{count: count, integrity: integrity} = r} ->
        ok = integrity and count == reference.count
        {id, Map.merge(r, %{status: if(ok, do: :pass, else: :fail), reference_count: reference.count})}
      end)

    {:ok, statused, Ledger.record(ledger, :HARD_CORRECTNESS, statused)}
  end

  defp hard_gate_script do
    ~S"""
    archive = System.get_env("AE003_ARCHIVE") || raise("AE003_ARCHIVE is required")

    Application.put_env(
      :tiannara,
      :asc,
      Keyword.merge(Application.get_env(:tiannara, :asc, []),
        repair_library_persistence_file: archive
      )
    )

    target = Tiannara.ASC.Crucible.RepairLibrary
    {:ok, _pid} = target.start_link([])
    count = target.pattern_count()
    integrity = target.verify_integrity()
    IO.puts("HARD_GATE count=#{count} integrity=#{integrity}")
    System.halt(0)
    """
  end

  defp run_hard_gate(wt, mission, script) do
    path = Path.join(wt, "bench/ae003_hard_gate.exs")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, script)

    env = [
      {"MIX_ENV", "test"},
      {"AE003_ARCHIVE", Path.expand(mission.archive_rel)}
    ]

    {output, status} =
      System.cmd("mix", ["run", "--no-start", "bench/ae003_hard_gate.exs"],
        cd: wt,
        env: env,
        stderr_to_stdout: true
      )

    case Regex.run(~r/HARD_GATE count=(\d+) integrity=(true|false)/, output) do
      [_, count, integrity] ->
        {String.to_integer(count), integrity == "true"}

      _ ->
        raise "hard gate output unparseable in #{wt} (status #{status}):\n#{String.slice(output, 0, 800)}"
    end
  end

  # ---- paired measurement ------------------------------------------------------

  defp paired_rounds(arms, mission, survivors) do
    arm_ids = [:baseline | Enum.map(survivors, & &1.id)]

    for r <- 1..mission.rounds do
      order = Infrastructure.rotate(arm_ids, r - 1)
      IO.write("  round #{r}/#{mission.rounds} ...")

      row =
        Enum.reduce(order, %{round: r, order: order}, fn arm_id, acc ->
          _warm = Infrastructure.bench!(arms[arm_id], mission, Path.join(System.tmp_dir!(), "ae003_warm.eterm"))

          out =
            Path.expand(
              "priv/asc/missions/#{mission.id}/rounds/r#{String.pad_leading("#{r}", 2, "0")}_#{arm_id}.eterm"
            )

          File.mkdir_p!(Path.dirname(out))
          Map.put(acc, arm_id, Infrastructure.bench!(arms[arm_id], mission, out))
        end)

      IO.puts(" base=#{Float.round(row[:baseline].p50_ms, 3)}ms")
      row
    end
  end

  # ---- statistics, statuses, verdict --------------------------------------------

  defp per_candidate_stats(results, mission, survivors) do
    for c <- survivors do
      latency_deltas =
        Enum.map(results, fn row ->
          (row[:baseline].p50_ms - row[c.id].p50_ms) / row[:baseline].p50_ms
        end)

      peak_deltas =
        Enum.map(results, fn row ->
          b = Stats.median(row[:baseline].mem_boot_mb_samples)
          x = Stats.median(row[c.id].mem_boot_mb_samples)
          (x - b) / max(b, 0.0001)
        end)

      retained_deltas =
        Enum.map(results, fn row ->
          b = Stats.median(row[:baseline].mem_gc_mb_samples)
          x = Stats.median(row[c.id].mem_gc_mb_samples)
          (x - b) / max(b, 0.0001)
        end)

      med = Stats.median(latency_deltas)
      ci = Stats.bootstrap_ci(latency_deltas, seed: mission.seed)
      peak_ci = Stats.bootstrap_ci(peak_deltas, seed: mission.seed)
      retained_ci = Stats.bootstrap_ci(retained_deltas, seed: mission.seed)

      %{
        candidate: c.id,
        hypothesis: c.hypothesis,
        median_improvement: Float.round(med, 5),
        ci_95: {Float.round(elem(ci, 0), 5), Float.round(elem(ci, 1), 5)},
        ci_width: Float.round(elem(ci, 1) - elem(ci, 0), 5),
        rounds_negative: Stats.rounds_negative(latency_deltas),
        peak_delta: Float.round(Stats.median(peak_deltas), 5),
        peak_ci: {Float.round(elem(peak_ci, 0), 5), Float.round(elem(peak_ci, 1), 5)},
        retained_delta: Float.round(Stats.median(retained_deltas), 5),
        retained_ci: {Float.round(elem(retained_ci, 0), 5), Float.round(elem(retained_ci, 1), 5)}
      }
    end
  end

  # ---- falsification records (first-class knowledge) ---------------------------

  defp falsifications(mission, statused, eliminated) do
    from_status =
      for s <- statused,
          s.status in [:rejected_peak, :rejected_memory, :rejected_no_effect, :insufficient] do
        cand = Enum.find(mission.candidates, &(&1.id == s.candidate))

        %{
          candidate: s.candidate,
          hypothesis: cand.hypothesis,
          prediction: cand.prediction,
          falsifier: cand.falsifier,
          evidence: %{
            median_improvement: s.median_improvement,
            ci_95: s.ci_95,
            peak_ci: s.peak_ci,
            retained_ci: s.retained_ci,
            rounds_negative: s.rounds_negative
          },
          status:
            case s.status do
              :rejected_peak -> :falsified_resource
              :rejected_memory -> :falsified_resource
              :rejected_no_effect -> :falsified
              :insufficient -> :insufficient_evidence
            end,
          updated_conclusion:
            case s.status do
              :rejected_peak ->
                "Rejected: transient peak violates the pre-declared ceiling."

              :rejected_memory ->
                "Rejected: retained memory violates the pre-declared reject floor."

              :rejected_no_effect ->
                "Rejected for this workload under paired repeated measurement."

              :insufficient ->
                "Not decided: evidence insufficient to clear the contract; neither confirmed nor falsified."
            end
        }
      end

    from_elimination =
      for id <- eliminated do
        cand = Enum.find(mission.candidates, &(&1.id == id))

        %{
          candidate: id,
          hypothesis: cand.hypothesis,
          status: :eliminated_correctness,
          evidence: %{},
          updated_conclusion:
            "Failed a correctness gate (unit suite or real-archive boot); excluded before measurement."
        }
      end

    from_status ++ from_elimination
  end

  # ---- knowledge artifact --------------------------------------------------------

  defp write_knowledge(mission, statused, verdict, front, fals) do
    dir = "priv/asc/missions/#{mission.id}"
    File.mkdir_p!(dir)

    artifact = %{
      mission: mission.id,
      objective: mission.objective,
      contract: mission.contract,
      verdict: verdict,
      front: front,
      statuses: Enum.map(statused, &{&1.candidate, &1.status}),
      falsifications: fals,
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    File.write!(Path.join(dir, "knowledge.eterm"), :erlang.term_to_binary(artifact))

    store_status =
      if Process.whereis(Tiannara.ASC.Core.KnowledgeStore) do
        {:ok, id} =
          Tiannara.ASC.Core.KnowledgeStore.put(:engineering_knowledge, artifact, trace_id: mission.id)

        {:archived, id}
      else
        :skipped_no_store_running
      end

    %{file: Path.join(dir, "knowledge.eterm"), store: store_status}
  end

  # ---- contract fidelity oracle -----------------------------------------------------

  @doc """
  Runs the sealed oracle AFTER the verdict is finalized. The oracle reads the
  PERSISTED ledger (contract, statistics, statuses, verdict) and independently
  recomputes statuses, front, and verdict from the recorded statistics. Exact
  match required; the oracle file must be byte-identical to its PROTOCOL hash
  (modification after sealing is a fatal signal).
  """
  def check_contract_fidelity(ledger, oracle_path, sealed_hash) do
    current_hash = Infrastructure.sha256_file(oracle_path)

    if current_hash != sealed_hash do
      %{
        pass: false,
        reason: :oracle_modified_after_sealing,
        sealed_sha256: sealed_hash,
        current_sha256: current_hash
      }
    else
      entries = Ledger.entries(ledger)
      entry = fn phase -> entries |> Enum.filter(&(&1.phase == phase)) |> List.first() end

      contract = entry.(:PROTOCOL).data.contract
      stats = entry.(:STATISTICS).data
      statuses = entry.(:STATUSES).data
      verdict_entry = entry.(:VERDICT).data

      Code.require_file(oracle_path)

      runner_outcome = %{
        statuses: Map.new(statuses),
        front: verdict_entry.front,
        verdict: verdict_entry.verdict
      }

      Tiannara.ASC.CMissions.OracleAE003.check(contract, stats, runner_outcome)
    end
  end

  # ---- finalization ---------------------------------------------------------------

  defp finalize(root, arms, mission, ledger, verdict, front, fidelity) do
    report = Path.expand("priv/asc/missions/#{mission.id}/report.md")
    File.write!(report, render_report(mission, verdict, front, fidelity, ledger))

    Enum.each(arms, fn {_id, wt} -> Infrastructure.destroy_worktree(wt) end)

    IO.puts("\n========================================================")
    IO.puts("  #{mission.id} VERDICT: #{verdict}  (front: #{inspect(front)})")

    IO.puts(
      "  CONTRACT FIDELITY: pass=#{fidelity[:pass]} " <>
        "(oracle_verdict=#{inspect(fidelity[:oracle_verdict])} oracle_front=#{inspect(fidelity[:oracle_front])})"
    )

    IO.puts("========================================================")
    IO.puts("  Report: #{report}")
    IO.puts("  Ledger: #{ledger.path}")
    IO.puts("  Candidate branches preserved (worktrees destroyed).")
    IO.puts("  Adoption requires human authorization. No merge capability exists.")
    IO.puts("========================================================\n")

    unless fidelity[:pass] do
      IO.puts("[AE-003] CONTRACT FIDELITY FAILURE — halting: #{inspect(fidelity[:reason])}")
      System.halt(1)
    end

    {verdict, front, fidelity}
  end

  defp render_report(mission, verdict, front, fidelity, ledger) do
    entries = Ledger.entries(ledger)
    entry = fn phase -> entries |> Enum.filter(&(&1.phase == phase)) |> List.first() end

    statuses = entry.(:STATUSES) && entry.(:STATUSES).data
    stats = entry.(:STATISTICS) && entry.(:STATISTICS).data
    fals = entry.(:FALSIFICATIONS) && entry.(:FALSIFICATIONS).data
    hard = entry.(:HARD_CORRECTNESS) && entry.(:HARD_CORRECTNESS).data

    """
    # #{mission.id} — Tradeoff-Aware Engineering Mission (contract K-AE003)

    **Verdict: #{verdict}** | Front: #{inspect(front)}
    **Contract fidelity (sealed oracle): pass=#{fidelity[:pass]}**
    (oracle_verdict=#{inspect(fidelity[:oracle_verdict])}, oracle_front=#{inspect(fidelity[:oracle_front])})

    ## Pre-declared contract (K-AE003)
    ```
    #{inspect(mission.contract, pretty: true)}
    ```

    ## Candidate statuses
    ```
    #{inspect(statuses, pretty: true)}
    ```

    ## Statistics (paired, per-round medians + bootstrap 95% CIs)
    ```
    #{inspect(stats, pretty: true, limit: :infinity)}
    ```

    ## Hard correctness (real-archive boot: count == baseline, integrity)
    ```
    #{inspect(hard, pretty: true, limit: :infinity)}
    ```

    ## Falsification records
    ```
    #{inspect(fals, pretty: true, limit: :infinity)}
    ```

    Adoption gate: #{if verdict == :accept_eligible, do: "HUMAN AUTHORIZATION REQUIRED (REVIEW never adopts)", else: "nothing adopted by this mission"}
    """
  end
end