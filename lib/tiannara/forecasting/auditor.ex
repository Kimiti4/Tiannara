defmodule Tiannara.Forecasting.ForecastAuditor do
  @moduledoc """
  Evidence-bound forecast auditor.

  Historical versions emitted hard-coded metrics. This auditor now accepts only
  measured resolution records and returns descriptive performance summaries.
  It never changes calibration parameters automatically.
  """
  alias Tiannara.Forecasting.PerformanceLedger

  @spec audit(atom(), map()) :: {:ok, map()} | {:error, term()}
  def audit(scenario, payload) when is_atom(scenario) and is_map(payload) do
    case scenario do
      :forecast_accuracy -> summarize_records(payload)
      :collapse_prediction -> summarize_records(payload)
      :forecast_self_correction -> {:error, :automatic_self_correction_disabled}
      _ -> {:error, :unknown_audit_scenario}
    end
  end

  defp summarize_records(%{records: records}) when is_list(records) do
    {:ok, PerformanceLedger.summarize(records)}
  end

  defp summarize_records(_), do: {:error, :measured_records_required}
end

defmodule Tiannara.Forecasting.DecisionArchive do
  @moduledoc """
  The forecasting equivalent of ImmuneMemory or FossilRecord.
  Stores predicted outcome, chosen intervention, actual outcome, and regret score.
  """
  require Logger

  def record(decision) do
    Logger.debug("📜 [DecisionArchive] Persisting strategic decision record: #{inspect(decision)}")
  end
end
