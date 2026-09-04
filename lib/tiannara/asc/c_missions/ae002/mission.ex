defmodule Tiannara.ASC.CMissions.AE002.Mission do
  @moduledoc """
  ASC-AE-002 mission spec: discrimination test on RepairLibrary boot ingestion.
  Candidates are ranked blind; ground truth lives in the sealed labels file.

  Anchors are byte-exact against lib/tiannara/asc/crucible/repair_library.ex
  (verified at authoring time). The boot ingestion loop lives in
  `load_persisted_patterns/0`:

      path
      |> File.stream!([], :line)
      |> Enum.reduce(0, fn line, acc -> ... insert_bounded(pattern) ... end)

  Each candidate replaces that loop expression (op 1) and injects its
  implementation before the module end (op 2, anchored on the unique tail of
  `persist_pattern/1`).

  Workload note: measurement runs on `data/repair_patterns.ae002.ndjson` —
  the first 6000 lines of the production archive. The full 18k-line archive
  makes the baseline boot O(n^2) (per-row `:ets.match_delete` full scans) and
  thus ~77s/boot: a 15-round mission would run ~10 hours. The 6k subset
  preserves the same O(n^2)-vs-O(n) discrimination at ~9s/boot (~1.5h
  mission). Lineage and SHA-256 are recorded in the PROTOCOL ledger entry.

  WARNING: heredoc closers (`"""`) must sit at column 0, or Elixir strips
  common indentation and the anchors no longer match the source bytes.
  """

  @bench_rel "bench/ae002_ingestion_bench.exs"

  # Injected identically (byte-for-byte, hash-verified) into every arm.
  # Arguments arrive via env (AE002_*) — mix run argv semantics are avoided.
  @bench_script ~S"""
  archive = System.get_env("AE002_ARCHIVE") || raise("AE002_ARCHIVE is required")
  n = String.to_integer(System.get_env("AE002_N") || "15")
  warm = String.to_integer(System.get_env("AE002_WARM") || "2")
  out = System.get_env("AE002_OUT") || raise("AE002_OUT is required")

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

  measure = fn ->
    case Process.whereis(target) do
      nil -> :ok
      pid -> GenServer.stop(pid, :normal, 15_000)
    end

    {us, result} = :timer.tc(fn -> target.start_link([]) end)

    case result do
      {:ok, _pid} ->
        :ok

      other ->
        IO.puts("BENCH_ABORT: start_link failed: #{inspect(other)}")
        System.halt(3)
    end

    us / 1_000
  end

  Enum.each(1..warm, fn _ -> measure.() end)
  samples = Enum.map(1..n, fn _ -> measure.() end)
  sorted = Enum.sort(samples)

  :erlang.garbage_collect()
  :timer.sleep(300)

  File.write!(
    out,
    :erlang.term_to_binary(%{
      p50_ms: Enum.at(sorted, div(n, 2)),
      samples_ms: samples,
      memory_mb: (:erlang.memory(:processes_used) + :erlang.memory(:ets)) / (1024 * 1024),
      n: n
    })
  )

  IO.puts("p50=#{Float.round(Enum.at(sorted, div(n, 2)), 3)}ms")
  """

  # Byte-exact ingestion loop expression of load_persisted_patterns/0.
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

  def spec do
    %{
      id: "ASC-AE-002",
      objective:
        "Discrimination test: rank RepairLibrary boot-ingestion candidates by paired " <>
          "statistical evidence; adopt only a genuinely beneficial optimization.",
      target: "Tiannara.ASC.Crucible.RepairLibrary boot ingestion (18k-entry NDJSON archive)",
      gate_latency: 0.10,
      gate_memory: 0.05,
      rounds: 15,
      n_per_run: 5,
      warm_per_call: 1,
      seed: {20_260_818, 2, 1},
      bench_rel: @bench_rel,
      bench_script: @bench_script,
      labels_path: "priv/asc/missions/ASC-AE-002/labels.sealed.exs",
      correctness_paths: ["test/tiannara/asc/crucible", "test/tiannara/asc/core"],
      commit_paths: ["lib", "test", "config", "bench", "mix.exs", "mix.lock"],
      archive_rel: "data/repair_patterns.ae002.ndjson",
      candidates: [parallel_ingest(), bulk_ingest(), recursive_ingest()]
    }
  end

  # Candidate A — the D1-analog trap.
  defp parallel_ingest do
    %{
      id: :parallel_ingest,
      hypothesis: "Parallelizing archive insertion across tasks reduces ingestion latency.",
      prediction: "p50 ingestion improves >= 10% via concurrent ETS writes.",
      falsifier: "Paired 95% CI upper bound < 10% falsifies the hypothesis.",
      files: [
        %{
          path: "lib/tiannara/asc/crucible/repair_library.ex",
          ops: [
            {@ingest_loop,
             """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> parallel_ingest()
"""},
            {@module_tail,
             """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end

  # AE-002 candidate A: parallel chunk ingestion.
  defp parallel_ingest(stream) do
    stream
    |> Stream.chunk_every(2_000)
    |> Task.async_stream(
      fn chunk ->
        Enum.reduce(chunk, 0, fn line, acc ->
          case decode_archive_line(line) do
            {:ok, %{id: id} = pattern} when is_binary(id) ->
              insert_bounded(pattern)
              acc + 1

            _ ->
              acc
          end
        end)
      end,
      max_concurrency: System.schedulers_online(),
      timeout: 60_000,
      on_timeout: :kill_task
    )
    |> Enum.reduce(0, fn
      {:ok, n}, acc -> acc + n
      _err, acc -> acc
    end)
  end
"""}
          ]
        }
      ]
    }
  end

  # Candidate B — genuine optimization: per-row ETS ops replaced by bulk inserts.
  defp bulk_ingest do
    %{
      id: :bulk_ingest,
      hypothesis: "Per-row ETS overhead dominates ingestion; bulk insertion removes it.",
      prediction: "p50 ingestion improves >= 10% with identical final table contents.",
      falsifier: "Paired 95% CI upper bound < 10% falsifies the hypothesis.",
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

  # AE-002 candidate B: bulk ETS insertion with direct seq assignment.
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

  # Candidate C — plausible, expected-neutral traversal change.
  defp recursive_ingest do
    %{
      id: :recursive_ingest,
      hypothesis: "Recursive traversal removes per-row enumeration overhead.",
      prediction: "p50 ingestion improves >= 10% by avoiding Enum dispatch.",
      falsifier: "Paired 95% CI upper bound < 10% falsifies the hypothesis.",
      files: [
        %{
          path: "lib/tiannara/asc/crucible/repair_library.ex",
          ops: [
            {@ingest_loop,
             """
      raw_loaded =
        path
        |> File.stream!([], :line)
        |> Enum.to_list()
        |> recursive_ingest()
"""},
            {@module_tail,
             """
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(persistence_file(), json_line <> "\\n", [:append])
  end

  # AE-002 candidate C: recursive traversal.
  defp recursive_ingest(lines), do: do_recursive_ingest(lines, 0)

  defp do_recursive_ingest([], acc), do: acc

  defp do_recursive_ingest([line | rest], acc) do
    n =
      case decode_archive_line(line) do
        {:ok, %{id: id} = pattern} when is_binary(id) ->
          insert_bounded(pattern)
          acc + 1

        _ ->
          acc
      end

    do_recursive_ingest(rest, n)
  end
"""}
          ]
        }
      ]
    }
  end
end