defmodule Tiannara.Forecasting.Decision do
  @moduledoc """
  The D3 immutable Decision: a choice made on decision-time information.

  A Decision is constructed from a `DecisionRequest` (question + alternatives)
  and preserved as an immutable `Contracts.Decision`. Expected value, risk, and
  the recommendation are computed from decision-time information only — never
  from hindsight.

  Lifecycle:
      Decision.new(attrs)   → Decision        (version 1)
      Decision.version(decision, updates) → new immutable version (v+1)
      Decision.validate(decision) → {:ok, _} | {:error, reason}

  Constitutional rules:
    - alternatives keep their decision-time probability distribution.
    - a recommendation is a recommendation, not an authorization.
    - `:unknown` probabilities are valid and distinct from `0.0`.
    - versioning appends; history is never overwritten.
  """

  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionRequest, Decision}

  @type t :: Decision.t()

  @spec new(map() | DecisionRequest.t()) :: Decision.t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    m = normalize_map(attrs)

    %Decision{
      id: Map.get(m, :id) || Tiannara.Executive.Types.new_id(),
      question: Map.get(m, :question),
      alternatives: Enum.map(Map.get(m, :alternatives, []) || [], &ensure_alternative/1),
      recommended_alternative_id: Map.get(m, :recommended_alternative_id),
      selected_alternative_id: Map.get(m, :selected_alternative_id),
      expected_values: Map.get(m, :expected_values),
      risk_evaluation: Map.get(m, :risk_evaluation),
      context: Map.get(m, :context),
      created_at: Map.get(m, :created_at) || DateTime.utc_now(),
      decision_version: Map.get(m, :decision_version, 1),
      lineage: Map.get(m, :lineage, []),
      forecast_refs: Map.get(m, :forecast_refs, []),
      decisioner: Map.get(m, :decisioner)
    }
  end

  @spec validate(Decision.t()) :: {:ok, Decision.t()} | {:error, term()}
  def validate(%Decision{} = d) do
    cond do
      is_nil(d.question) ->
        {:error, :missing_question}

      not is_list(d.alternatives) or d.alternatives == [] ->
        {:error, :missing_alternatives}

      Enum.any?(d.alternatives, &(not alternative_ok?(&1))) ->
        {:error, :invalid_alternative}

      length(Enum.uniq(Enum.map(d.alternatives, & &1.id))) != length(d.alternatives) ->
        {:error, :duplicate_alternative_ids}

      true ->
        {:ok, d}
    end
  end

  @spec version(Decision.t(), map() | Keyword.t()) :: Decision.t()
  def version(%Decision{} = d, updates) do
    u = Map.new(updates)
    previous_id = d.id

    new(d
        |> Map.from_struct()
        |> Map.drop([:id])
        |> Map.put(:created_at, DateTime.utc_now())
        |> Map.put(:decision_version, (d.decision_version || 1) + 1)
        |> Map.put(:lineage, [previous_id | d.lineage])
        |> Map.merge(u))
  end

  @doc """
  The default no-action alternative. A decision always compares against inaction.
  """
  @spec do_nothing(label :: String.t()) :: Alternative.t()
  def do_nothing(label \\ "do_nothing") do
    %Alternative{
      id: :do_nothing,
      label: label,
      outcomes: ["no_change"],
      probabilities: [1.0],
      utilities: [0],
      reversibility: :reversible
    }
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp normalize_map(attrs) do
    if is_struct(attrs) do
      Map.from_struct(attrs)
    else
      Map.new(attrs)
    end
  end

  defp ensure_alternative(%Alternative{} = a), do: a

  defp ensure_alternative(a) when is_map(a) do
    m = if is_struct(a), do: Map.from_struct(a), else: Map.new(a)

    struct!(%Alternative{}, Map.take(m, [
      :id, :label, :probabilities, :outcomes, :utilities,
      :risk, :reversibility, :assets_at_risk
    ]))
  end

  defp ensure_alternative(_), do: %Alternative{}

  defp alternative_ok?(%Alternative{outcomes: o, probabilities: p, utilities: u})
       when is_list(o) and o != [] do
    probabilities_ok?(o, p) and utilities_match?(o, u)
  end

  defp alternative_ok?(%Alternative{}), do: false

  defp probabilities_ok?(_o, :unknown), do: true
  defp probabilities_ok?(_o, nil), do: true

  defp probabilities_ok?(o, p) when is_list(p) do
    length(p) == length(o) and Enum.all?(p, &valid_probability?/1)
  end

  defp probabilities_ok?(_o, _p), do: false

  defp valid_probability?(p), do: is_number(p) and finite?(p) and p >= 0 and p <= 1

  defp finite?(p) when is_integer(p), do: true
  defp finite?(p) when is_float(p), do: p - p == 0.0
  defp finite?(_), do: false

  defp utilities_match?(o, u) when is_list(u), do: length(o) == length(u)
  defp utilities_match?(_o, _u), do: false
end
