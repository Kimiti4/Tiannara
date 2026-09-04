defmodule Tiannara.CRAV.LaunchReadiness do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 15 — Launch Readiness.

  Computes the final Alpha launch readiness score across
  runtime, observatory, discovery, scientific, engineering,
  planetary, and civilization dimensions.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :launch_readiness, :computed]

  @scientific_subsystems MapSet.new([
    :core, :physics, :topology, :cosmology, :rea, :rel,
    :cognition, :discovery, :epistemic_mirror, :forecasting,
    :knowledge_graph, :nde, :twp, :ird, :opc, :dfg, :ros,
    :domain_cortex, :meta_cognition, :architecture,
    :discovery_pipeline, :simulation_runtime, :theory_ecology
  ])

  @engineering_subsystems MapSet.new([
    :telemetry, :stabilization, :sentinel, :omce, :omcs, :oed,
    :asc, :ctl, :euf, :aac, :ecl, :leoc, :msg, :web, :os,
    :civilization_atlas, :runtime, :validation, :audit, :profiling,
    :engineering_pipeline, :sopl, :hsv, :grcc, :cis
  ])

  @planetary_subsystems MapSet.new([
    :planetary_twin, :world_model, :theory_ecology, :knowledge_graph
  ])

  @civilization_subsystems MapSet.new([
    :civilization_runtime, :simulation_runtime, :knowledge_graph
  ])

  @spec score() :: {:ok, map()} | {:error, term()}
  def score do
    try do
      {activation_entries, alive_names} = fetch_activation_data()
      total_subsystems = length(activation_entries)

      runtime_readiness = compute_runtime_readiness(activation_entries)
      observatory_readiness = compute_observatory_readiness()
      discovery_readiness = compute_discovery_readiness()
      scientific_readiness = compute_category_readiness(alive_names, total_subsystems, @scientific_subsystems)
      engineering_readiness = compute_category_readiness(alive_names, total_subsystems, @engineering_subsystems)
      planetary_readiness = compute_category_readiness(alive_names, total_subsystems, @planetary_subsystems)
      civilization_readiness = compute_category_readiness(alive_names, total_subsystems, @civilization_subsystems)

      overall = compute_overall(
        runtime_readiness, observatory_readiness, discovery_readiness,
        scientific_readiness, engineering_readiness, planetary_readiness,
        civilization_readiness
      )

      blocker_list = detect_blockers(activation_entries, observatory_readiness, discovery_readiness)
      recommendation = compute_recommendation(overall, blocker_list)

      result = %{
        runtime_readiness: Float.round(runtime_readiness, 1),
        observatory_readiness: Float.round(observatory_readiness, 1),
        discovery_readiness: Float.round(discovery_readiness, 1),
        scientific_readiness: Float.round(scientific_readiness, 1),
        engineering_readiness: Float.round(engineering_readiness, 1),
        planetary_readiness: Float.round(planetary_readiness, 1),
        civilization_readiness: Float.round(civilization_readiness, 1),
        overall_alpha_readiness: Float.round(overall, 1),
        recommendation: recommendation,
        blockers: blocker_list
      }

      measurements = %{overall_readiness: result.overall_alpha_readiness}
      metadata = %{
        recommendation: recommendation,
        blocker_count: length(blocker_list),
        timestamp: DateTime.utc_now()
      }

      :telemetry.execute(@telemetry_event, measurements, metadata)

      {:ok, result}
    rescue
      err -> {:error, {:launch_readiness_failed, err}}
    catch
      kind, reason -> {:error, {:launch_readiness_crashed, kind, reason}}
    end
  end

  @spec recommendation() :: {:ok, :ready | :blocked | :conditional} | {:error, term()}
  def recommendation do
    case score() do
      {:ok, result} -> {:ok, result.recommendation}
      err -> err
    end
  end

  @spec blockers() :: {:ok, [binary()]} | {:error, term()}
  def blockers do
    case score() do
      {:ok, result} -> {:ok, result.blockers}
      err -> err
    end
  end

  @spec readiness_report() :: {:ok, String.t()} | {:error, term()}
  def readiness_report do
    case score() do
      {:ok, result} ->
        lines = [
          "═══════════════════════════════════════════════════",
          "  ALPHA LAUNCH READINESS",
          "═══════════════════════════════════════════════════",
          "  Runtime ............... #{format_pct(result.runtime_readiness)}",
          "  Observatory ..........  #{format_pct(result.observatory_readiness)}",
          "  Discovery ............. #{format_pct(result.discovery_readiness)}",
          "  Scientific ............ #{format_pct(result.scientific_readiness)}",
          "  Engineering ........... #{format_pct(result.engineering_readiness)}",
          "  Planetary ............. #{format_pct(result.planetary_readiness)}",
          "  Civilization .......... #{format_pct(result.civilization_readiness)}",
          "  Overall ............... #{format_pct(result.overall_alpha_readiness)}",
          "",
          "  Recommendation: #{Atom.to_string(result.recommendation) |> String.upcase()}",
          blocker_line(result.blockers),
          "═══════════════════════════════════════════════════"
        ]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  defp fetch_activation_data do
    if Code.ensure_loaded?(Tiannara.CRAV.ActivationMatrix) do
      case safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, []) do
        {:ok, entries} ->
          alive_names =
            entries
            |> Enum.filter(&(&1.overall == :active))
            |> Enum.map(& &1.name)
            |> MapSet.new()

          {entries, alive_names}

        _ ->
          {[], MapSet.new()}
      end
    else
      {[], MapSet.new()}
    end
  end

  defp compute_runtime_readiness([]), do: 0.0

  defp compute_runtime_readiness(entries) do
    total = length(entries)
    active = Enum.count(entries, &(&1.overall == :active))

    if total > 0 do
      active / total * 100
    else
      0.0
    end
  end

  defp compute_observatory_readiness do
    if Code.ensure_loaded?(Tiannara.CRAV.ObservatoryCoverage) do
      case safe_call(Tiannara.CRAV.ObservatoryCoverage, :overall_coverage, []) do
        {:ok, coverage} when is_float(coverage) ->
          coverage * 100

        {:ok, entries} when is_list(entries) ->
          total = length(entries)

          if total > 0 do
            covered =
              Enum.count(entries, fn e -> Map.get(e, :coverage_score, 0) > 0 end)

            covered / total * 100
          else
            0.0
          end

        _ ->
          0.0
      end
    else
      0.0
    end
  end

  defp compute_discovery_readiness do
    if Code.ensure_loaded?(Tiannara.CRAV.DiscoveryChain) do
      case safe_call(Tiannara.CRAV.DiscoveryChain, :verify, []) do
        {:ok, results} when is_list(results) ->
          total = length(results)
          reachable = Enum.count(results, & &1.reachable)

          if total > 0 do
            reachable / total * 100
          else
            0.0
          end

        _ ->
          0.0
      end
    else
      0.0
    end
  end

  defp compute_category_readiness(alive_names, _total_subsystems, category_set) do
    total_in_category = MapSet.size(category_set)

    if total_in_category == 0 do
      0.0
    else
      alive_in_category =
        category_set
        |> MapSet.intersection(alive_names)
        |> MapSet.size()

      alive_in_category / total_in_category * 100
    end
  end

  defp compute_overall(
         runtime, observatory, discovery,
         scientific, engineering, planetary, civilization
       ) do
    sum =
      runtime * 2 +
        observatory +
        discovery +
        scientific +
        engineering +
        planetary +
        civilization

    sum / 8
  end

  defp detect_blockers(activation_entries, observatory_readiness, discovery_readiness) do
    blockers = []

    blockers =
      if has_critical_supervisor?(activation_entries) do
        blockers ++ ["Critical supervisor failure"]
      else
        blockers
      end

    blockers =
      if discovery_readiness < 100.0 do
        blockers ++ ["Discovery chain incomplete"]
      else
        blockers
      end

    blockers =
      if observatory_readiness < 50.0 do
        blockers ++ ["Observatory coverage below 50%"]
      else
        blockers
      end

    blockers =
      if dormancy_above_50?(activation_entries) do
        blockers ++ ["Dormancy exceeds 50%"]
      else
        blockers
      end

    blockers
  end

  defp has_critical_supervisor?([]), do: true

  defp has_critical_supervisor?(entries) do
    Enum.any?(entries, fn entry ->
      entry.overall == :failed
    end)
  end

  defp dormancy_above_50?([]), do: true

  defp dormancy_above_50?(entries) do
    total = length(entries)
    dormant = Enum.count(entries, &(&1.overall == :dormant))

    total > 0 and dormant / total > 0.5
  end

  defp compute_recommendation(overall, blockers) do
    has_critical =
      Enum.any?(blockers, fn b ->
        b == "Critical supervisor failure"
      end)

    cond do
      overall >= 90.0 and not has_critical -> :ready
      overall < 50.0 or has_critical -> :blocked
      true -> :conditional
    end
  end

  defp format_pct(value) do
    formatted = Float.round(value, 1)

    str =
      if formatted == trunc(formatted) do
        "#{trunc(formatted)}.0%"
      else
        "#{formatted}%"
      end

    String.pad_leading(str, 7)
  end

  defp blocker_line([]), do: "  Blockers: None"
  defp blocker_line(blockers), do: "  Blockers: #{Enum.join(blockers, ", ")}"

  defp safe_call(mod, fun, args) do
    if Code.ensure_loaded?(mod) do
      try do
        apply(mod, fun, args)
      rescue
        err -> {:error, {:module_call_failed, mod, fun, err}}
      catch
        kind, reason -> {:error, {:module_threw, mod, fun, kind, reason}}
      end
    else
      {:error, {:module_not_loaded, mod}}
    end
  end
end
