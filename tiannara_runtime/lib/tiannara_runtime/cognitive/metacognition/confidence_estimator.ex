defmodule TiannaraRuntime.Cognitive.Metacognition.ConfidenceEstimator do
  @moduledoc "Phase 18.8 — Confidence estimation and calibration"

  def estimate(evidence) do
    count = length(evidence)
    quality_count = Enum.count(evidence, fn e -> Map.get(e, :quality, 0.0) > 0.5 end)
    value = if count > 0, do: quality_count / count, else: 0.0
    qualities = Enum.map(evidence, fn e -> Map.get(e, :quality, 0.0) end)
    mean = if count > 0, do: Enum.sum(qualities) / count, else: 0.0
    variance = if count > 1, do: Enum.reduce(qualities, 0.0, fn q, acc -> acc + (q - mean) ** 2 end) / count, else: 0.0
    {:ok, %{value: value, source: :evidence_quality, variance: variance, calibration_error: 0.0, predicted_confidence: value, actual_accuracy: 0.0, calibration_curve: []}}
  end

  def calibrate(outcomes, predictions) do
    predicted_confidence = if predictions == [], do: 0.0, else: Enum.sum(predictions) / length(predictions)
    actual_accuracy = if outcomes == [], do: 0.0, else: Enum.sum(outcomes) / length(outcomes)
    miscalibration = abs(predicted_confidence - actual_accuracy)
    buckets = Enum.map(0..9, fn i ->
      lower = i / 10.0
      upper = (i + 1) / 10.0
      bucket_pairs = Enum.zip(predictions, outcomes) |> Enum.filter(fn {p, _} -> p >= lower and p < upper end)
      bucket_pred = if bucket_pairs == [], do: 0.0, else: Enum.sum(Enum.map(bucket_pairs, fn {p, _} -> p end)) / length(bucket_pairs)
      bucket_actual = if bucket_pairs == [], do: 0.0, else: Enum.sum(Enum.map(bucket_pairs, fn {_, a} -> a end)) / length(bucket_pairs)
      %{bucket: "#{Float.round(lower, 1)}-#{Float.round(upper, 1)}", predicted: bucket_pred, actual: bucket_actual}
    end)
    {:ok, %{predicted_confidence: predicted_confidence, actual_accuracy: actual_accuracy, miscalibration: miscalibration, calibration_curve: buckets, calibrated_at: :erlang.unique_integer([:positive])}}
  end

  def miscalibration_score(calibration) do
    {:ok, Map.get(calibration, :miscalibration, 0.0)}
  end

  def is_calibrated(calibration, threshold) do
    {:ok, Map.get(calibration, :miscalibration, 1.0) <= threshold}
  end
end
