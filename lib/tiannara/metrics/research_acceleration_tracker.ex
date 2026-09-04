defmodule Tiannara.Metrics.ResearchAccelerationTracker do
  alias Tiannara.Discovery.Discovery

  @spec compute([Discovery.t()]) :: map()
  def compute(discoveries) when is_list(discoveries) do
    completed = Enum.filter(discoveries, &(&1.status == :completed))

    if completed == [] do
      %{
        time_to_discovery_avg: 0.0,
        throughput_per_day: 0.0,
        quality_adjusted_throughput: 0.0,
        acceleration_ratio: 1.0,
        sample_size: 0
      }
    else
      durations =
        Enum.map(completed, fn disc ->
          case {disc.created_at, disc.completed_at} do
            {created, completed_at} when not is_nil(completed_at) ->
              DateTime.diff(completed_at, created, :hour)
            _ ->
              0
          end
        end)

      avg_duration = Enum.sum(durations) / length(durations)

      total_days = compute_total_days(completed)
      throughput = if total_days > 0, do: length(completed) / total_days, else: 0.0

      quality_sum =
        Enum.reduce(completed, 0.0, fn disc, acc ->
          acc + Tiannara.Discovery.DiscoveryScore.composite(disc.score)
        end)

      quality_adjusted = if total_days > 0, do: quality_sum / total_days, else: 0.0

      baseline_throughput = 1.0 / 30.0
      acceleration = if baseline_throughput > 0, do: throughput / baseline_throughput, else: 1.0

      %{
        time_to_discovery_avg: avg_duration,
        throughput_per_day: throughput,
        quality_adjusted_throughput: quality_adjusted,
        acceleration_ratio: acceleration,
        sample_size: length(completed)
      }
    end
  end

  defp compute_total_days(discoveries) do
    timestamps = Enum.map(discoveries, & &1.created_at)
    earliest = Enum.min_by(timestamps, &DateTime.to_unix/1)
    completed_timestamps = Enum.map(discoveries, fn d -> d.completed_at || DateTime.utc_now() end)
    latest = Enum.max_by(completed_timestamps, &DateTime.to_unix/1)
    max(1, DateTime.diff(latest, earliest, :day))
  end
end
