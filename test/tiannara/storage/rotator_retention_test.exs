defmodule Tiannara.Storage.RotatorRetentionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Storage.Rotator

  @tmp "test_data/rotator_retention"

  setup do
    File.rm_rf!(@tmp)
    File.mkdir_p!(@tmp)
    Application.put_env(:tiannara, :dets_retention_max_archives, 2)
    Application.put_env(:tiannara, :dets_archive_ttl_minutes, 60)
    on_exit(fn -> File.rm_rf!(@tmp) end)
    :ok
  end

  test "reaper bounds archives to max, oldest first, live file untouched" do
    base = Path.join(@tmp, "store.dets")
    File.write!(base, "live")

    for i <- 1..5 do
      File.write!("#{base}.archive.2026010#{i}T000000", "old-#{i}")
    end

    :ok = Rotator.reap_archives(base)

    names = File.ls!(@tmp)
    archives = Enum.filter(names, &String.contains?(&1, ".archive."))

    assert length(archives) == 2,
           "expected archives bounded to max(2), got #{length(archives)}: #{inspect(archives)}"

    assert "store.dets" in names, "live file must never be reaped"
    assert Enum.member?(archives, "store.dets.archive.20260105T000000"),
           "keeps the two most-recent archives, got #{inspect(archives)}"
  end

  test "reaper ages out expired archives independent of the count cap" do
    base = Path.join(@tmp, "store.dets")
    File.write!(base, "live")

    # one recent (keep under count), one OLD (ttl expires it even though count < max)
    File.write!("#{base}.archive.20260101T000000", "recent")
    # mtime far in the past so it is older than ttl_min (60)
    File.write!("#{base}.archive.19700101T000000", "ancient")
    old = "#{base}.archive.19700101T000000"

    :calendar.universal_time()
    |> :calendar.datetime_to_gregorian_seconds()

    File.touch!(old, {{1970, 1, 1}, {0, 0, 0}})

    :ok = Rotator.reap_archives(base)

    names = File.ls!(@tmp)

    refute "store.dets.archive.19700101T000000" in names,
           "expired archive must be reaped"

    assert "store.dets.archive.20260101T000000" in names, "recent archive must survive"
    assert "store.dets" in names, "live file must survive"
  end

  test "reaper degrades (never crashes) on unreadable dir" do
    assert :ok = Rotator.reap_archives(Path.join(@tmp, "no_such_dir/store.dets"))
  end

  # Call-site proof: rotate/4 must actually invoke the reaper and bound the
  # archive directory. Drives a real DETS rotation with a small threshold.
  test "rotate/4 invokes reaper so archives stay bounded across rotations" do
    Application.put_env(:tiannara, :dets_rotate_bytes, 4_096)
    Application.put_env(:tiannara, :dets_retention_max_archives, 2)
    Application.put_env(:tiannara, :dets_archive_ttl_minutes, 60)

    base = Path.join(@tmp, "live.dets")
    table = :"rot_retention_live_#{System.unique_integer([:positive])}"
    file_opts = [type: :set, file: String.to_charlist(base), auto_save: 100]

    assert {:ok, ^table} = :dets.open_file(table, file_opts)

    # Push the live file past the threshold so should_rotate? fires, then rotate
    # several times to spawn multiple archives; the reaper must cap the count.
    Enum.each(1..200, fn i -> :dets.insert(table, {{i, i}, i}) end)

    Enum.each(1..5, fn n ->
      true = Rotator.should_rotate?(base)
      assert {:ok, _archive} = Rotator.rotate(table, base, file_opts)
      # reopen handle for the next rotation (rotate closes + reopens the base)
      assert {:ok, ^table} = :dets.open_file(table, file_opts)
      Enum.each(1..200, fn i -> :dets.insert(table, {{n, i}, i}) end)
    end)

    :dets.close(table)

    names = File.ls!(@tmp)
    archives = Enum.filter(names, &String.contains?(&1, ".archive."))

    assert length(archives) <= 2,
           "rotate/4 must bound archives to max(2); got #{length(archives)}: #{inspect(archives)}"

    assert "live.dets" in names, "live file must remain after rotations"
  after
    Application.put_env(:tiannara, :dets_rotate_bytes, 1_800_000_000)
  end
end
