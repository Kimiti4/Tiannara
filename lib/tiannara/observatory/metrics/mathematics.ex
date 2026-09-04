defmodule Tiannara.Observatory.Metrics.Mathematics do
  def attach_telemetry do
    :telemetry.attach("tiannara-math-metrics", [:tiannara, :math, :operation], &handle_event/4, nil)
  end

  def handle_event([:tiannara, :math, :operation], measurements, metadata, _config) do
    :ets.insert(:tiannara_math_metrics, {{metadata.module, metadata.operation}, measurements.duration})
  end

  def get_dashboard_data do
    {:error, :mathematics_dashboard_unavailable}
  end
end
