defmodule Tiannara.Integration.ViewModel do
  @moduledoc """
  View model assembled from a RunContext for dashboard rendering.
  """

  defstruct [
    :funnel,
    :manifest,
    :observatory,
    :knowledge,
    :funnel_counts,
    :observatory_summary
  ]

  def build(opts) do
    funnel = Keyword.get(opts, :funnel)
    manifest = Keyword.get(opts, :manifest)
    observatory = Keyword.get(opts, :observatory)
    knowledge = Keyword.get(opts, :knowledge)

    %__MODULE__{
      funnel: funnel,
      manifest: manifest,
      observatory: observatory,
      knowledge: knowledge,
      funnel_counts: count_funnel(funnel),
      observatory_summary: summarize_observatory(observatory)
    }
  end

  defp count_funnel(nil), do: %{}

  defp count_funnel(events) do
    Enum.frequencies_by(events, fn
      {:created, stage, _id, _} -> stage
      {:disposition, stage, _id, _action, _target} -> stage
      other -> elem(other, 0)
    end)
  end

  defp summarize_observatory(nil), do: %{}
  defp summarize_observatory(samples) do
    throughputs = Enum.map(samples, &Map.get(&1, :event_throughput, 0))
    latencies = Enum.map(samples, &Map.get(&1, :discovery_cycle_latency, 0))

    %{
      samples: length(samples),
      avg_event_throughput: avg(throughputs),
      avg_discovery_cycle_latency: avg(latencies)
    }
  end

  defp avg([]), do: 0.0
  defp avg(values), do: Enum.sum(values) / length(values)
end