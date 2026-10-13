defmodule Tiannara.Council.AuditLogRecoveryTest do
  use ExUnit.Case, async: false

  @moduledoc """
  D-A6/B5 failure-injection evidence for the audit-log recovery ladder.

  Covers: writer lock, archive-gated recovery, fail-closed unrecoverable
  cases (no File.rm of authoritative state), post-repair chain verification,
  restart persistence, and degraded-mode behavior.
  """

  alias Tiannara.Council.AuditLog

  @sup Tiannara.Council.Supervisor

  setup do
    path = AuditLog.dets_path()
    File.mkdir_p!(Path.dirname(path))
    lock = path <> ".lock"

    # Own the AuditLog lifecycle: detach from the app supervisor so GenServer.stop
    # does not race an automatic rest_for_one restart.
    case Supervisor.terminate_child(@sup, AuditLog) do
      :ok -> :ok
      {:error, :not_found} -> :ok
      {:error, _} -> :ok
    end

    on_exit(fn ->
      _ = File.rm(path <> ".lock")

      case Supervisor.restart_child(@sup, AuditLog) do
        {:ok, _} -> :ok
        {:error, :running} -> :ok
        {:error, :already_started} -> :ok
        _ -> Supervisor.start_child(@sup, AuditLog)
      end
    end)

    {:ok, pid} = AuditLog.start_link([])
    %{path: path, lock: lock, pid: pid, archives: archive_count(path)}
  end

  defp wait_until(fun, attempts \\ 50) do
    cond do
      fun.() ->
        :ok

      attempts <= 0 ->
        flunk("condition not met in time")

      true ->
        Process.sleep(100)
        wait_until(fun, attempts - 1)
    end
  end

  defp archive_count(path) do
    dir = Path.dirname(path)
    base = Path.basename(path)

    case File.ls(dir) do
      {:ok, names} ->
        names
        |> Enum.filter(&String.starts_with?(&1, base <> ".corrupted."))
        |> length()

      _ ->
        0
    end
  end

  defp stop_audit(pid) do
    GenServer.stop(pid, :normal, 5_000)
    wait_until(fn -> is_nil(Process.whereis(AuditLog)) end)
  end

  describe "1. healthy open holds a writer lock and verifies chain" do
    test "lock file exists while AuditLog is alive", %{lock: lock} do
      assert File.exists?(lock), "writer lock must be present while owner is alive"
      assert :ok = AuditLog.verify_integrity()
      refute AuditLog.degraded?()
    end

    test "append is durable-visible after sync", %{path: path} do
      assert {:ok, entry} = AuditLog.append(:d_a6_sync_probe, :test, %{probe: true})
      assert entry.seq > 0
      assert :ok = AuditLog.verify_integrity()
      assert File.exists?(path)
    end
  end

  describe "2. second writer is refused while lock is held" do
    test "live foreign lock payload blocks a fresh AuditLog open", %{
      path: path,
      pid: pid,
      lock: lock
    } do
      stop_audit(pid)

      # Live OS pid + foreign node → not stale → must fail closed.
      foreign_node = "nonexistent@127.0.0.1"

      File.write!(
        lock,
        "#{:os.getpid()} #{foreign_node} <0.999.0> #{System.system_time(:second)}"
      )

      {:ok, probe} = AuditLog.start_link([])
      status = AuditLog.storage_status()
      assert status.degraded, "second owner must fail closed to degraded"
      assert match?({:writer_locked, _}, status.degradation_reason)
      assert AuditLog.append(:blocked, :test, %{}) == {:error, :storage_degraded}
      stop_audit(probe)
      File.rm(lock)

      {:ok, restored} = AuditLog.start_link([])
      assert is_pid(restored)
      refute AuditLog.degraded?()
      assert File.exists?(path)
    end
  end

  describe "3. unrecoverable corruption fails closed without deleting the file" do
    test "garbage body → degraded, original preserved, archive created", %{
      path: path,
      pid: pid
    } do
      before = archive_count(path)
      stop_audit(pid)

      garbage = "GARBAGE_NOT_DETS_#{System.unique_integer([:positive])}"
      File.write!(path, garbage)

      {:ok, degraded_pid} = AuditLog.start_link([])
      wait_until(fn -> AuditLog.degraded?() end)

      assert AuditLog.degraded?()
      status = AuditLog.storage_status()
      assert status.storage_available == false
      assert status.degradation_reason != nil
      assert AuditLog.append(:should_block, :test, %{}) == {:error, :storage_degraded}
      assert AuditLog.verify_integrity() == {:error, :storage_degraded}
      assert AuditLog.chain_tip().seq == 0

      # Fail-closed: authoritative bytes still on disk (never File.rm'd).
      assert File.exists?(path)
      assert File.read!(path) == garbage

      assert archive_count(path) > before,
             "unrecoverable case must still archive for forensics"

      stop_audit(degraded_pid)
      File.rm(path)
      {:ok, restored} = AuditLog.start_link([])
      assert is_pid(restored)
      refute AuditLog.degraded?()
    end
  end

  describe "4. repair path archives first, verifies chain, and preserves history" do
    test "unclean cross-process holder (killed without close) recovers history", %{
      path: path,
      pid: pid
    } do
      assert {:ok, _e1} = AuditLog.append(:d_a6_hist_a, :test, %{n: 1})
      assert {:ok, e2} = AuditLog.append(:d_a6_hist_b, :test, %{n: 2})
      tip_before = AuditLog.chain_tip().seq
      assert tip_before == e2.seq

      stop_audit(pid)
      assert File.exists?(path)
      before = archive_count(path)

      # Cross-process holder opens the well-formed file and never closes it.
      # SIGKILL-equivalent leaves DETS "not properly closed".
      holder_dir = Path.join(System.tmp_dir!(), "d_a6_holder_#{System.unique_integer([:positive])}")
      File.mkdir_p!(holder_dir)
      pidfile = Path.join(holder_dir, "holder.pid")

      holder = """
      path = #{inspect(path)}
      pidfile = #{inspect(pidfile)}
      case :dets.open_file(:d_a6_holder, type: :set, file: String.to_charlist(path), repair: false) do
        {:ok, t} ->
          # Buffer a write and do NOT sync — kill must leave needs_repair.
          :dets.insert(t, {999_999, %{seq: 999_999, marker: :unclean_holder}})
          IO.puts("holder_open=ok")
          File.write!(pidfile, to_string(:os.getpid()))
          Process.sleep(120_000)
        {:error, r} ->
          IO.puts("holder_open=error " <> inspect(r))
          File.write!(pidfile, "open_failed")
          System.halt(2)
      end
      """

      holder_script = Path.join(holder_dir, "holder.exs")
      File.write!(holder_script, holder)

      task =
        Task.async(fn ->
          System.cmd("elixir", [holder_script], stderr_to_stdout: true)
        end)

      wait_until(
        fn ->
          case File.read(pidfile) do
            {:ok, "open_failed"} -> flunk("holder failed to open the audit file")
            {:ok, pidstr} -> String.trim(pidstr) != ""
            _ -> false
          end
        end,
        100
      )

      holder_os = String.trim(File.read!(pidfile))

      # Brutal OS kill — no :dets.close, no terminate.
      {_, kill_status} = System.cmd("taskkill", ["/PID", holder_os, "/F"], stderr_to_stdout: true)
      assert kill_status == 0, "taskkill must succeed for holder pid=#{holder_os}"
      _ = Task.shutdown(task, :brutal_kill)

      # File is dirty (open flag left set). Strict open must fail.
      strict =
        :dets.open_file(:d_a6_strict_probe,
          type: :set,
          file: String.to_charlist(path),
          repair: false
        )

      case strict do
        {:ok, t} ->
          :dets.close(t)
          flunk("expected dirty file after brutal holder kill")

        {:error, reason} ->
          assert match?({:needs_repair, _}, reason) or match?({:file_error, _, _}, reason),
                 "unexpected dirty-open error: #{inspect(reason)}"
      end

      # Restart → archive + repair + chain verify must preserve history.
      {:ok, restarted} = AuditLog.start_link([])
      wait_until(fn -> not AuditLog.degraded?() end)

      refute AuditLog.degraded?()
      assert :ok = AuditLog.verify_integrity()
      assert AuditLog.chain_tip().seq >= tip_before

      recent_actions = Enum.map(AuditLog.recent(10), & &1.action)
      assert :d_a6_hist_a in recent_actions
      assert :d_a6_hist_b in recent_actions

      assert archive_count(path) > before,
             "repair path must archive the pre-repair file"

      stop_audit(restarted)
      File.rm_rf(holder_dir)
    end

    test "logical chain break fails closed (DETS repair cannot fix hashes)", %{
      path: path,
      pid: pid
    } do
      assert {:ok, _} = AuditLog.append(:d_a6_chain_ok, :test, %{n: 1})
      assert {:ok, _} = AuditLog.append(:d_a6_chain_ok2, :test, %{n: 2})
      stop_audit(pid)

      before = archive_count(path)

      # Structural file is valid; corrupt one stored hash in place.
      {:ok, t} = :dets.open_file(:d_a6_mangle, type: :set, file: String.to_charlist(path), repair: true)
      [{seq, entry} | _] = :dets.match_object(t, {:_, :_})
      bad = %{entry | hash: <<1::256>>}
      :ok = :dets.insert(t, {seq, bad})
      :ok = :dets.sync(t)
      :ok = :dets.close(t)

      {:ok, dp} = AuditLog.start_link([])
      wait_until(fn -> AuditLog.degraded?() end)

      assert AuditLog.degraded?()
      status = AuditLog.storage_status()
      assert match?({:repair_integrity_failed, _, _, _}, status.degradation_reason) or
               match?({:repair_failed, _, _, _}, status.degradation_reason),
             "expected fail-closed integrity reason, got: #{inspect(status.degradation_reason)}"

      assert File.exists?(path), "authoritative file must remain after failed integrity repair"
      assert archive_count(path) > before, "archive required before mutation attempt"
      assert AuditLog.append(:blocked, :test, %{}) == {:error, :storage_degraded}

      stop_audit(dp)
      File.rm(path)
      {:ok, restored} = AuditLog.start_link([])
      assert is_pid(restored)
      refute AuditLog.degraded?()
    end
  end

  describe "5. restart persistence after clean stop" do
    test "chain survives stop/start without a new archive", %{path: path} do
      before = archive_count(path)
      pid = Process.whereis(AuditLog)
      assert {:ok, e} = AuditLog.append(:d_a6_persist, :test, %{persist: true})
      tip = AuditLog.chain_tip().seq
      assert tip == e.seq

      stop_audit(pid)

      {:ok, pid2} = AuditLog.start_link([])
      wait_until(fn -> not AuditLog.degraded?() end)

      assert AuditLog.chain_tip().seq == tip
      assert :ok = AuditLog.verify_integrity()
      assert :d_a6_persist in Enum.map(AuditLog.recent(5), & &1.action)
      assert archive_count(path) == before, "clean restart must not archive"

      stop_audit(pid2)
      {:ok, final} = AuditLog.start_link([])
      assert is_pid(final)
      assert AuditLog.chain_tip().seq == tip
    end
  end

  describe "6. repeated recovery is stable" do
    test "double garbage cycle archives twice and stays fail-closed", %{path: path} do
      pid = Process.whereis(AuditLog)
      stop_audit(pid)
      File.rm(path)

      {:ok, _} = AuditLog.start_link([])
      wait_until(fn -> not AuditLog.degraded?() end)

      c0 = archive_count(path)

      for cycle <- 1..2 do
        pid = Process.whereis(AuditLog)
        stop_audit(pid)
        File.write!(path, "CYCLE_#{cycle}_#{System.unique_integer([:positive])}")

        {:ok, dp} = AuditLog.start_link([])
        wait_until(fn -> AuditLog.degraded?() end)
        assert AuditLog.degraded?()
        assert File.exists?(path)
        assert archive_count(path) > c0
        stop_audit(dp)
        File.rm(path)
        {:ok, _} = AuditLog.start_link([])
        wait_until(fn -> not AuditLog.degraded?() end)
      end

      assert Process.alive?(Process.whereis(AuditLog))
      refute AuditLog.degraded?()
      assert :ok = AuditLog.verify_integrity()
    end
  end
end
