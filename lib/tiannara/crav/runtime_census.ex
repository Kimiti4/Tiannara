defmodule Tiannara.CRAV.RuntimeCensus do
  @moduledoc """
  Phase Ω+ CRAV Runtime Census — Deliverable 1.

  Auto-discovers every subsystem running on the BEAM and generates
  a comprehensive census by combining supervision tree walks,
  named process discovery, ETS table scanning, and the
  SubsystemRegistry.
  """

  require Logger

  alias Tiannara.PhaseOmega.RuntimeDiscoverer
  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :census, :complete]

  @spec census() :: {:ok, [map()]} | {:error, term()}
  def census do
    try do
      entries =
        discover_all()
        |> Enum.map(&build_entry/1)
        |> Enum.uniq_by(& &1.name)

      measurements = %{count: length(entries)}
      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:census_failed, err}}
    end
  end

  @spec census_report() :: {:ok, String.t()} | {:error, term()}
  def census_report do
    case census() do
      {:ok, entries} ->
        alive = Enum.count(entries, &(&1.status == :alive))
        dormant = Enum.count(entries, &(&1.status == :dormant))
        failed = Enum.count(entries, &(&1.status == :failed))
        total = length(entries)
        now = DateTime.utc_now()

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV RUNTIME CENSUS — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Total: #{total}  |  Alive: #{alive}  |  Dormant: #{dormant}  |  Failed: #{failed}",
            "───────────────────────────────────────────────────────"
          ] ++
          Enum.map(entries, fn e ->
            health_str =
              case e.health do
                h when is_float(h) -> Float.round(h, 2) |> to_string()
                _ -> "n/a"
              end

            "  #{pad_atom(e.name, 40)} #{pad_status(e.status, 12)} health=#{health_str} mem=#{e.memory_bytes}B mq=#{e.message_queue_len}"
          end) ++
          [
            "═══════════════════════════════════════════════════════"
          ]

        {:ok, Enum.join(lines, "\n")}

      {:error, _} = err ->
        err
    end
  end

  @spec subsystem_count() :: {:ok, non_neg_integer()} | {:error, term()}
  def subsystem_count do
    case census() do
      {:ok, entries} -> {:ok, length(entries)}
      err -> err
    end
  end

  @spec alive_count() :: {:ok, non_neg_integer()} | {:error, term()}
  def alive_count do
    case census() do
      {:ok, entries} -> {:ok, Enum.count(entries, &(&1.status == :alive))}
      err -> err
    end
  end

  @spec dormant_count() :: {:ok, non_neg_integer()} | {:error, term()}
  def dormant_count do
    case census() do
      {:ok, entries} -> {:ok, Enum.count(entries, &(&1.status == :dormant))}
      err -> err
    end
  end

  defp discover_all do
    registry_entries = safe_registry_all()
    supervisor_entries = discover_from_supervision_trees()
    named_process_entries = discover_named_processes()
    ets_entries = discover_ets()
    app_entries = discover_applications()

    all = registry_entries ++ supervisor_entries ++ named_process_entries ++ ets_entries ++ app_entries

    all
    |> Enum.group_by(&discovery_name/1)
    |> Enum.map(fn {name, group} -> merge_discoveries(name, group) end)
  end

  defp discovery_name(entry), do: Map.get(entry, :name, :unknown)

  defp merge_discoveries(name, group) do
    Enum.reduce(group, %{name: name}, fn entry, acc ->
      Map.merge(acc, entry, fn
        _k, nil, v -> v
        _k, v, nil -> v
        _k, [], v -> v
        _k, v, [] -> v
        _k, v, v -> v
        _k, old, new when is_list(old) and is_list(new) -> Enum.uniq(old ++ new)
        _k, _old, new -> new
      end)
    end)
  end

  defp safe_registry_all do
    try do
      if Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
        |> Enum.map(fn rec ->
          %{
            name: rec.name,
            module: rec.module,
            application: rec.app,
            version: format_version(rec.version),
            pid: rec.pid,
            supervisor: rec.supervisor,
            children: rec.children || [],
            dependencies: rec.deps || [],
            registry_status: rec.status,
            registry_health: rec.health,
            last_activity: datetime_to_unix(rec.last_activity),
            ets_tables: rec.ets_tables || []
          }
        end)
      else
        []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp discover_from_supervision_trees do
    root_pids = find_supervisor_roots()

    root_pids
    |> Enum.flat_map(fn pid ->
      safe_walk(pid)
    end)
    |> Enum.map(fn {id, child_pid, type} ->
      name = resolve_name(id, child_pid)
      info = safe_process_info(child_pid)
      {mod, app} = resolve_module_and_app(child_pid)

      %{
        name: name,
        module: mod,
        application: app,
        pid: child_pid,
        children: [],
        state: infer_state(info),
        memory_bytes: Keyword.get(info, :memory, 0),
        message_queue_len: Keyword.get(info, :message_queue_len, 0),
        type: type
      }
    end)
  end

  defp find_supervisor_roots do
    registered = Process.registered()
    |> Enum.map(&Process.whereis/1)
    |> Enum.filter(&is_pid/1)
    |> Enum.filter(&supervisor_pid?/1)

    known = [Tiannara.Application, TiannaraRuntime.StartupSupervisor]
    |> Enum.map(&Process.whereis/1)
    |> Enum.filter(&is_pid/1)

    Enum.uniq(registered ++ known)
  end

  defp supervisor_pid?(pid) do
    try do
      case Process.info(pid, :dictionary) do
        {:dictionary, dict} when is_list(dict) ->
          Enum.any?(dict, fn
            {:"$initial_call", {:supervisor, _, _}} -> true
            _ -> false
          end)
        _ -> false
      end
    rescue
      _ -> false
    end
  end

  defp safe_walk(pid) do
    try do
      RuntimeDiscoverer.walk_supervisor_tree(pid)
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp discover_named_processes do
    Process.registered()
    |> Enum.map(fn name ->
      pid = Process.whereis(name)
      info = safe_process_info(pid)
      {mod, app} = resolve_module_and_app(pid)

      %{
        name: name,
        module: mod,
        application: app,
        pid: pid,
        state: infer_state(info),
        memory_bytes: Keyword.get(info, :memory, 0),
        message_queue_len: Keyword.get(info, :message_queue_len, 0)
      }
    end)
  end

  defp discover_ets do
    :ets.all()
    |> Enum.map(fn tid ->
      try do
        name = :ets.info(tid, :name)
        owner = :ets.info(tid, :owner)
        size = :ets.info(tid, :size)
        memory = :ets.info(tid, :memory)

        owner_name = case Process.info(owner, :registered_name) do
          {:registered_name, n} when is_atom(n) -> n
          _ -> name
        end

        %{
          name: :"ets:#{owner_name}",
          module: :ets,
          application: find_app_for_pid(owner),
          pid: owner,
          state: :running,
          memory_bytes: memory * :erlang.system_info(:wordsize),
          message_queue_len: 0,
          ets_tables: [name],
          meta: %{ets_size: size}
        }
      rescue
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp discover_applications do
    :application.which_applications()
    |> Enum.map(fn {name, _desc, vsn} ->
      %{
        name: :"app:#{name}",
        module: name,
        application: name,
        version: parse_vsn(vsn),
        pid: nil,
        state: :running,
        memory_bytes: 0,
        message_queue_len: 0
      }
    end)
  end

  defp build_entry(discovery) do
    pid = Map.get(discovery, :pid)
    info = safe_process_info(pid)

    name = Map.get(discovery, :name, :unknown)
    mod = Map.get(discovery, :module)
    app = Map.get(discovery, :application, :unknown)
    version = Map.get(discovery, :version)
    supervisor = Map.get(discovery, :supervisor)
    children = Map.get(discovery, :children, [])
    deps = Map.get(discovery, :dependencies, [])
    last_activity = Map.get(discovery, :last_activity)

    state = if Map.has_key?(discovery, :state) do
      Map.get(discovery, :state)
    else
      infer_state(info)
    end

    memory = if Map.has_key?(discovery, :memory_bytes) do
      Map.get(discovery, :memory_bytes)
    else
      Keyword.get(info, :memory, 0)
    end

    mq_len = if Map.has_key?(discovery, :message_queue_len) do
      Map.get(discovery, :message_queue_len)
    else
      Keyword.get(info, :message_queue_len, 0)
    end

    restart_count = Keyword.get(info, :reductions, 0)
    |> then(fn r -> max(0, div(r, 1000)) end)

    health = compute_health(state, mq_len, memory)
    status = compute_status(state, pid)

    %{
      name: name,
      module: mod,
      application: app,
      version: version,
      pid: pid,
      state: state,
      supervisor: supervisor,
      children: Enum.map(children, &ensure_map/1),
      restart_count: restart_count,
      last_activity: last_activity,
      health: health,
      dependencies: deps,
      events_published: [],
      events_received: [],
      memory_bytes: memory,
      message_queue_len: mq_len,
      status: status
    }
  end

  defp infer_state(info) when is_list(info) do
    status = Keyword.get(info, :status)

    case status do
      :waiting -> :sleeping
      :running -> :running
      :suspended -> :blocked
      :exiting -> :error
      _ -> :unknown
    end
  end
  defp infer_state(_), do: :unknown

  defp compute_health(state, mq_len, memory) do
    base = case state do
      :running -> 1.0
      :sleeping -> 0.8
      :blocked -> 0.4
      :error -> 0.0
      :unknown -> 0.5
    end

    mq_penalty = min(mq_len / 1000, 0.3)
    mem_penalty = min(memory / 100_000_000, 0.2)

    Float.round(max(0.0, min(1.0, base - mq_penalty - mem_penalty)), 4)
  end

  defp compute_status(state, pid) do
    cond do
      pid != nil and is_pid(pid) and Process.alive?(pid) and state in [:running, :sleeping] -> :alive
      pid != nil and is_pid(pid) and Process.alive?(pid) and state == :error -> :failed
      pid == nil or (is_pid(pid) and not Process.alive?(pid)) -> :dormant
      state == :blocked -> :dormant
      true -> :dormant
    end
  end

  defp safe_process_info(nil), do: []
  defp safe_process_info(pid) when is_pid(pid) do
    try do
      if Process.alive?(pid) do
        Process.info(pid, [:registered_name, :status, :memory, :message_queue_len,
                           :initial_call, :dictionary, :reductions, :current_function])
        |> case do
          nil -> []
          info -> info
        end
      else
        []
      end
    rescue
      _ -> []
    end
  end

  defp safe_process_info(_), do: []

  defp resolve_name(id, _pid) when is_atom(id), do: id
  defp resolve_name(_id, pid) when is_pid(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} when is_atom(name) -> name
      _ ->
        case Process.info(pid, :initial_call) do
          {:initial_call, {mod, _, _}} -> mod
          _ -> pid
        end
    end
  end
  defp resolve_name(id, _pid), do: id

  defp resolve_module_and_app(nil), do: {nil, :unknown}
  defp resolve_module_and_app(pid) when is_pid(pid) do
    info = safe_process_info(pid)

    mod = case Keyword.get(info, :initial_call) do
      {m, _, _} when is_atom(m) -> m
      _ ->
        case Keyword.get(info, :registered_name) do
          n when is_atom(n) -> n
          _ -> nil
        end
    end

    app = find_app_for_pid(pid)
    {mod, app}
  end

  defp resolve_module_and_app(_), do: {nil, :unknown}

  defp find_app_for_pid(nil), do: :unknown
  defp find_app_for_pid(pid) when is_pid(pid) do
    case Process.info(pid, :initial_call) do
      {:initial_call, {mod, _, _}} when is_atom(mod) ->
        case :application.get_application(mod) do
          {:ok, app} -> app
          :undefined -> :unknown
        end
      _ -> :unknown
    end
  end

  defp find_app_for_pid(_), do: :unknown

  defp format_version(v) when is_integer(v), do: Integer.to_string(v)
  defp format_version(v) when is_binary(v), do: v
  defp format_version(_), do: nil

  defp parse_vsn(vsn) when is_list(vsn), do: List.to_string(vsn)
  defp parse_vsn(vsn) when is_binary(vsn), do: vsn
  defp parse_vsn(_), do: nil

  defp datetime_to_unix(nil), do: nil
  defp datetime_to_unix(%DateTime{} = dt), do: DateTime.to_unix(dt)
  defp datetime_to_unix(_), do: nil

  defp ensure_map(m) when is_map(m), do: m
  defp ensure_map(m) when is_atom(m), do: %{name: m}
  defp ensure_map(m) when is_pid(m), do: %{pid: m}
  defp ensure_map(m), do: %{name: m}

  defp pad_atom(atom, width) when is_atom(atom) do
    str = Atom.to_string(atom)
    String.pad_trailing(str, width)
  end
  defp pad_atom(other, width) do
    str = to_string(other)
    String.pad_trailing(str, width)
  end

  defp pad_status(status, width) do
    str = Atom.to_string(status)
    String.pad_trailing(str, width)
  end
end
