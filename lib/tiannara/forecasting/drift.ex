defmodule Tiannara.Forecasting.Drift do
  @moduledoc """
  Conservative distribution-drift diagnostics.

  Drift detection raises an investigation signal. It does not establish why
  the distribution changed and never marks a forecast operationally valid.
  """

  def mean_shift(reference, current, opts \\ []) do
    threshold = Keyword.get(opts, :standardized_threshold, 2.0)

    cond do
      not valid_series?(reference) or not valid_series?(current) ->
        {:error, :invalid_series}

      reference == [] or current == [] ->
        {:error, :empty_series}

      true ->
        ref_mean = mean(reference)
        cur_mean = mean(current)
        pooled = max(std(reference ++ current), 1.0e-12)
        standardized_shift = abs(cur_mean - ref_mean) / pooled

        {:ok, %{
          reference_mean: ref_mean,
          current_mean: cur_mean,
          standardized_shift: standardized_shift,
          drift_candidate: standardized_shift >= threshold,
          method: :standardized_mean_shift,
          status: :investigation_signal,
          causal_explanation: :not_established,
          certification_eligible: false
        }}
    end
  end

  def forecast_degradation(actuals, predictions, opts \\ []) do
    threshold = Keyword.get(opts, :relative_mae_increase, 0.20)

    if length(actuals) != length(predictions) or actuals == [] do
      {:error, :invalid_sample}
    else
      if Enum.all?(Enum.zip(actuals, predictions), fn {a, p} -> is_number(a) and is_number(p) end) do
        mae = mean(Enum.map(Enum.zip(actuals, predictions), fn {a, p} -> abs(a - p) end))
        baseline = Keyword.get(opts, :baseline_mae)

        degradation =
          if is_number(baseline) and baseline > 0,
            do: (mae - baseline) / baseline,
            else: :baseline_unavailable

        {:ok, %{mae: mae, baseline_mae: baseline, relative_degradation: degradation,
                degradation_candidate: is_number(degradation) and degradation >= threshold,
                status: :monitoring_signal, certification_eligible: false}}
      else
        {:error, :non_numeric_observations}
      end
    end
  end

  defp valid_series?(series), do: is_list(series) and Enum.all?(series, &is_number/1)
  defp mean(values), do: Enum.sum(values) / length(values)
  defp std(values) do
    m = mean(values)
    :math.sqrt(Enum.sum(Enum.map(values, fn v -> :math.pow(v - m, 2) end)) / length(values))
  end
end
