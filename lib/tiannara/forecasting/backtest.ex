defmodule Tiannara.Forecasting.Backtest do
  @moduledoc """
  Leakage-resistant rolling-origin evaluation.

  Test windows only contain observations that would have been available at the
  forecast origin. The module returns metrics, not a certification decision.
  """

  def rolling(series, forecast_fun, opts \\ []) when is_list(series) and is_function(forecast_fun, 1) do
    min_train = Keyword.get(opts, :min_train, 5)
    horizon = Keyword.get(opts, :horizon, 1)

    cond do
      min_train < 1 or horizon < 1 -> {:error, :invalid_window}
      length(series) < min_train + horizon -> {:error, :insufficient_history}
      true ->
        origins = Enum.to_list(min_train..(length(series) - horizon))
        results =
          Enum.map(origins, fn origin ->
            train = Enum.take(series, origin)
            actual = Enum.slice(series, origin, horizon)
            case forecast_fun.(train) do
              {:ok, prediction} -> %{origin: origin, train_size: length(train), prediction: prediction, actual: actual, status: :evaluated}
              {:error, reason} -> %{origin: origin, train_size: length(train), error: reason, status: :failed}
              other -> %{origin: origin, train_size: length(train), prediction: other, actual: actual, status: :evaluated}
            end
          end)

        {:ok, %{method: :rolling_origin, min_train: min_train, horizon: horizon, results: results,
                leakage_check: :past_only}}
    end
  end

  def compare(predictions, baseline_predictions) when is_list(predictions) and is_list(baseline_predictions) do
    pairs = Enum.zip(predictions, baseline_predictions)
    if pairs == [], do: {:error, :no_comparable_results},
      else: {:ok, %{pairs: length(pairs), status: :comparison_only}}
  end
end
