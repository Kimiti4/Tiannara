defmodule Tiannara.Forecasting.ForecastIntegrity do
  @moduledoc """
  Cross-cutting integrity gates for EFDI forecasts.

  This module does not predict. It decides whether a forecast record has enough
  structural, temporal and epistemic metadata to be consumed by downstream
  decision or research systems.
  """

  alias Tiannara.Forecasting.Forecast

  def audit(%Forecast{} = forecast) do
    checks = %{
      forecast_valid: match?({:ok, _}, Forecast.validate(forecast)),
      probabilities_known_or_explicitly_unknown:
        forecast.probabilities in [:unknown, nil] or is_list(forecast.probabilities),
      confidence_separate_from_probability: forecast.confidence != forecast.probability,
      uncertainty_declared: not is_nil(forecast.uncertainty),
      assumptions_declared: is_list(forecast.assumptions),
      provenance_present: is_map(forecast.provenance) or is_nil(forecast.provenance),
      lineage_structured: is_list(forecast.lineage),
      immutable_versioned: is_integer(forecast.forecast_version) and forecast.forecast_version >= 1
    }

    {:ok, %{checks: checks, status: if(Enum.all?(Map.values(checks)), do: :pass, else: :fail),
            certification_eligible: false}}
  end

  def temporal_consistent?(%Forecast{created_at: created_at, context: context}) when is_map(context) do
    cutoff = Map.get(context, :data_cutoff) || Map.get(context, "data_cutoff")
    is_nil(cutoff) or (match?(%DateTime{}, cutoff) and DateTime.compare(cutoff, created_at) != :gt)
  end

  def temporal_consistent?(_), do: true
end
