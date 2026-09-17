defmodule Tiannara.RRG.ExposureTracker do
  @moduledoc """
  Exposure Tracker - Tracks observer exposure to ontological concepts to prevent overload.
  """

  defstruct [
    :observer_id,
    :seen_ctn_patterns,
    :anomaly_saturation,
    :collapse_risk_index,
    :exposure_entropy,
    :last_updated
  ]

  def new(observer_id) do
    %__MODULE__{
      observer_id: observer_id,
      seen_ctn_patterns: MapSet.new(),
      anomaly_saturation: 0.0,
      collapse_risk_index: 0.0,
      exposure_entropy: 0.0,
      last_updated: System.system_time(:millisecond)
    }
  end

  def record_ctn_pattern(exposure_tracker, pattern) do
    updated_patterns = MapSet.put(exposure_tracker.seen_ctn_patterns, pattern)
    %{exposure_tracker | seen_ctn_patterns: updated_patterns, last_updated: System.system_time(:millisecond)}
  end

  def increment_anomaly_saturation(exposure_tracker, amount \\ 0.1) when is_number(amount) do
    new_saturation = min(1.0, exposure_tracker.anomaly_saturation + amount)
    %{exposure_tracker | anomaly_saturation: new_saturation, last_updated: System.system_time(:millisecond)}
  end

  def reset_anomaly_saturation(exposure_tracker) do
    %{exposure_tracker | anomaly_saturation: 0.0, last_updated: System.system_time(:millisecond)}
  end

  def update_collapse_risk(exposure_tracker, risk_level) when is_number(risk_level) do
    clamped_risk = max(0.0, min(1.0, risk_level))
    %{exposure_tracker | collapse_risk_index: clamped_risk, last_updated: System.system_time(:millisecond)}
  end

  def update_exposure_entropy(exposure_tracker, entropy) when is_number(entropy) do
    %{exposure_tracker | exposure_entropy: entropy, last_updated: System.system_time(:millisecond)}
  end

  def is_at_risk?(exposure_tracker, threshold \\ 0.7) do
    exposure_tracker.collapse_risk_index > threshold
  end

  def is_overloaded?(exposure_tracker, saturation_threshold \\ 0.8) do
    exposure_tracker.anomaly_saturation > saturation_threshold
  end

  def get_exposure_stats(exposure_tracker) do
    %{
      total_patterns: MapSet.size(exposure_tracker.seen_ctn_patterns),
      anomaly_saturation: exposure_tracker.anomaly_saturation,
      collapse_risk: exposure_tracker.collapse_risk_index,
      exposure_entropy: exposure_tracker.exposure_entropy
    }
  end

  def clear_old_patterns(exposure_tracker, retention_hours \\ 24) do
    # In a real implementation, we would remove patterns older than retention_hours
    # For now, just return the tracker unchanged
    %{exposure_tracker | last_updated: System.system_time(:millisecond)}
  end
end
