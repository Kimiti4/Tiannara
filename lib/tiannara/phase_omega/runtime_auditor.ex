defmodule Tiannara.PhaseOmega.RuntimeAuditor do
  @moduledoc """
  Ω.6–8 — Combined Supervisor, Worker, and Scheduler Audit.

  Inspects every supervision tree, process, and periodic scheduler in the
  runtime. Detects:

    - Deadlocked or starved workers
    - Orphaned processes (no supervisor)
    - Supervision tree depth and breadth
    - Scheduler liveness
    - Process mailbox sizes
    - Memory usage per process
  """

  require Logger

  @max_mailbox_before_warning 100
  @tiannara_prefixes [:tiannara, :Tiannara, :TiannaraOS, :TiannaraRuntime]

  @doc """
  Run full audit of all supervisors, workers, and schedulers.
  """
  def audit_all do
    Logger.info("[PhaseΩ:Auditor] Starting full runtime audit...")

    supervisors = audit_supervisors()
    workers = audit_workers()
    schedulers = audit_schedulers()

    %{
      supervisors: supervisors,
      workers: workers,
      schedulers: schedulers,
      summary: %{
        total_supervisors: supervisors.total,
        total_workers: workers.total,
        unhealthy_workers: length(workers.unhealthy),
        large_mailboxes: length(workers.large_mailbox),
        schedulers_running: schedulers.running,
        orphaned_processes: length(workers.orphaned)
      },
      timestamp: DateTime.utc_now()
    }
  end

  # --------------------------------------------------------------------------
  # Ω.6 — Supervisor Audit
  # --------------------------------------------------------------------------

  def audit_supervisors do
    supervisors = find_supervisors()

    inspected = Enum.map(supervisors, fn {name, pid} ->
      inspect_supervisor(name, pid)
    end)

    %{
      total: length(inspected),
      items: inspected
    }
  end

  defp find_supervisors do
    # Get known supervisors from SubsystemRegistry — avoids destructive GenServer.call probes
    try do
      Tiannara.PhaseOmega.SubsystemRegistry.all()
      |> Enum.map(fn record ->
        pid = record.pid
        if is_pid(pid) && Process.alive?(pid) do
          name = case Process.info(pid, :registered_name) do
            {:registered_name, n} when is_atom(n) -> n
            _ -> record.module
          end
          {name, pid}
        end
      end)
      |> Enum.reject(&is_nil/1)
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp inspect_supervisor(name, pid) do
    children = safe_which_children(pid)

    counts = Enum.reduce(children, %{supervisor: 0, worker: 0, gen_server: 0, other: 0}, fn
      {_id, _child_pid, :supervisor, _mods}, acc -> Map.update!(acc, :supervisor, &(&1 + 1))
      {_id, _child_pid, :worker, _mods}, acc -> Map.update!(acc, :worker, &(&1 + 1))
      {_id, _child_pid, :gen_server, _mods}, acc -> Map.update!(acc, :gen_server, &(&1 + 1))
      _, acc -> Map.update!(acc, :other, &(&1 + 1))
    end)

    %{
      name: name,
      pid: pid,
      children_count: length(children),
      types: counts,
      depth: supervision_depth(pid, 0)
    }
  end

  defp safe_which_children(pid) do
    if is_otp_supervisor?(pid) do
      try do
        Supervisor.which_children(pid)
      rescue
        _ -> []
      catch
        _, _ -> []
      end
    else
      []
    end
  end

  defp is_otp_supervisor?(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dict} when is_list(dict) ->
        case Keyword.fetch(dict, :"$initial_call") do
          {:ok, {:supervisor, _}} -> true
          _ -> false
        end
      _ -> false
    end
  end

  defp supervision_depth(pid, depth) do
    children = safe_which_children(pid)
    sub_supervisors = Enum.filter(children, fn
      {_id, child_pid, :supervisor, _mods} when is_pid(child_pid) -> true
      _ -> false
    end)

    if sub_supervisors == [] do
      depth
    else
      Enum.map(sub_supervisors, fn {_id, child_pid, _type, _mods} ->
        supervision_depth(child_pid, depth + 1)
      end)
      |> Enum.max(fn -> depth end)
    end
  end

  # --------------------------------------------------------------------------
  # Ω.7 — Worker Audit
  # --------------------------------------------------------------------------

  def audit_workers do
    processes = :erlang.processes()
    |> Enum.filter(&Process.alive?/1)
    |> Enum.map(fn pid ->
      info = Process.info(pid, [:registered_name, :message_queue_len, :memory, :initial_call, :dictionary, :reductions])
      {pid, info}
    end)
    |> Enum.filter(fn {_pid, info} -> is_tiannara?(info) end)

    unhealthy = Enum.filter(processes, fn {_pid, info} ->
      mq = Keyword.get(info, :message_queue_len, 0)
      mq > @max_mailbox_before_warning
    end)

    large_mailbox = Enum.map(unhealthy, fn {pid, info} ->
      %{
        pid: pid,
        name: get_name(info),
        mailbox_size: Keyword.get(info, :message_queue_len, 0),
        memory: Keyword.get(info, :memory, 0)
      }
    end)

    orphaned = find_orphaned(processes)

    %{
      total: length(processes),
      unhealthy: large_mailbox,
      large_mailbox: large_mailbox,
      orphaned: orphaned
    }
  end

  defp find_orphaned(processes) do
    # Use registered supervisor PIDs — avoids destructive :count_children probes
    all_supervisor_pids = try do
      Tiannara.PhaseOmega.SubsystemRegistry.all()
      |> Enum.map(& &1.pid)
      |> Enum.filter(&is_pid/1)
      |> MapSet.new()
    rescue
      _ -> MapSet.new()
    catch
      _, _ -> MapSet.new()
    end

    processes
    |> Enum.filter(fn {pid, _info} ->
      not MapSet.member?(all_supervisor_pids, pid) && not has_supervisor?(pid)
    end)
    |> Enum.map(fn {pid, info} ->
      %{
        pid: pid,
        name: get_name(info),
        memory: Keyword.get(info, :memory, 0)
      }
    end)
  end

  defp has_supervisor?(pid) do
    try do
      # Check if this process is a child of any supervisor
      Process.info(pid, :dictionary)
      |> elem(1)
      |> case do
        dict when is_list(dict) ->
          Enum.any?(dict, fn
            {:"$ancestors", ancestors} when is_list(ancestors) -> ancestors != []
            _ -> false
          end)
        _ -> false
      end
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------------------------
  # Ω.8 — Scheduler Audit
  # --------------------------------------------------------------------------

  def audit_schedulers do
    # Check Erlang scheduler info
    scheduler_count = :erlang.system_info(:schedulers_online)
    run_queue = :erlang.statistics(:run_queue)

    # Check for known periodic schedulers / timers
    known_timers = find_known_timers()

    %{
      erlang_schedulers_online: scheduler_count,
      run_queue_length: run_queue,
      known_timers: known_timers,
      running: known_timers.running
    }
  end

  defp find_known_timers do
    timer_modules = [
      Tiannara.PhaseOmega.RuntimeVerifier,
      Tiannara.Runtime.TimeReverse,
      TiannaraRuntime.Monitoring.TelemetryPublisher
    ]

    results = Enum.map(timer_modules, fn mod ->
      pid = Process.whereis(mod)
      %{
        module: mod,
        pid: pid,
        alive: pid != nil && Process.alive?(pid)
      }
    end)

    %{
      total: length(results),
      running: Enum.count(results, & &1.alive),
      timers: results
    }
  end

  # --------------------------------------------------------------------------
  # Shared helpers
  # --------------------------------------------------------------------------

  defp is_tiannara?(nil), do: false
  defp is_tiannara?(info) when is_list(info) do
    has_prefix?(Keyword.get(info, :registered_name)) ||
    has_prefix?(elem(Keyword.get(info, :initial_call, {nil, nil, nil}), 0))
  end

  defp has_prefix?(nil), do: false
  defp has_prefix?(name) when is_atom(name) do
    str = Atom.to_string(name)
    # Elixir module atoms (e.g. :Tiannara.Foo) are stored as "Elixir.Tiannara.Foo"
    str = String.replace_prefix(str, "Elixir.", "")
    str_lower = String.downcase(str)
    Enum.any?(@tiannara_prefixes, fn prefix ->
      pfx = Atom.to_string(prefix)
      String.starts_with?(str, pfx) || String.starts_with?(str_lower, pfx) ||
      String.starts_with?(str_lower, String.downcase(pfx))
    end)
  end
  defp has_prefix?(_), do: false

  defp get_name(info) do
    case Keyword.get(info, :registered_name) do
      name when is_atom(name) -> name
      _ ->
        case Keyword.get(info, :initial_call) do
          {mod, _fun, _arity} -> mod
          _ -> :anonymous
        end
    end
  end
end
