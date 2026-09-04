defmodule Tiannara.CRAV.SupervisorIntegrity do
  @moduledoc """
  Phase Ω+ CRAV Supervisor Integrity — Deliverable 10.

  Audits every supervisor in the runtime by walking supervision trees,
  collecting child health metrics, and classifying each supervisor
  as healthy, degraded, or critical.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :supervisor, :audited]

  @root_supervisors [
    Tiannara.Application,
    Tiannara.Core.Supervisor,
    Tiannara.Stabilization.Supervisor,
    Tiannara.Physics.Supervisor,
    Tiannara.Sentinel.Supervisor,
    Tiannara.REA.Supervisor,
    Tiannara.SOPL.Supervisor,
    Tiannara.CIS.Supervisor,
    Tiannara.MSG.Supervisor,
    Tiannara.OMCE.Supervisor,
    Tiannara.HSV.Supervisor,
    Tiannara.GRCC.Supervisor,
    Tiannara.OED.Supervisor,
    Tiannara.CTL.Supervisor,
    Tiannara.A10.Supervisor,
    Tiannara.ASC.Supervisor,
    Tiannara.WorldModel.Supervisor,
    Tiannara.PlanetaryTwin.Supervisor,
    Tiannara.DiscoveryPipeline.Supervisor,
    Tiannara.EngineeringPipeline.Supervisor,
    Tiannara.SimulationRuntime.Supervisor,
    Tiannara.TheoryEcology.Supervisor,
    Tiannara.KnowledgeGraph.Supervisor,
    Tiannara.CivilizationRuntime.Supervisor
  ]

  @spec audit() :: {:ok, [map()]} | {:error, term()}
  def audit do
    try do
      supervisor_pids = discover_supervisors()

      entries =
        supervisor_pids
        |> Enum.map(&inspect_supervisor/1)
        |> Enum.reject(&is_nil/1)

      measurements = %{
        total: length(entries),
        healthy: Enum.count(entries, &(&1.health == :healthy)),
        degraded: Enum.count(entries, &(&1.health == :degraded)),
        critical: Enum.count(entries, &(&1.health == :critical))
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:supervisor_integrity_failed, err}}
    catch
      kind, reason -> {:error, {:supervisor_integrity_crashed, kind, reason}}
    end
  end

  @spec critical_supervisors() :: {:ok, [map()]} | {:error, term()}
  def critical_supervisors do
    case audit() do
      {:ok, entries} ->
        {:ok, Enum.filter(entries, &(&1.health == :critical))}

      err ->
        err
    end
  end

  @spec healthy_supervisors() :: {:ok, [map()]} | {:error, term()}
  def healthy_supervisors do
    case audit() do
      {:ok, entries} ->
        {:ok, Enum.filter(entries, &(&1.health == :healthy))}

      err ->
        err
    end
  end

  @spec supervisor_report() :: {:ok, String.t()} | {:error, term()}
  def supervisor_report do
    case audit() do
      {:ok, entries} ->
        now = DateTime.utc_now()
        total = length(entries)
        healthy_count = Enum.count(entries, &(&1.health == :healthy))
        degraded_count = Enum.count(entries, &(&1.health == :degraded))
        critical_count = Enum.count(entries, &(&1.health == :critical))

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV SUPERVISOR INTEGRITY — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Total: #{total}  |  Healthy: #{healthy_count}  |  Degraded: #{degraded_count}  |  Critical: #{critical_count}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(entries, fn e ->
              name_str =
                e.name
                |> format_supervisor_name()
                |> String.pad_trailing(40)

              health_str =
                e.health
                |> Atom.to_string()
                |> String.upcase()
                |> String.pad_trailing(10)

              children_str = "#{e.children_alive}/#{e.children_total}"
              strategy_str = Atom.to_string(e.strategy) |> String.pad_trailing(18)

              "  #{name_str} #{health_str} children=#{String.pad_leading(children_str, 7)} strategy=#{strategy_str} mem=#{e.memory_bytes}B mq=#{e.mailbox_size}"
            end) ++
            [
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp discover_supervisors do
    named =
      @root_supervisors
      |> Enum.map(&safe_whereis/1)
      |> Enum.filter(&is_pid/1)

    registered =
      Process.registered()
      |> Enum.map(&Process.whereis/1)
      |> Enum.filter(&is_pid/1)
      |> Enum.filter(&supervisor_pid?/1)

    (named ++ registered)
    |> Enum.uniq()
  end

  defp safe_whereis(name) do
    try do
      Process.whereis(name)
    rescue
      _ -> nil
    end
  end

  defp supervisor_pid?(pid) do
    try do
      case Process.info(pid, :dictionary) do
        {:dictionary, dict} when is_list(dict) ->
          Enum.any?(dict, fn
            {:"$initial_call", {:supervisor, _, _}} -> true
            _ -> false
          end)

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp inspect_supervisor(pid) do
    try do
      if Process.alive?(pid) do
        name = resolve_supervisor_name(pid)
        strategy = detect_strategy(pid)
        children = safe_which_children(pid)
        info = safe_process_info(pid)
        linked = safe_process_links(pid)

        children_total = length(children)

        children_alive =
          Enum.count(children, fn
            {_id, child_pid, _type, _mods} when is_pid(child_pid) -> Process.alive?(child_pid)
            _ -> false
          end)

        restart_frequency =
          if children_total > 0 do
            Float.round(children_alive / children_total, 4)
          else
            0.0
          end

        memory_bytes = Keyword.get(info, :memory, 0)
        mailbox_size = Keyword.get(info, :message_queue_len, 0)
        queue_depth = compute_queue_depth(children)
        started = Process.alive?(pid)
        health = determine_health(children_alive, children_total, mailbox_size)

        %{
          name: name,
          pid: pid,
          started: started,
          strategy: strategy,
          linked: linked,
          children_alive: children_alive,
          children_total: children_total,
          restart_frequency: restart_frequency,
          memory_bytes: memory_bytes,
          mailbox_size: mailbox_size,
          queue_depth: queue_depth,
          health: health
        }
      else
        nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp resolve_supervisor_name(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} when is_atom(name) ->
        name

      _ ->
        case Process.info(pid, :initial_call) do
          {:initial_call, {mod, _, _}} when is_atom(mod) -> mod
          _ -> pid
        end
    end
  end

  defp detect_strategy(pid) do
    try do
      state = :sys.get_state(pid, 1000)

      case state do
        tuple when is_tuple(tuple) and tuple_size(tuple) >= 3 ->
          elem(tuple, 2) |> normalize_strategy()

        _ ->
          :one_for_one
      end
    rescue
      _ -> :one_for_one
    catch
      _, _ -> :one_for_one
    end
  end

  defp normalize_strategy(:one_for_one), do: :one_for_one
  defp normalize_strategy(:one_for_all), do: :one_for_all
  defp normalize_strategy(:rest_for_one), do: :rest_for_one
  defp normalize_strategy(:simple_one_for_one), do: :simple_one_for_one
  defp normalize_strategy(_), do: :one_for_one

  defp safe_which_children(pid) do
    try do
      Supervisor.which_children(pid)
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp safe_process_info(pid) do
    try do
      if Process.alive?(pid) do
        case Process.info(pid, [:memory, :message_queue_len]) do
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

  defp safe_process_links(pid) do
    try do
      case Process.info(pid, :links) do
        {:links, links} when is_list(links) -> Enum.filter(links, &is_pid/1)
        _ -> []
      end
    rescue
      _ -> []
    end
  end

  defp compute_queue_depth(children) do
    children
    |> Enum.map(fn
      {_id, child_pid, _type, _mods} when is_pid(child_pid) ->
        try do
          if Process.alive?(child_pid) do
            case Process.info(child_pid, :message_queue_len) do
              {:message_queue_len, len} when is_integer(len) -> len
              _ -> 0
            end
          else
            0
          end
        rescue
          _ -> 0
        end

      _ ->
        0
    end)
    |> Enum.sum()
  end

  defp determine_health(children_alive, children_total, mailbox_size) do
    dead = children_total - children_alive
    half_dead = children_total > 0 and dead > 0 and dead >= div(children_total + 1, 2)

    cond do
      dead == 0 and mailbox_size < 50 ->
        :healthy

      half_dead or mailbox_size >= 200 ->
        :critical

      dead > 0 or mailbox_size >= 50 ->
        :degraded

      true ->
        :degraded
    end
  end

  defp format_supervisor_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
  end

  defp format_supervisor_name(name) do
    to_string(name)
  end
end
