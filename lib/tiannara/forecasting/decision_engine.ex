defmodule Tiannara.Forecasting.DecisionEngine do
  @moduledoc """
  D3 decision engine: computes expected value, risk, and a recommendation from
  a `DecisionRequest` (or `Alternative` list) using decision-time information
  only.

  Expected value is the probability-weighted utility over an alternative's
  outcome distribution. Risk is the variance / standard deviation of that
  utility. Where probabilities are `:unknown`, expected value is `:unknown`
  and the engine never fabricates a number.

  A recommendation is the highest expected-value alternative among those with a
  determinate expected value. Choosing it is a recommendation — not an
  authorization. The engine NEVER decides permission.

  Design:
    - `decide/1` → `{:ok, Decision}` or `{:error, reason}`.
    - `expected_value/1|2`, `variance/1`, `stddev/1` are exposed for
      transparent, independently-verifiable arithmetic.
  """

  alias Tiannara.Forecasting.{Decision}
  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionRequest}

  @type result :: {:ok, Decision.t()} | {:error, term()}

  @doc """
  Builds and analyzes a decision from a request or attribute map.

  Returns `{:ok, decision}` where the decision carries per-alternative
  `expected_values` and `risk_evaluation` plus a `recommended_alternative_id`.
  """
  @spec decide(map() | DecisionRequest.t()) :: result
  def decide(attrs) do
    d = Decision.new(attrs)

    case Decision.validate(d) do
      {:error, reason} ->
        {:error, reason}

      {:ok, d} ->
        ev = Enum.map(d.alternatives, &{&1.id, expected_value(&1)})
        risk = Enum.map(d.alternatives, &{&1.id, risk_evaluation(&1)})
        recommended = select_recommendation(d.alternatives)

        result =
          %{d |
            expected_values: Map.new(ev),
            risk_evaluation: Map.new(risk),
            recommended_alternative_id: recommended
          }

        {:ok, result}
    end
  end

  @doc """
  Expected value of an alternative: Σ p_i · u_i over its decision-time
  distribution. Returns `:unknown` when probabilities are not determinate.
  """
  @spec expected_value(Alternative.t()) :: float() | :unknown
  def expected_value(%Alternative{probabilities: p, utilities: u}) when is_list(p) and is_list(u) do
    if Enum.all?(p, &(is_number(&1))) and length(p) == length(u) do
      p
      |> Enum.zip(u)
      |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * ui end)
    else
      :unknown
    end
  end

  def expected_value(%Alternative{}), do: :unknown

  @doc """
  Variance of an alternative's utility: Σ p_i · (u_i − EV)².
  Returns `:unknown` when expected value is `:unknown`.
  """
  @spec variance(Alternative.t()) :: float() | :unknown
  def variance(%Alternative{} = a) do
    case expected_value(a) do
      :unknown ->
        :unknown

      ev ->
        case {a.probabilities, a.utilities} do
          {p, u} when is_list(p) and is_list(u) and length(p) == length(u) ->
            p
            |> Enum.zip(u)
            |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * (ui - ev) ** 2 end)

          _ ->
            :unknown
        end
    end
  end

  @doc """
  Standard deviation of an alternative's utility. `:unknown` when variance is.
  """
  @spec stddev(Alternative.t()) :: float() | :unknown
  def stddev(%Alternative{} = a) do
    case variance(a) do
      :unknown -> :unknown
      v -> :math.sqrt(v)
    end
  end

  @doc """
  Risk evaluation for an alternative: expected value, variance, stddev, and a
  normalized risk score in `[0,1]`. Risk score blends the coefficient of
  variation with the reversibility, when known.
  """
  @spec risk_evaluation(Alternative.t()) :: map()
  def risk_evaluation(%Alternative{} = a) do
    ev = expected_value(a)
    var = variance(a)
    sd = stddev(a)
    %{
      expected_value: ev,
      variance: var,
      stddev: sd,
      risk_score: risk_score(ev, sd, a.reversibility)
    }
  end

  @doc """
  Selects the highest-expected-value alternative among those with a determinate
  expected value. Returns `nil` when none are determinate.
  """
  @spec select_recommendation([Alternative.t()]) :: term() | nil
  def select_recommendation(alternatives) when is_list(alternatives) do
    alternatives
    |> Enum.map(fn a -> {a.id, expected_value(a)} end)
    |> Enum.filter(fn {_, ev} -> is_number(ev) end)
    |> Enum.reduce(nil, fn {id, ev}, best ->
      case best do
        nil -> {id, ev}
        {_, best_ev} when ev > best_ev -> {id, ev}
        _ -> best
      end
    end)
    |> case do
      nil -> nil
      {id, _} -> id
    end
  end

  defp risk_score(_ev, :unknown, _rev), do: :unknown
  defp risk_score(ev, _sd, :irreversible) when is_number(ev), do: 1.0
  defp risk_score(ev, sd, rev) when is_number(ev) and is_number(sd) do
    base = if ev != 0, do: min(1.0, abs(sd) / abs(ev)), else: sd
    reversibility_penalty = case rev do
      :partially_reversible -> 0.5
      :reversible -> 0.0
      _ -> 0.0
    end
    min(1.0, base + reversibility_penalty)
  end
  defp risk_score(_ev, _sd, _rev), do: :unknown
end
