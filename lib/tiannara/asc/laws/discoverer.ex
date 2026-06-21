defmodule Tiannara.ASC.Laws.Discoverer do
  @moduledoc """
  Extracts software engineering laws from the Observatory corpus.

  Runs periodically, scans all `Observatory.Metrics` snapshots, and looks
  for statistically robust patterns. When a pattern is first observed in
  3+ projects it becomes a `:candidate_law` in `Laws.Registry`. Evidence
  from subsequent projects promotes or demotes confidence through the
  4-tier system: candidate_pattern → candidate_law → established_law → canonical_principle.

  ## Discovery Heuristics (Phase H.5)

  Currently uses threshold-based rules. Phase I will replace these with
  more sophisticated statistical tests as the project corpus grows.

  ### Architecture Style Laws
  - Compare `architecture_fitness` across projects grouped by `architecture_style`
  - Compare `crucible_iterations` across styles

  ### Test Strategy Laws
  - Correlate `test_effectiveness` with `bug_discovery_rate`

  ### API Evolution Laws  ← NEW
  - Correlate `api_fitness` with `long_term_stability`

  ### Repair Laws  ← NEW
  - Correlate `repair_success_rate` with `architecture_style`
  """

  require Logger

  alias Tiannara.ASC.Observatory.ProjectObservatory
  alias Tiannara.ASC.Laws.{Registry, Law}

  @min_projects_for_candidate 3
  @discovery_interval_ms 300_000   # Run every 5 minutes
  @ecology_sentinel_project "asc_transfer_ecology"

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Start the periodic discovery loop as a linked Task."
  def start_link(_opts \\ []) do
    Task.start_link(fn -> loop() end)
  end

  @doc "Run a single discovery pass synchronously. Returns list of new/updated laws."
  @spec run() :: [Law.t()]
  def run do
    snapshots = ProjectObservatory.all_snapshots()

    if length(snapshots) < @min_projects_for_candidate do
      Logger.debug("[ASC.Laws.Discoverer] Insufficient projects (#{length(snapshots)}) for law discovery")
      discover_transfer_ecology_laws()
      []
    else
      laws =
        []
        |> Enum.concat(discover_bootstrap_laws(snapshots))  # ← NEW: Tier 0 foundational correlations
        |> Enum.concat(discover_architecture_fitness_laws(snapshots))
        |> Enum.concat(discover_crucible_iteration_laws(snapshots))
        |> Enum.concat(discover_test_effectiveness_laws(snapshots))
        |> Enum.concat(discover_api_evolution_laws(snapshots))
        |> Enum.concat(discover_repair_laws(snapshots))

      if length(laws) > 0 do
        Logger.info("[ASC.Laws.Discoverer] Discovery pass found #{length(laws)} new/updated laws")
        emit_promotion_events(laws)
      end

      # Phase 5E: Transfer Ecology Law Extraction
      discover_transfer_ecology_laws()

      laws
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 5E: Transfer Ecology Law Extraction
  # ---------------------------------------------------------------------------

  @doc """
  Extracts empirical transfer principles from the TransferEcology
  and mints them as canonical laws in the Registry.
  """
  def discover_transfer_ecology_laws do
    Logger.info("🌍 [Laws.Discoverer] Mining Transfer Ecology Matrix for fundamental laws...")

    candidates = Tiannara.ASC.Crucible.TransferEcology.generate_law_candidates()

    if Enum.empty?(candidates) do
      Logger.info("🌍 [Laws.Discoverer] No statistically significant transfer laws discovered yet.")
    else
      Logger.info("🌍 [Laws.Discoverer] Found #{length(candidates)} candidate laws. Minting to Registry...")

      Enum.each(candidates, fn candidate ->
        metadata = %{
          evidence: candidate.evidence,
          confidence: candidate.confidence,
          support_count: candidate.support_count,
          contradiction_count: Map.get(candidate, :contradiction_count, 0),
          tags: candidate.tags ++ [:ecology_derived],
          scope: :global,
          architecture_styles: [:cache, :web_app, :replica],
          discovered_at: System.system_time(:millisecond)
        }

        if falsification_check(metadata) do
          # Upsert into the global registry using the ecology sentinel
          Registry.upsert_law(
            @ecology_sentinel_project,
            candidate.law,
            metadata
          )

          Logger.info("  📜 MINTED: \"#{candidate.law}\" (Confidence: #{candidate.confidence}, Support: #{candidate.support_count})")
        else
          Logger.info("  🛡️ REJECTED BY FALSIFICATION CHECK: \"#{candidate.law}\" (Confidence: #{candidate.confidence}, Support: #{candidate.support_count})")
        end
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # Private discovery heuristics
  # ---------------------------------------------------------------------------

  defp falsification_check(%{support_count: support, contradiction_count: contradictions, confidence: conf}) do
    if support < 30 do
      false
    else
      total = support + contradictions
      success_rate = if total > 0, do: support / total, else: 0.0

      cond do
        success_rate < 0.5 -> false # More contradictions than support
        conf < 0.15 -> false # Signal too weak
        true -> true
      end
    end
  end

  defp loop do
    Process.sleep(@discovery_interval_ms)
    run()
    loop()
  end

  defp discover_architecture_fitness_laws(snapshots) do
    # Group by architecture style, compare composite fitness
    by_style = Enum.group_by(snapshots, &(&1.architecture_style))

    Enum.flat_map(by_style, fn {style, style_snapshots} ->
      if is_nil(style) or length(style_snapshots) < @min_projects_for_candidate do
        []
      else
        avg_fitness = avg(Enum.map(style_snapshots, &(&1.architecture_fitness)))
        avg_stability = avg(Enum.map(style_snapshots, &(&1.long_term_stability)))

        statement = "#{style} architectures achieve avg_fitness=#{Float.round(avg_fitness, 3)} and avg_stability=#{Float.round(avg_stability, 3)} across #{length(style_snapshots)} projects"

        upsert_law(statement, %{architecture_style: style, avg_fitness: avg_fitness},
          Enum.map(style_snapshots, &(&1.project_id)))
      end
    end)
  end

  defp discover_crucible_iteration_laws(snapshots) do
    by_style = Enum.group_by(snapshots, &(&1.architecture_style))

    Enum.flat_map(by_style, fn {style, style_snapshots} ->
      if is_nil(style) or length(style_snapshots) < @min_projects_for_candidate do
        []
      else
        avg_iters = avg(Enum.map(style_snapshots, &(&1.crucible_iterations)))
        statement = "#{style} architectures require avg #{Float.round(avg_iters, 1)} crucible iterations to achieve robustness"

        upsert_law(statement, %{architecture_style: style, avg_crucible_iterations: avg_iters},
          Enum.map(style_snapshots, &(&1.project_id)))
      end
    end)
  end

  defp discover_test_effectiveness_laws(snapshots) do
    high_effectiveness = Enum.filter(snapshots, &(&1.test_effectiveness > 0.7))

    if length(high_effectiveness) < @min_projects_for_candidate do
      []
    else
      avg_bug_rate = avg(Enum.map(high_effectiveness, &(&1.bug_discovery_rate)))
      statement = "Projects with test_effectiveness > 0.7 achieve avg bug_discovery_rate=#{Float.round(avg_bug_rate, 3)}"

      upsert_law(statement, %{test_effectiveness_threshold: 0.7, avg_bug_discovery_rate: avg_bug_rate},
        Enum.map(high_effectiveness, &(&1.project_id)))
    end
    |> List.wrap()
  end

  defp upsert_law(statement, variables, project_ids) do
    # Check if a law with this statement already exists
    existing = Registry.all() |> Enum.find(&(&1.statement == statement))

    law = if existing do
      Enum.reduce(project_ids, existing, fn pid, l ->
        if pid in l.supporting_project_ids, do: l,
          else: Law.update_confidence(l, :confirms, pid)
      end)
    else
      base = Law.new(statement, variables)
      Enum.reduce(project_ids, base, fn pid, l ->
        Law.update_confidence(l, :confirms, pid)
      end)
    end

    {:ok, stored} = Registry.store(law)
    stored
  end

  defp avg([]), do: 0.0
  defp avg(values), do: Enum.sum(values) / length(values)

  # ---------------------------------------------------------------------------
  # NEW: API Evolution Laws
  # ---------------------------------------------------------------------------

  defp discover_api_evolution_laws(snapshots) do
    # Correlate api_fitness with long_term_stability
    # High api_fitness projects tend to have higher long_term_stability
    qualified = Enum.filter(snapshots, fn s ->
      is_number(s.api_fitness) and is_number(Map.get(s, :long_term_stability, nil))
    end)

    if length(qualified) < @min_projects_for_candidate do
      []
    else
      {high_api, low_api} = Enum.split_with(qualified, fn s -> s.api_fitness >= 0.7 end)

      if length(high_api) >= @min_projects_for_candidate do
        avg_stability_high = avg(Enum.map(high_api, & &1.long_term_stability))
        avg_stability_low  = if length(low_api) > 0,
          do: avg(Enum.map(low_api, & &1.long_term_stability)), else: 0.0

        if avg_stability_high > avg_stability_low * 1.15 do
          # At least 15% improvement — worth recording
          statement = "Projects with api_fitness >= 0.7 achieve avg long_term_stability=#{Float.round(avg_stability_high, 3)} vs #{Float.round(avg_stability_low, 3)} for lower api_fitness (#{length(high_api)} vs #{length(low_api)} projects)"
          [upsert_law(statement, %{api_fitness_threshold: 0.7, avg_stability_high: avg_stability_high, avg_stability_low: avg_stability_low},
            Enum.map(high_api, & &1.project_id))]
        else
          []
        end
      else
        []
      end
    end
  end

  # ---------------------------------------------------------------------------
  # NEW: Repair Laws
  # ---------------------------------------------------------------------------

  defp discover_repair_laws(snapshots) do
    # Correlate repair_success_rate with architecture_style
    by_style = snapshots
      |> Enum.filter(fn s -> is_number(Map.get(s, :repair_success_rate, nil)) end)
      |> Enum.group_by(& &1.architecture_style)

    Enum.flat_map(by_style, fn {style, style_snapshots} ->
      if is_nil(style) or length(style_snapshots) < @min_projects_for_candidate do
        []
      else
        avg_repair = avg(Enum.map(style_snapshots, & &1.repair_success_rate))
        statement = "#{style} architectures achieve avg repair_success_rate=#{Float.round(avg_repair, 3)} across #{length(style_snapshots)} projects"

        [upsert_law(statement,
          %{architecture_style: style, avg_repair_success_rate: avg_repair},
          Enum.map(style_snapshots, & &1.project_id))]
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Tier 0 — Bootstrap Law Discovery (Foundational Correlations)
  # Uses metrics available from Requirements/Testing/Implementation phases
  # ---------------------------------------------------------------------------

  defp discover_bootstrap_laws(snapshots) do
    []
    |> Enum.concat(discover_capability_clarity_law(snapshots))
    |> Enum.concat(discover_invariant_density_law(snapshots))
    |> Enum.concat(discover_specification_completeness_law(snapshots))
  end

  # Law 1: Capability Clarity predicts Specification Completeness
  defp discover_capability_clarity_law(snapshots) do
    # Group projects by capability_count ranges
    high_caps = Enum.filter(snapshots, &(&1.capability_count >= 3))
    low_caps = Enum.filter(snapshots, &(&1.capability_count < 3))

    if length(high_caps) >= @min_projects_for_candidate and length(low_caps) >= @min_projects_for_candidate do
      avg_completeness_high = avg(Enum.map(high_caps, &(&1.requirements_completeness)))
      avg_completeness_low = avg(Enum.map(low_caps, &(&1.requirements_completeness)))

      # If high-capability projects have significantly higher completeness
      if avg_completeness_high > avg_completeness_low * 1.3 do
        statement = "Capability Clarity predicts Specification Completeness (high-cap=#{Float.round(avg_completeness_high, 2)} vs low-cap=#{Float.round(avg_completeness_low, 2)})"

        [upsert_law(statement,
          %{metric_correlation: "capability_count → requirements_completeness",
            high_avg: avg_completeness_high, low_avg: avg_completeness_low},
          Enum.map(high_caps ++ low_caps, & &1.project_id))]
      else
        []
      end
    else
      []
    end
  end

  # Law 2: Invariant Density predicts Verification Depth
  defp discover_invariant_density_law(snapshots) do
    high_inv = Enum.filter(snapshots, &(&1.invariant_count >= 2))
    low_inv = Enum.filter(snapshots, &(&1.invariant_count < 2))

    if length(high_inv) >= @min_projects_for_candidate and length(low_inv) >= @min_projects_for_candidate do
      avg_tests_high = avg(Enum.map(high_inv, &(&1.test_contract_count)))
      avg_tests_low = avg(Enum.map(low_inv, &(&1.test_contract_count)))

      # If high-invariant projects generate significantly more tests
      if avg_tests_high > avg_tests_low * 1.5 do
        statement = "Invariant Density predicts Verification Depth (high-inv=#{Float.round(avg_tests_high, 1)} tests vs low-inv=#{Float.round(avg_tests_low, 1)} tests)"

        [upsert_law(statement,
          %{metric_correlation: "invariant_count → test_contract_count",
            high_avg: avg_tests_high, low_avg: avg_tests_low},
          Enum.map(high_inv ++ low_inv, & &1.project_id))]
      else
        []
      end
    else
      []
    end
  end

  # Law 3: Specification Completeness predicts Implementation Richness
  defp discover_specification_completeness_law(snapshots) do
    high_spec = Enum.filter(snapshots, &(&1.requirements_completeness >= 0.5))
    low_spec = Enum.filter(snapshots, &(&1.requirements_completeness < 0.5))

    if length(high_spec) >= @min_projects_for_candidate and length(low_spec) >= @min_projects_for_candidate do
      avg_files_high = avg(Enum.map(high_spec, &(&1.source_file_count)))
      avg_files_low = avg(Enum.map(low_spec, &(&1.source_file_count)))

      # If high-spec projects generate more source files
      if avg_files_high > avg_files_low * 1.4 do
        statement = "Specification Completeness predicts Implementation Richness (high-spec=#{Float.round(avg_files_high, 1)} files vs low-spec=#{Float.round(avg_files_low, 1)} files)"

        [upsert_law(statement,
          %{metric_correlation: "requirements_completeness → source_file_count",
            high_avg: avg_files_high, low_avg: avg_files_low},
          Enum.map(high_spec ++ low_spec, & &1.project_id))]
      else
        []
      end
    else
      []
    end
  end

  # ---------------------------------------------------------------------------
  # Promotion event emission
  # ---------------------------------------------------------------------------

  defp emit_promotion_events(laws) do
    Enum.each(laws, fn law ->
      if law.status in [:established_law, :canonical_principle] do
        Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:law:promoted", %{
          law_id:    law.id,
          status:    law.status,
          statement: law.statement,
          confidence: law.confidence,
          promoted_at: law.promoted_at
        })
      end
    end)
  end
end
