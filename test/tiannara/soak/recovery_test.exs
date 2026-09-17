defmodule Tiannara.Soak.RecoveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Soak.{Checkpoint, Recovery, TimeAccounting, RecoveryGate}
  alias Tiannara.Soak.CheckpointStore.IsolatedFileStore

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "tiannara_soak_recovery_#{System.unique_integer([:positive])}"
      )

    run_id = "run-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
    {:ok, store} = IsolatedFileStore.open(dir, run_id)
    on_exit(fn -> File.rm_rf!(dir) end)

    {:ok, store: store, run_id: run_id}
  end

  defp checkpoint(run_id, elapsed, extra \\ %{}) do
    Checkpoint.new(
      Map.merge(
        %{
          soak_run_id: run_id,
          elapsed_seconds: elapsed,
          phase: :running,
          created_at: System.system_time(:microsecond),
          counters: %{observations: 100},
          discovery_state: %{validated_discoveries: 3},
          configuration_hash: "cfg-abc"
        },
        extra
      )
    )
  end

  test "resumes after abnormal termination; does not reset to 0",
       %{store: store, run_id: run_id} do
    cp = checkpoint(run_id, 3 * 3600 + 40 * 60)
    :ok = store.__struct__.write(store, cp)

    # Abrupt termination happens here (no graceful shutdown).

    assert {:resume, restored} = Recovery.load(store, run_id)
    assert restored.elapsed_seconds == 3 * 3600 + 40 * 60
    assert restored.counters.observations == 100
    assert restored.discovery_state.validated_discoveries == 3
  end

  test "integrated: crash -> restart -> resume -> reconciled report",
       %{store: store, run_id: run_id} do
    t_checkpoint = 3 * 3600 + 40 * 60
    cp = checkpoint(run_id, t_checkpoint, %{created_at: t_checkpoint})
    :ok = store.__struct__.write(store, cp)

    # Crash at ~3h45m; restart at 3h52m wall-clock.
    restart_wall = 3 * 3600 + 52 * 60

    assert {:resume, restored} = Recovery.load(store, run_id)
    assert restored.elapsed_seconds == t_checkpoint

    t = TimeAccounting.compute(restart_wall, 0, restored.elapsed_seconds, restarted?: true)

    assert t.validated_seconds == t_checkpoint
    assert t.wall_clock_seconds == restart_wall
    assert t.unvalidated_seconds == restart_wall - t_checkpoint
    assert TimeAccounting.reconciled?(t)
    assert TimeAccounting.report(t) =~ "Validated soak time"
  end

  test "corrupted latest checkpoint falls back to previous valid",
       %{store: store, run_id: run_id} do
    older = checkpoint(run_id, 3600, %{created_at: 1_000})
    newer = checkpoint(run_id, 7200, %{created_at: 2_000})

    :ok = store.__struct__.write(store, older)
    :ok = store.__struct__.write(store, newer)

    corrupt_newest_on_disk(store)

    assert {:resume, restored} = Recovery.load(store, run_id)
    assert restored.elapsed_seconds == 3600
  end

  test "undecodable (torn) checkpoint file is skipped",
       %{store: store, run_id: run_id} do
    valid = checkpoint(run_id, 1000, %{created_at: 1_000})
    :ok = store.__struct__.write(store, valid)

    File.write!(Path.join(store.data_dir, "checkpoint-9999.bin"), <<0, 1, 2, 3>>)

    assert {:resume, restored} = Recovery.load(store, run_id)
    assert restored.elapsed_seconds == 1000
  end

  test "missing checkpoint -> clean start at 0", %{store: store, run_id: run_id} do
    assert {:clean_start, state} = Recovery.load(store, run_id)
    assert state.elapsed_seconds == 0
  end

  test "never resumes across run IDs", %{store: store, run_id: run_id} do
    foreign = checkpoint("run-OTHER", 5000)
    :ok = store.__struct__.write(store, foreign)

    assert {:run_mismatch, _} = Recovery.load(store, run_id)
  end

  test "wall-clock vs validated are distinguished and reconcile" do
    t = TimeAccounting.compute(3 * 3600 + 52 * 60, 0, 3 * 3600 + 40 * 60, restarted?: true)

    assert t.wall_clock_seconds == 3 * 3600 + 52 * 60
    assert t.validated_seconds == 3 * 3600 + 40 * 60
    assert t.unvalidated_seconds == 12 * 60
    assert t.consistent?
    assert TimeAccounting.reconciled?(t)
  end

  test "refuses the production checkpoint path" do
    assert {:error, :production_path_forbidden} =
             IsolatedFileStore.open("checkpoints/production", "run-x")
  end

  test "recovery gate is closed until all checks pass" do
    assert {:gate_closed, missing} = RecoveryGate.verdict([])
    assert length(missing) == length(RecoveryGate.required_checks())

    assert :gate_open == RecoveryGate.verdict(RecoveryGate.required_checks())
  end

  # --- helper ---

  defp corrupt_newest_on_disk(store) do
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
  end

  defp parse_seq("checkpoint-" <> rest) do
    rest |> String.replace_suffix(".bin", "") |> String.to_integer()
  end
end
