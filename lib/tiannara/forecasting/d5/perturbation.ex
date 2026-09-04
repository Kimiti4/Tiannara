defmodule Tiannara.Forecasting.D5.Perturbation do
  @moduledoc """
  D5 Perturbation — "what may be changed, and by how much?" (contract §5).

  A `PerturbationPlan` is pre-registered BEFORE execution and is immutable once
  registered. It declares, for each closed dimension: target, variants within
  budget, rationale, expected invariance (if any), and the full variant list.
  Late additions require a NEW plan id and are permanently flagged
  `LATE_ADDED` — such plans may support exploration but never classification.
  This is the anti-selective-perturbation rule (§5.2).

  Dimension set is closed (§5.1) — no dimension outside it exists.
  Perturbation validity (§5.4): VALID / INVALID / CONTAMINATION.
  """

  alias Tiannara.Forecasting.D5.Budget
  alias Tiannara.Forecasting.D5.Thresholds

  @dimension_keys [
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

  @doc "Closed set of perturbation dimensions (order-independent membership check)."
  @spec valid_dimension(atom()) :: boolean()
  def valid_dimension(dim), do: dim in @dimension_keys

  @spec dimensions() :: [atom()]
  def dimensions, do: @dimension_keys

  @doc """
  Pre-register a PerturbationPlan. Returns `{:ok, plan}` with a content hash and
  deterministic id, or `{:error, reason}` for structural invalidity.

  Required fields:
    - `:target`      — what is being studied
    - `:dimensions`  — map of `dim => variants` (each variant a label)
    - `:rationale`   — text or map rationale for each dimension
    - `:expected_invariance` — list of dims expected not to matter (optional)
  The plan is considered immutable after this call. Any subsequent change must
  be a NEW plan flagged `LATE_ADDED`.
  """
  @spec register(map()) :: {:ok, map()} | {:error, term()}
  def register(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)
    dims = Map.get(m, :dimensions, %{})

    with :ok <- validate_dims(dims),
         :ok <- validate_budget(dims),
         :ok <- validate_declared(dims) do
      plan = build_plan(m, dims, :preregistered)
      {:ok, plan}
    end
  end

  @doc """
  Register a plan that was materially changed AFTER first pre-registration.
  Such plans are permanently `LATE_ADDED` and may support exploration only —
  they can never drive a classification (contract §5.2).
  """
  @spec register_late_added(map()) :: {:ok, map()} | {:error, term()}
  def register_late_added(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)
    dims = Map.get(m, :dimensions, %{})

    with :ok <- validate_dims(dims),
         :ok <- validate_budget(dims),
         :ok <- validate_declared(dims) do
      plan = build_plan(m, dims, :late_added)
      {:ok, plan}
    end
  end

  @doc """
  Perturbation validity determination (§5.4).
    - `:valid`          — varies only declared dimensions within budget
    - `:invalid`        — undeclared dimension, over-budget, or touches an
                          immutable/decision-time input
    - `:contamination`  — the "perturbation" alters what was known at decision
                          time (temporal violation, §9)
  """
  @spec classify(map(), map()) :: {:ok, atom() | map()} | {:error, term()}
  def classify(plan, observation) do
    observed_dims = Map.get(observation, :varied_dimensions, [])

    cond do
      contamination?(observation) ->
        {:ok, :contamination}

      Enum.any?(observed_dims, &(not valid_dimension(&1))) ->
        {:ok, :invalid}

      over_budget?(plan, observed_dims) ->
        {:ok, :invalid}

      not fully_declared?(plan, observed_dims) ->
        {:ok, :invalid}

      true ->
        detail = %{
          validity: :valid,
          dimension_count: length(observed_dims),
          within_budget: true,
          temporal_integrity: :preserved
        }

        {:ok, detail}
    end
  end

  @doc """
  Whether a plan may drive classification. Preregistered (not LATE_ADDED) plans
  with complete declared dimensions qualify.
  """
  @spec classification_eligible?(map()) :: boolean()
  def classification_eligible?(plan) do
    Map.get(plan, :registration) == :preregistered and
      Map.get(plan, :completed, false)
  end

  @doc "Mark a plan completed (all declared dimensions executed)."
  @spec complete(map()) :: map()
  def complete(plan), do: %{plan | completed: true}

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp validate_dims(dims) when is_map(dims) do
    unknown = Enum.any?(Map.keys(dims), &(not valid_dimension(&1)))
    count = map_size(dims)

    cond do
      unknown -> {:error, :unknown_dimension}
      count == 0 -> {:error, :no_dimensions}
      count > Thresholds.max_perturbation_dimensions() -> {:error, :too_many_dimensions}
      true -> :ok
    end
  end

  defp validate_dims(_), do: {:error, :invalid_dimensions}

  defp validate_budget(dims) when is_map(dims) do
    if Budget.allowed?(%{
         dimensions: map_size(dims),
         variants_per_dimension: Map.new(dims, fn {k, v} -> {k, List.wrap(v) |> length()} end),
         models: 1,
         evaluators: 1
       }) do
      :ok
    else
      {:error, :over_budget}
    end
  end

  defp validate_declared(dims) do
    empty =
      Enum.any?(dims, fn {_k, v} ->
        List.wrap(v) == []
      end)

    if empty, do: {:error, :empty_variants}, else: :ok
  end

  defp build_plan(m, dims, registration) do
    variants_details =
      Map.new(dims, fn {dim, variants} ->
        {dim, %{variants: List.wrap(variants), count: length(List.wrap(variants))}}
      end)

    content =
      :erlang.term_to_binary({dims, Map.get(m, :target), Map.get(m, :rationale),
                              Map.get(m, :expected_invariance, [])})

    hash = Base.encode16(:erlang.md5(content))

    %{
      id: Map.get(m, :id, "d5plan_" <> hash),
      content_hash: hash,
      registration: registration,
      target: Map.get(m, :target),
      rationale: Map.get(m, :rationale),
      expected_invariance: Map.get(m, :expected_invariance, []),
      dimension_count: map_size(dims),
      dimensions: variants_details,
      completed: false,
      contract_version: Thresholds.contract_version(),
      threshold_set_hash: Thresholds.threshold_set_hash(),
      created_at: Map.get(m, :created_at, DateTime.utc_now())
    }
  end

  defp contamination?(obs) do
    Map.get(obs, :at_decision_time_known, true) == false or
      Map.get(obs, :alters_decision_time_evidence, false) == true
  end

  defp over_budget?(plan, observed_dims) do
    Enum.any?(observed_dims, fn dim ->
      case Map.get(Map.get(plan, :dimensions, %{}), dim) do
        %{count: c} -> c > Thresholds.max_variants_per_dimension()
        _ -> true
      end
    end)
  end

  defp fully_declared?(plan, observed_dims) do
    declared = Map.keys(Map.get(plan, :dimensions, %{}))
    Enum.all?(observed_dims, &(&1 in declared))
  end
end
