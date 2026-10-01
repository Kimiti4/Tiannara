defmodule Tiannara.Forecasting.Baseline do
  @moduledoc """
  Transparent forecasting baselines.

  Complex forecasters must be evaluated against these before their additional
  complexity is justified. No baseline claims superiority without evaluation.
  """

  def naive([]), do: {:error, :empty_series}
  def naive(series) when is_list(series), do: {:ok, List.last(series)}

  def mean([]), do: {:error, :empty_series}
  def mean(series) when is_list(series) do
    if Enum.all?(series, &is_number/1),
      do: {:ok, Enum.sum(series) / length(series)},
      else: {:error, :non_numeric_series}
  end

  def moving_average(series, window) when is_list(series) and is_integer(window) and window > 0 do
    cond do
      length(series) < window -> {:error, :insufficient_history}
      not Enum.all?(series, &is_number/1) -> {:error, :non_numeric_series}
      true ->
        {:ok, series |> Enum.take(-window) |> mean_value()}
    end
  end
  def moving_average(_, _), do: {:error, :invalid_window}

  def persistence(series), do: naive(series)

  defp mean_value(values), do: Enum.sum(values) / length(values)
end
