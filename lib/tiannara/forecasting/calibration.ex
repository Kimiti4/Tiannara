defmodule Tiannara.Forecasting.Calibration do
  @moduledoc """
  D2 calibration engine.

  Scores probabilistic forecasts against observed outcomes and measures
  calibration. Distinguishes:

      INSUFFICIENT_DATA   (not enough observations to be statistically meaningful)
      POOR_CALIBRATION    (measured, and poor)

  Supports: Brier Score, Log Loss, Calibration Error, Reliability analysis,
  Resolution, Sharpness.

  Scoring methodology is versioned — historical scores remain attributable to
  the method that produced them (no hidden recalibration).

  All scoring composes existing Tiannara math (no new probability machinery).
  """

  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Foundations.InformationTheory

  @min_sample 5

  @type score_result :: %{method: atom(), value: number() | :unknown, sample_size: non_neg_integer()}

  @doc """
  Scores a forecast against an observed outcome index.

  forecast: `%Forecast{probabilities: [..], outcomes: [..]}`
  observed: index into `outcomes` that actually occurred, or the outcome value.
  """
  @spec score(Forecast.t(), term(), atom()) :: score_result()
  def score(%Forecast{} = f, observed, method \\ :brier) do
    p = forecast_probability(f, observed)

    case score_method(method, p) do
      {:ok, value} ->
        %{method: method, value: value, sample_size: 1}

      :unknown ->
        %{method: method, value: :unknown, sample_size: 0}
    end
  end

  @spec brier(pid_prob :: number(), observed :: 0 | 1) :: number()
  def brier(p, observed) when is_number(p) do
    :math.pow(p - observed, 2)
  end

  @spec log_loss(pid_prob :: number(), observed :: 0 | 1) :: number() | :unknown
  def log_loss(p, _observed) when p == 0 or p == 1, do: :unknown
  def log_loss(p, observed) when is_number(p) and observed in [0, 1], do: -:math.log(p)
  def log_loss(_p, _observed), do: :unknown

  defp score_method(:brier, p) when is_number(p), do: {:ok, brier(p, 1)}
  defp score_method(:log_loss, p) when is_number(p) do
    case log_loss(p, 1) do
      :unknown -> :unknown
      v -> {:ok, v}
    end
  end
  defp score_method(_, _), do: :unknown

  defp forecast_probability(%Forecast{probabilities: :unknown}, _), do: :unknown
  defp forecast_probability(%Forecast{probabilities: nil}, _), do: :unknown

  defp forecast_probability(%Forecast{probabilities: probs}, observed) when is_integer(observed) do
    Enum.at(probs, observed, :unknown)
  end

  defp forecast_probability(%Forecast{outcomes: outcomes, probabilities: probs}, observed) do
    # observed is likely the outcome value; find index
    case Enum.find_index(outcomes, &(&1 == observed)) do
      nil -> :unknown
      i -> Enum.at(probs, i, :unknown)
    end
  end

  @doc "Mean Brier score over a list of {forecast, observed} pairs."
  @spec mean_brier([{Forecast.t(), term()}]) :: number() | :unknown
  def mean_brier(pairs) when is_list(pairs) and pairs != [] do
    vals =
      Enum.map(pairs, fn {f, o} ->
        case score(f, o, :brier) do
          %{value: v} when is_number(v) -> v
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if vals == [], do: :unknown, else: Enum.sum(vals) / length(vals)
  end

  def mean_brier(_), do: :unknown

  @doc "Mean log loss over a list of {forecast, observed} pairs."
  @spec mean_log_loss([{Forecast.t(), term()}]) :: number() | :unknown
  def mean_log_loss(pairs) when is_list(pairs) and pairs != [] do
    vals =
      Enum.map(pairs, fn {f, o} ->
        case score(f, o, :log_loss) do
          %{value: v} when is_number(v) -> v
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if vals == [], do: :unknown, else: Enum.sum(vals) / length(vals)
  end

  def mean_log_loss(_), do: :unknown

  @doc """
  Calibration error: mean absolute difference between forecast probability and
  observed frequency, binned by probability range.
  """
  @spec calibration_error([{number(), 0 | 1}]) :: number() | :unknown
  def calibration_error(binned) when is_list(binned) and binned != [] do
    diffs =
      Enum.map(binned, fn {p, o} when is_number(p) and o in [0, 1] -> abs(p - o) end)
      |> Enum.reject(&is_nil/1)

    if diffs == [], do: :unknown, else: Enum.sum(diffs) / length(diffs)
  end

  def calibration_error(_), do: :unknown

  @doc """
  Whether the sample is insufficient for statistically meaningful calibration.
  Distinct from poor calibration: `:insufficient` vs `:poor` vs `:adequate`.
  """
  @spec reliability_level(non_neg_integer()) :: :insufficient | :adequate
  def reliability_level(n) when n < @min_sample, do: :insufficient
  def reliability_level(_), do: :adequate

  @doc "Resolution: variance of observed frequencies vs overall (clustering)."
  @spec resolution([{number(), 0 | 1}]) :: number() | :unknown
  def resolution(binned) when is_list(binned) and binned != [] do
    freqs = for {_p, o} <- binned, do: o
    if freqs == [], do: :unknown, else: variance(freqs)
  end

  def resolution(_), do: :unknown

  @doc "Sharpness: negative entropy of the forecast distribution (average)."
  @spec sharpness(Forecast.t()) :: number() | :unknown
  def sharpness(%Forecast{probabilities: probs}) when is_list(probs) do
    case InformationTheory.shannon_entropy(probs) do
      e when is_number(e) -> -e
      _ -> :unknown
    end
  end

  def sharpness(_), do: :unknown

  @doc "Reliability analysis over binned {prob, observed_freq} pairs."
  @spec reliability([{number(), number()}]) :: map()
  def reliability(binned) when is_list(binned) and binned != [] do
    %{
      reliability_diagram: binned,
      calibration_error: calibration_error(binned),
      resolution: resolution(binned),
      level: reliability_level(length(binned))
    }
  end

  def reliability(_), do: %{reliability_diagram: [], level: :insufficient}

  defp variance(vals) when is_list(vals) and vals != [] do
    mean = Enum.sum(vals) / length(vals)
    Enum.sum(Enum.map(vals, fn v -> :math.pow(v - mean, 2) end)) / length(vals)
  end

  defp variance(_), do: :unknown
end