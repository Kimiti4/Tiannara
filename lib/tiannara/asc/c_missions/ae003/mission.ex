defmodule Tiannara.ASC.CMissions.AE003.Mission do
  @moduledoc """
  ASC-AE-003 mission spec: tradeoff-aware engineering under K-AE003.

  Answers the open question recorded in K-002: is bulk_ingest's +31.8%
  post-boot memory a transient peak (reclaimable by a forced GC) or truly
  retained? The bench instrument separates the two:

    - mem_boot_mb — VM total right after boot, BEFORE any GC (transient peak)
    - mem_gc_mb   — VM total after GC of every process (retained)

  Decision logic is the pre-declared K-AE003 contract (Contract module):
  statuses from CIs, Pareto front over {latency, retained}, final verdict
  (accept_eligible / review / reject_no_adoption). The contract map is
  hashed into the PROTOCOL ledger entry before any measurement.

  Candidates:
    A. bulk_ingest      — AE-002 lineage, byte-identical (unchanged).
    B. bulk_gc_ingest   — bulk + one forced GC at the end of init.
    C. chunked_bulk_ingest — 2k-row bulk chunks, bounded transient memory.

  Anchors are byte-exact against lib/tiannara/asc/crucible/repair_library.ex
  (same anchors proven in ASC-AE-002). Workload: data/repair_patterns.ae002.ndjson
  (first 6000 lines; SHA-256 recorded in the PROTOCOL).

  WARNING: heredoc closers (`"""`) must sit at column 0, or Elixir strips
  common indentation and the anchors no longer match the source bytes.
  """

  @bench_rel "bench/ae003_ingestion_bench.exs"

  # Injected identically (byte-for-byte, hash-verified) into every arm.
  # Arguments arrive via env (AE003_*) — mix run argv semantics are avoided.
  @bench_script ~S"""
  archive = System.get_env("AE003_ARCHIVE") || raise("AE003_ARCHIVE is required")
  n = String.to_integer(System.get_env("AE003_N") || "15")
  warm = String.to_integer(System.get_env("AE003_WARM") || "2")
  out = System.get_env("AE003_OUT") || raise("AE003_OUT is required")

  Application.put_env(
    :tiannara,
    :asc,
    Keyword.merge(Application.get_env(:tiannara, :asc, []),
      repair_library_persistence_file: archive
    )
  )

  target = Tiannara.ASC.Crucible.RepairLibrary

  unless Code.ensure_loaded?(target) and function_exported?(target, :start_link, 1) do
    IO.puts("BENCH_ABORT: target module shape mismatch (expected start_link/1)")
    System.halt(2)
  end

  gc_all = fn ->
    Enum.each(Process.list(), fn pid ->
      :erlang.garbage_collect(pid)
    end)
  end

  measure = fn ->
    case Process.whereis(target) do
      nil -> :ok
      pid -> GenServer.stop(pid, :normal, 15_000)
    end

    gc_all.()

    {us, result} = :timer.tc(fn -> target.start_link([]) end)

    case result do
      {:ok, _pid} ->
        :ok

      other ->
        IO.puts("BENCH_ABORT: start_link failed: #{inspect(other)}")
        System.halt(3)
    end

    mem_boot_mb = :erlang.memory(:total) / (1024 * 1024)

    gc_all.()

    mem_gc_mb = :erlang.memory(:total) / (1024 * 1024)

    %{boot_ms: us / 1_000, mem_boot_mb: mem_boot_mb, mem_gc_mb: mem_gc_mb}
  end

  Enum.each(1..warm, fn _ -> measure.() end)
  samples = Enum.map(1..n, fn _ -> measure.() end)

  boot_ms = Enum.map(samples, & &1.boot_ms)
  sorted = Enum.sort(boot_ms)

  File.write!(
    out,
    :erlang.term_to_binary(%{
      p50_ms: Enum.at(sorted, div(n, 2)),
      samples_ms: sorted,
      mem_boot_mb_samples: Enum.map(samples, & &1.mem_boot_mb),
      mem_gc_mb_samples: Enum.map(samples, & &1.mem_gc_mb),
      n: n
    })
  )

  IO.puts("p50=#{Float.round(Enum.at(sorted, div(n, 2)), 3)}ms")
  """

  # Byte-exact ingestion loop expression of load_persisted_patterns/0.
  # Same anchor as ASC-AE-002 (verified byte-exact at AE-002 authoring time;
  # repair_library.ex has not changed since).
  @ingest_loop """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> Enum.reduce(0, fn line, acc ->
          case decode_archive_line(line) do
            {:ok, %{id: id} = pattern} when is_binary(id) ->
              insert_bounded(pattern)
              acc + 1

            _ ->
              acc
          end
        end)
"""

  # Byte-exact tail of persist_pattern/1 (ends just before the module end).
  @module_tail """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end
"""

  # ---- K-AE003: pre-declared contract thresholds ---------------------------------

  defp contract do
    %{
      peak_ceiling: 0.25,
      retained_reject_floor: 0.15,
      latency_no_effect_ceiling: 0.25,
      retained_ceiling: 0.05,
      latency_adoption_floor: 0.25,
      review_band_retained_max: 0.15,
      review_band_latency_min: 0.60
    }
  end

  def spec do
    %{
      id: "ASC-AE-003",
      objective:
        "Tradeoff-aware engineering: is bulk-load memory a transient peak or retained? " <>
          "Under the pre-declared K-AE003 contract, separate transient peak from " <>
          "retained memory and decide adoption only when the measured tradeoff clears it.",
      target: "Tiannara.ASC.Crucible.RepairLibrary boot ingestion (6k-line derived archive)",
      contract: contract(),
      rounds: 15,
      n_per_run: 15,
      warm_per_call: 2,
      seed: {20_260_818, 3, 1},
      bench_rel: @bench_rel,
      bench_script: @bench_script,
      bench_env: %{
        archive: "AE003_ARCHIVE",
        n: "AE003_N",
        warm: "AE003_WARM",
        out: "AE003_OUT"
      },
      oracle_path: "priv/asc/missions/ASC-AE-003/oracle.sealed.exs",
      correctness_paths: ["test/tiannara/asc/crucible", "test/tiannara/asc/core"],
      commit_paths: ["lib", "test", "config", "bench", "mix.exs", "mix.lock"],
      archive_rel: "data/repair_patterns.ae002.ndjson",
      candidates: [bulk_ingest(), bulk_gc_ingest(), chunked_bulk_ingest()]
    }
  end

  # Candidate A — AE-002 lineage, byte-identical (proven in ASC-AE-002 run 2).
  defp bulk_ingest do
    %{
      id: :bulk_ingest,
      hypothesis:
        "AE-002 lineage, unchanged: per-row ETS overhead removed by bulk insertion.",
      prediction:
        "Latency improves >= 25% (adoption floor). The transient peak (pre-GC) " <>
          "reproduces the AE-002 +31.8%; whether it survives as retained memory " <>
          "after a forced GC answers the K-002 open question.",
      falsifier:
        "peak_ci.low > 0.25 (reject_peak) or retained_ci.low > 0.15 (rejected_memory) " <>
          "or latency_ci.high < 0.25 (rejected_no_effect).",
      files: [
        %{
          path: "lib/tiannara/asc/crucible/repair_library.ex",
          ops: [
            {@ingest_loop,
             """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> bulk_ingest()
"""},
            {@module_tail,
             """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end

  # AE-003 candidate A: bulk ETS insertion with direct seq assignment.
  # Byte-identical to the ASC-AE-002 candidate that passed correctness 9/9.
  defp bulk_ingest(stream) do
    {count, rows, seq_rows} =
      Enum.reduce(stream, {0, %{}, %{}}, fn line, {acc, rows, seq_rows} ->
        case decode_archive_line(line) do
          {:ok, %{id: id} = pattern} when is_binary(id) ->
            seq = acc + 1
            {seq, Map.put(rows, id, pattern), Map.put(seq_rows, id, seq)}

          _ ->
            {acc, rows, seq_rows}
        end
      end)

    if count > 0 do
      :ets.insert(@table_name, Map.to_list(rows))
      :ets.insert(@seq_table, Enum.map(seq_rows, fn {id, seq} -> {seq, id} end))
      :ets.insert(@meta_table, {:seq, count})

      overflow = count - max_patterns()
      if overflow > 0, do: Enum.each(1..overflow, fn _ -> evict_oldest() end)
    end

    count
  end
"""}
          ]
        }
      ]
    }
  end

  # Candidate B — bulk + one forced GC at the end of init.
  defp bulk_gc_ingest do
    %{
      id: :bulk_gc_ingest,
      hypothesis:
        "The AE-002 memory delta is a transient peak in the library process heap; " <>
          "one forced GC at the end of init reclaims it without losing the latency win.",
      prediction:
        "Latency >= 25% (as bulk) with peak_ci and retained_ci both inside their " <>
          "ceilings -> eligible; discriminates the K-002 worlds (transient vs retained).",
      falsifier:
        "peak_ci.low > 0.25 or retained_ci.low > 0.15 (memory is genuinely retained) " <>
          "or latency_ci.high < 0.25.",
      files: [
        %{
          path: "lib/tiannara/asc/crucible/repair_library.ex",
          ops: [
            {@ingest_loop,
             """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> bulk_gc_ingest()
"""},
            {@module_tail,
             """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end

  # AE-003 candidate B: bulk insertion + one forced GC at the end of init.
  defp bulk_gc_ingest(stream) do
    {count, rows, seq_rows} =
      Enum.reduce(stream, {0, %{}, %{}}, fn line, {acc, rows, seq_rows} ->
        case decode_archive_line(line) do
          {:ok, %{id: id} = pattern} when is_binary(id) ->
            seq = acc + 1
            {seq, Map.put(rows, id, pattern), Map.put(seq_rows, id, seq)}

          _ ->
            {acc, rows, seq_rows}
        end
      end)

    if count > 0 do
      :ets.insert(@table_name, Map.to_list(rows))
      :ets.insert(@seq_table, Enum.map(seq_rows, fn {id, seq} -> {seq, id} end))
      :ets.insert(@meta_table, {:seq, count})

      overflow = count - max_patterns()
      if overflow > 0, do: Enum.each(1..overflow, fn _ -> evict_oldest() end)
    end

    :erlang.garbage_collect()
    count
  end
"""}
          ]
        }
      ]
    }
  end

  # Candidate C — bounded 2k-row bulk chunks: bulk-style writes, bounded
  # transient memory (chunk-local maps instead of whole-archive maps).
  defp chunked_bulk_ingest do
    %{
      id: :chunked_bulk_ingest,
      hypothesis:
        "Chunking the bulk load bounds the transient peak (chunk-local maps) " <>
          "while retaining most of the latency win: a middle path in the tradeoff space.",
      prediction:
        "Latency between baseline and bulk; peak and retained CIs small enough to " <>
          "clear the ceilings; may land in :eligible or :review_band.",
      falsifier:
        "latency_ci.high < 0.25 (rejected_no_effect) or peak_ci.low > 0.25 " <>
          "or retained_ci.low > 0.15.",
      files: [
        %{
          path: "lib/tiannara/asc/crucible/repair_library.ex",
          ops: [
            {@ingest_loop,
             """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> chunked_bulk_ingest()
"""},
            {@module_tail,
             """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end

  # AE-003 candidate C: 2k-row bulk chunks with bounded transient memory.
  defp chunked_bulk_ingest(stream) do
    {total, _seen} =
      stream
      |> Stream.chunk_every(2_000)
      |> Enum.reduce({0, %{}}, fn chunk, {total, seen} ->
        {count, rows, seq_rows} =
          Enum.reduce(chunk, {0, %{}, %{}}, fn line, {acc, rows, seq_rows} ->
            case decode_archive_line(line) do
              {:ok, %{id: id} = pattern} when is_binary(id) ->
                {acc + 1, Map.put(rows, id, pattern), Map.put(seq_rows, id, acc + 1)}

              _ ->
                {acc, rows, seq_rows}
            end
          end)

        if count > 0 do
          base = :ets.update_counter(@meta_table, :seq, {2, count}) - count

          # Retire stale seq rows for ids re-inserted across chunks (last wins)
          Enum.each(rows, fn {id, _p} ->
            if Map.has_key?(seen, id) do
              :ets.match_delete(@seq_table, {:"$1", id})
            end
          end)

          :ets.insert(@table_name, Map.to_list(rows))
          :ets.insert(@seq_table, Enum.map(seq_rows, fn {id, pos} -> {base + pos, id} end))

          {total + count, Map.merge(seen, seq_rows)}
        else
          {total, seen}
        end
      end)

    if total > 0 do
      # Size-based bound enforcement (matches baseline's per-insert condition)
      bound = max_patterns()

      case :ets.info(@table_name, :size) do
        size when size > bound ->
          Enum.each(1..(size - bound), fn _ -> evict_oldest() end)

        _ ->
          :ok
      end
    end

    total
  end
"""}
          ]
        }
      ]
    }
  end
end