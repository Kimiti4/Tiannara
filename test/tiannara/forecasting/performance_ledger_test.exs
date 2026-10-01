defmodule Tiannara.Forecasting.PerformanceLedgerTest do
  use ExUnit.Case, async: false
  alias Tiannara.Forecasting.PerformanceLedger

  setup do
    case Process.whereis(PerformanceLedger) do
      nil -> {:ok, _} = PerformanceLedger.start_link()
      _ -> :ok
    end
    :ok
  end

  test "records only resolved evidence-backed forecasts" do
    assert :ok = PerformanceLedger.append(%{
      forecast_id: "f-1", model_ref: "model-a", forecast_version: "v1",
      status: :resolved_not_certified, evidence_status: :simulated_observation,
      scores: %{brier: 0.1, log_loss: 0.2, directional_accuracy: 1}})
    assert length(PerformanceLedger.history("model-a", "v1")) == 1
  end

  test "rejects unresolved records" do
    assert {:error, :record_not_resolved} =
      PerformanceLedger.append(%{forecast_id: "f-2", status: :pending})
  end
end
