defmodule Tiannara.Sentinel.AnomalyDetector do
  @moduledoc """
  Detects anomalies in telemetry signals across all Tiannara subsystems.
  Categorizes anomalies into Type A-G as defined in the Sentinel architecture.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Analyzes a telemetry signal for anomalies.
  """
  def analyze(subsystem, signal_type, data) do
    GenServer.cast(__MODULE__, {:analyze, subsystem, signal_type, data})
  end

  @doc """
  Synchronously detects anomalies by comparing observations against a world model.
  Returns a detection_result map with anomalies, explanations, confidence, at-risk designs, and actions.
  """
  @spec detect_anomalies(map(), [map()], float()) :: map()
  def detect_anomalies(world_model, observations, threshold \\ 10.0) do
    predictions = Map.get(world_model, :predictions, [])
    designs = Map.get(world_model, :designs, [])

    anomalies =
      observations
      |> Enum.flat_map(fn obs ->
        obs_key = Map.get(obs, :key, Map.get(obs, :metric))
        obs_value = Map.get(obs, :value, 0.0)

        predictions
        |> Enum.filter(fn pred -> Map.get(pred, :key, Map.get(pred, :metric)) == obs_key end)
        |> Enum.map(fn pred ->
          predicted = Map.get(pred, :value, 0.0)
          deviation = calculate_deviation(obs_value, predicted)
          {obs, pred, deviation}
        end)
      end)
      |> Enum.filter(fn {_obs, _pred, deviation} -> abs(deviation) >= threshold end)
      |> Enum.map(fn {obs, pred, deviation} ->
        severity = classify_severity(deviation, threshold)
        key = Map.get(obs, :key, Map.get(obs, :metric))

        %{
          key: key,
          observed: Map.get(obs, :value, 0.0),
          predicted: Map.get(pred, :value, 0.0),
          deviation_percent: Float.round(deviation, 2),
          severity: severity,
          timestamp: Map.get(obs, :timestamp, DateTime.utc_now())
        }
      end)

    anomaly_keys = anomalies |> Enum.map(& &1.key) |> Enum.uniq()

    explanations =
      anomaly_keys
      |> Enum.flat_map(fn key ->
        generate_explanations(key, anomalies, world_model)
      end)

    at_risk = identify_at_risk_designs(designs, anomaly_keys, world_model)

    recommended_actions = generate_recommended_actions(anomalies, explanations)

    confidence = calculate_confidence(anomalies, predictions, observations)

    %{
      anomalies_detected: anomalies,
      explanations: explanations,
      confidence: confidence,
      at_risk_designs: at_risk,
      recommended_actions: recommended_actions
    }
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [SENTINEL] AnomalyDetector initialized.")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:analyze, subsystem, signal_type, data}, state) do
    case detect_anomaly(subsystem, signal_type, data) do
      {:ok, anomaly} ->
        Logger.warning("🚨 [SENTINEL] Anomaly Detected: #{anomaly.type} in #{subsystem}!")
        Tiannara.Sentinel.ImmuneCoordinator.triage(anomaly)
      :none ->
        :ok
    end

    {:noreply, state}
  end

  # Private Helpers

  defp detect_anomaly(:mscl, :pressure, %{value: value}) when value > 0.95 do
    {:ok, %{type: :type_a, subsystem: :mscl, severity: :high, details: "Pressure threshold exceeded: #{value}"}}
  end

  defp detect_anomaly(:grcc, :diversity, %{entropy: entropy}) when entropy < 0.2 do
    {:ok, %{type: :type_b, subsystem: :grcc, severity: :critical, details: "Ecological monoculture detected: entropy=#{entropy}"}}
  end

  defp detect_anomaly(:ctl, :consistency, %{divergence: divergence}) when divergence > 0.5 do
    {:ok, %{type: :type_c, subsystem: :ctl, severity: :high, details: "Causal divergence detected: #{divergence}"}}
  end

  defp detect_anomaly(_subsystem, _signal_type, _data), do: :none

  defp calculate_deviation(_observed, +0.0), do: 0.0

  defp calculate_deviation(_observed, -0.0), do: 0.0

  defp calculate_deviation(observed, predicted) do
    ((observed - predicted) / abs(predicted)) * 100.0
  end

  defp classify_severity(deviation, threshold) do
    abs_dev = abs(deviation)
    abs_thresh = abs(threshold)

    cond do
      abs_dev >= 4.0 * abs_thresh -> :critical
      abs_dev >= 2.0 * abs_thresh -> :high
      abs_dev >= abs_thresh -> :medium
      true -> :low
    end
  end

  defp generate_explanations(key, anomalies, world_model) do
    key_anomalies = Enum.filter(anomalies, &(&1.key == key))

    primary = Enum.find(key_anomalies, fn a -> a.severity in [:critical, :high] end) ||
              List.first(key_anomalies)

    trend = Map.get(world_model, :trend_data, %{})
    trend_direction = Map.get(trend, key, :unknown)

    explanation_a = %{
      anomaly_key: key,
      explanation_id: :measurement_drift,
      description: "Sensor calibration drift or measurement artifact in #{key} readings",
      likelihood: 0.35,
      evidence: build_evidence("measurement_drift", primary, trend_direction),
      testable: true,
      suggested_test: "Deploy redundant sensor and cross-calibrate against reference standard"
    }

    explanation_b = %{
      anomaly_key: key,
      explanation_id: :systemic_phase_transition,
      description: "Underlying system entering a phase transition affecting #{key} dynamics",
      likelihood: 0.28,
      evidence: build_evidence("phase_transition", primary, trend_direction),
      testable: true,
      suggested_test: "Monitor higher-order statistics and variance for non-stationarity indicators"
    }

    explanation_c = %{
      anomaly_key: key,
      explanation_id: :coupled_feedback_loop,
      description: "Coupled feedback loop from correlated subsystem amplifying #{key} deviation",
      likelihood: 0.22,
      evidence: build_evidence("feedback_loop", primary, trend_direction),
      testable: true,
      suggested_test: "Isolate the variable and measure response without feedback coupling"
    }

    [explanation_a, explanation_b, explanation_c]
  end

  defp build_evidence(kind, anomaly, trend_direction) do
    severity = if anomaly, do: anomaly.severity, else: :unknown
    deviation = if anomaly, do: anomaly.deviation_percent, else: 0.0

    %{
      mechanism: kind,
      severity_observed: severity,
      deviation_magnitude: deviation,
      trend_alignment: trend_alignment(kind, trend_direction),
      historical_precedent_count: precedent_count(kind)
    }
  end

  defp trend_alignment("phase_transition", direction) when direction in [:accelerating, :nonlinear], do: :consistent
  defp trend_alignment("feedback_loop", direction) when direction in [:oscillating, :divergent], do: :consistent
  defp trend_alignment(_, :stable), do: :inconsistent
  defp trend_alignment(_, _), do: :inconclusive

  defp precedent_count("measurement_drift"), do: 14
  defp precedent_count("phase_transition"), do: 7
  defp precedent_count("feedback_loop"), do: 11
  defp precedent_count(_), do: 0

  defp identify_at_risk_designs([], _anomaly_keys, _world_model), do: []

  defp identify_at_risk_designs(designs, anomaly_keys, world_model) do
    dependencies = Map.get(world_model, :design_dependencies, %{})

    Enum.filter(designs, fn design ->
      design_name = Map.get(design, :name, Map.get(design, :id))
      deps = Map.get(dependencies, design_name, [])
      Enum.any?(deps, fn dep -> dep in anomaly_keys end)
    end)
    |> Enum.map(fn design ->
      design_name = Map.get(design, :name, Map.get(design, :id))
      deps = Map.get(dependencies, design_name, [])
      affected = Enum.filter(deps, fn dep -> dep in anomaly_keys end)
      count = length(affected)

      {risk_level, recommendation} =
        if count >= 2, do: {:high, :suspend}, else: {:medium, :monitor}

      %{
        design: design_name,
        affected_dependencies: affected,
        risk_level: risk_level,
        recommendation: recommendation
      }
    end)
  end

  defp generate_recommended_actions(anomalies, explanations) do
    critical = Enum.filter(anomalies, &(&1.severity == :critical))
    high = Enum.filter(anomalies, &(&1.severity == :high))

    immediate_actions =
      if length(critical) > 0 do
        keys = critical |> Enum.map(& &1.key) |> Enum.uniq()

        Enum.map(keys, fn key ->
          %{
            priority: :immediate,
            action: "Halt dependent operations and isolate #{key} subsystem",
            affected_key: key,
            rationale: "Critical deviation detected (#{(Enum.find(critical, &(&1.key == key)) || %{}).deviation_percent}%)",
            timeout: "1 hour"
          }
        end)
      else
        []
      end

    investigation_actions =
      if length(high) > 0 or length(critical) > 0 do
        keys = (high ++ critical) |> Enum.map(& &1.key) |> Enum.uniq()

        Enum.map(keys, fn key ->
          relevant_explanations = Enum.filter(explanations, &(&1.anomaly_key == key))
          top_explanation = Enum.max_by(relevant_explanations, & &1.likelihood, fn -> nil end)

          %{
            priority: :high,
            action: "Run diagnostic: #{(top_explanation || %{}).suggested_test || "investigate #{key}"}",
            affected_key: key,
            rationale: "Deviation of #{(Enum.find(high ++ critical, &(&1.key == key)) || %{}).deviation_percent}% requires root-cause analysis",
            timeout: "24 hours"
          }
        end)
      else
        []
      end

    monitoring_actions =
      anomalies
      |> Enum.map(& &1.key)
      |> Enum.uniq()
      |> Enum.map(fn key ->
        %{
          priority: :ongoing,
          action: "Increase monitoring frequency for #{key} to 10x baseline",
          affected_key: key,
          rationale: "Anomalous behavior requires elevated surveillance",
          timeout: "until stabilization confirmed"
        }
      end)

    immediate_actions ++ investigation_actions ++ monitoring_actions
  end

  defp calculate_confidence(anomalies, predictions, observations) do
    total_predictions = max(length(predictions), 1)
    total_observations = max(length(observations), 1)
    anomaly_count = length(anomalies)

    coverage = Enum.min([length(predictions) / total_observations, 1.0])
    anomaly_ratio = anomaly_count / total_predictions
    severity_penalty = Enum.reduce(anomalies, 0.0, fn a, acc ->
      penalty = case a.severity do
        :critical -> 0.05
        :high -> 0.03
        :medium -> 0.01
        :low -> 0.005
      end
      acc + penalty
    end)

    base_confidence = 0.90 * coverage
    anomaly_confidence = max(0.0, base_confidence - anomaly_ratio * 0.3)
    max(0.01, Float.round(anomaly_confidence - severity_penalty, 4))
  end
end
