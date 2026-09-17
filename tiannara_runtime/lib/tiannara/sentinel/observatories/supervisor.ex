defmodule Tiannara.Sentinel.Observatories.Supervisor do
  @moduledoc """
  Phase D.1: Passive Observatory Mesh Supervisor.
  
  CRITICAL: This supervisor does NOT start any processes that can:
  - Modify Intervention contracts
  - Call RecommendationEngine
  - Access ShadowForkManager
  - Influence runtime execution
  
  Observatories generate evidence ONLY.
  """
  use Supervisor
  require Logger
  alias Tiannara.Sentinel.Observatories.Core.HealthReport

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.Sentinel.Observatories.Core.ReliabilityTracker, []},
      {Tiannara.Sentinel.Observatories.Core.MetricsCollector, []},
      {Tiannara.Sentinel.Observatories.Core.AlignmentTracker, []},
      {Tiannara.Sentinel.Observatories.Core.ObservatoryArchive, []},
      {Tiannara.Sentinel.Observatories.Specialized.RuntimeObservatory, []},
      {Tiannara.Sentinel.Observatories.Specialized.EcologicalObservatory, []},
      {Tiannara.Sentinel.Observatories.Specialized.SemanticObservatory, []},
      {Tiannara.Sentinel.Observatories.SignalRouter, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def active_observatories do
    [:runtime, :ecological, :semantic]
  end

  @doc """
  PHASE D.1A SAFETY: Explicitly blocks promotion to D.2 until criteria are met.
  """
  @spec promote_to_d2() :: {:ok, :promoted} | {:error, :criteria_not_met, list()}
  def promote_to_d2 do
    report = HealthReport.observatory_report()
    
    if report.promotion_gate.d2_ready do
      Logger.info("✅ [D.1→D.2] Promotion criteria met. Observatory mesh ready for decision influence.")
      {:ok, :promoted}
    else
      Logger.warning("⚠️ [D.1→D.2] Promotion blocked. Failed conditions: #{inspect(report.promotion_gate.failed_conditions)}")
      {:error, :criteria_not_met, report.promotion_gate.failed_conditions}
    end
  end

  defp count_trusted(observatories) do
    observatories |> Map.values() |> Enum.count(&(&1.status == :trusted))
  end

  defp avg_calibration_error(observatories) do
    if map_size(observatories) == 0 do
      1.0
    else
      sum = observatories |> Map.values() |> Enum.map(& &1.calibration_error) |> Enum.sum()
      sum / map_size(observatories)
    end
  end

  defp get_disagreement_archive_count do
    0 # Placeholder
  end
end
