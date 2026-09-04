defmodule Tiannara.MetaScience.BottleneckDetector do
  @moduledoc """
  Actively searches for bottlenecks in the discovery pipeline.
  Emits telemetry to the passive Observatory for display.
  """

  def analyze_pipeline(domain_metrics) do
    stalled =
      Enum.filter(domain_metrics, fn m ->
        m.hypotheses_generated > 50 and m.experiments_completed < 2
      end)

    if stalled != [] do
      :telemetry.execute(
        [:tiannara, :meta_science, :bottleneck],
        %{affected_domains: stalled, severity: :high},
        %{type: :discovery_stall}
      )

      {:warning, :discovery_stall, stalled}
    else
      {:ok, :healthy}
    end
  end
end
