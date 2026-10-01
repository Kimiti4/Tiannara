defmodule Tiannara.Forecasting.LineageTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{Lineage, Signal}

  test "connects validated signal provenance to forecast lineage" do
    signal = Signal.new(%{source: :sensor_a, observation: 42, timestamp: ~U[2026-01-01 00:00:00Z]})
    attrs = %{forecast_id: "f1", origin: ~U[2026-01-02 00:00:00Z], model_id: "m1",
      model_version: "v1", training_window: {~U[2025-01-01 00:00:00Z], ~U[2026-01-01 00:00:00Z]},
      feature_ids: [signal.id], excluded_signal_ids: [], validation: %{method: :rolling_origin},
      uncertainty: %{interval: {0, 1}}}
    assert {:ok, forecast} = Lineage.build_forecast(attrs, [signal])
    assert {:ok, audit} = Lineage.audit(forecast)
    assert audit.status == :lineage_auditable
    assert audit.signal_count == 1
  end

  test "rejects malformed signal lineage" do
    attrs = %{forecast_id: "f1", origin: 1, model_id: "m1", model_version: "v1",
      training_window: {0, 1}, feature_ids: [], excluded_signal_ids: [],
      validation: %{}, uncertainty: %{}}
    assert {:error, :invalid_signal_lineage} = Lineage.build_forecast(attrs, [%{}])
  end
end
