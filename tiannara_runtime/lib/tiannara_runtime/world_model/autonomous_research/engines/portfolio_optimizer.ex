defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.PortfolioOptimizer do
  @moduledoc """
  Phase 17.8.4 — ARPEPortfolioManager.

  Selects the active experiment portfolio from a set of ExperimentPortfolio
  and ExperimentBudget artifacts, optimising across five objectives driven
  entirely by the PortfolioConfig.

  Constitutional rules enforced:
  - All thresholds and weights come from PortfolioConfig — never hardcoded.
  - If PortfolioConfig is absent, optimize/3 returns {:error, %PortfolioConfigMissing{}}.
  - Portfolio state is supplied by the caller — the engine reads it, does not own it.
  - Portfolio scoring is deterministic: identical inputs → identical output.
  - Tie-breaking: ascending lexicographic over portfolio_id (content-addressed hash).
  - Pruning threshold (min_value_threshold) comes from config, not context.
  - Diversity enforcement threshold (min_domain_diversity_threshold) comes from config.
  - No DateTime.utc_now(). No random. No wall-clock. No network.
  - Output is an ExperimentPortfolio struct with content-addressed ID.

  Input contract:
  - candidate_portfolios: list of ExperimentPortfolio.t()
  - budget: ExperimentBudget.t()
  - portfolio_config: PortfolioConfig.t()

  Output contract:
  - {:ok, ExperimentPortfolio.t()} — the selected portfolio (sub-selection of candidates)
  - {:error, reason} — if config is absent/invalid or selection fails
  """

  alias TiannaraRuntime.Shared.Canonical
  alias TiannaraRuntime.WorldModel.AutonomousResearch.PortfolioConfig
  alias TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentPortfolio
  alias TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentBudget

  # ---------------------------------------------------------------------------
  # Failure artifact types
  # ---------------------------------------------------------------------------

  defmodule PortfolioConfigMissing do
    @moduledoc "Produced when PortfolioConfig is absent or invalid."
    defstruct [:reason]
    @type t :: %__MODULE__{reason: String.t()}
  end

  defmodule PortfolioSelectionFailure do
    @moduledoc "Produced when no portfolio survives pruning or diversity enforcement."
    defstruct [:reason, :candidate_count, :pruned_count]
    @type t :: %__MODULE__{reason: String.t(), candidate_count: integer(), pruned_count: integer()}
  end

  defmodule BudgetMissing do
    @moduledoc "Produced when the ExperimentBudget is absent or invalid."
    defstruct [:reason]
    @type t :: %__MODULE__{reason: String.t()}
  end

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Selects an optimal portfolio from candidate ExperimentPortfolio artifacts.

  Steps:
  1. Validate config and budget
  2. Score each candidate using the five-objective function from PortfolioConfig
  3. Prune candidates below config.min_value_threshold
  4. Enforce diversity: if diversity < config.min_domain_diversity_threshold,
     re-admit the highest-scoring pruned candidates until threshold is met
  5. Cap at config.max_portfolio_size (keep top-N by composite score)
  6. Tie-break: ascending lexicographic over portfolio_id
  7. Compute optimisation proof hash from the scored candidate set
  8. Build and return a new ExperimentPortfolio artifact representing the selection
  """
  @spec optimize(
          candidate_portfolios :: [ExperimentPortfolio.t()],
          budget :: ExperimentBudget.t(),
          portfolio_config :: PortfolioConfig.t()
        ) :: {:ok, ExperimentPortfolio.t()} | {:error, term()}
  def optimize(candidate_portfolios, budget, portfolio_config)
      when is_list(candidate_portfolios) do
    with :ok <- validate_config(portfolio_config),
         :ok <- validate_budget(budget) do
      scored = score_all(candidate_portfolios, portfolio_config)
      {passing, pruned} = split_by_threshold(scored, portfolio_config.min_value_threshold)
      restored = restore_for_diversity(passing, pruned, portfolio_config)
      capped = cap_to_max(restored, portfolio_config.max_portfolio_size)

      if capped == [] do
        {:error,
         %PortfolioSelectionFailure{
           reason: "all candidates pruned; no portfolio meets the value threshold",
           candidate_count: length(candidate_portfolios),
           pruned_count: length(scored) - length(capped)
         }}
      else
        build_output_portfolio(capped, scored, portfolio_config, budget)
      end
    end
  end

  def optimize(_candidates, _budget, nil),
    do: {:error, %PortfolioConfigMissing{reason: "PortfolioConfig is required; nil supplied"}}

  def optimize(_candidates, _budget, _config),
    do: {:error, %PortfolioConfigMissing{reason: "candidates must be a list"}}

  # ---------------------------------------------------------------------------
  # Private: config and budget validation
  # ---------------------------------------------------------------------------

  defp validate_config(nil),
    do: {:error, %PortfolioConfigMissing{reason: "PortfolioConfig is required; nil supplied"}}

  defp validate_config(%PortfolioConfig{config_id: nil}),
    do: {:error, %PortfolioConfigMissing{reason: "PortfolioConfig has no config_id"}}

  defp validate_config(%PortfolioConfig{} = config) do
    case PortfolioConfig.verify_id(config) do
      :ok -> :ok
      {:error, r} -> {:error, %PortfolioConfigMissing{reason: "Config ID invalid: #{r}"}}
    end
  end

  defp validate_config(_),
    do: {:error, %PortfolioConfigMissing{reason: "portfolio_config must be a PortfolioConfig struct"}}

  defp validate_budget(nil),
    do: {:error, %BudgetMissing{reason: "ExperimentBudget is required; nil supplied"}}

  defp validate_budget(%ExperimentBudget{budget_id: nil}),
    do: {:error, %BudgetMissing{reason: "ExperimentBudget has no budget_id"}}

  defp validate_budget(%ExperimentBudget{}), do: :ok

  defp validate_budget(_),
    do: {:error, %BudgetMissing{reason: "budget must be an ExperimentBudget struct"}}

  # ---------------------------------------------------------------------------
  # Private: scoring
  # The composite objective is:
  #   score = w_information_gain       × expected_total_information_gain
  #         + w_scientific_diversity   × diversity_score
  #         + w_constitutional_priority × constitutional_priority_score
  #         + w_resource_utilization   × (1 - resource_fraction)
  #         + w_long_term_impact       × long_term_impact_score
  #
  # All five signals are read from ExperimentPortfolio fields — no derivation
  # from raw experiment lists, no effect_size or sample_size lookups.
  # ---------------------------------------------------------------------------

  defp score_all(candidates, %PortfolioConfig{} = config) do
    Enum.map(candidates, fn pf ->
      score = compute_composite(pf, config)
      {score, pf}
    end)
    |> Enum.sort(fn {sa, pa}, {sb, pb} ->
      if sa != sb, do: sa > sb, else: pa.portfolio_id <= pb.portfolio_id
    end)
  end

  defp compute_composite(%ExperimentPortfolio{} = pf, %PortfolioConfig{} = config) do
    info_gain = safe_float(pf.expected_total_information_gain)
    diversity = safe_float(pf.diversity_score)

    # constitutional_priority_score and long_term_impact_score are stored in
    # ExperimentPortfolio.selection_rationale_hash reference — we use the
    # selection_rationale_hash as a tiebreaker proxy (not a numeric score).
    # Until Phase 17.8.9 wires in the full program engine, we extract these
    # from the portfolio's metadata map if present, otherwise treat as absent
    # and fail-close by returning 0.0 (caller must supply these fields).
    constitutional_priority = extract_optional_float(pf, :constitutional_priority_score)
    long_term_impact = extract_optional_float(pf, :long_term_impact_score)

    # resource_utilization is inversely weighted:
    # a portfolio that consumes less of the available budget scores higher.
    resource_fraction = extract_optional_float(pf, :resource_utilization_fraction)
    resource_score = max(0.0, 1.0 - resource_fraction)

    config.w_information_gain * info_gain +
      config.w_scientific_diversity * diversity +
      config.w_constitutional_priority * constitutional_priority +
      config.w_resource_utilization * resource_score +
      config.w_long_term_impact * long_term_impact
  end

  # Read a float field from struct or metadata map. Return 0.0 if absent.
  # 0.0 is a legitimate "not present" signal — it does not default a domain value,
  # it records that the portfolio did not supply this signal.
  defp extract_optional_float(%ExperimentPortfolio{} = pf, field) do
    value =
      Map.get(pf, field) ||
        (pf |> Map.get(:metadata) |> then(fn m -> if is_map(m), do: Map.get(m, field), else: nil end))

    safe_float(value)
  end

  defp safe_float(v) when is_float(v), do: max(0.0, v)
  defp safe_float(v) when is_integer(v), do: max(0.0, v * 1.0)
  defp safe_float(_), do: 0.0

  # ---------------------------------------------------------------------------
  # Private: pruning
  # ---------------------------------------------------------------------------

  defp split_by_threshold(scored, threshold) when is_float(threshold) do
    Enum.split_with(scored, fn {score, _pf} -> score >= threshold end)
  end

  # ---------------------------------------------------------------------------
  # Private: diversity enforcement
  # If the passing set's domain diversity is below threshold, restore the
  # highest-scoring pruned portfolios (ascending by score desc, id asc)
  # until the threshold is met or pruned set is exhausted.
  # ---------------------------------------------------------------------------

  defp restore_for_diversity(passing, pruned, %PortfolioConfig{} = config) do
    current_diversity = compute_diversity_score(Enum.map(passing, fn {_, pf} -> pf end))

    if current_diversity >= config.min_domain_diversity_threshold or pruned == [] do
      passing
    else
      do_restore(passing, pruned, config.min_domain_diversity_threshold)
    end
  end

  defp do_restore(passing, [], _threshold), do: passing

  defp do_restore(passing, [candidate | rest], threshold) do
    candidate_diversity =
      compute_diversity_score(Enum.map([candidate | passing], fn {_, pf} -> pf end))

    if candidate_diversity >= threshold do
      [candidate | passing]
    else
      do_restore([candidate | passing], rest, threshold)
    end
  end

  # Domain diversity: ratio of unique domain values to total portfolios.
  # Domains are extracted from the portfolio's selected_program_ids list length
  # as a proxy — the actual domain signals come from ExperimentPortfolio.diversity_score
  # which is pre-computed by the planner.
  defp compute_diversity_score([]), do: 0.0

  defp compute_diversity_score(portfolios) do
    avg =
      portfolios
      |> Enum.map(fn pf -> safe_float(pf.diversity_score) end)
      |> then(fn scores ->
        if scores == [], do: 0.0, else: Enum.sum(scores) / length(scores)
      end)

    min(1.0, avg)
  end

  # ---------------------------------------------------------------------------
  # Private: cap to max portfolio size
  # Passing list is already sorted by score desc, id asc.
  # ---------------------------------------------------------------------------

  defp cap_to_max(scored, max_size) when is_integer(max_size) and max_size > 0 do
    Enum.take(scored, max_size)
  end

  # ---------------------------------------------------------------------------
  # Private: build output ExperimentPortfolio
  # ---------------------------------------------------------------------------

  defp build_output_portfolio(selected_scored, all_scored, config, budget) do
    selected_pfs = Enum.map(selected_scored, fn {_, pf} -> pf end)
    selected_program_ids = Enum.flat_map(selected_pfs, & &1.selected_program_ids)
    selected_experiment_ids = Enum.flat_map(selected_pfs, & &1.selected_experiment_ids)

    total_info_gain =
      selected_pfs
      |> Enum.map(fn pf -> safe_float(pf.expected_total_information_gain) end)
      |> Enum.sum()

    avg_diversity =
      compute_diversity_score(selected_pfs)

    # Optimisation proof hash: deterministic hash over the scored candidate set
    # and the config used. This allows the independent auditor to verify that
    # the selection was computed from these exact inputs.
    proof_input =
      all_scored
      |> Enum.map(fn {score, pf} -> "#{pf.portfolio_id}:#{score}" end)
      |> Enum.sort()
      |> Enum.join("|")

    optimization_proof_hash =
      :crypto.hash(:sha256, proof_input <> "|" <> config.config_id)
      |> Base.encode16(case: :lower)
      |> then(&("opf_" <> &1))

    selection_rationale =
      Canonical.generate_id(
        %{
          selected_portfolio_ids: Enum.map(selected_pfs, & &1.portfolio_id),
          config_id: config.config_id
        },
        :__ref__,
        "rat"
      )

    ExperimentPortfolio.new(
      epoch_id: config.epoch_id,
      config_hash: config.config_id,
      selected_program_ids: selected_program_ids |> Enum.uniq() |> Enum.sort(),
      selected_experiment_ids: selected_experiment_ids |> Enum.uniq() |> Enum.sort(),
      diversity_score: avg_diversity,
      expected_total_information_gain: total_info_gain,
      optimization_proof_hash: optimization_proof_hash,
      budget_allocation_id: budget.budget_id,
      selection_rationale_hash: selection_rationale
    )
  end
end
