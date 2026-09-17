defmodule Tiannara.Executive.ExecutiveMemoryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Executive.ExecutiveMemory

  describe "basic operations" do
    test "put and get string key" do
      assert :ok = ExecutiveMemory.put("emtest_key1", "value1")
      assert {:ok, %{value: "value1"}} = ExecutiveMemory.get("emtest_key1")
      ExecutiveMemory.delete("emtest_key1")
    end

    test "get missing key returns error" do
      assert ExecutiveMemory.get("emtest_nonexistent") == :error
    end

    test "put and get atom key" do
      assert :ok = ExecutiveMemory.put(:emtest_a, 42)
      assert {:ok, %{value: 42}} = ExecutiveMemory.get(:emtest_a)
      ExecutiveMemory.delete(:emtest_a)
    end

    test "put and get complex value" do
      data = %{nested: %{map: :value}, list: [1, 2, 3]}
      assert :ok = ExecutiveMemory.put("emtest_complex", data)
      assert {:ok, %{value: ^data}} = ExecutiveMemory.get("emtest_complex")
      ExecutiveMemory.delete("emtest_complex")
    end

    test "delete removes key" do
      ExecutiveMemory.put("emtest_temp", "value")
      assert {:ok, _} = ExecutiveMemory.get("emtest_temp")
      assert :ok = ExecutiveMemory.delete("emtest_temp")
      assert ExecutiveMemory.get("emtest_temp") == :error
    end

    test "size returns record count" do
      assert ExecutiveMemory.size() >= 0
    end
  end

  describe "health and metrics" do
    test "health returns status map" do
      health = ExecutiveMemory.health()
      assert health.status == :active or health.status == :degraded
      assert is_integer(health.cache_size)
      assert is_map(health.metrics)
    end

    test "metrics returns map" do
      m = ExecutiveMemory.metrics()
      assert is_integer(m.total_writes)
      assert is_integer(m.total_reads)
      assert is_integer(m.total_deletes)
    end

    test "diagnostics return basic info" do
      diag = ExecutiveMemory.diagnostics()
      assert diag.status == :active or diag.status == :degraded
      assert is_integer(diag.record_count)
    end
  end

  describe "recovery and rebuild" do
    test "recover returns ok" do
      ExecutiveMemory.put("emtest_r1", "v1")
      assert ExecutiveMemory.recover() == :ok
      assert {:ok, %{value: "v1"}} = ExecutiveMemory.get("emtest_r1")
      ExecutiveMemory.delete("emtest_r1")
    end
  end

  describe "corruption detector" do
    test "deep check accepts compound keys and transaction journal records" do
      dir = Path.join(System.tmp_dir!(), "em_dets_test_#{:os.system_time(:millisecond)}")
      File.mkdir_p!(dir)
      path = Path.join(dir, "mem.dets")
      {:ok, ref} = Tiannara.Executive.DetsStore.open(path)

      :dets.insert(ref, {{:knowledge, "k_1"}, %{value: "v1", class: :persistent}})
      :dets.insert(ref, {:plain_atom, %{value: 1}})
      :dets.insert(ref, {:plain_binary, %{value: 2}})
      :dets.insert(ref, {{:tx, "t_1"}, %{operation: :put, key: {:knowledge, "k_1"}}})

      check = Tiannara.Executive.CorruptionDetector.deep_check(ref)
      assert check.ok? == true
      assert check.corrupt == 0
      assert check.total == 4

      :dets.insert(ref, {:not_a_record, :oops, :extra})
      check_bad = Tiannara.Executive.CorruptionDetector.deep_check(ref)
      assert check_bad.ok? == false
      assert check_bad.corrupt == 1

      Tiannara.Executive.DetsStore.close(ref)
      File.rm_rf!(dir)
    end

    test "maintenance signals corruption but never repairs a live table" do
      dir = Path.join(System.tmp_dir!(), "em_maintenance_#{:os.system_time(:millisecond)}")
      File.mkdir_p!(dir)
      path = Path.join(dir, "mem.dets")

      {:ok, ref} = Tiannara.Executive.DetsStore.open(path)
      :dets.insert(ref, {{:knowledge, "k_1"}, %{value: "v1"}})
      :dets.insert(ref, {:not_a_record, :oops, :extra})
      Tiannara.Executive.DetsStore.close(ref)

      pid =
        start_supervised!(
          {ExecutiveMemory,
           name: :em_maintenance_guard,
           dets_dir: dir,
           dets_file: path,
           snapshot_dir: Path.join(dir, "snapshots"),
           maintenance_interval: 3_600_000}
        )

      Process.send(pid, :maintenance, [])
      Process.sleep(150)

      assert Process.alive?(pid)
      diag = GenServer.call(pid, :diagnostics)
      assert diag.corruption_detected == true

      stop_supervised!(ExecutiveMemory)
      File.rm_rf!(dir)
    end
  end

  describe "fault injection" do
    test "inject and clear faults" do
      assert ExecutiveMemory.inject_fault(:read_delay, %{read_delay_ms: 10}) == :ok
      assert ExecutiveMemory.clear_faults() == :ok
    end
  end

  describe "snapshot" do
    test "snapshot creates a snapshot file" do
      ExecutiveMemory.put("emtest_snap1", "snap_val")
      {:ok, path} = ExecutiveMemory.snapshot()
      assert is_binary(path)
      assert String.contains?(path, "snapshot")
      ExecutiveMemory.delete("emtest_snap1")
    end
  end
end
