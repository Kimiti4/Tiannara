defmodule Tiannara.Forecasting.EvidenceFusion do
  @moduledoc """
  Evidence-preserving fusion for forecasting.

  Historical frequency is never treated as sufficient by itself. Weak,
  contradictory, anomalous and independent evidence are retained as distinct
  channels so that a dominant base rate cannot silently erase a contrary signal.
  """

  @valid_directions [:supporting, :contrary, :neutral]

  def analyze(base_rate, observations, opts \\ [])
      when is_number(base_rate) and is_list(observations) do
    contradiction_threshold = Keyword.get(opts, :contradiction_threshold, 0.05)

    with :ok <- validate_base_rate(base_rate),
         :ok <- validate_threshold(contradiction_threshold),
         :ok <- validate_observations(observations) do
      {contrary, supporting, neutral} =
        Enum.reduce(observations, {[], [], []}, fn observation, {c, s, n} ->
          case Map.get(observation, :direction, :neutral) do
            :contrary -> {[observation | c], s, n}
            :supporting -> {c, [observation | s], n}
            :neutral -> {c, s, [observation | n]}
          end
        end)

      contradiction_strength =
        contrary
        |> Enum.map(&Map.get(&1, :weight, 0.0))
        |> Enum.sum()

      {:ok, %{
        base_rate: base_rate,
        supporting_evidence: Enum.reverse(supporting),
        contrary_evidence: Enum.reverse(contrary),
        neutral_evidence: Enum.reverse(neutral),
        contradiction_strength: contradiction_strength,
        contradiction_detected: contradiction_strength >= contradiction_threshold,
        status: :requires_joint_evaluation,
        certification_eligible: false
      }}
    end
  end

  def compare_models(base_rate_result, anomaly_sensitive_result)
      when is_map(base_rate_result) and is_map(anomaly_sensitive_result) do
    {:ok, %{
      base_rate_model: base_rate_result,
      anomaly_sensitive_model: anomaly_sensitive_result,
      comparison: :required_before_forecast_acceptance,
      status: :not_decided,
      certification_eligible: false
    }}
  end

  defp validate_base_rate(rate) when rate >= 0 and rate <= 1, do: :ok
  defp validate_base_rate(_), do: {:error, :invalid_base_rate}

  defp validate_threshold(v) when is_number(v) and v >= 0, do: :ok
  defp validate_threshold(_), do: {:error, :invalid_contradiction_threshold}

  defp validate_observations(observations) do
    if Enum.all?(observations, fn observation ->
      is_map(observation) and
        Map.get(observation, :direction, :neutral) in @valid_directions and
        is_number(Map.get(observation, :weight, 0.0)) and
        Map.get(observation, :weight, 0.0) >= 0
    end), do: :ok, else: {:error, :invalid_evidence_observation}
  end
end
