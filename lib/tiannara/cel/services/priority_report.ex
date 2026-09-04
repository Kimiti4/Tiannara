defmodule Tiannara.CEL.Services.PriorityReport do
  defstruct [
    :service_id,
    :prio,
    :confidence_interval,
    :feature_breakdown,
    :prediction_interval,
    :evidence_count,
    :signals_in_window,
    :calibration,
    :drift_detected,
    :recommendation,
    :computed_at
  ]

  def explain(report) do
    features = report.feature_breakdown || %{}

    lines = [
      "PriorityEngine v2 Report for #{report.service_id}",
      "  Priority Score: #{Float.round(report.prio, 4)}",
      "  95% CI: [#{Float.round(elem(report.confidence_interval, 0), 4)}, #{Float.round(elem(report.confidence_interval, 1), 4)}]",
      "  Evidence: #{report.evidence_count} signals in window (#{report.signals_in_window} total)",
      "  Calibration: #{Float.round(report.calibration * 100, 1)}%",
      "  Drift: #{if report.drift_detected, do: "DETECTED", else: "none"}",
    ]

    feature_lines = if map_size(features) > 0 do
      ["  Feature Contributions:"] ++
        Enum.map(features, fn {k, v} ->
          "    #{k}: #{Float.round(v, 4)}"
        end)
    else
      ["  Feature Contributions: (none)"]
    end

    rec_line = ["  Recommendation: #{report.recommendation}"]

    Enum.join(lines ++ feature_lines ++ rec_line, "\n")
  end
end
