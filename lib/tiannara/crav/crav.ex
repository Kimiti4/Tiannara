defmodule Tiannara.CRAV do
  @moduledoc """
  Phase Ω+ CRAV — Constitutional Runtime Activation & Verification.

  Main orchestrator that runs all CRAV deliverables and produces
  a comprehensive launch readiness report.
  """

  require Logger

  @telemetry_event [:tiannara, :crav, :complete]

  @scientific_subsystems MapSet.new([
    :core, :physics, :topology, :cosmology, :rea, :rel,
    :cognition, :discovery, :epistemic_mirror, :forecasting,
    :knowledge_graph, :nde, :twp, :ird, :opc, :dfg, :ros,
    :domain_cortex, :meta_cognition, :architecture
  ])

  @engineering_subsystems MapSet.new([
    :telemetry, :stabilization, :sentinel, :omce, :omcs, :oed,
    :asc, :ctl, :euf, :aac, :ecl, :leoc, :msg, :web, :os,
    :civilization_atlas, :runtime, :validation, :audit, :profiling
  ])

  @spec run() :: {:ok, map()} | {:error, term()}
  def run do
    try do
      census_result = safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])
      matrix_result = safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, [])
      dead_code_result = safe_call(Tiannara.CRAV.DeadCodeDetector, :detect, [])
      dep_graph_result = safe_call(Tiannara.CRAV.RuntimeDependencyGraph, :graph, [])
      participation_result = safe_call(Tiannara.CRAV.ParticipationGraph, :participation, [])
      event_bus_result = safe_call(Tiannara.CRAV.EventBusAudit, :audit, [])
      observatory_result = safe_call(Tiannara.CRAV.ObservatoryCoverage, :coverage, [])
      chain_result = safe_call(Tiannara.CRAV.DiscoveryChain, :verify, [])
      comms_result = safe_call(Tiannara.CRAV.CommunicationAudit, :audit, [])
      supervisor_result = safe_call(Tiannara.CRAV.SupervisorIntegrity, :audit, [])
      knowledge_result = safe_call(Tiannara.CRAV.KnowledgeFlow, :flow, [])
      autonomous_result = safe_call(Tiannara.CRAV.AutonomousReport, :report, [])
      compliance_result = safe_call(Tiannara.CRAV.ComplianceAudit, :audit, [])
      heatmap_result = safe_call(Tiannara.CRAV.RuntimeHeatmap, :heatmap, [])
      readiness_result = safe_call(Tiannara.CRAV.LaunchReadiness, :score, [])

      report = build_full_report(
        census_result, matrix_result, dead_code_result,
        dep_graph_result, participation_result, event_bus_result,
        observatory_result, chain_result, comms_result,
        supervisor_result, knowledge_result, autonomous_result,
        compliance_result, heatmap_result, readiness_result
      )

      measurements = %{overall_readiness: report.launch_readiness.overall_alpha_readiness}
      metadata = %{verdict: report.verdict, timestamp: report.timestamp}
      :telemetry.execute(@telemetry_event, measurements, metadata)

      Logger.info("[CRAV] Complete — verdict=#{report.verdict}")

      {:ok, report}
    rescue
      err -> {:error, {:crav_run_failed, err}}
    end
  end

  @spec run(atom()) :: {:ok, map()} | {:error, term()}
  def run(:runtime_census) do
    case safe_call(Tiannara.CRAV.RuntimeCensus, :census, []) do
      {:ok, entries} ->
        {:ok, summarize_census(entries)}
      err ->
        err
    end
  end

  def run(:activation_matrix) do
    case safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, []) do
      {:ok, matrix} -> {:ok, matrix}
      err -> err
    end
  end

  def run(:dead_code) do
    case safe_call(Tiannara.CRAV.DeadCodeDetector, :detect, []) do
      {:ok, result} -> {:ok, result}
      err -> err
    end
  end

  def run(:launch_readiness), do: safe_call(Tiannara.CRAV.LaunchReadiness, :score, [])
  def run(:dependency_graph), do: safe_call(Tiannara.CRAV.RuntimeDependencyGraph, :graph, [])
  def run(:participation), do: safe_call(Tiannara.CRAV.ParticipationGraph, :participation, [])
  def run(:event_bus), do: safe_call(Tiannara.CRAV.EventBusAudit, :audit, [])
  def run(:observatory_coverage), do: safe_call(Tiannara.CRAV.ObservatoryCoverage, :coverage, [])
  def run(:discovery_chain), do: safe_call(Tiannara.CRAV.DiscoveryChain, :verify, [])
  def run(:communication), do: safe_call(Tiannara.CRAV.CommunicationAudit, :audit, [])
  def run(:supervisor_integrity), do: safe_call(Tiannara.CRAV.SupervisorIntegrity, :audit, [])
  def run(:knowledge_flow), do: safe_call(Tiannara.CRAV.KnowledgeFlow, :flow, [])
  def run(:autonomous), do: safe_call(Tiannara.CRAV.AutonomousReport, :report, [])
  def run(:compliance), do: safe_call(Tiannara.CRAV.ComplianceAudit, :audit, [])
  def run(:heatmap), do: safe_call(Tiannara.CRAV.RuntimeHeatmap, :heatmap, [])
  def run(unknown), do: {:error, {:unknown_deliverable, unknown}}

  @spec report() :: {:ok, String.t()} | {:error, term()}
  def report do
    case run() do
      {:ok, r} ->
        formatted = format_report(r)
        {:ok, formatted}

      {:error, _} = err ->
        err
    end
  end

  @spec launch_readiness() :: {:ok, map()} | {:error, term()}
  def launch_readiness do
    case safe_call(Tiannara.CRAV.LaunchReadiness, :score, []) do
      {:ok, result} -> {:ok, result}
      _ ->
        census_entries = case safe_call(Tiannara.CRAV.RuntimeCensus, :census, []) do
          {:ok, entries} -> entries
          _ -> []
        end
        matrix_data = case safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, []) do
          {:ok, %{active: a, dormant: d, score: s}} ->
            %{active: a, dormant: d, score: normalize_score(s)}
          _ -> derive_activation_from_census(census_entries)
        end
        {:ok, derive_launch_readiness_internal(census_entries, matrix_data)}
    end
  end

  @spec run_omega_21() :: :pass | :warn | :fail
  def run_omega_21 do
    case run() do
      {:ok, %{verdict: :ready}} -> :pass
      {:ok, %{verdict: :conditional}} -> :warn
      {:ok, %{verdict: :blocked}} -> :fail
      {:error, _} -> :fail
    end
  end

  defp build_full_report(
    census_result, matrix_result, dead_code_result,
    _dep_graph_result, _participation_result, _event_bus_result,
    _observatory_result, chain_result, _comms_result,
    _supervisor_result, _knowledge_result, _autonomous_result,
    _compliance_result, _heatmap_result, readiness_result
  ) do
    census_entries = case census_result do
      {:ok, entries} when is_list(entries) -> entries
      _ -> []
    end

    census_summary = summarize_census(census_entries)

    matrix_data = case matrix_result do
      {:ok, %{active: a, dormant: d, score: s}} ->
        %{active: a, dormant: d, score: normalize_score(s)}
      _ ->
        derive_activation_from_census(census_entries)
    end

    dead_code_data = case dead_code_result do
      {:ok, %{dormant_modules: dm, planned_modules: pm}} ->
        total = length(census_entries)
        dormancy_pct = if total > 0, do: length(dm) / total * 100, else: 0.0
        %{dormant_modules: dm, planned_modules: pm, dormancy_percentage: Float.round(dormancy_pct, 1)}
      _ ->
        dormant_mods = census_entries
        |> Enum.filter(&(&1.status == :dormant))
        |> Enum.map(& &1.module)
        |> Enum.reject(&is_nil/1)

        total = length(census_entries)
        dormancy_pct = if total > 0, do: length(dormant_mods) / total * 100, else: 0.0

        %{dormant_modules: dormant_mods, planned_modules: [], dormancy_percentage: Float.round(dormancy_pct, 1)}
    end

    chain_data = case chain_result do
      {:ok, stages} when is_list(stages) ->
        reachable = Enum.count(stages, & &1.reachable)
        total = length(stages)
        %{reachable: reachable, total: total, complete: reachable == total}
      _ ->
        %{reachable: 0, total: 12, complete: false}
    end

    readiness = case readiness_result do
      {:ok, r} when is_map(r) ->
        %{
          runtime_readiness: Map.get(r, :runtime_readiness, 0.0),
          observatory_readiness: Map.get(r, :observatory_readiness, 0.0),
          discovery_readiness: Map.get(r, :discovery_readiness, 0.0),
          scientific_readiness: Map.get(r, :scientific_readiness, 0.0),
          engineering_readiness: Map.get(r, :engineering_readiness, 0.0),
          planetary_readiness: Map.get(r, :planetary_readiness, 0.0),
          civilization_readiness: Map.get(r, :civilization_readiness, 0.0),
          overall_alpha_readiness: Map.get(r, :overall_alpha_readiness, 0.0),
          recommendation: Map.get(r, :recommendation, :blocked)
        }
      _ ->
        derive_launch_readiness_internal(census_entries, matrix_data)
    end

    %{
      timestamp: DateTime.utc_now(),
      runtime_census: census_summary,
      activation_matrix: matrix_data,
      dead_code: dead_code_data,
      discovery_chain: chain_data,
      launch_readiness: readiness,
      verdict: readiness.recommendation
    }
  end

  defp summarize_census(entries) do
    total = length(entries)
    alive = Enum.count(entries, &(&1.status == :alive))
    dormant = total - alive

    %{total: total, alive: alive, dormant: dormant}
  end

  defp derive_activation_from_census(entries) do
    active = entries
    |> Enum.filter(&(&1.status == :alive))
    |> Enum.map(& &1.name)

    dormant = entries
    |> Enum.filter(&(&1.status != :alive))
    |> Enum.map(& &1.name)

    total = length(entries)
    score = if total > 0, do: length(active) / total, else: 0.0

    %{active: active, dormant: dormant, score: Float.round(score, 4)}
  end

  defp derive_launch_readiness_internal(census_entries, matrix_data) do
    matrix_score = matrix_data.score

    alive_names = census_entries
    |> Enum.filter(&(&1.status == :alive))
    |> Enum.map(& &1.name)
    |> MapSet.new()

    census_names = census_entries
    |> Enum.map(& &1.name)
    |> MapSet.new()

    runtime_readiness = matrix_score * 100
    scientific_readiness = category_readiness(alive_names, census_names, @scientific_subsystems)
    engineering_readiness = category_readiness(alive_names, census_names, @engineering_subsystems)

    overall = weighted_average(runtime_readiness, scientific_readiness, engineering_readiness)

    recommendation = cond do
      overall >= 90.0 -> :ready
      overall < 50.0 -> :blocked
      true -> :conditional
    end

    %{
      runtime_readiness: Float.round(runtime_readiness, 1),
      observatory_readiness: 0.0,
      discovery_readiness: 0.0,
      scientific_readiness: Float.round(scientific_readiness, 1),
      engineering_readiness: Float.round(engineering_readiness, 1),
      planetary_readiness: 0.0,
      civilization_readiness: 0.0,
      overall_alpha_readiness: Float.round(overall, 1),
      recommendation: recommendation
    }
  end

  defp category_readiness(alive_names, census_names, category_set) do
    relevant = census_names |> MapSet.intersection(category_set)
    total = MapSet.size(relevant)

    if total == 0 do
      0.0
    else
      alive_in_category = relevant |> MapSet.intersection(alive_names) |> MapSet.size()
      alive_in_category / total * 100
    end
  end

  defp weighted_average(runtime, scientific, engineering) do
    runtime * 0.40 + scientific * 0.30 + engineering * 0.30
  end

  defp normalize_score(s) when is_float(s) and s <= 1.0, do: Float.round(s, 4)
  defp normalize_score(s) when is_float(s), do: Float.round(s / 100, 4)
  defp normalize_score(s) when is_integer(s) and s <= 1, do: s / 1
  defp normalize_score(s) when is_integer(s), do: s / 100

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

  defp format_report(r) do
    census = r.runtime_census
    matrix = r.activation_matrix
    dead = r.dead_code
    chain = r.discovery_chain
    readiness = r.launch_readiness

    active_names = matrix.active
    |> Enum.take(8)
    |> Enum.map(&format_name/1)
    |> Enum.join(", ")

    dormant_names = matrix.dormant
    |> Enum.take(5)
    |> Enum.map(&format_name/1)
    |> Enum.join(", ")

    score_pct = Float.round(matrix.score * 100, 1)
    verdict_str = r.verdict |> Atom.to_string() |> String.upcase()

    [
      "═══════════════════════════════════════════════════",
      "  TIANNARA CONSTITUTIONAL RUNTIME ACTIVATION",
      "  Phase Ω+ CRAV Report",
      "═══════════════════════════════════════════════════",
      "",
      "Runtime Census",
      "  Total Subsystems ....... #{census.total}",
      "  Alive .................. #{census.alive}",
      "  Dormant ................ #{census.dormant}",
      "",
      "Activation Matrix",
      "  Score .................. #{score_pct}%",
      "  Active: #{active_names}",
      "  Dormant: #{dormant_names}",
      "",
      "Dead Code Detection",
      "  Dormant Modules ........ #{length(dead.dormant_modules)}",
      "  Planned (Stubs) ........ #{length(dead.planned_modules)}",
      "  Dormancy ............... #{dead.dormancy_percentage}%",
      "",
      "Discovery Chain",
      "  Reachable .............. #{chain.reachable}/#{chain.total}",
      "  Complete ............... #{chain.complete}",
      "",
      "Launch Readiness",
      "  Runtime ................ #{readiness.runtime_readiness}%",
      "  Observatory ............ #{readiness.observatory_readiness}%",
      "  Discovery .............. #{readiness.discovery_readiness}%",
      "  Scientific ............. #{readiness.scientific_readiness}%",
      "  Engineering ............ #{readiness.engineering_readiness}%",
      "  Planetary .............. #{readiness.planetary_readiness}%",
      "  Civilization ........... #{readiness.civilization_readiness}%",
      "  Overall Alpha .......... #{readiness.overall_alpha_readiness}%",
      "",
      "Verdict: #{verdict_str}",
      "═══════════════════════════════════════════════════"
    ]
    |> Enum.join("\n")
  end

  @doc """
  Runs a specific CRAV validation suite by name.
  Used by the Sentinel Activation Layer to trigger targeted validation.
  """
  @spec run_suite(atom()) :: :ok
  def run_suite(:full_constitutional) do
    Logger.info("[CRAV] Running full constitutional validation suite")
    # Run constitutional challenge suites
    safe_call(Tiannara.CRAV.ComplianceAudit, :audit, [])
    safe_call(Tiannara.CRAV.CommunicationAudit, :audit, [])
    safe_call(Tiannara.CRAV.DeadCodeDetector, :detect, [])
    :ok
  end

  def run_suite(:governance_validation) do
    Logger.info("[CRAV] Running governance validation suite")
    safe_call(Tiannara.CRAV.ComplianceAudit, :audit, [])
    :ok
  end

  def run_suite(:discovery_certification) do
    Logger.info("[CRAV] Running discovery certification suite")
    safe_call(Tiannara.CRAV.DiscoveryChain, :verify, [])
    safe_call(Tiannara.CRAV.KnowledgeFlow, :flow, [])
    :ok
  end

  def run_suite(:evolution_robustness) do
    Logger.info("[CRAV] Running evolution robustness tests")
    safe_call(Tiannara.CRAV.RuntimeCensus, :census, [])
    safe_call(Tiannara.CRAV.ActivationMatrix, :matrix, [])
    :ok
  end

  def run_suite(:critical_incident_review) do
    Logger.info("[CRAV] Running critical incident review")
    run()
  end

  def run_suite(name) do
    Logger.warning("[CRAV] Unknown suite requested: #{inspect(name)}")
    :ok
  end

  defp format_name(name) when is_atom(name) do
    name |> Atom.to_string() |> String.upcase()
  end
  defp format_name(name), do: to_string(name) |> String.upcase()
end
