defmodule Tiannara.Forecasting.D5.Budget do
  @moduledoc """
  D5 Budget — enforced computational limits (contract §10).

  Hard maxima are frozen in D5.Thresholds and enforced HERE at plan submission,
  BEFORE any run begins. Over-budget plans are REJECTED deterministically —
  never truncated mid-run, never silently allowed.

  Also encodes PARTIAL_COVERAGE semantics: an analysis that executes under
  partial coverage (e.g. a declared dimension dropped for cause) may classify
  only as UNKNOWN or within the explicitly tested scope. Budget exhaustion is
  therefore an epistemic signal, never a silent failure.
  """

  alias Tiannara.Forecasting.D5.Thresholds

  @closed_dimensions [
    :prompt,
    :evidence_order,
    :model,
    :evaluator,
    :parameter,
    :prior,
    :scenario,
    :sampling,
    :temporal
  ]

  @spec closed_dimensions() :: [atom()]
  def closed_dimensions, do: @closed_dimensions

  @spec valid_dimension?(atom()) :: boolean()
  def valid_dimension?(dim), do: dim in @closed_dimensions

  @doc """
  Validate a proposed execution against the frozen budget maxima.

  Options:
    - `:variants_per_dimension`  %{dim => count}
    - `:models`      list/map size
    - `:evaluators`  list/map size
    - `:dimensions`  number of declared perturbation dimensions
    - `:running_cost` partial cost already consumed (default 0)

  Returns `{:ok, %{total_runs, within_budget, detail}}` (computed as an
  upper-bound one-at-a-time + bounded crossing estimate) or `{:error, reason}`
  for structural invalidity (unknown dimension, budget violation).
  """
  @spec evaluate(map()) :: {:ok, map()} | {:error, term()}
  def evaluate(opts) do
    dims = Map.get(opts, :dimensions, 0)
    variants = Map.get(opts, :variants_per_dimension, %{})
    models = count_value(Map.get(opts, :models))
    evaluators = count_value(Map.get(opts, :evaluators))
    running = Map.get(opts, :running_cost, 0)

    with :ok <- validate_dimension_count(dims),
         :ok <- validate_variants(variants, dims),
         :ok <- validate_models(models),
         :ok <- validate_evaluators(evaluators) do
      # Planned total (upper bound on actual executions): each variant across
      # every model × evaluator. A one-at-a-time design stays small; a naive
      # full-factorial across all variants × models × evaluators explodes and
      # is rejected here (forcing the §10.2 crossed bounded design instead).
      span = max(span_variants(variants), 1)
      total = span * max(models, 1) * max(evaluators, 1)

      detail = %{
        total_variants: span_variants(variants),
        models: models,
        evaluators: evaluators,
        dimensions: dims,
        planned_runs: total,
        running_cost: running,
        total_runs: total + running
      }

      if total + running > Thresholds.max_runs_per_analysis() do
        {:ok, Map.put(detail, :within_budget, false)}
      else
        {:ok, Map.put(detail, :within_budget, true)}
      end
    end
  end

  @doc "Deterministic rejection of a plan that violates any hard maximum."
  @spec allowed?(map()) :: boolean()
  def allowed?(opts) do
    case evaluate(opts) do
      {:ok, %{within_budget: true}} -> true
      _ -> false
    end
  end

  @doc """
  PARTIAL_COVERAGE constructor: call when a declared dimension was not fully
  executed. Per §10.3 / §12 this downgrades the analysis to coverage-scoped
  UNKNOWN unless the remaining scope is explicitly stated.
  """
  @spec partial_coverage([atom()], [atom()]) :: map()
  def partial_coverage(declared, executed) do
    missing = declared -- executed

    %{
      coverage: :partial,
      declared_dimensions: declared,
      executed_dimensions: executed,
      missing_dimensions: missing,
      forced_state: :coverage_scoped_unknown,
      description: "Declared dimension(s) not fully executed: #{inspect(missing)}"
    }
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp count_value(v) when is_list(v), do: length(v)
  defp count_value(v) when is_map(v), do: map_size(v)
  defp count_value(v) when is_integer(v) and v >= 0, do: v
  defp count_value(_), do: 0

  defp validate_dimension_count(d) when is_integer(d) and d >= 0 do
    if d > Thresholds.max_perturbation_dimensions(),
      do: {:error, :too_many_dimensions},
      else: :ok
  end

  defp validate_dimension_count(_), do: {:error, :invalid_dimensions}

  defp validate_variants(variants, dims) when is_map(variants) do
    over =
      Enum.any?(variants, fn {_dim, count} ->
        count > Thresholds.max_variants_per_dimension()
      end)

    unknown =
      Enum.any?(Map.keys(variants), fn dim ->
        not valid_dimension?(dim)
      end)

    declared_count = map_size(variants)

    cond do
      unknown -> {:error, :unknown_dimension}
      declared_count > dims -> {:error, :dimension_mismatch}
      over -> {:error, :too_many_variants}
      true -> :ok
    end
  end

  defp validate_variants(_, _), do: {:error, :invalid_variants}

  defp validate_models(m) when is_integer(m) do
    if m > Thresholds.max_models_per_analysis(),
      do: {:error, :too_many_models},
      else: :ok
  end

  defp validate_models(_), do: {:error, :invalid_models}

  defp validate_evaluators(e) when is_integer(e) do
    if e > Thresholds.max_evaluators_per_analysis(),
      do: {:error, :too_many_evaluators},
      else: :ok
  end

  defp validate_evaluators(_), do: {:error, :invalid_evaluators}

  defp span_variants(variants) when is_map(variants) do
    Enum.reduce(variants, 0, fn {_dim, count}, acc -> acc + count end)
  end
end
