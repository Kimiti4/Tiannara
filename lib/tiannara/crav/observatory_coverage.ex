defmodule Tiannara.CRAV.ObservatoryCoverage do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 7 — Observatory Coverage.

  Checks what percentage of subsystems are visible in the Observatory
  across runtime status, metrics, replay, historical timeline,
  live dashboard, alerts, certification, and evolution dimensions.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :observatory, :coverage]

  @dimensions [
    :runtime_status,
    :metrics,
    :replay,
    :historical_timeline,
    :live_dashboard,
    :alerts,
    :certification,
    :evolution
  ]

  @subsystems [
    :rea, :sopl, :cis, :msg, :omce, :hsv, :grcc, :oed, :ctl,
    :a10, :asc, :world_model, :sentinel, :planetary_twin,
    :discovery_pipeline, :engineering_pipeline, :simulation_runtime,
    :theory_ecology, :knowledge_graph, :civilization_runtime
  ]

  @subsystem_modules %{
    rea: [Tiannara.REA, Tiannara.REA.Supervisor],
    sopl: [Tiannara.SOPL, Tiannara.SOPL.Supervisor],
    cis: [Tiannara.CIS, Tiannara.CIS.Supervisor],
    msg: [Tiannara.MSG, Tiannara.MSG.Supervisor],
    omce: [Tiannara.OMCE, Tiannara.OMCE.Supervisor],
    hsv: [Tiannara.HSV, Tiannara.HSV.Supervisor],
    grcc: [Tiannara.GRCC, Tiannara.GRCC.Supervisor],
    oed: [Tiannara.OED, Tiannara.OED.Supervisor],
    ctl: [Tiannara.CTL, Tiannara.CTL.Supervisor],
    a10: [Tiannara.A10, Tiannara.A10.Supervisor],
    asc: [Tiannara.ASC, Tiannara.ASC.Supervisor],
    world_model: [Tiannara.WorldModel, Tiannara.WorldModel.Supervisor],
    sentinel: [Tiannara.Sentinel, Tiannara.Sentinel.Supervisor],
    planetary_twin: [Tiannara.PlanetaryTwin, Tiannara.PlanetaryTwin.Supervisor],
    discovery_pipeline: [Tiannara.DiscoveryPipeline, Tiannara.DiscoveryPipeline.Supervisor],
    engineering_pipeline: [Tiannara.EngineeringPipeline, Tiannara.EngineeringPipeline.Supervisor],
    simulation_runtime: [Tiannara.SimulationRuntime, Tiannara.SimulationRuntime.Supervisor],
    theory_ecology: [Tiannara.TheoryEcology, Tiannara.TheoryEcology.Supervisor],
    knowledge_graph: [Tiannara.KnowledgeGraph, Tiannara.KnowledgeGraph.Supervisor],
    civilization_runtime: [Tiannara.CivilizationRuntime, Tiannara.CivilizationRuntime.Supervisor]
  }

  @spec coverage() :: {:ok, [map()]} | {:error, term()}
  def coverage do
    try do
      observatory_mods = discover_observatory_modules()

      entries =
        @subsystems
        |> Enum.map(fn subsystem ->
          mods = Map.get(@subsystem_modules, subsystem, [])

          runtime_status = check_runtime_status(subsystem, mods)
          metrics = check_metrics(subsystem, observatory_mods)
          replay = check_replay(subsystem, observatory_mods)
          historical_timeline = check_historical_timeline(subsystem, observatory_mods)
          live_dashboard = check_live_dashboard(subsystem, observatory_mods)
          alerts = check_alerts(subsystem, observatory_mods)
          certification = check_certification(subsystem, observatory_mods)
          evolution = check_evolution(subsystem, observatory_mods)

          score = compute_score([
            runtime_status, metrics, replay, historical_timeline,
            live_dashboard, alerts, certification, evolution
          ])

          %{
            name: subsystem,
            runtime_status: runtime_status,
            metrics: metrics,
            replay: replay,
            historical_timeline: historical_timeline,
            live_dashboard: live_dashboard,
            alerts: alerts,
            certification: certification,
            evolution: evolution,
            coverage_score: score
          }
        end)

      total_dims = length(entries) * length(@dimensions)
      covered = Enum.sum(Enum.map(entries, fn e ->
        count_true([
          e.runtime_status, e.metrics, e.replay, e.historical_timeline,
          e.live_dashboard, e.alerts, e.certification, e.evolution
        ])
      end))

      overall = if total_dims > 0, do: Float.round(covered / total_dims, 4), else: 0.0

      measurements = %{
        total_subsystems: length(entries),
        overall_coverage: overall,
        covered_dimensions: covered,
        total_dimensions: total_dims
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, entries}
    rescue
      err -> {:error, {:observatory_coverage_failed, err}}
    catch
      kind, reason -> {:error, {:observatory_coverage_crashed, kind, reason}}
    end
  end

  @spec overall_coverage() :: {:ok, float()} | {:error, term()}
  def overall_coverage do
    case coverage() do
      {:ok, entries} ->
        total_dims = length(entries) * length(@dimensions)

        covered =
          Enum.sum(Enum.map(entries, fn e ->
            count_true([
              e.runtime_status, e.metrics, e.replay, e.historical_timeline,
              e.live_dashboard, e.alerts, e.certification, e.evolution
            ])
          end))

        score = if total_dims > 0, do: Float.round(covered / total_dims, 4), else: 0.0
        {:ok, score}

      err ->
        err
    end
  end

  @spec uncovered_subsystems() :: {:ok, [atom()]} | {:error, term()}
  def uncovered_subsystems do
    case coverage() do
      {:ok, entries} ->
        {:ok, entries |> Enum.filter(&(&1.coverage_score == 0.0)) |> Enum.map(& &1.name)}

      err ->
        err
    end
  end

  @spec coverage_report() :: {:ok, String.t()} | {:error, term()}
  def coverage_report do
    case coverage() do
      {:ok, entries} ->
        now = DateTime.utc_now()
        total_dims = length(entries) * length(@dimensions)

        covered =
          Enum.sum(Enum.map(entries, fn e ->
            count_true([
              e.runtime_status, e.metrics, e.replay, e.historical_timeline,
              e.live_dashboard, e.alerts, e.certification, e.evolution
            ])
          end))

        overall_pct = if total_dims > 0, do: Float.round(covered / total_dims * 100, 1), else: 0.0
        target_pct = 100.0
        remaining = Float.round(max(0.0, target_pct - overall_pct), 1)
        fully_covered = Enum.count(entries, &(&1.coverage_score == 1.0))
        partially_covered = Enum.count(entries, fn e -> e.coverage_score > 0.0 and e.coverage_score < 1.0 end)
        uncovered = Enum.count(entries, &(&1.coverage_score == 0.0))

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV OBSERVATORY COVERAGE — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Overall Coverage ....... #{overall_pct}%  (target: #{target_pct}%, remaining: #{remaining}%)",
            "  Fully Covered .......... #{fully_covered}/#{length(entries)}",
            "  Partially Covered ...... #{partially_covered}/#{length(entries)}",
            "  Uncovered .............. #{uncovered}/#{length(entries)}",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(entries, fn e ->
              name_str = e.name |> Atom.to_string() |> String.upcase() |> String.pad_trailing(24)
              pct = Float.round(e.coverage_score * 100, 1)
              dims = dimension_flags(e)

              "  #{name_str} #{String.pad_leading("#{pct}%", 7)}  #{dims}"
            end) ++
            [
              "───────────────────────────────────────────────────────",
              "  Target: 100% — #{remaining}% remaining to full Observatory visibility",
              "═══════════════════════════════════════════════════════"
            ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp discover_observatory_modules do
    case :application.get_key(:tiannara, :modules) do
      {:ok, modules} when is_list(modules) ->
        modules
        |> Enum.filter(fn mod ->
          str = Atom.to_string(mod)
          String.contains?(str, "Observatory")
        end)

      _ ->
        []
    end
  end

  defp check_runtime_status(subsystem, mods) do
    has_process =
      Enum.any?(mods, fn mod ->
        try do
          pid = Process.whereis(mod)
          is_pid(pid) and Process.alive?(pid)
        rescue
          _ -> false
        end
      end)

    registry_check =
      try do
        if Code.ensure_loaded?(Tiannara.PhaseOmega.SubsystemRegistry) do
          case Tiannara.PhaseOmega.SubsystemRegistry.get(subsystem) do
            nil -> false
            record -> record.status == :alive
          end
        else
          false
        end
      rescue
        _ -> false
      catch
        _, _ -> false
      end

    telemetry_check =
      try do
        :telemetry.list_handlers([:tiannara, :subsystem])
        |> Enum.any?(fn h ->
          case Map.get(h, :id) do
            {mod, _} when is_atom(mod) -> Enum.member?(mods, mod)
            mod when is_atom(mod) -> Enum.member?(mods, mod)
            _ -> false
          end
        end)
      rescue
        _ -> false
      end

    has_process or registry_check or telemetry_check
  end

  defp check_metrics(subsystem, observatory_mods) do
    has_metrics_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Metrics") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_telemetry_metrics =
      try do
        :telemetry.list_handlers([:tiannara, subsystem, :metrics])
        |> Enum.any?()
      rescue
        _ -> false
      end

    has_metrics_api =
      Enum.any?(observatory_mods, fn mod ->
        try do
          Code.ensure_loaded?(mod) and function_exported?(mod, :metrics_for, 1)
        rescue
          _ -> false
        end
      end)

    has_metrics_module or has_telemetry_metrics or has_metrics_api
  end

  defp check_replay(subsystem, observatory_mods) do
    has_replay_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Replay") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_artifacts =
      try do
        if Code.ensure_loaded?(Tiannara.Observatory.Replay) do
          function_exported?(Tiannara.Observatory.Replay, :list_artifacts, 1)
        else
          false
        end
      rescue
        _ -> false
      end

    has_replay_module or has_artifacts
  end

  defp check_historical_timeline(subsystem, observatory_mods) do
    has_timeline_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Timeline") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_entries =
      try do
        if Code.ensure_loaded?(Tiannara.Observatory.Timeline) do
          function_exported?(Tiannara.Observatory.Timeline, :entries_for, 1)
        else
          false
        end
      rescue
        _ -> false
      end

    has_timeline_module or has_entries
  end

  defp check_live_dashboard(subsystem, observatory_mods) do
    has_liveview =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Live") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_screen =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Screen") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_liveview or has_screen
  end

  defp check_alerts(subsystem, observatory_mods) do
    has_alert_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Alert") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_rules =
      try do
        if Code.ensure_loaded?(Tiannara.Observatory.Alerts) do
          function_exported?(Tiannara.Observatory.Alerts, :rules_for, 1)
        else
          false
        end
      rescue
        _ -> false
      end

    has_alert_module or has_rules
  end

  defp check_certification(subsystem, observatory_mods) do
    has_cert_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Certification") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_artifacts =
      try do
        if Code.ensure_loaded?(Tiannara.Observatory.Certification) do
          function_exported?(Tiannara.Observatory.Certification, :artifacts_for, 1)
        else
          false
        end
      rescue
        _ -> false
      end

    has_cert_module or has_artifacts
  end

  defp check_evolution(subsystem, observatory_mods) do
    has_evolution_module =
      Enum.any?(observatory_mods, fn mod ->
        str = Atom.to_string(mod)
        String.contains?(str, "Evolution") and String.contains?(str, subsystem_string(subsystem))
      end)

    has_tracking =
      try do
        if Code.ensure_loaded?(Tiannara.Observatory.Evolution) do
          function_exported?(Tiannara.Observatory.Evolution, :tracking_for, 1)
        else
          false
        end
      rescue
        _ -> false
      end

    has_evolution_module or has_tracking
  end

  defp subsystem_string(subsystem) do
    subsystem
    |> Atom.to_string()
    |> String.replace("_", "")
    |> String.downcase()
  end

  defp compute_score(bools) do
    total = length(bools)
    true_count = count_true(bools)

    if total > 0 do
      Float.round(true_count / total, 4)
    else
      0.0
    end
  end

  defp count_true(bools) do
    Enum.count(bools, &(&1 == true))
  end

  defp dimension_flags(entry) do
    @dimensions
    |> Enum.map(fn dim ->
      val = Map.get(entry, dim)
      flag = if val, do: "+", else: "-"
      dim_str = dim |> Atom.to_string() |> String.first() |> String.upcase()
      "#{dim_str}#{flag}"
    end)
    |> Enum.join(" ")
  end
end
