defmodule Tiannara.Observatory.Dashboards do
  @moduledoc "Read-only views over telemetry data for the Control Center."

  def get_math_utilization do
    records =
      :ets.match(:tiannara_telemetry_log, {:_, %{event: [:tiannara, :foundations, :math, :operation]}})
      |> Enum.map(fn {_, data} -> data.measurements.duration end)

    percentiles(records)
  end

  defp percentiles([]), do: %{p50: 0, p99: 0}
  defp percentiles(durations) do
    sorted = Enum.sort(durations)
    len = length(sorted)
    %{p50: Enum.at(sorted, div(len, 2)), p99: Enum.at(sorted, div(len * 99, 100))}
  end
end
