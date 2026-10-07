defmodule Tiannara.Forecasting.Calibration do
  @moduledoc """
  Evidence-aware forecast scoring.

  A single resolved forecast is an observation, not a statistically sufficient
  calibration study. Aggregate calibration requires an adequate resolved sample.
  """

  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Foundations.InformationTheory

  @min_sample 5
  @brier_clamp_epsilon 1.0e-15
  @log_epsilon 1.0e-15

  @type score_result :: %{method: atom(), value: number() | :unknown, sample_size: non_neg_integer()}

  def score(%Forecast{} = f, observed, method \\ :brier) do
    case forecast_probability(f, observed) do
      p when is_number(p) ->
        case score_method(method, p) do
          {:ok, value} -> %{method: method, value: value, sample_size: 1}
          :unknown -> %{method: method, value: :unknown, sample_size: 0}
        end
      _ ->
        %{method: method, value: :unknown, sample_size: 0}
    end
  end

  def brier(p, observed) when is_number(p) and observed in [0, 1] and p >= 0 and p <= 1, do: :math.pow(p - observed, 2)
  def brier(_, _), do: :unknown

  def log_loss(p, _observed) when p == 0 or p == 1, do: :unknown

  def log_loss(p, observed) when is_number(p) and observed in [0, 1] do
    clipped = min(max(p, @log_epsilon), 1.0 - @log_epsilon)
    -((observed * :math.log(clipped)) + ((1 - observed) * :math.log(1.0 - clipped)))
  end
  def log_loss(_, _), do: :unknown

  def mean_brier(pairs) when is_list(pairs) and pairs != [],
    do: aggregate(pairs, :brier)
  def mean_brier(_), do: :unknown

  def mean_log_loss(pairs) when is_list(pairs) and pairs != [],
    do: aggregate(pairs, :log_loss)
  def mean_log_loss(_), do: :unknown

  def calibration_error(binned) when is_list(binned) and binned != [] do
    diffs =
      Enum.map(binned, fn {p, o} when is_number(p) and is_number(o) -> abs(p - o) end)
      |> Enum.reject(&is_nil/1)

    if diffs != [], do: Enum.sum(diffs) / length(diffs), else: :unknown
  end
  def calibration_error(_), do: :unknown

  def reliability_level(n) when n < @min_sample, do: :insufficient
  def reliability_level(_), do: :adequate

  def resolution(binned) when is_list(binned) and binned != [] do
    freqs = for {_p, o} <- binned, is_number(o), do: o
    if freqs != [], do: variance(freqs), else: :unknown
  end
  def resolution(_), do: :unknown

  def sharpness(%Forecast{probabilities: probs}) when is_list(probs) do
    case InformationTheory.shannon_entropy(probs) do
      e when is_number(e) -> -e
      _ -> :unknown
    end
  end
  def sharpness(_), do: :unknown

  def calibration_status(pairs) when is_list(pairs) do
    n = length(pairs)
    if n < @min_sample, do: :insufficient_sample, else: :diagnostic_only
  end

  def reliability(binned) when is_list(binned) do
    %{reliability_diagram: binned,
      calibration_error: calibration_error(binned),
      resolution: resolution(binned),
      level: reliability_level(length(binned))}
  end
  def reliability(_), do: %{reliability_diagram: [], level: :insufficient}

  defp score_method(:brier, p), do: numeric_score(brier(p, 1))
  defp score_method(:log_loss, p), do: numeric_score(log_loss(p, 1))
  defp score_method(_, _), do: :unknown

  defp numeric_score(:unknown), do: :unknown
  defp numeric_score(v), do: {:ok, v}

  defp forecast_probability(%Forecast{probabilities: probs, outcomes: outcomes}, observed)
       when is_list(probs) and is_list(outcomes) do
    case observed_index(outcomes, observed) do
      {:ok, index} -> Enum.at(probs, index, :unknown)
      :error -> :unknown
    end
  end
  defp forecast_probability(_, _), do: :unknown

  defp observed_index(outcomes, observed) when is_integer(observed) and observed >= 0 do
    if observed < length(outcomes), do: {:ok, observed}, else: :error
  end
  defp observed_index(outcomes, observed) do
    case Enum.find_index(outcomes, &(&1 == observed)) do
      nil -> :error
      index -> {:ok, index}
    end
  end

  defp aggregate(pairs, method) do
    values =
      pairs
      |> Enum.map(fn {forecast, observed} ->
        case score(forecast, observed, method).value do
          value when is_number(value) -> value
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if values != [], do: Enum.sum(values) / length(values), else: :unknown
  end

  defp variance(vals) do
    mean = Enum.sum(vals) / length(vals)
    Enum.sum(Enum.map(vals, fn v -> :math.pow(v - mean, 2) end)) / length(vals)
  end
end
