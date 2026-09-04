defmodule Tiannara.Forecasting.ForecastEngine do
  @moduledoc """
  D2 probabilistic forecast engine.

  Composes existing Tiannara math (Constraints, Math.Probability,
  InformationTheory) to turn a `ForecastRequest` (signals + evidence + base
  rate + context) into an immutable `Contracts.Forecast`.

  Design principles:
    - Single, honest forecaster. No artificial model zoo.
    - Probability and confidence are kept separate.
    - `:unknown` is used when probabilities cannot be justified.
    - Forecasts are falsifiable and reproducible.
  """

  alias Tiannara.Forecasting.{Forecast, BaseRateEngine}
  alias Tiannara.Forecasting.Contracts.{BaseRate, ForecastRequest}
  alias Tiannara.Math.Probability

  @type forecaster_result :: Forecast.t()

  @doc """
  Generates a forecast distribution from a request.

  Returns `{:ok, forecast}` or `{:error, reason}`. When the base rate is
  unavailable and no evidence yields signal-quality, the forecast's
  probabilities are `:unknown` (never fabricated).
  """
  @spec forecast(ForecastRequest.t() | map()) :: {:ok, Forecast.t()} | {:error, term()}
  def forecast(%ForecastRequest{} = req), do: do_forecast(req)

  def forecast(attrs) when is_map(attrs) or is_list(attrs) do
    # Convert to plain map first (structs don't implement Enumerable for Map.new/1).
    attrs_map = if is_struct(attrs), do: Map.from_struct(attrs), else: Map.new(attrs)
    req = struct!(%ForecastRequest{}, attrs_map)
    do_forecast(req)
  end

  defp do_forecast(%ForecastRequest{} = req) do
    with {:ok, outcomes} <- check_outcomes(req),
         {:ok, base_rate} <- resolve_base_rate(req.base_rate),
         {prior, prior_src} <- base_rate_prior(base_rate, outcomes),
         {:ok, model_ref} <- resolve_model(req.model) do
      forecast_input = %{
        question: req.question,
        event: req.event,
        outcomes: outcomes,
        horizon: req.horizon,
        signal_refs: req.signal_ids || [],
        evidence_refs: req.evidence_ids || [],
        base_rate_ref: base_rate,
        model_ref: model_ref,
        assumptions: req.assumptions || [],
        context: req.context,
        regime: req.regime,
        probabilities: prior,
        confidence: prior_confidence(prior_src, prior, base_rate),
        uncertainty: prior_src
      }

      {:ok, Forecast.new(forecast_input)}
    end
  end

  defp check_outcomes(%ForecastRequest{outcomes: o}) when is_list(o) and o != [], do: {:ok, o}
  defp check_outcomes(%ForecastRequest{}), do: {:error, :missing_outcomes}

  defp resolve_base_rate(nil), do: {:ok, nil}
  defp resolve_base_rate(%BaseRate{} = br) do
    case BaseRateEngine.validate(br) do
      {:ok, br} -> {:ok, br}
      {:error, r} -> {:error, r}
    end
  end

  defp resolve_base_rate(br_map) when is_map(br_map) do
    resolve_base_rate(BaseRateEngine.new(br_map))
  end

  @doc """
  Base-rate prior: use the historical frequency when available; otherwise
  `:unknown` prior (honest — do not fabricate uniform justification unless
  evidence supports it).
  """
  @spec base_rate_prior(BaseRate.t() | nil, [term()]) :: {term(), atom()}
  def base_rate_prior(%BaseRate{historical_frequency: f}, outcomes) when is_number(f) do
    case outcomes do
      [_a, _b] -> {[f, 1.0 - f], :base_rate}
      _ -> {:unknown, :base_rate_outcome_mismatch}
    end
  end

  def base_rate_prior(%BaseRate{}, _outcomes), do: {:unknown, :base_rate_unavailable}
  def base_rate_prior(nil, _outcomes), do: {:unknown, :no_base_rate}

  defp prior_confidence(_, _prior, %BaseRate{} = br) do
    br.confidence || br.base_rate_uncertainty
  end

  defp prior_confidence(_, _prior, _), do: nil

  defp resolve_model(nil), do: {:ok, :default}
  defp resolve_model(m), do: {:ok, m}

  @doc """
  Evidence update: applies Bayes to a forecast's prior given a likelihood
  (P(evidence|outcome)) and evidence probability. Both args may be `:unknown`
  — an update never fabricates a posterior.
  """
  @spec update_with_bayes(term(), number(), number()) :: {:ok, number()} | {:error, term()}
  def update_with_bayes(prior, likelihood, evidence_prob)
      when is_number(prior) and is_number(likelihood) and is_number(evidence_prob) do
    Probability.bayes_update(prior, likelihood, evidence_prob)
  end

  def update_with_bayes(:unknown, _, _), do: {:error, :unknown_prior}
  def update_with_bayes(_, _, _), do: {:error, :unknown_evidence}
end