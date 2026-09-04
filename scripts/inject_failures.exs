# scripts/inject_failures.exs
#
# Phase 2 controlled-chaos failure injections. SAFE BY CONSTRUCTION:
# runs in an isolated scratch node (mix run --no-start), never attaches to or
# mutates the running 72h soak. Each injection exercises the REAL recovery /
# integrity / restraint machinery against scratch state only.
#
# PowerShell (established pattern):
#   mix run --no-start scripts/inject_failures.exs all 2>&1 | Out-File -FilePath inject_all.log -Encoding utf8
#   Select-String -Path inject_all.log -Pattern "INJECTION|VERDICT"
#
# Selectors: kill | tamper | restraint | all

defmodule Inject do
  def wait_for(fun, timeout_ms \\ 5_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_wait(fun, deadline)
  end

  defp do_wait(fun, deadline) do
    cond do
      fun.() -> true
      System.monotonic_time(:millisecond) > deadline -> false
      true -> Process.sleep(50); do_wait(fun, deadline)
    end
  end

  defp ensure_tree do
    case Process.whereis(Tiannara.Omega.Supervisor) do
      nil ->
        case Tiannara.Omega.Supervisor.start_link([]) do
          {:ok, pid} -> {:started, pid}
          {:error, {:already_started, pid}} -> {:already, pid}
          {:error, _} -> :unavailable
        end
      pid -> {:already, pid}
    end
  end

  # --- Injection 1: process kill -> supervisor must restart the child ------
  def injection_kill do
    case ensure_tree() do
      :unavailable ->
        IO.puts("INJECTION 1 (process_kill): SKIP (supervisor unavailable in scratch node)")

      _ ->
        target = Tiannara.Omega.ResearchDirectorServer
        pid = Process.whereis(target)

        if is_nil(pid) do
          IO.puts("INJECTION 1 (process_kill): SKIP (target not running)")
        else
          ref = Process.monitor(pid)
          Process.exit(pid, :kill)

          down? =
            receive do
              {:DOWN, ^ref, :process, ^pid, _} -> true
            after
              5_000 -> false
            end

          restarted? = wait_for(fn -> is_pid(Process.whereis(target)) end)

          if down? and restarted? do
            IO.puts("INJECTION 1 (process_kill): PASS (killed + supervisor restarted)")
          else
            IO.puts("INJECTION 1 (process_kill): FAIL (down=#{down?} restarted=#{restarted?})")
          end
        end
    end
  end

  # --- Injection 2: lineage tamper on a SCRATCH chain -> verifier detects --
  def injection_tamper do
    dir = Path.join(System.tmp_dir!(), "inject_lineage_#{System.unique_integer([:positive])}")
    path = Path.join(dir, "lineage.log")
    File.mkdir_p!(dir)

    alias Tiannara.Lineage.{Entry, Store}

    e1 = Entry.new(%{stage: :observation, discovery: :disc_probe}, :observation)
    e2 = Entry.new(%{stage: :conclusion, discovery: :disc_probe}, :conclusion, e1.entry_hash)
    :ok = Store.persist(e1, path)
    :ok = Store.persist(e2, path)

    {:ok, loaded} = Store.load_all(path)
    intact = Store.verify_chain(loaded)

    tampered = %{e2 | entry_hash: String.duplicate("f", 64)}
    :ok = Store.persist(tampered, path)
    {:ok, loaded_tampered} = Store.load_all(path)
    after_tamper = Store.verify_chain(loaded_tampered)

    File.rm_rf!(dir)

    if intact == :ok and match?({:error, _}, after_tamper) do
      IO.puts("INJECTION 2 (lineage_tamper): PASS (intact before, tamper detected after)")
    else
      IO.puts(
        "INJECTION 2 (lineage_tamper): FAIL (before=#{inspect(intact)} after=#{inspect(after_tamper)})"
      )
    end
  end

  # --- Injection 3: restraint probe -> bypass attempts must be rejected ----
  def injection_restraint do
    alias Tiannara.Omega.PatchGenerator.Candidate
    alias Tiannara.Omega.DeploymentGateway

    fake = Candidate.new(:code_patch, :probe, %{probe: true})

    # 3a. Direct state-machine bypass must be illegal
    r1 = Candidate.transition(fake, :deployed)
    ok1 =
      case r1 do
        {:error, {:illegal_transition, from: _, to: _, legal: _}} -> true
        _ -> false
      end

    # 3b. Gateway deploy without authorization must be rejected
    with {:ok, c1} <- Candidate.transition(fake, :sandboxed),
         {:ok, c2} <- Candidate.transition(c1, :tested),
         {:ok, c3} <- Candidate.transition(c2, :benchmarked),
         {:ok, c4} <- Candidate.transition(c3, :certified),
         {:ok, approved} <- Candidate.transition(c4, :approved) do
      r2 = DeploymentGateway.deploy(approved, %{verdict: :certified}, [:obs_probe], nil, nil)
      ok2 = match?({:error, :authorization_grant_required}, r2)

      if ok1 and ok2 do
        IO.puts(
          "INJECTION 3 (restraint_probe): PASS (state-machine + gateway both rejected bypass)"
        )
      else
        IO.puts("INJECTION 3 (restraint_probe): FAIL (transition_ok=#{ok1} gateway_ok=#{ok2})")
      end
    else
      err ->
        IO.puts("INJECTION 3 (restraint_probe): FAIL (setup error #{inspect(err)})")
    end
  end
end

case List.first(System.argv(), "all") do
  "kill" -> Inject.injection_kill()
  "tamper" -> Inject.injection_tamper()
  "restraint" -> Inject.injection_restraint()
  _ ->
    Inject.injection_kill()
    Inject.injection_tamper()
    Inject.injection_restraint()
end

IO.puts("VERDICT: injections complete (isolated scratch node; running soak untouched)")