defmodule Tiannara.Forecasting.Features do
  @moduledoc """
  Leakage-resistant temporal feature generation.

  Features are derived only from observations preceding the forecast origin.
  The module preserves feature provenance and never labels a feature as causal.
  """

  def build(series, origin, opts \\ []) when is_list(series) and is_integer(origin) do
    lags = Keyword.get(opts, :lags, [1, 2, 3])
    windows = Keyword.get(opts, :windows, [3, 7])

    cond do
      origin < 1 or origin > length(series) -> {:error, :invalid_origin}
      not Enum.all?(series, &is_number/1) -> {:error, :non_numeric_series}
      not Enum.all?(lags, &(is_integer(&1) and &1 > 0)) -> {:error, :invalid_lags}
      not Enum.all?(windows, &(is_integer(&1) and &1 > 0)) -> {:error, :invalid_windows}
      true ->
        history = Enum.take(series, origin)

        lag_features =
          Enum.into(lags, %{}, fn lag ->
            {String.to_atom("lag_#{lag}"), Enum.at(history, length(history) - lag)}
          end)

        rolling_features =
          Enum.into(windows, %{}, fn window ->
            key = String.to_atom("rolling_mean_#{window}")
            value = if length(history) >= window,
              do: history |> Enum.take(-window) |> mean(),
              else: :insufficient_history
            {key, value}
          end)

        {:ok, %{
          origin: origin,
          features: Map.merge(lag_features, rolling_features),
          provenance: %{source_end_index: origin - 1, leakage_check: :past_only},
          status: :derived_not_certified
        }}
    end
  end

  defp mean(values), do: Enum.sum(values) / length(values)
end
