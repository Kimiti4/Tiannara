defmodule Tiannara.Forecasting.OutcomeResolution do
  @moduledoc """
  Evidence-bound forecast to reality resolution.

  Linking an outcome is not the same thing as proving that it is usable for
  performance learning. This layer keeps that distinction explicit.
  """
  alias Tiannara.Forecasting.Calibration
  alias Tiannara.Forecasting.Contracts.Forecast

  @spec resolve(Forecast.t(), map(), map()) :: {:ok, map()} | {:error, term()}
  def resolve(%Forecast{} = forecast, outcome, evidence \\ %{}) when is_map(outcome) do
    with :ok <- validate_link(forecast, outcome),
         :ok <- validate_evidence(evidence),
         {:ok, scores} <- score(forecast, outcome) do
      {:ok, %{
        resolution_id: id(),
        forecast_id: forecast.id,
        forecast_version: forecast.forecast_version,
        model_ref: forecast.model_ref,
        forecast_created_at: forecast.created_at,
        observed_outcome: outcome.observed_outcome,
        observed_at: outcome.observed_at,
        resolution_source: outcome.source,
        scores: scores,
        evidence: normalize_evidence(evidence),
        evidence_status: evidence_status(evidence),
        status: :resolved_not_certified,
        model_update: :requires_independent_review
      }}
    end
  end

  def resolve(_, _, _), do: {:error, :invalid_resolution_input}

  @spec validate_evidence(map()) :: :ok | {:error, term()}
  def validate_evidence(evidence) when is_map(evidence) do
    klass = Map.get(evidence, :evidence_class, :unknown)
    mode = Map.get(evidence, :execution_mode, :unknown)

    cond do
      klass not in [:simulated, :real, :unknown] -> {:error, :invalid_evidence_class}
      mode not in [:simulation, :real_execution, :unknown] -> {:error, :invalid_execution_mode}
      klass == :real and mode != :real_execution -> {:error, :real_evidence_requires_real_execution}
      mode == :real_execution and klass != :real -> {:error, :real_execution_requires_real_evidence}
      true -> :ok
    end
  end

  defp validate_link(%Forecast{id: forecast_id, created_at: created_at}, outcome) do
    cond do
      not is_binary(forecast_id) -> {:error, :forecast_id_missing}
      Map.get(outcome, :forecast_id) != forecast_id -> {:error, :forecast_id_mismatch}
      not is_map_key(outcome, :observed_outcome) -> {:error, :observed_outcome_missing}
      not match?(%DateTime{}, Map.get(outcome, :observed_at)) -> {:error, :observed_at_required}
      not is_nil(created_at) and DateTime.compare(outcome.observed_at, created_at) == :lt ->
        {:error, :hindsight_contamination}
      true -> :ok
    end
  end

  defp score(%Forecast{} = forecast, outcome) do
    observed = outcome.observed_outcome
    brier = Calibration.score(forecast, observed, :brier)
    log_loss = Calibration.score(forecast, observed, :log_loss)

    directional =
      case {forecast.outcomes, forecast.probabilities} do
        {outcomes, probs} when is_list(outcomes) and is_list(probs) and outcomes != [] and probs != [] ->
          {_, index} = Enum.with_index(probs) |> Enum.max_by(fn {p, _} -> p end)
          if Enum.at(outcomes, index) == observed, do: 1, else: 0
        _ -> :unknown
      end

    {:ok, %{
      brier: brier.value,
      log_loss: log_loss.value,
      directional_accuracy: directional,
      sample_size: 1
    }}
  end

  defp evidence_status(%{evidence_class: :real, execution_mode: :real_execution}), do: :real_observation
  defp evidence_status(%{evidence_class: :simulated, execution_mode: :simulation}), do: :simulated_observation
  defp evidence_status(_), do: :evidence_unresolved

  defp normalize_evidence(evidence) do
    %{
      evidence_class: Map.get(evidence, :evidence_class, :unknown),
      execution_mode: Map.get(evidence, :execution_mode, :unknown),
      observation_id: Map.get(evidence, :observation_id),
      provenance: Map.get(evidence, :provenance),
      effect_verified: Map.get(evidence, :effect_verified, false)
    }
  end

  defp id, do: "forecast-resolution-" <> Integer.to_string(System.unique_integer([:positive]))
end
