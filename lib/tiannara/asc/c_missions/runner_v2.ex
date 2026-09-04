defmodule Tiannara.ASC.CMissions.RunnerV2 do
  @moduledoc """
  Evidence-ranked autonomous engineering runner (C-mission v2).

  Encodes the ASC-AE-001 architectural lesson: a candidate passing a
  deterministic gate is not sufficient evidence for adoption when the
  measured advantage is near the decision boundary.

  Upgrades over v1:
    1. Same-environment rule — baseline and all candidates measured as
       paired, interleaved, counterbalanced rounds inside one run.
    2. Statistical validation inside the mission (bootstrap 95% CI tiers).
    3. Evidence ranking (tier, effect size, CI width). No first-PASS.
    4. Falsification records as first-class knowledge.
    5. At most ADOPTION_ELIGIBLE — adoption remains human-authorized.

  Instrument blindness: ground-truth labels are hashed at pre-registration
  and read ONLY in score_discrimination/4, after ranking, verdict, and
  falsification records are finalized and persisted.

  Sandbox arms reuse the v1 mirror worktree (same battle-tested builder):
  arms are created at HEAD, overlaid with the real working tree (lib/test/
  config/mix/deps/priv minus priv/asc), and candidate patches are applied
  as working-tree changes then committed onto sandbox branches (lineage is
  real this time; `deps/` is never committed).
  """

  alias Tiannara.ASC.CMissions.{Ledger, Stats, Worktree}

  def run(mission) do
    ledger = Ledger.init("priv/asc/missions/#{mission.id}")
    root = File.cwd!()
    labels_path = Path.join(root, mission.labels_path)
    labels_hash = sha256_file(labels_path)

    ledger = Ledger.record(ledger, :PROTOCOL, pre_registration(mission, labels_hash))
    IO.puts("[AE-002] Protocol pre-registered. Gate=#{mission.gate_latency}, rounds=#{mission.rounds}")

    case build_arms(root, mission) do
      {:ok, arms, prep_notes} ->
        ledger = Ledger.record(ledger, :ARMS, prep_notes)

        with :ok <- verify_bench_integrity(arms, mission),
             {:ok, correctness, ledger} <- correctness_gate(arms, mission, ledger) do
          survivors = for c <- mission.candidates, correctness[c.id].status == :pass, do: c
          eliminated = for c <- mission.candidates, correctness[c.id].status != :pass, do: c.id
          ledger = Ledger.record(ledger, :CORRECTNESS_ELIMINATED, eliminated)

          IO.puts("[AE-002] Measuring #{mission.rounds} paired rounds over #{length(survivors) + 1} arms...")
          results = paired_rounds(arms, mission, survivors)

          stats = per_candidate_stats(results, mission, survivors)
          ranked = rank(stats)
          {verdict, selected} = select(ranked)

          fals = falsifications(mission, ranked, eliminated)

          ledger =
            ledger
            |> Ledger.record(:STATISTICS, stats)
            |> Ledger.record(:RANKING, ranked)
            |> Ledger.record(:FALSIFICATIONS, fals)
            |> Ledger.record(:VERDICT, %{verdict: verdict, selected: selected})

          knowledge = write_knowledge(mission, ranked, verdict, selected, fals)
          ledger = Ledger.record(ledger, :KNOWLEDGE, knowledge)

          # --- sealed-label scoring: only after everything above is persisted ---
          disc = score_discrimination(labels_path, labels_hash, ranked, fals)
          ledger = Ledger.record(ledger, :DISCRIMINATION_SCORE, disc)

          finalize(root, arms, mission, ledger, verdict, selected, disc)
        else
          {:error, stage, reason} ->
            Ledger.record(ledger, :ABORT, %{stage: stage, reason: inspect(reason)})
            IO.puts("[AE-002] ABORT at #{stage}: #{inspect(reason)}")
            {:error, stage, reason}
        end

      {:error, reason} ->
        Ledger.record(ledger, :ABORT, %{stage: :arm_preparation, reason: inspect(reason)})
        IO.puts("[AE-002] ABORT at arm preparation: #{inspect(reason)}")
        {:error, :arm_preparation, reason}
    end
  end

  # ---- pre-registration ------------------------------------------------------

  defp pre_registration(mission, labels_hash) do
    %{
      mission: mission.id,
      objective: mission.objective,
      target: mission.target,
      gate_latency: mission.gate_latency,
      gate_memory: mission.gate_memory,
      rounds: mission.rounds,
      n_per_run: mission.n_per_run,
      warm_per_call: mission.warm_per_call,
      order: "interleaved, rotated per round (counterbalanced)",
      statistic: "bootstrap 95% CI over median of paired per-round relative improvement",
      seed: mission.seed,
      archive: mission.archive_rel,
      correctness_paths: mission.correctness_paths,
      decision_rule: %{
        eligible: "ci_low >= gate",
        rejected: "ci_high < gate",
        insufficient: "CI straddles gate",
        memory_override: "memory_delta > gate_memory => rejected_memory"
      },
      selection_rule: "rank by {tier, -median, ci_width}; select strongest eligible; else NO_ADOPTION",
      sealed_labels_sha256: labels_hash,
      environment_locked: %{
        mix_env: "test",
        set_by: "harness",
        bench_args: "env AE002_ARCHIVE/AE002_N/AE002_WARM/AE002_OUT"
      },
      elixir: System.version(),
      otp: to_string(:erlang.system_info(:otp_release)),
      amendment:
        "RUN 2: run 1 aborted after round 10 of 15 (external console termination, exit 0). " <>
          "bulk_ingest failed the correctness gate in run 1 (boot-retention test: missing bounded " <>
          "eviction on bulk load); candidate corrected to preserve the bound, re-committed. " <>
          "Labels file untouched (hash identical). All gates, rules, and parameters unchanged."
    }
  end

  # ---- arm preparation -------------------------------------------------------

  defp build_arms(root, mission) do
    baseline_wt = Worktree.create("asc-ae002-baseline")

    cand_results =
      Enum.map(mission.candidates, fn cand ->
        branch = "asc-ae002-#{cand.id}"
        wt = Worktree.create(branch)

        bench_path = Path.join(wt.path, mission.bench_rel)
        File.mkdir_p!(Path.dirname(bench_path))
        File.write!(bench_path, mission.bench_script)

        case apply_patch(wt.path, cand) do
          :ok ->
            commit_candidate(wt.path, cand.id, mission.commit_paths)
            {:ok, cand.id, wt.path, branch}

          {:error, reason} ->
            Worktree.destroy(wt.path)
            {:error, %{candidate: cand.id, stage: :patch, reason: reason}}
        end
      end)

    {failed, arms_cands} = Enum.split_with(cand_results, &match?({:error, _}, &1))

    prep_notes = %{
      baseline: %{path: baseline_wt.path, commit: git_rev(root, "HEAD")},
      candidates:
        Enum.map(arms_cands, fn {:ok, id, wt, branch} -> %{id: id, path: wt, branch: branch} end),
      patch_failures: Enum.map(failed, fn {:error, e} -> e end)
    }

    arms = Map.merge(%{baseline: baseline_wt.path}, Map.new(arms_cands, fn {:ok, id, wt, _} -> {id, wt} end))

    # Identical measurement instrument injected into every arm (uncommitted copy)
    Enum.each(arms, fn {_id, wt} ->
      path = Path.join(wt, mission.bench_rel)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, mission.bench_script)
    end)

    # Compile all arms before measurement; one discarded warm call each
    Enum.each(arms, fn {_id, wt} ->
      {_, 0} =
        System.cmd("mix", ["compile"], cd: wt, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

      _ = bench!(wt, mission, Path.join(System.tmp_dir!(), "ae002_prep_warm.eterm"))
    end)

    {:ok, arms, prep_notes}
  end

  defp commit_candidate(wt, cand_id, paths) do
    existing = Enum.filter(paths, fn p -> File.exists?(Path.join(wt, p)) end)

    case System.cmd("git", ["-C", wt, "add", "--"] ++ existing, stderr_to_stdout: true) do
      {_, 0} ->
        case System.cmd(
               "git",
               ["-C", wt, "commit", "-m", "ASC-AE-002 candidate #{cand_id} (sandboxed, automated)"],
               stderr_to_stdout: true
             ) do
          {_, 0} -> :ok
          {out, _} -> {:commit_failed, String.slice(out, 0, 200)}
        end

      {out, _} ->
        {:commit_failed, String.slice(out, 0, 200)}
    end
  end

  # ---- bounded patch engine (exact-once anchors, loud drift, syntax-verified) --

  def apply_patch(wt, cand) do
    Enum.reduce_while(cand.files, :ok, fn %{path: rel, ops: ops}, :ok ->
      path = Path.join(wt, rel)

      if File.exists?(path) do
        src = File.read!(path)

        # EOL-adaptive: anchors are authored LF-normal; adapt to the file's
        # dominant newline so byte-exact matching holds for CRLF sources too.
        {src, ops} =
          if String.contains?(src, "\r\n") do
            adapted =
              Enum.map(ops, fn {a, r} ->
                {String.replace(a, "\n", "\r\n"), String.replace(r, "\n", "\r\n")}
              end)

            {src, adapted}
          else
            {src, ops}
          end

        result =
          Enum.reduce_while(ops, {:ok, src}, fn {anchor, replacement}, {:ok, acc} ->
            if occurrences(acc, anchor) == 1 do
              {:cont, {:ok, String.replace(acc, anchor, replacement, global: false)}}
            else
              {:halt, {:error, {:shape_drift, rel, String.slice(anchor, 0, 60), occurrences(acc, anchor)}}}
            end
          end)

        case result do
          {:ok, new_src} ->
            case Code.string_to_quoted(new_src) do
              {:ok, _} ->
                File.write!(path, new_src)
                {:cont, :ok}

              {:error, e} ->
                {:halt, {:error, {:syntax_invalid, rel, inspect(e)}}}
            end

          {:error, _} = e ->
            {:halt, e}
        end
      else
        {:halt, {:error, {:shape_drift, rel, :file_missing}}}
      end
    end)
  end

  defp occurrences(src, anchor) do
    if anchor == "" do
      0
    else
      div(
        String.length(src) - String.length(String.replace(src, anchor, "")),
        String.length(anchor)
      )
    end
  end

  # ---- integrity + correctness gates -----------------------------------------

  defp verify_bench_integrity(arms, mission) do
    hashes =
      arms
      |> Enum.map(fn {_id, wt} -> sha256_file(Path.join(wt, mission.bench_rel)) end)
      |> Enum.uniq()

    if length(hashes) == 1 and hd(hashes) == sha256_bytes(mission.bench_script) do
      :ok
    else
      {:error, :bench_instrument_divergence}
    end
  end

  defp correctness_gate(arms, mission, ledger) do
    results =
      Map.new(arms, fn {id, wt} ->
        IO.puts("[AE-002] correctness gate: #{id}")
        paths = mission.correctness_paths

        {output, status} =
          System.cmd("mix", ["test"] ++ paths ++ ["--no-start"],
            cd: wt,
            env: [{"MIX_ENV", "test"}],
            stderr_to_stdout: true
          )

        summary =
          case Regex.run(~r/(\d+) tests?, (\d+) failures?/, output) do
            [_, p, f] -> %{passed: String.to_integer(p), failed: String.to_integer(f)}
            _ -> %{passed: 0, failed: -1}
          end

        {id,
         %{status: if(status == 0 and summary.failed == 0, do: :pass, else: :fail), summary: summary}}
      end)

    {:ok, results, Ledger.record(ledger, :CORRECTNESS, results)}
  end

  # ---- paired measurement ------------------------------------------------------

  defp paired_rounds(arms, mission, survivors) do
    arm_ids = [:baseline | Enum.map(survivors, & &1.id)]

    for r <- 1..mission.rounds do
      order = rotate(arm_ids, r - 1)
      IO.write("  round #{r}/#{mission.rounds} ...")

      row =
        Enum.reduce(order, %{round: r, order: order}, fn arm_id, acc ->
          _warm = bench!(arms[arm_id], mission, Path.join(System.tmp_dir!(), "ae002_warm.eterm"))
          out = Path.expand("priv/asc/missions/#{mission.id}/rounds/r#{String.pad_leading("#{r}", 2, "0")}_#{arm_id}.eterm")
          File.mkdir_p!(Path.dirname(out))
          Map.put(acc, arm_id, bench!(arms[arm_id], mission, out))
        end)

      IO.puts(" base=#{Float.round(row[:baseline].p50_ms, 3)}ms")
      row
    end
  end

  defp rotate(list, k), do: Enum.drop(list, k) ++ Enum.take(list, k)

  defp bench!(wt, mission, out_path) do
    archive = Path.expand(mission.archive_rel)

    env = [
      {"MIX_ENV", "test"},
      {"AE002_ARCHIVE", archive},
      {"AE002_N", "#{mission.n_per_run}"},
      {"AE002_WARM", "#{mission.warm_per_call}"},
      {"AE002_OUT", out_path}
    ]

    {output, status} =
      System.cmd("mix", ["run", "--no-start", mission.bench_rel], cd: wt, env: env, stderr_to_stdout: true)

    cond do
      status != 0 -> raise "bench failed in #{wt}:\n#{String.slice(output, 0, 800)}"
      String.contains?(output, "BENCH_ABORT") -> raise "bench aborted in #{wt}:\n#{output}"
      true -> :erlang.binary_to_term(File.read!(out_path))
    end
  end

  # ---- statistics, ranking, selection ----------------------------------------

  defp per_candidate_stats(results, mission, survivors) do
    for c <- survivors do
      deltas =
        Enum.map(results, fn row ->
          (row[:baseline].p50_ms - row[c.id].p50_ms) / row[:baseline].p50_ms
        end)

      med = Stats.median(deltas)
      ci = Stats.bootstrap_ci(deltas, seed: mission.seed)

      mem_base = Stats.median(Enum.map(results, & &1[:baseline].memory_mb))
      mem_cand = Stats.median(Enum.map(results, & &1[c.id].memory_mb))
      mem_delta = (mem_cand - mem_base) / max(mem_base, 0.0001)

      tier =
        if mem_delta > mission.gate_memory,
          do: :rejected_memory,
          else: Stats.decide(med, ci, mission.gate_latency)

      %{
        candidate: c.id,
        hypothesis: c.hypothesis,
        median_improvement: Float.round(med, 5),
        ci_95: {Float.round(elem(ci, 0), 5), Float.round(elem(ci, 1), 5)},
        ci_width: Float.round(elem(ci, 1) - elem(ci, 0), 5),
        rounds_negative: Stats.rounds_negative(deltas),
        memory_delta: Float.round(mem_delta, 5),
        tier: tier
      }
    end
  end

  @tier_order %{eligible: 0, insufficient_evidence: 1, rejected_memory: 2, rejected: 2}

  defp rank(stats) do
    Enum.sort_by(stats, fn s -> {@tier_order[s.tier], -s.median_improvement, s.ci_width} end)
  end

  defp select([]), do: {:no_adoption_no_candidates, nil}

  defp select([%{tier: :eligible} = top | _]), do: {:adoption_eligible, top.candidate}
  defp select(ranked), do: {:no_adoption, hd(ranked).candidate}

  # ---- falsification records (first-class knowledge) --------------------------

  defp falsifications(mission, ranked, eliminated) do
    from_ranking =
      for s <- ranked, s.tier != :eligible do
        cand = Enum.find(mission.candidates, &(&1.id == s.candidate))

        %{
          candidate: s.candidate,
          hypothesis: cand.hypothesis,
          prediction: cand.prediction,
          falsifier: cand.falsifier,
          evidence: %{
            median_improvement: s.median_improvement,
            ci_95: s.ci_95,
            rounds_negative: s.rounds_negative,
            memory_delta: s.memory_delta
          },
          status:
            case s.tier do
              :rejected -> :falsified
              :rejected_memory -> :falsified_resource
              :insufficient_evidence -> :insufficient_evidence
            end,
          updated_conclusion: conclusion_for(s.tier)
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
          updated_conclusion: "Failed the correctness gate; excluded before measurement."
        }
      end

    from_ranking ++ from_elimination
  end

  defp conclusion_for(:rejected),
    do: "Rejected for this workload under paired repeated measurement."

  defp conclusion_for(:rejected_memory),
    do: "Rejected: resource gate violated under repeated measurement."

  defp conclusion_for(:insufficient_evidence),
    do: "Not adopted: evidence insufficient to clear the gate; neither confirmed nor falsified."

  # ---- knowledge artifact -------------------------------------------------------

  defp write_knowledge(mission, ranked, verdict, selected, fals) do
    dir = "priv/asc/missions/#{mission.id}"
    File.mkdir_p!(dir)

    artifact = %{
      mission: mission.id,
      objective: mission.objective,
      verdict: verdict,
      selected: selected,
      ranking: ranked,
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

  # ---- sealed-label discrimination scoring ---------------------------------------

  defp score_discrimination(labels_path, sealed_hash, ranked, fals) do
    if sha256_file(labels_path) != sealed_hash do
      %{status: :aborted_labels_modified_after_registration, pass: false}
    else
      {labels, _} = Code.eval_file(labels_path)

      accepted = for r <- ranked, r.tier == :eligible, do: r.candidate

      top =
        case ranked do
          [first | _] -> first.candidate
          [] -> nil
        end

      ds1 = top == labels.genuine
      ds2 = Enum.all?(labels.non_beneficial, &(&1 not in accepted))
      ds3 =
        Enum.all?(ranked, fn r ->
          r.tier == :eligible or Enum.any?(fals, &(&1.candidate == r.candidate))
        end)

      %{
        pass: ds1 and ds2 and ds3,
        ds1_top_ranked_is_genuine: ds1,
        ds2_no_non_beneficial_accepted: ds2,
        ds3_falsification_records_complete: ds3,
        accepted: accepted,
        revealed_labels: labels
      }
    end
  end

  # ---- finalization -------------------------------------------------------------

  defp finalize(root, arms, mission, ledger, verdict, selected, disc) do
    report = Path.expand("priv/asc/missions/#{mission.id}/report.md")
    File.write!(report, render_report(mission, verdict, selected, disc, ledger))

    Enum.each(arms, fn {_id, wt} -> Worktree.destroy(wt) end)

    IO.puts("\n========================================================")
    IO.puts("  #{mission.id} VERDICT: #{verdict}  (selected: #{inspect(selected)})")

    IO.puts(
      "  DISCRIMINATION SCORE: pass=#{disc[:pass]} ds1=#{disc[:ds1_top_ranked_is_genuine]} " <>
        "ds2=#{disc[:ds2_no_non_beneficial_accepted]} ds3=#{disc[:ds3_falsification_records_complete]}"
    )

    IO.puts("========================================================")
    IO.puts("  Report: #{report}")
    IO.puts("  Ledger: #{ledger.path}")
    IO.puts("  Candidate branches preserved (worktrees destroyed).")
    IO.puts("  Adoption requires human authorization. No merge capability exists.")
    IO.puts("========================================================\n")

    {verdict, selected, disc}
  end

  defp render_report(mission, verdict, selected, disc, ledger) do
    entries = Ledger.entries(ledger)
    entry = fn phase -> entries |> Enum.filter(&(&1.phase == phase)) |> List.first() end

    ranking = entry.(:RANKING) && entry.(:RANKING).data
    fals = entry.(:FALSIFICATIONS) && entry.(:FALSIFICATIONS).data

    """
    # #{mission.id} — Evidence-Ranked Autonomous Engineering Mission

    **Verdict: #{verdict}** | Selected: #{inspect(selected)}
    **Discrimination score: pass=#{disc[:pass]}** (ds1=#{disc[:ds1_top_ranked_is_genuine]}, ds2=#{disc[:ds2_no_non_beneficial_accepted]}, ds3=#{disc[:ds3_falsification_records_complete]})

    ## Ranking
    ```
    #{inspect(ranking, pretty: true, limit: :infinity)}
    ```

    ## Falsification records
    ```
    #{inspect(fals, pretty: true, limit: :infinity)}
    ```

    ## Revealed ground truth (unsealed after verdict finalization)
    ```
    #{inspect(disc[:revealed_labels], pretty: true)}
    ```

    Adoption gate: #{if verdict == :adoption_eligible, do: "HUMAN AUTHORIZATION REQUIRED", else: "no candidate eligible; nothing to adopt"}
    """
  end

  # ---- utils ------------------------------------------------------------------

  defp sha256_file(path), do: sha256_bytes(File.read!(path))
  defp sha256_bytes(bin), do: :crypto.hash(:sha256, bin) |> Base.encode16(case: :lower)

  defp git_rev(root, ref) do
    case System.cmd("git", ["-C", root, "rev-parse", ref], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> :unknown
    end
  end
end