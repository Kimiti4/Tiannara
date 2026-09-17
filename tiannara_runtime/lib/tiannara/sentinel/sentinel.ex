defmodule Tiannara.Sentinel do
  @moduledoc """
  The top-level public API for the Tiannara Sentinel runtime epistemology service.
  This allows the existing dashboard to consume Sentinel APIs without a bespoke visualization layer.
  """

  alias Tiannara.Sentinel.Contracts.Forecast

  @doc "Retrieves a high-level health snapshot from the Sentinel."
  def health_snapshot do
    # Delegate to internal services
    %{status: :ok, message: "Phase A.5 Active: Baseline Learning"}
  end

  @doc "Lists currently active or recent anomalies."
  def active_anomalies do
    # Delegate to AnomalyDetector
    []
  end

  @doc "Returns the latest forecast summary regarding runtime collapse risk."
  def forecast_summary do
    # Delegate to CollapseForecaster
    %Forecast{
      id: "fc_initial",
      target: :runtime,
      risk_level: :info,
      confidence: 1.0,
      contributing_factors: %{},
      timestamp: System.system_time(:second)
    }
  end

  @doc "Returns the current ecological entropy value."
  def runtime_entropy do
    # Delegate to EntropyTracker
    0.0
  end

  @doc "Returns the current MSCL/OLEF pressure metric."
  def runtime_pressure do
    # Delegate to PressureMonitor
    0.0
  end

  @doc "Returns pending Phase B1 interventions."
  def pending_recommendations do
    Tiannara.Sentinel.Immune.StabilizationAuditor.get_pending()
  end

  @doc "Returns the immutable history of all formulated recommendations."
  def recommendation_history do
    Tiannara.Sentinel.Immune.StabilizationAuditor.get_history()
  end

  @doc "Returns Sentinel's empirical effectiveness metrics."
  def effectiveness_report do
    Tiannara.Sentinel.Immune.RecommendationScorer.get_effectiveness_report()
  end

  @doc "Returns Sentinel's ESG Replay Engine accuracy metrics for Phase C readiness."
  def esg_replay_accuracy do
    Tiannara.Sentinel.Shadow.ReplayMetrics.get_accuracy_report()
  end

  @doc "Returns Sentinel's ESG Epistemic Simulation accuracy metrics for Phase C.1A."
  def shadow_accuracy_report do
    Tiannara.Sentinel.Shadow.ShadowMetrics.get_accuracy_report()
  end

  @doc "Runs the Phase D.0 Certification Suite for Observatory Mesh."
  def run_certification_suite do
    report = Tiannara.Sentinel.Validation.ConsensusBenchmark.run_suite(500)
    Tiannara.Sentinel.Validation.ValidationState.set_report(report)
    report
  end

  @doc "Returns the Phase D.0 validation report if it has been run."
  def validation_report do
    Tiannara.Sentinel.Validation.ValidationState.get_report()
  end

  @doc "Returns the mesh certification status and advanced reporting."
  def certification_status do
    case validation_report() do
      nil -> %{certification_status: :untested, reason: "Certification suite not run."}
      report -> 
        # Mesh Graduation Requirements
        certified = 
          report.benchmark_cases >= 500 and
          report.consensus_advantage > 0.0

        status = if certified, do: :passed, else: :failed
          
        %{
          certification_status: status,
          benchmark_cases: report.benchmark_cases,
          consensus_advantage: report.consensus_advantage,
          best_single_accuracy: report.best_single_accuracy,
          consensus_accuracy: report.consensus_accuracy,
          disagreement_resolution_accuracy: report.disagreement_resolution_accuracy,
          monoculture_detection_rate: report.monoculture_detection_rate,
          adversarial_suite_pass_rate: report.adversarial_suite_pass_rate,
          observatories_certified: Map.keys(report.observatory_accuracies)
        }
    end
  end

  @doc "Returns the live Observatory Mesh health and metrics (Phase D.1)."
  def observatory_report do
    Tiannara.Sentinel.Observatories.Core.HealthReport.observatory_report()
  end
end
