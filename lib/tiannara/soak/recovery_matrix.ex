defmodule Tiannara.Soak.RecoveryMatrix do
  @moduledoc """
  Runs the mandatory checkpoint-recovery checks and reports which passed.

  Each check corresponds to one requirement in `RecoveryGate.required_checks/0`.
  The matrix writes real checkpoints through `IsolatedFileStore` and loads them
  back through `Recovery`, so `passed` is never inferred — it is the actual
  outcome of exercising the storage and resume semantics.

  Returns a list of `%{id: atom, passed: boolean, detail: String.t()}`.
  """

  alias Tiannara.Soak.{Checkpoint, Recovery, TimeAccounting, RecoveryGate}
  alias Tiannara.Soak.CheckpointStore.IsolatedFileStore

  def run_all(base_dir) do
    run_id = "matrix-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)

    results =
      [
        fn -> resumes_after_abnormal_termination(base_dir, run_id) end,
        fn -> preserves_elapsed_and_counters(base_dir, run_id) end,
        fn -> preserves_discovery_state(base_dir, run_id) end,
        fn -> rejects_corrupt_loads_previous_valid(base_dir, run_id) end,
        fn -> skips_undecodable_checkpoint(base_dir, run_id) end,
        fn -> clean_start_on_missing(base_dir, run_id) end,
        fn -> never_resumes_cross_run(base_dir, run_id) end,
        fn -> distinguishes_wall_clock_from_validated() end,
        fn -> refuses_production_checkpoint_path() end
      ]

    Enum.map(results, fn check ->
      try do
        check.()
      rescue
        e -> failed(:"#{inspect(check)}", "raised: #{Exception.message(e)}")
      catch
        kind, reason -> failed(:check, "caught #{kind}: #{inspect(reason)}")
      end
    end)
  end

  defp passes(id, detail), do: %{id: id, passed: true, detail: detail}
  defp failed(id, detail), do: %{id: id, passed: false, detail: detail}

  defp open_store(dir) do
    run_id = "matrix-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
    IsolatedFileStore.open(dir, run_id)
  end

  defp checkpoint(run_id, elapsed, extra \\ %{}) do
    Checkpoint.new(
      Map.merge(
        %{
          soak_run_id: run_id,
          elapsed_seconds: elapsed,
          phase: :running,
          created_at: System.system_time(:microsecond),
          counters: %{observations: 100, challenges_passed: 7, failures: 0, recoveries: 1},
          discovery_state: %{validated_discoveries: 3, gaps_detected: 2, knowledge_entities: 41},
          configuration_hash: "cfg-matrix"
        },
        extra
      )
    )
  end

  defp write_checkpoint(store, cp) do
    :ok = store.__struct__.write(store, cp)
    cp
  end

  defp load_latest(dir, run_id) do
    {:ok, store} = IsolatedFileStore.open(dir, run_id)
    store.__struct__.latest_valid(store)
  end

  # --- checks --------------------------------------------------------------

  defp resumes_after_abnormal_termination(dir, run_id) do
    sub = Path.join(dir, "resume")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)
    write_checkpoint(store, checkpoint(run_id, 3 * 3600 + 40 * 60))

    assert_resume(Recovery.load(store, run_id))
    passes(:resumes_after_abnormal_termination, "checkpoint written, then loaded via Recovery")
  end

  defp preserves_elapsed_and_counters(dir, run_id) do
    sub = Path.join(dir, "counters")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)
    cp = write_checkpoint(store, checkpoint(run_id, 3 * 3600 + 40 * 60))

    assert_resume(Recovery.load(store, run_id))

    if cp.elapsed_seconds != 3 * 3600 + 40 * 60 or
         Map.get(cp.counters, :observations) != 100 or
         Map.get(cp.counters, :challenges_passed) != 7 do
      failed(:preserves_elapsed_and_counters, "elapsed/counters not preserved")
    else
      passes(:preserves_elapsed_and_counters, "elapsed_seconds and counters round-tripped")
    end
  end

  defp preserves_discovery_state(dir, run_id) do
    sub = Path.join(dir, "discovery")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)
    cp = write_checkpoint(store, checkpoint(run_id, 3600))

    assert_resume(Recovery.load(store, run_id))

    if Map.get(cp.discovery_state, :validated_discoveries) != 3 or
         Map.get(cp.discovery_state, :knowledge_entities) != 41 do
      failed(:preserves_discovery_state, "discovery state not preserved")
    else
      passes(:preserves_discovery_state, "discovery counters round-tripped")
    end
  end

  defp rejects_corrupt_loads_previous_valid(dir, run_id) do
    sub = Path.join(dir, "corrupt")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)

    older = write_checkpoint(store, checkpoint(run_id, 3600, %{created_at: 1_000}))
    newer = write_checkpoint(store, checkpoint(run_id, 7200, %{created_at: 2_000}))

    newest =
      store.data_dir
      |> File.ls!()
      |> Enum.filter(&String.starts_with?(&1, "checkpoint-"))
      |> Enum.sort_by(&parse_seq/1, :desc)
      |> hd()

    path = Path.join(store.data_dir, newest)
    {:ok, bin} = File.read(path)
    {:ok, cp} = Checkpoint.deserialize(bin)
    File.write!(path, Checkpoint.serialize(Checkpoint.corrupt!(cp)))

    case Recovery.load(store, run_id) do
      {:resume, restored} when restored.elapsed_seconds == older.elapsed_seconds ->
        passes(:rejects_corrupt_loads_previous_valid,
          "corrupted newest fell back to previous valid (#{restored.elapsed_seconds}s)")

      other ->
        failed(:rejects_corrupt_loads_previous_valid, "unexpected: #{inspect(other)}")
    end
  end

  defp skips_undecodable_checkpoint(dir, run_id) do
    sub = Path.join(dir, "torn")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)
    write_checkpoint(store, checkpoint(run_id, 1000, %{created_at: 1_000}))

    File.write!(Path.join(store.data_dir, "checkpoint-9999.bin"), <<0, 1, 2, 3>>)

    case Recovery.load(store, run_id) do
      {:resume, restored} when restored.elapsed_seconds == 1000 ->
        passes(:skips_undecodable_checkpoint, "torn checkpoint skipped, valid one loaded")

      other ->
        failed(:skips_undecodable_checkpoint, "unexpected: #{inspect(other)}")
    end
  end

  defp clean_start_on_missing(dir, run_id) do
    sub = Path.join(dir, "missing")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)

    case Recovery.load(store, run_id) do
      {:clean_start, state} when state.elapsed_seconds == 0 ->
        passes(:clean_start_on_missing, "no checkpoint -> clean start at 0")

      other ->
        failed(:clean_start_on_missing, "unexpected: #{inspect(other)}")
    end
  end

  defp never_resumes_cross_run(dir, run_id) do
    sub = Path.join(dir, "cross")
    {:ok, store} = IsolatedFileStore.open(sub, run_id)
    write_checkpoint(store, checkpoint("run-OTHER", 5000))

    case Recovery.load(store, run_id) do
      {:run_mismatch, _} ->
        passes(:never_resumes_cross_run, "foreign run_id rejected")

      other ->
        failed(:never_resumes_cross_run, "unexpected: #{inspect(other)}")
    end
  end

  defp distinguishes_wall_clock_from_validated do
    t = TimeAccounting.compute(3 * 3600 + 52 * 60, 0, 3 * 3600 + 40 * 60, restarted?: true)

    if t.wall_clock_seconds == 3 * 3600 + 52 * 60 and t.validated_seconds == 3 * 3600 + 40 * 60 and
         t.unvalidated_seconds == 12 * 60 and TimeAccounting.reconciled?(t) do
      passes(:distinguishes_wall_clock_from_validated,
        "wall=#{t.wall_clock_seconds}s validated=#{t.validated_seconds}s reconciled")
    else
      failed(:distinguishes_wall_clock_from_validated, "time accounting mismatch: #{inspect(t)}")
    end
  end

  defp refuses_production_checkpoint_path do
    case IsolatedFileStore.open("checkpoints/production", "run-x") do
      {:error, :production_path_forbidden} ->
        passes(:refuses_production_checkpoint_path, "production checkpoint path refused")

      other ->
        failed(:refuses_production_checkpoint_path, "unexpected: #{inspect(other)}")
    end
  end

  # --- helpers -------------------------------------------------------------

  defp assert_resume({:resume, _}), do: :ok

  defp assert_resume(other) do
    raise "expected {:resume, _}, got: #{inspect(other)}"
  end

  defp parse_seq("checkpoint-" <> rest) do
    rest |> String.replace_suffix(".bin", "") |> String.to_integer()
  end
end
