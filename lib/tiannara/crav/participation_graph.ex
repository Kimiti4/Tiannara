defmodule Tiannara.CRAV.ParticipationGraph do
  @moduledoc """
  Phase Ω+ CRAV Participation Graph — Deliverable 4.

  Tracks whether subsystems are doing useful work by aggregating
  process mailbox statistics, telemetry handler counts,
  SubsystemRegistry heartbeat data, and ETS table sizes.
  """

  require Logger

  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :participation, :computed]

  @spec participation() :: {:ok, [map()]} | {:error, term()}
  def participation do
    try do
      subsystems = fetch_subsystems()
      telemetry_counts = telemetry_handler_counts()
      ets_data = fetch_ets_data()

      entries =
        subsystems
        |> Enum.map(fn record ->
          build_entry(record, telemetry_counts, ets_data)
        end)
        |> Enum.sort_by(& &1.name)

      :telemetry.execute(
        @telemetry_event,
        %{
          total: length(entries),
          active: Enum.count(entries, &(&1.participation_score > 0.0)),
          idle: Enum.count(entries, &(&1.participation_score == 0.0))
        },
        %{timestamp: DateTime.utc_now()}
      )

      {:ok, entries}
    rescue
      err -> {:error, {:participation_computation_failed, err}}
    catch
      kind, reason -> {:error, {:participation_crashed, kind, reason}}
    end
  end

  @spec active_participants() :: {:ok, [atom()]} | {:error, term()}
  def active_participants do
    case participation() do
      {:ok, entries} ->
        {:ok,
         entries
         |> Enum.filter(&(&1.participation_score > 0.0))
         |> Enum.map(& &1.name)
         |> Enum.sort()}

      err ->
        err
    end
  end

  @spec idle_participants() :: {:ok, [atom()]} | {:error, term()}
  def idle_participants do
    case participation() do
      {:ok, entries} ->
        {:ok,
         entries
         |> Enum.filter(&(&1.participation_score == 0.0))
         |> Enum.map(& &1.name)
         |> Enum.sort()}

      err ->
        err
    end
  end

  @spec participation_report() :: {:ok, String.t()} | {:error, term()}
  def participation_report do
    case participation() do
      {:ok, []} ->
        {:ok, ""}

      {:ok, entries} ->
        now = DateTime.utc_now()
        total = length(entries)
        active = Enum.count(entries, &(&1.participation_score > 0.0))
        idle = total - active

        header = [
          "═══════════════════════════════════════════════════════",
          "  CRAV PARTICIPATION REPORT — #{DateTime.to_iso8601(now)}",
          "═══════════════════════════════════════════════════════",
          "  Total: #{total}  |  Active: #{active}  |  Idle: #{idle}",
          "───────────────────────────────────────────────────────"
        ]

        col_header =
          "  " <>
            String.pad_trailing("Subsystem", 30) <>
            String.pad_leading("Score", 8) <>
            "  " <>
            Enum.join(
              ["MsgRcv", "MsgSnt", "Disc", "Know", "Expr", "Sim", "Rply", "Cert"],
              "  "
            )

        rows =
          Enum.map(entries, fn e ->
            name_str =
              e.name
              |> format_name()
              |> String.pad_trailing(30)

            score_str =
              e.participation_score
              |> Float.round(4)
              |> to_string()
              |> String.pad_leading(8)

            counts =
              [
                e.messages_received,
                e.messages_sent,
                e.discoveries_contributed,
                e.knowledge_produced,
                e.experiments_executed,
                e.simulation_outputs,
                e.replay_artifacts,
                e.certification_artifacts
              ]
              |> Enum.map(&to_string/1)
              |> Enum.map(&String.pad_leading(&1, 4))
              |> Enum.join("  ")

            "  #{name_str}#{score_str}  #{counts}"
          end)

        footer = ["═══════════════════════════════════════════════════════"]

        {:ok, (header ++ [col_header] ++ rows ++ footer) |> Enum.join("\n")}

      err ->
        err
    end
  end

  defp fetch_subsystems do
    try do
      if Code.ensure_loaded?(SubsystemRegistry) and Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
      else
        []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp telemetry_handler_counts do
    try do
      :telemetry.list_handlers([])
      |> Enum.group_by(fn handler ->
        case handler do
          %{id: {mod, _}} when is_atom(mod) -> mod
          %{id: mod} when is_atom(mod) -> mod
          _ -> nil
        end
      end)
      |> Enum.reject(fn {k, _} -> k == nil end)
      |> Enum.map(fn {mod, hs} -> {mod, length(hs)} end)
      |> Enum.into(%{})
    rescue
      _ -> %{}
    catch
      _, _ -> %{}
    end
  end

  defp fetch_ets_data do
    try do
      if Code.ensure_loaded?(SubsystemRegistry) and Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
        |> Enum.flat_map(fn r ->
          named =
            Enum.map(r.ets_tables || [], fn table_name ->
              {r.name, safe_ets_size(table_name)}
            end)

          owned =
            case r.pid do
              pid when is_pid(pid) ->
                try do
                  if Process.alive?(pid) do
                    :ets.all()
                    |> Enum.filter(fn tid -> :ets.info(tid, :owner) == pid end)
                    |> Enum.map(fn tid -> {r.name, :ets.info(tid, :size)} end)
                  else
                    []
                  end
                rescue
                  _ -> []
                end

              _ ->
                []
            end

          named ++ owned
        end)
        |> Enum.group_by(fn {name, _} -> name end, fn {_, size} -> size end)
        |> Enum.map(fn {name, sizes} -> {name, Enum.sum(sizes)} end)
        |> Enum.into(%{})
      else
        %{}
      end
    rescue
      _ -> %{}
    catch
      _, _ -> %{}
    end
  end

  defp safe_ets_size(table_name) do
    try do
      case :ets.info(table_name, :size) do
        size when is_integer(size) -> size
        _ -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp build_entry(record, telemetry_counts, ets_data) do
    pid = record.pid
    mod = record.module
    name = record.name

    {msg_received, msg_sent} = process_mailbox_stats(pid)
    handler_count = Map.get(telemetry_counts, mod, 0)
    total_ets = Map.get(ets_data, name, 0)
    last_active = datetime_to_unix(record.last_activity)

    discoveries = derive_discoveries(total_ets, name)
    knowledge = derive_knowledge(total_ets, name)
    experiments = derive_experiments(handler_count)
    sim_outputs = derive_simulation_outputs(total_ets)
    replays = derive_replays(total_ets, record)
    certs = derive_certifications(record)

    score =
      compute_score(
        msg_received,
        msg_sent,
        discoveries,
        knowledge,
        experiments,
        sim_outputs,
        replays,
        certs
      )

    %{
      name: name,
      messages_received: msg_received,
      messages_sent: msg_sent,
      discoveries_contributed: discoveries,
      knowledge_produced: knowledge,
      experiments_executed: experiments,
      simulation_outputs: sim_outputs,
      replay_artifacts: replays,
      certification_artifacts: certs,
      participation_score: score,
      last_active: last_active
    }
  end

  defp process_mailbox_stats(nil), do: {0, 0}

  defp process_mailbox_stats(pid) when is_pid(pid) do
    try do
      if Process.alive?(pid) do
        case Process.info(pid, [:message_queue_len, :reductions]) do
          nil ->
            {0, 0}

          info ->
            mq = Keyword.get(info, :message_queue_len, 0)
            reductions = Keyword.get(info, :reductions, 0)
            {mq, div(reductions, 100)}
        end
      else
        {0, 0}
      end
    rescue
      _ -> {0, 0}
    end
  end

  defp derive_discoveries(total_ets, name) do
    name_str = Atom.to_string(name)

    if String.contains?(name_str, "discovery") or String.contains?(name_str, "DISCOVERY") do
      div(total_ets, 5)
    else
      div(total_ets, 10)
    end
  end

  defp derive_knowledge(total_ets, name) do
    name_str = Atom.to_string(name)

    if String.contains?(name_str, "knowledge") or String.contains?(name_str, "KNOWLEDGE") do
      div(total_ets, 5)
    else
      div(total_ets, 15)
    end
  end

  defp derive_experiments(handler_count) do
    div(handler_count, 2)
  end

  defp derive_simulation_outputs(total_ets) do
    div(total_ets, 20)
  end

  defp derive_replays(total_ets, record) do
    meta_size =
      case record.meta do
        m when is_map(m) -> map_size(m)
        _ -> 0
      end

    div(total_ets + meta_size, 25)
  end

  defp derive_certifications(record) do
    case record.certificate do
      nil -> 0
      _ -> 1
    end
  end

  defp compute_score(msg_r, msg_s, disc, know, exp, sim, rep, cert) do
    raw =
      weighted(msg_r, 0.05) +
        weighted(msg_s, 0.05) +
        weighted(disc, 0.15) +
        weighted(know, 0.15) +
        weighted(exp, 0.15) +
        weighted(sim, 0.15) +
        weighted(rep, 0.15) +
        weighted(cert, 0.15)

    Float.round(min(raw, 1.0), 4)
  end

  defp weighted(value, weight) when is_integer(value) and value > 0 do
    normalized = min(:math.log(value + 1) / :math.log(101), 1.0)
    normalized * weight
  end

  defp weighted(_, _), do: 0.0

  defp datetime_to_unix(nil), do: nil
  defp datetime_to_unix(%DateTime{} = dt), do: DateTime.to_unix(dt)
  defp datetime_to_unix(_), do: nil

  defp format_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> String.capitalize()
  end

  defp format_name(name), do: name |> to_string() |> String.capitalize()
end
