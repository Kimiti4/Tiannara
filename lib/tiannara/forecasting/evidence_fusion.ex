defmodule Tiannara.Forecasting.EvidenceFusion do
  @moduledoc """
  Evidence-preserving fusion for forecasting.

  Historical frequency is never treated as sufficient by itself. Weak,
  contradictory, anomalous and independent evidence are retained as distinct
  channels so that a dominant base rate cannot silently erase a contrary signal.
  """

  def analyze(base_rate, observations, opts \\ [])
      when is_number(base_rate) and is_list(observations) do
    contradiction_threshold = Keyword.get(opts, :contradiction_threshold, 0.05)

    {contrary, supporting, neutral} =
      Enum.reduce(observations, {[], [], []}, fn observation, {c, s, n} ->
        case Map.get(observation, :direction, :neutral) do
          :contrary -> {[observation | c], s, n}
          :supporting -> {c, [observation | s], n}
          _ -> {c, s, [observation | n]}
        end
      end)

    contradiction_strength =
      contrary
      |> Enum.map(&Map.get(&1, :weight, 0.0))
      |> Enum.filter(&is_number/1)
      |> Enum.sum()

    {:ok, %{
      base_rate: base_rate,
      supporting_evidence: Enum.reverse(supporting),
      contrary_evidence: Enum.reverse(contrary),
      neutral_evidence: Enum.reverse(neutral),
      contradiction_strength: contradiction_strength,
      contradiction_detected: contradiction_strength >= contradiction_threshold,
      status: :requires_joint_evaluation
    }}
  end

  def compare_models(base_rate_result, anomaly_sensitive_result)
      when is_map(base_rate_result) and is_map(anomaly_sensitive_result) do
    {:ok, %{
      base_rate_model: base_rate_result,
      anomaly_sensitive_model: anomaly_sensitive_result,
      comparison: :required_before_forecast_acceptance,
      status: :not_decided
    }}
  end
end
