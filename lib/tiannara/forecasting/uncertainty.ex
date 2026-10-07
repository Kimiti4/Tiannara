defmodule Tiannara.Forecasting.Uncertainty do
  @moduledoc """
  Distribution-free uncertainty diagnostics for forecast intervals.

  Interval coverage is empirical: it describes how often realized outcomes
  fell inside previously issued intervals. It is not a guarantee about future
  coverage and is not certification of the forecasting model.
  """

  def interval_score(lower, upper, actual, alpha)
      when is_number(lower) and is_number(upper) and is_number(actual) and
             is_number(alpha) and alpha > 0 and alpha < 1 do
    if lower <= upper do
      width = upper - lower
      penalty_low = if actual < lower, do: (2 / alpha) * (lower - actual), else: 0.0
      penalty_high = if actual > upper, do: (2 / alpha) * (actual - upper), else: 0.0
      {:ok, width + penalty_low + penalty_high}
    else
      {:error, :invalid_interval}
    end
  end

  def interval_score(_, _, _, _), do: {:error, :invalid_interval_parameters}

  def coverage(intervals, alpha)
      when is_list(intervals) and is_number(alpha) and alpha > 0 and alpha < 1 do
    if intervals == [] do
      {:error, :empty_sample}
    else
      valid =
        Enum.filter(intervals, fn
          %{lower: l, upper: u, actual: a} when is_number(l) and is_number(u) and is_number(a) ->
            l <= u
          _ -> false
        end)

      if length(valid) != length(intervals) do
        {:error, :invalid_interval_sample}
      else
        hits = Enum.count(valid, fn %{lower: l, upper: u, actual: a} -> a >= l and a <= u end)
        {:ok, %{coverage: hits / length(valid), nominal_coverage: 1 - alpha,
                sample_size: length(valid), status: :empirical_diagnostic,
                certification_eligible: false}}
      end
    end
  end

  def model_risk(decomposition) when is_map(decomposition) do
    allowed = [:data, :distribution_shift, :parameter, :model,
               :feature, :measurement, :unknown]
    keys = Map.keys(decomposition)

    if Enum.all?(keys, &(&1 in allowed)) and
         Enum.all?(Map.values(decomposition), &(is_number(&1) and &1 >= 0)) do
      {:ok, %{components: decomposition,
              total: Float.round(Enum.sum(Map.values(decomposition)), 15),
              interpretation: :risk_decomposition_not_probability,
              status: :diagnostic_only,
              certification_eligible: false}}
    else
      {:error, :invalid_risk_decomposition}
    end
  end

  def model_risk(_), do: {:error, :invalid_risk_decomposition}
end
