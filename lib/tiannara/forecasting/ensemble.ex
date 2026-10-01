defmodule Tiannara.Forecasting.Ensemble do
  @moduledoc """
  Evidence-aware forecast aggregation.

  Ensembles preserve component forecasts and weights. Weighting must be supplied
  by an evaluated procedure; this module does not infer weights from confidence.
  """

  def combine(forecasts, weights) when is_list(forecasts) and is_list(weights) do
    cond do
      forecasts == [] or length(forecasts) != length(weights) ->
        {:error, :invalid_ensemble}
      not Enum.all?(forecasts, &is_number/1) ->
        {:error, :invalid_forecast}
      not Enum.all?(weights, &(is_number(&1) and &1 >= 0)) ->
        {:error, :invalid_weight}
      Enum.sum(weights) <= 0 ->
        {:error, :zero_total_weight}
      true ->
        total = Enum.sum(weights)
        value = Enum.zip(forecasts, weights) |> Enum.reduce(0.0, fn {f,w}, acc -> acc + f * w / total end)
        {:ok, %{forecast: value, components: forecasts, weights: weights,
                weight_source: :externally_evaluated,
                status: :aggregated_not_certified,
                certification_eligible: false}}
    end
  end
end
