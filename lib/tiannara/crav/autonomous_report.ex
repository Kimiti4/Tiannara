defmodule Tiannara.CRAV.AutonomousReport do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 12 — Autonomous Activity Report.

  Generates autonomous activity reports for 24/48/72 hour windows by
  aggregating telemetry events, SubsystemRegistry health transitions,
  process uptime statistics, and ETS table growth metrics.
  """

  require Logger

  alias Tiannara.CRAV.ParticipationGraph
  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :autonomous, :reported]

  @window_seconds %{hours_24: 86_400, hours_48: 172_800, hours_72: 259_200}

  @type window :: :hours_24 | :hours_48 | :hours_72

  @type metrics :: %{
    window: window(),
    discoveries: non_neg_integer(),
    experiments: non_neg_integer(),
    adaptations: non_neg_integer(),
    self_improvements: non_neg_integer(),
    failures: non_neg_integer(),
    recoveries: non_neg_integer(),
    idle_time_seconds: non_neg_integer(),
    uptime_seconds: non_neg_integer(),
    activity_score: float()
  }

  @spec report() :: {:ok, %{hours_24: metrics(), hours_48: metrics(), hours_72: metrics()}} | {:error, term()}
  def report do
    try do
      activity = collect_activity_counts()
      health = collect_health_data()
      uptime_secs = collect_uptime_seconds()
      ets_size = collect_ets_total_size()

      result = %{
        hours_24: build_metrics(:hours_24, activity, health, uptime_secs, ets_size),
        hours_48: build_metrics(:hours_48, activity, health, uptime_secs, ets_size),
        hours_72: build_metrics(:hours_72, activity, health, uptime_secs, ets_size)
      }

      :telemetry.execute(
        @telemetry_event,
        %{
          windows_reported: 3,
          score_24h: result.hours_24.activity_score,
          score_72h: result.hours_72.activity_score
        },
        %{timestamp: DateTime.utc_now()}
      )

      {:ok, result}
    rescue
      err -> {:error, {:autonomous_report_failed, err}}
    catch
      kind, reason -> {:error, {:autonomous_report_crashed, kind, reason}}
    end
  end

  @spec current_window() :: {:ok, metrics()} | {:error, term()}
  def current_window do
    case report() do
      {:ok, result} -> {:ok, result.hours_24}
      err -> err
    end
  end

  @spec autonomous_score() :: {:ok, float()} | {:error, term()}
  def autonomous_score do
    case report() do
      {:ok, result} ->
        score =
          result.hours_24.activity_score * 0.5 +
            result.hours_48.activity_score * 0.3 +
            result.hours_72.activity_score * 0.2

        {:ok, Float.round(min(1.0, max(0.0, score)), 4)}

      err ->
        err
    end
  end

  @spec autonomous_report() :: {:ok, String.t()} | {:error, term()}
  def autonomous_report do
    case report() do
      {:ok, result} ->
        now = DateTime.utc_now()

        composite =
          min(
            1.0,
            result.hours_24.activity_score * 0.5 +
              result.hours_48.activity_score * 0.3 +
              result.hours_72.activity_score * 0.2
          )

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV AUTONOMOUS REPORT — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Composite Autonomous Score: #{Float.round(composite * 100, 1)}%",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.flat_map([:hours_24, :hours_48, :hours_72], fn window ->
              m = Map.get(result, window)
              label = window |> Atom.to_string() |> String.upcase()

              [
                "  Window: #{label}",
                "    Discoveries ......... #{pad_int(m.discoveries)}",
                "    Experiments ......... #{pad_int(m.experiments)}",
                "    Adaptations ......... #{pad_int(m.adaptations)}",
                "    Self-Improvements ... #{pad_int(m.self_improvements)}",
                "    Failures ............ #{pad_int(m.failures)}",
                "    Recoveries .......... #{pad_int(m.recoveries)}",
                "    Idle Time (s) ....... #{pad_int(m.idle_time_seconds)}",
                "    Uptime (s) .......... #{pad_int(m.uptime_seconds)}",
                "    Activity Score ...... #{Float.round(m.activity_score, 4)}",
                ""
              ]
            end) ++
            ["═══════════════════════════════════════════════════════"]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp build_metrics(window, activity, health, uptime_secs, ets_size) do
    window_secs = Map.get(@window_seconds, window, 86_400)
    capped_uptime = min(uptime_secs, window_secs)

    failures = Map.get(health, :failures, 0)
    recoveries = Map.get(health, :recoveries, 0)

    %{
      window: window,
      discoveries: Map.get(activity, :discoveries, 0),
      experiments: Map.get(activity, :experiments, 0),
      adaptations: Map.get(activity, :adaptations, 0),
      self_improvements: Map.get(activity, :self_improvements, 0),
      failures: failures,
      recoveries: recoveries,
      idle_time_seconds: max(0, window_secs - capped_uptime),
      uptime_seconds: capped_uptime,
      activity_score: compute_score(activity, failures, recoveries, capped_uptime, window_secs, ets_size)
    }
  end

  defp compute_score(activity, failures, recoveries, uptime_secs, window_secs, ets_size) do
    if window_secs <= 0 do
      0.0
    else
      total =
        Map.get(activity, :discoveries, 0) +
          Map.get(activity, :experiments, 0) +
          Map.get(activity, :adaptations, 0) +
          Map.get(activity, :self_improvements, 0)

      productivity = min(1.0, total / 100)
      reliability = if failures + recoveries > 0, do: recoveries / (failures + recoveries), else: 1.0
      uptime_ratio = min(1.0, uptime_secs / window_secs)
      knowledge = min(1.0, ets_size / 10_000)

      raw = productivity * 0.35 + reliability * 0.25 + uptime_ratio * 0.25 + knowledge * 0.15
      Float.round(min(1.0, max(0.0, raw)), 4)
    end
  end

  defp collect_activity_counts do
    participation_result = collect_from_participation()
    handler_result = collect_from_handlers()

    %{
      discoveries: max(participation_result.discoveries, handler_result.discoveries),
      experiments: max(participation_result.experiments, handler_result.experiments),
      adaptations: max(participation_result.adaptations, handler_result.adaptations),
      self_improvements: max(participation_result.self_improvements, handler_result.self_improvements)
    }
  end

  defp collect_from_participation do
    try do
      if Code.ensure_loaded?(ParticipationGraph) do
        case ParticipationGraph.participation() do
          {:ok, entries} when is_list(entries) and entries != [] ->
            %{
              discoveries: Enum.sum(Enum.map(entries, & &1.discoveries_contributed)),
              experiments: Enum.sum(Enum.map(entries, & &1.experiments_executed)),
              adaptations: Enum.sum(Enum.map(entries, & &1.knowledge_produced)),
              self_improvements: Enum.sum(Enum.map(entries, & &1.certification_artifacts))
            }

          _ ->
            empty_counts()
        end
      else
        empty_counts()
      end
    rescue
      _ -> empty_counts()
    catch
      _, _ -> empty_counts()
    end
  end

  defp collect_from_handlers do
    try do
      handlers = :telemetry.list_handlers([])

      %{
        discoveries: count_matching(handlers, [:tiannara, :discovery]),
        experiments: count_matching(handlers, [:tiannara, :experiment]),
        adaptations: count_matching(handlers, [:tiannara, :adaptation]),
        self_improvements:
          count_matching(handlers, [:tiannara, :self_improvement]) +
            count_matching(handlers, [:tiannara, :improvement])
      }
    rescue
      _ -> empty_counts()
    catch
      _, _ -> empty_counts()
    end
  end

  defp count_matching(handlers, prefix) do
    prefix_len = length(prefix)

    Enum.count(handlers, fn handler ->
      event = Map.get(handler, :event_name, [])
      is_list(event) && Enum.take(event, prefix_len) == prefix
    end)
  end

  defp empty_counts do
    %{discoveries: 0, experiments: 0, adaptations: 0, self_improvements: 0}
  end

  defp collect_health_data do
    try do
      if Code.ensure_loaded?(SubsystemRegistry) and Process.whereis(SubsystemRegistry) do
        records = SubsystemRegistry.all()
        failures = Enum.count(records, fn r -> r.health == :failed end)
        recoveries = Enum.count(records, fn r -> r.health == :healthy and r.status in [:healthy, :booted] end)
        %{failures: failures, recoveries: recoveries}
      else
        %{failures: 0, recoveries: 0}
      end
    rescue
      _ -> %{failures: 0, recoveries: 0}
    catch
      _, _ -> %{failures: 0, recoveries: 0}
    end
  end

  defp collect_uptime_seconds do
    try do
      {total_wall, _} = :erlang.statistics(:wall_clock)
      div(total_wall, 1000)
    rescue
      _ -> 0
    catch
      _, _ -> 0
    end
  end

  defp collect_ets_total_size do
    try do
      :ets.all()
      |> Enum.reduce(0, fn tid, acc ->
        try do
          acc + :ets.info(tid, :size)
        rescue
          _ -> acc
        end
      end)
    rescue
      _ -> 0
    catch
      _, _ -> 0
    end
  end

  defp pad_int(val) when is_integer(val), do: val |> to_string() |> String.pad_leading(6)
  defp pad_int(val), do: to_string(val) |> String.pad_leading(6)
end
