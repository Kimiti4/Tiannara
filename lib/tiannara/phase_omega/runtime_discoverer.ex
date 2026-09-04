defmodule Tiannara.PhaseOmega.RuntimeDiscoverer do
  alias Tiannara.PhaseOmega.SubsystemRegistry
  @moduledoc """
  Ω.1 — Automatic runtime discovery engine.

  Introspects the BEAM to discover every running process, supervisor,
  GenServer, ETS table, registered process, and OTP application, then
  registers them in the SubsystemRegistry.

  ## Discovery modes

    discovery
      ─ Scans :erlang.processes() and registers every supervised
        GenServer registered under a Tiannara namespace

    supervisor_walk
      ─ Given a supervisor pid, walks its children recursively
        to build the full supervision tree

    ets_scan
      ─ Discovers all ETS tables owned by Tiannara processes

    app_scan
      ─ Discovers all loaded OTP applications containing Tiannara
        modules
  """

  require Logger

  @tiannara_prefixes [:tiannara, :Tiannara, :TiannaraOS, :ObservatoryApi,
                       :ObservationBus, :TelemetryGateway, :TiannaraRuntime]

  @doc """
  Run full discovery: scan all processes, supervisors, ETS tables,
  and OTP applications. Returns the count of newly discovered items.
  """
  def run_full_discovery do
    Logger.info("[PhaseΩ:Discoverer] Starting full runtime discovery...")

    app_count = discover_applications()
    sv_count = discover_tiannara_processes()
    ets_count = discover_ets_tables()

    total = app_count + sv_count + ets_count
    Logger.info("[PhaseΩ:Discoverer] Discovery complete — #{total} items registered")
    :ok
  end

  @doc """
  Discover all OTP applications with Tiannara-related modules.
  """
  def discover_applications do
    :application.which_applications()
    |> Enum.filter(fn {name, _desc, _vsn} ->
      Enum.any?(@tiannara_prefixes, fn prefix ->
        String.starts_with?(Atom.to_string(name), Atom.to_string(prefix)) ||
        String.starts_with?(Atom.to_string(name), String.downcase(Atom.to_string(prefix)))
      end) || name in [:phoenix, :phoenix_pubsub, :telemetry, :gnat]
    end)
    |> Enum.map(fn {name, _desc, vsn} ->
      Tiannara.PhaseOmega.SubsystemRegistry.register(name, %{
        module: name,
        app: name,
        version: parse_version(vsn),
        description: "OTP application: #{name}"
      })
      Tiannara.PhaseOmega.SubsystemRegistry.transition(name, :healthy)
      name
    end)
    |> length()
  end

  @doc """
  Scan all BEAM processes and register those belonging to Tiannara.
  Detects supervisors, GenServers, and registered named processes.
  """
  def discover_tiannara_processes do
    :erlang.processes()
    |> Enum.filter(&is_process_alive/1)
    |> Enum.map(fn pid ->
      info = Process.info(pid, [:registered_name, :initial_call, :dictionary])
      {pid, info}
    end)
    |> Enum.filter(fn {_pid, info} -> is_tiannara_process?(info) end)
    |> Enum.map(fn {pid, info} ->
      register_process(pid, info)
    end)
    |> length()
  end

  @doc """
  Discover ETS tables owned by Tiannara processes.
  """
  def discover_ets_tables do
    :ets.all()
    |> Enum.filter(fn tid ->
      try do
        owner = :ets.info(tid, :owner)
        owner_info = Process.info(owner, [:registered_name])
        is_tiannara_process?(owner_info)
      rescue
        _ -> false
      end
    end)
    |> Enum.map(fn tid ->
      name = :ets.info(tid, :name)
      owner = :ets.info(tid, :owner)
      owner_name = get_process_name(owner)

      record = SubsystemRegistry.get(owner_name)
      current_ets = if record, do: record.ets_tables, else: []

      if record do
        SubsystemRegistry.register(record.name, %{
          module: record.module,
          ets_tables: [name | current_ets] |> Enum.uniq()
        })
      end
    end)
    |> length()
  end

  @doc """
  Recursively walk a supervisor tree starting from `pid`.
  Returns a flat list of {child_name, child_pid, child_type}.
  """
  def walk_supervisor_tree(pid, acc \\ []) do
    try do
      children = Supervisor.which_children(pid)

      Enum.reduce(children, acc, fn {id, child_pid, type, _modules}, inner_acc ->
        entry = {id, child_pid, type}
        new_acc = [entry | inner_acc]

        if type == :supervisor && is_pid(child_pid) do
          walk_supervisor_tree(child_pid, new_acc)
        else
          new_acc
        end
      end)
    rescue
      _ -> acc
    end
  end

  @doc """
  Get the supervision tree for the entire Tiannara application.
  Returns a nested map structure.
  """
  def supervision_forest do
    [Tiannara.Application, TiannaraRuntime.StartupSupervisor]
    |> Enum.filter(fn mod -> Code.ensure_loaded?(mod) end)
    |> Enum.filter(fn mod -> function_exported?(mod, :start_link, 1) end)
    |> Enum.map(fn mod ->
      pid = Process.whereis(mod)
      if pid && Process.alive?(pid) do
        children = walk_supervisor_tree(pid)
        format_supervisor_tree(mod, pid, children)
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  defp is_process_alive(pid) do
    try do
      Process.alive?(pid)
    rescue
      _ -> false
    end
  end

  defp is_tiannara_process?(nil), do: false
  defp is_tiannara_process?(info) when is_list(info) do
    has_tiannara_name?(info) || has_tiannara_call?(info)
  end

  defp has_tiannara_name?(info) do
    case Keyword.get(info, :registered_name) do
      name when is_atom(name) ->
        name_str = Atom.to_string(name)
        Enum.any?(@tiannara_prefixes, fn prefix ->
          String.starts_with?(name_str, Atom.to_string(prefix)) ||
          String.starts_with?(name_str, String.downcase(Atom.to_string(prefix)))
        end)
      _ -> false
    end
  end

  defp has_tiannara_call?(info) do
    case Keyword.get(info, :initial_call) do
      {mod, _fun, _arity} ->
        mod_str = Atom.to_string(mod)
        String.contains?(mod_str, "Tiannara") || String.contains?(mod_str, "tiannara")
      _ -> false
    end
  end

  defp register_process(pid, info) do
    name = get_process_name(info)
    initial_call = Keyword.get(info, :initial_call, {nil, nil, nil})
    {call_mod, call_fun, _arity} = initial_call

    is_supervisor = supervisor_module?(call_mod, call_fun)

    Tiannara.PhaseOmega.SubsystemRegistry.register(name, %{
      module: call_mod,
      pid: pid,
      supervisor: if(is_supervisor, do: call_mod, else: nil),
      app: find_app(call_mod),
      description: "Process: #{call_mod}.#{call_fun}/#{elem(initial_call, 2)}"
    })

    if is_supervisor do
      children = walk_supervisor_tree(pid)
      child_modules = children |> Enum.map(fn {_id, _pid, type} -> type end)

      Tiannara.PhaseOmega.SubsystemRegistry.register(name, %{
        module: call_mod,
        supervisor: call_mod,
        children: child_modules,
        running_children: Enum.map(children, fn {_id, pid, _type} -> pid end)
      })
    end

    Tiannara.PhaseOmega.SubsystemRegistry.transition(name, :healthy, pid: pid)
  end

  defp get_process_name(info) do
    case Keyword.get(info, :registered_name) do
      name when is_atom(name) -> name
      _ ->
        case Keyword.get(info, :initial_call) do
          {mod, _fun, _arity} -> mod
          _ -> :anonymous_process
        end
    end
  end

  defp supervisor_module?(_mod, :start_link), do: true
  defp supervisor_module?(_mod, :init), do: true
  defp supervisor_module?(_, _), do: false

  defp find_app(module) do
    case :application.get_application(module) do
      {:ok, app} -> app
      :undefined -> :unknown
    end
  end

  defp parse_version(vsn) when is_list(vsn) do
    vsn
    |> List.to_string()
    |> String.split(".")
    |> hd()
    |> String.to_integer()
  rescue
    _ -> 1
  end
  defp parse_version(_), do: 1

  defp format_supervisor_tree(mod, pid, children) do
    grouped = Enum.group_by(children, fn {_id, _pid, type} -> type end)

    %{
      module: mod,
      pid: pid,
      supervisors: length(Map.get(grouped, :supervisor, [])),
      workers: length(Map.get(grouped, :worker, [])),
      gen_servers: length(Map.get(grouped, :gen_server, [])),
      total_children: length(children)
    }
  end
end
