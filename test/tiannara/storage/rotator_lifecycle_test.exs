defmodule Tiannara.Storage.RotatorLifecycleTest do
  use ExUnit.Case, async: false

  alias Tiannara.Storage.{Rotator, DetsLifecycle}

  @default_rotate_bytes 1_800_000_000
  @default_retention_hours 720

  defmodule TestStore do
    @moduledoc """
    Minimal store implementing the lifecycle contract (dets_path/0, rotate/0,
    prune/0) backed by its own DETS table.
    """

    use GenServer

    @table :rotator_lifecycle_test_store

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def table, do: Application.get_env(:tiannara, :rotator_test_table, @table)
    def dets_path, do: Application.fetch_env!(:tiannara, :rotator_test_path)
    def rotate, do: GenServer.call(__MODULE__, :rotate, 60_000)
    def prune, do: GenServer.call(__MODULE__, :prune, 60_000)

    @impl true
    def init(opts) do
      path = Keyword.fetch!(opts, :path)
      table = Keyword.get(opts, :table, table())
      Application.put_env(:tiannara, :rotator_test_path, path)
      Application.put_env(:tiannara, :rotator_test_table, table)
      File.mkdir_p!(Path.dirname(path))

      {:ok, _table} = :dets.open_file(table, type: :set, file: String.to_charlist(path))

      {:ok, %{path: path, table: table}}
    end

    @impl true
    def terminate(_reason, state) do
      if :dets.info(state.table) != :undefined, do: :dets.close(state.table)
      :ok
    end

    @impl true
    def handle_call(:rotate, _from, state) do
      case Rotator.rotate(state.table, state.path, type: :set) do
        {:ok, archive} -> {:reply, {:ok, archive}, state}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end

    def handle_call(:prune, _from, state) do
      retention_hours = Application.get_env(:tiannara, :dets_test_retention_hours, 720)

      cutoff =
        DateTime.utc_now()
        |> DateTime.add(-(retention_hours * 3600), :second)

      stale =
        :dets.traverse(state.table, fn
          {id, %{executed_at: ts}} when is_struct(ts, DateTime) ->
            if DateTime.compare(ts, cutoff) == :lt, do: {:continue, id}, else: {:continue, :skip}

          _ ->
            {:continue, :skip}
        end)
        |> Enum.reject(&(&1 == :skip))

      Enum.each(stale, &:dets.delete(state.table, &1))
      {:reply, {:ok, length(stale)}, state}
    end
  end

  setup do
    dir = Path.join(System.tmp_dir!(), "rotator_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    %{dir: dir}
  end

  test "deletes do NOT shrink the DETS file — rotation is the only size bound", %{dir: dir} do
    path = Path.join(dir, "a.dets")
    table = String.to_atom("dets_no_shrink_#{System.unique_integer([:positive])}")
    payload = :binary.copy("x", 1024)

    {:ok, ^table} = :dets.open_file(table, type: :set, file: String.to_charlist(path))
    :ok = :dets.insert(table, Enum.map(1..500, fn i -> {i, payload} end))
    :ok = :dets.close(table)
    size_after_inserts = File.stat!(path).size
    assert size_after_inserts > 0

    {:ok, ^table} = :dets.open_file(table, type: :set, file: String.to_charlist(path))
    :ok = Enum.each(1..500, &:dets.delete(table, &1))
    :ok = :dets.close(table)
    size_after_deletes = File.stat!(path).size

    assert size_after_deletes >= size_after_inserts,
           "expected DETS file NOT to shrink after deletes (got #{size_after_inserts} -> #{size_after_deletes})"
  end

  test "rotation compacts: live path is small, archive reopens with full live history", %{
    dir: dir
  } do
    path = Path.join(dir, "b.dets")
    table = String.to_atom("dets_rotation_#{System.unique_integer([:positive])}")
    payload = :binary.copy("record", 512)

    {:ok, ^table} = :dets.open_file(table, type: :set, file: String.to_charlist(path))
    :ok = :dets.insert(table, Enum.map(1..400, fn i -> {i, payload} end))
    # delete 100 → dead space inside the file
    :ok = Enum.each(1..100, &:dets.delete(table, &1))
    :ok = :dets.sync(table)
    size_before = File.stat!(path).size

    assert {:ok, archive} = Rotator.rotate(table, path, type: :set)
    assert File.exists?(path)
    assert File.exists?(archive)

    live_size = File.stat!(path).size
    assert live_size < size_before, "expected compacted live file to be smaller"

    {:ok, live_tab} =
      :dets.open_file(
        String.to_atom("live_#{System.unique_integer([:positive])}"),
        type: :set,
        file: String.to_charlist(path)
      )

    assert record_count(live_tab) == 300, "live table must contain exactly the 300 live records"
    :ok = :dets.close(live_tab)

    # the archive is a clean, closed snapshot of the live state at rotation time
    # (DETS finalizes deletes on close, so the 100 deleted records are absent)
    {:ok, archive_tab} =
      :dets.open_file(
        String.to_atom("archive_#{System.unique_integer([:positive])}"),
        type: :set,
        file: String.to_charlist(archive)
      )

    assert record_count(archive_tab) == 300,
           "archive must reopen cleanly with the 300 live records"

    assert [{150, ^payload}] = :dets.lookup(archive_tab, 150)
    assert [] = :dets.lookup(archive_tab, 7), "deleted records must be absent from the archive"
    :ok = :dets.close(archive_tab)
  end

  test "rotation on an empty store still yields a working promoted file", %{dir: dir} do
    path = Path.join(dir, "empty.dets")
    table = String.to_atom("dets_empty_#{System.unique_integer([:positive])}")

    {:ok, ^table} = :dets.open_file(table, type: :set, file: String.to_charlist(path))
    assert {:ok, _archive} = Rotator.rotate(table, path, type: :set)
    assert :dets.info(table) != :undefined

    {:ok, reopened} =
      :dets.open_file(
        String.to_atom("empty_reopen_#{System.unique_integer([:positive])}"),
        type: :set,
        file: String.to_charlist(path)
      )

    assert record_count(reopened) == 0
    :ok = :dets.close(reopened)
  end

  test "lifecycle sweep rotates a store that crossed the threshold and emits metrics", %{dir: dir} do
    path = Path.join(dir, "c.dets")
    Application.put_env(:tiannara, :dets_rotate_bytes, 256)
    Application.put_env(:tiannara, :dets_warn_bytes, 128)
    on_exit(fn -> restore_dets_env() end)

    start_supervised!({TestStore, path: path, table: unique_table()})
    # wait for the store to publish its path env
    assert Process.whereis(TestStore)
    :dets.insert(TestStore.table(), {"seed", :binary.copy("s", 1024)})

    test_pid = self()
    handler_id = "rotator_test_#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:tiannara, :storage, :dets, :rotated],
      fn event, measurements, metadata, _ ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert :ok = DetsLifecycle.register(%{id: :test_store, module: TestStore})
    assert :test_store in DetsLifecycle.registered()
    assert :ok = DetsLifecycle.sweep_now()

    assert_receive {:telemetry_event, [:tiannara, :storage, :dets, :rotated], %{count: 1},
                    %{store: :test_store}},
                   3_000

    archive =
      path |> Path.dirname() |> File.ls!() |> Enum.find(&String.contains?(&1, ".archive."))

    assert archive, "expected an archive file after the sweep rotation"
  end

  test "lifecycle prune removes records older than retention and reports count", %{dir: dir} do
    path = Path.join(dir, "d.dets")
    Application.put_env(:tiannara, :dets_test_retention_hours, 1)
    on_exit(fn -> restore_dets_env() end)

    start_supervised!({TestStore, path: path, table: unique_table()})

    old = DateTime.utc_now() |> DateTime.add(-7200, :second)
    fresh = DateTime.utc_now()

    :dets.insert(TestStore.table(), {"old_1", %{executed_at: old}})
    :dets.insert(TestStore.table(), {"old_2", %{executed_at: old}})
    :dets.insert(TestStore.table(), {"fresh_1", %{executed_at: fresh}})

    assert :ok = DetsLifecycle.register(%{id: :prune_store, module: TestStore})
    assert :ok = DetsLifecycle.sweep_now()

    # sweep prunes on its own schedule only; force the prune path directly
    assert {:ok, 2} = TestStore.prune()

    # deletes are applied to the open table immediately; the file only
    # finalizes them on close, so assert against the live table
    assert record_count(TestStore.table()) == 1
    assert [{_, %{executed_at: ^fresh}}] = :dets.lookup(TestStore.table(), "fresh_1")
  end

  defp record_count(table), do: length(:dets.traverse(table, fn _ -> {:continue, 1} end))

  defp unique_table do
    String.to_atom("rotator_test_store_#{System.unique_integer([:positive])}")
  end

  defp restore_dets_env do
    Application.put_env(:tiannara, :dets_rotate_bytes, @default_rotate_bytes)
    Application.put_env(:tiannara, :dets_warn_bytes, 1_500_000_000)
    Application.put_env(:tiannara, :dets_test_retention_hours, @default_retention_hours)
  end
end
