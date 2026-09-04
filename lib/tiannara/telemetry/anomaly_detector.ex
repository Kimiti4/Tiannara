defmodule Tiannara.Telemetry.AnomalyDetector do
  @moduledoc """
  Detects anomalies from a window of telemetry observations. Deterministic and
  pure: given the same observation sequence, it produces the same anomalies.

  Detects:
    * `:monotonic_memory_growth` — a potential leak (strictly increasing memory)
    * `:metric_threshold_breach` — a metric exceeding a configured limit

  Constitutional basis: Safety and Reliability ("Detect anomalies", "Detect
  degraded performance"), Bottleneck Discovery, Continuous Self-Evaluation.
  """

  alias Tiannara.Telemetry.Observation

  @doc """
  Detect anomalies in a window of observations.

  Options:
    * `:growth_window` — how many trailing observations to check for monotonic
      growth (default 3)
    * `:thresholds` — map of metric => limit that triggers a breach
  """
  def detect(observations, opts \\ []) when is_list(observations) do
    growth_window = Keyword.get(opts, :growth_window, 3)
    thresholds = Keyword.get(opts, :thresholds, %{})

    []
    |> detect_monotonic_growth(observations, growth_window)
    |> detect_threshold_breach(observations, thresholds)
  end

  defp detect_monotonic_growth(anomalies, observations, window) do
    recent = Enum.take(observations, -window)
    mems = Enum.map(recent, & &1.metrics[:total_memory])

    if length(mems) == window and strictly_increasing?(mems) do
      [
        %{
          type: :monotonic_memory_growth,
          severity: :high,
          metric: :total_memory,
          evidence: mems
        }
        | anomalies
      ]
    else
      anomalies
    end
  end

  defp detect_threshold_breach(anomalies, [], _thresholds), do: anomalies

  defp detect_threshold_breach(anomalies, observations, thresholds) do
    latest = List.last(observations)

    Enum.reduce(thresholds, anomalies, fn {metric, limit}, acc ->
      value = latest.metrics[metric]

      if value != nil and value > limit do
        [
          %{
            type: :metric_threshold_breach,
            severity: :medium,
            metric: metric,
            value: value,
            threshold: limit
          }
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp strictly_increasing?([_]), do: false

  defp strictly_increasing?(list) do
    list
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [a, b] -> b > a end)
  end
end