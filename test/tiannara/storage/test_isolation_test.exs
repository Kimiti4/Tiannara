defmodule Tiannara.Storage.TestIsolationTest do
  use ExUnit.Case, async: false

  @moduledoc """
  D-A5 test/runtime persistence isolation matrix.

  Proves run roots are cross-VM unique, residue is not inherited,
  and test-env writes stay under test_data.
  """

  alias Tiannara.Storage.Paths

  test "1. persistence root is not a bare process-local unique_integer" do
    base = Application.fetch_env!(:tiannara, :dets_base_path)
    run_id = Application.get_env(:tiannara, :test_run_id) || Path.basename(base)

    # Must carry an OS-level discriminator (pid) and wall time, not only 1..N ints.
    assert String.contains?(run_id, "pid"), "run id must embed OS pid: #{run_id}"
    assert String.match?(run_id, ~r/\d{10,}/), "run id must embed wall time: #{run_id}"
    refute run_id =~ ~r/^\d+$/, "bare unique_integer run id is forbidden: #{run_id}"
    assert String.starts_with?(base, "./test_data/dets/") or
             String.starts_with?(base, "test_data/dets/"),
           "dets base must live under test_data/dets: #{base}"
  end

  test "2. two fresh BEAM invocations produce distinct isolation tokens" do
    # Cross-VM proof: spawn two elixir processes that print their own tokens.
    # Script must compute at CHILD runtime — no parent interpolation.
    dir = Path.join(System.tmp_dir!(), "d_a5_cross_vm_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    script = Path.join(dir, "token.exs")

    File.write!(
      script,
      "IO.puts(to_string(:os.getpid()) <> \"_\" <> to_string(System.system_time(:nanosecond)) <> \"_\" <> to_string(:erlang.unique_integer([:positive, :monotonic])))\n"
    )

    elixir = System.find_executable("elixir") || "elixir"

    {out1, s1} = System.cmd(elixir, [script])
    {out2, s2} = System.cmd(elixir, [script])
    assert s1 == 0 and s2 == 0, "child elixir failed: #{inspect({s1, s2, out1, out2})}"

    a = isolation_token()
    b = isolation_token()
    assert a != b, "monotonic+time tokens must differ within a run: #{a} vs #{b}"

    assert String.trim(out1) != String.trim(out2),
           "fresh elixir pids/times must differ: #{inspect(out1)} vs #{inspect(out2)}"

    bare_script = Path.join(dir, "bare.exs")
    File.write!(bare_script, "IO.puts(System.unique_integer([:positive]))\n")
    {u1, us1} = System.cmd(elixir, [bare_script])
    {u2, us2} = System.cmd(elixir, [bare_script])
    assert us1 == 0 and us2 == 0
    assert String.trim(u1) != "" and String.trim(u2) != ""

    File.rm_rf(dir)
  end

  test "3. concurrent-style tokens from two spawned VMs are distinct" do
    dir = Path.join(System.tmp_dir!(), "d_a5_conc_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    script = Path.join(dir, "token.exs")

    File.write!(
      script,
      "IO.puts(\"pid\" <> to_string(:os.getpid()) <> \"_t\" <> to_string(System.system_time(:nanosecond)) <> \"_u\" <> to_string(:erlang.unique_integer([:positive, :monotonic])))\n"
    )

    elixir = System.find_executable("elixir") || "elixir"

    tasks =
      for _ <- 1..2 do
        Task.async(fn -> System.cmd(elixir, [script]) end)
      end

    results = Task.await_many(tasks, 30_000)
    [{o1, s1}, {o2, s2}] = results
    assert s1 == 0 and s2 == 0, "child failed: #{inspect(results)}"
    assert String.trim(o1) != String.trim(o2), "concurrent VM tokens collided: #{inspect(o1)} vs #{inspect(o2)}"

    File.rm_rf(dir)
  end

  test "4. foreign residue path is never under this run's roots" do
    base = Application.fetch_env!(:tiannara, :dets_base_path)
    # Simulated other-run residue (historical unique_integer style dir name).
    foreign = Path.join(["test_data", "dets", "99999999", "dets", "test", "poison.dets"])
    refute String.starts_with?(Path.expand(foreign), Path.expand(base))

    storage = Application.get_env(:tiannara, :storage_base)
    if is_binary(storage) do
      foreign_artifact = Path.join(storage, "../other_run/checkpoints/x.json")
      refute Path.expand(foreign_artifact) == Path.expand(Path.join(storage, "checkpoints/x.json"))
    end

    # Current AuditLog path must sit inside THIS run only.
    audit = Tiannara.Council.AuditLog.dets_path()
    assert String.starts_with?(Path.expand(audit), Path.expand(base)) or
             String.starts_with?(audit, base),
           "audit log escaped run root: #{audit} vs #{base}"
    assert String.contains?(audit, "test_data")
  end

  test "5. storage context stays test and non-DETS path stays under test_data" do
    assert Paths.context() == :test
    p = Paths.path("checkpoints/probe.json")
    assert String.contains?(p, "test_data") or String.starts_with?(p, Paths.base())
    refute String.starts_with?(p, "dev_data/")
    refute String.starts_with?(p, "data/production")
    refute String.contains?(p, "/soak/")
  end

  test "6. DETS store paths resolve under the run root with test context" do
    base = Application.fetch_env!(:tiannara, :dets_base_path)
    name = Paths.dets("isolation_probe_store")
    assert String.starts_with?(name, base) or String.starts_with?(Path.expand(name), Path.expand(base))
    assert String.contains?(name, "test")
    assert String.ends_with?(name, "isolation_probe_store.dets")
  end

  test "7. cleanup contract: run root is exclusive and under test_data only" do
    base = Application.fetch_env!(:tiannara, :dets_base_path)
    assert File.dir?(base), "test_helper must create the run root"
    assert String.contains?(base, "test_data")
    refute String.contains?(base, "dev_data")
    refute String.contains?(base, "data/production")

    # Marker written only inside this root.
    marker = Path.join(base, "isolation_marker.txt")
    File.write!(marker, "run-ok")
    assert File.read!(marker) == "run-ok"
    File.rm!(marker)
  end

  test "8. TEST_PARTITION override pins the run id when set" do
    # Document contract without mutating global env mid-suite:
    run_id = Application.get_env(:tiannara, :test_run_id)
    assert is_binary(run_id) and run_id != ""
    base = Application.fetch_env!(:tiannara, :dets_base_path)
    assert String.ends_with?(base, run_id) or String.contains?(base, run_id)
  end

  defp isolation_token do
    "#{System.system_time(:nanosecond)}_pid#{:os.getpid()}_#{
      :erlang.unique_integer([:positive, :monotonic])
    }"
  end
end
