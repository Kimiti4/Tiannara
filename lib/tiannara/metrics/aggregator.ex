defmodule Tiannara.Metrics.Aggregator do
  @moduledoc """
  Subscribes to telemetry events and updates the current Snapshot state.
  """
  use GenServer
  require Logger
  alias Tiannara.Metrics.Snapshot

  def start_link(_opts), do: GenServer.start_link(__MODULE__, Snapshot.new(), name: __MODULE__)

  def init(initial_state) do
    # In a real app we would use :telemetry.attach
    # For now we provide a direct cast interface for subsystems to push events
    Logger.info("📊 [Metrics.Aggregator] Initialized.")
    {:ok, initial_state}
  end

  @doc """
  Pushes a telemetry event. E.g. push_event([:tiannara, :grcc, :entropy], 0.85)
  """
  def push_event(event_path, value) do
    GenServer.cast(__MODULE__, {:telemetry_event, event_path, value})
  end

  def get_snapshot do
    GenServer.call(__MODULE__, :get_snapshot)
  end

  def handle_cast({:telemetry_event, [:tiannara, :ctl, :causal_stress], value}, state) do
    {:noreply, %{state | reconciliation_load: value}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :ocm, :semantic_drift], value}, state) do
    {:noreply, %{state | semantic_drift: value}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :ocm, :ontology_diversity], _value}, state) do
    {:noreply, state} # Could add to snapshot if needed
  end
  def handle_cast({:telemetry_event, [:tiannara, :twp, metric], _value}, state) when metric in [:compression_ratio, :information_loss, :resurrection_rate, :timeline_diversity, :orbit_fidelity, :precedent_recovery_rate] do
    # Log or track these TWP metrics in the future if needed in Snapshot
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :cis, metric], _value}, state) when metric in [
    :immune_precision, :immune_recall, :false_positive_rate, :containment_time, :recovery_time, 
    :intervention_effectiveness, :adaptive_response_gain, :innovation_preservation_rate, 
    :immune_memory_strength, :governance_capture_detection, :collapse_probability
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :mirror, metric], _value}, state) when metric in [
    :risk_detection_accuracy, :collapse_prediction_lead_time, :mirror_fidelity, 
    :topology_accuracy, :false_alarm_rate, :model_drift_rate, 
    :unknown_structure_detection, :prediction_calibration, :dependency_visibility
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :forecasting, metric], _value}, state) when metric in [
    :forecast_accuracy, :brier_score, :prediction_calibration, :collapse_prediction_accuracy,
    :lead_time, :intervention_effectiveness, :regret_score, :simulation_divergence,
    :forecast_stability, :adaptive_calibration_gain, :black_swan_resilience,
    :forecast_confidence_accuracy, :intervention_restraint_score
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :governance, metric], _value}, state) when metric in [
    :resolution_quality, :federation_recovery_time, :containment_success_rate,
    :priority_allocation_efficiency, :forecast_integration_gain, :teleological_preservation_score,
    :deadlock_resolution_time, :governance_capture_resistance, :forecast_skepticism_score,
    :constitutional_consistency, :federation_scaling_efficiency
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :discovery, metric], _value}, state) when metric in [
    :rediscovery_rate, :false_discovery_rate, :cross_domain_transfer_efficiency,
    :precedent_utilization, :discovery_preservation_score, :research_roi,
    :replication_accuracy, :novelty_bias, :discovery_diversity,
    :confidence_calibration, :deep_time_survival
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :archaeology, metric], _value}, state) when metric in [
    :fossil_recovery_rate, :semantic_reconstruction_accuracy, :epoch_compression_fidelity,
    :historical_retrieval_accuracy, :recursive_compression_survival, :civilizational_identity_continuity,
    :multi_era_recovery_score
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :coherence, metric], _value}, state) when metric in [
    :deep_time_anchor_stability, :epistemic_entropy_level, :cross_epoch_fidelity
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :iv, metric], _value}, state) when metric in [
    :interaction_integrity, :cross_system_resilience, :integration_coverage, :systemic_coherence
  ] do
    {:noreply, state}
  end
  def handle_cast({:telemetry_event, [:tiannara, :grcc, :entropy], value}, state) do
    {:noreply, %{state | entropy: value}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :cis, :collapse_probability], value}, state) do
    {:noreply, %{state | collapse_probability: value}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :orbit, :transition], value}, state) do
    {:noreply, %{state | current_orbit: value}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :research, :theory, :validated], _value}, state) do
    {:noreply, %{state | theory_validation_rate: state.theory_validation_rate + 0.1}}
  end
  def handle_cast({:telemetry_event, [:tiannara, :domain, :capital, :updated], value}, state) do
    {:noreply, %{state | knowledge_capital: value}}
  end
  def handle_cast({:telemetry_event, _event, _value}, state) do
    # Fallback for unmapped telemetry events
    {:noreply, state}
  end

  def handle_call(:get_snapshot, _from, state) do
    {:reply, state, state}
  end
end
