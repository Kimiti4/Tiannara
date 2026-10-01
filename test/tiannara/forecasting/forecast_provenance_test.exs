defmodule Tiannara.Forecasting.ForecastProvenanceTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.ForecastProvenance

  defp attrs do
    %{forecast_id: "f1", origin: 10, model_id: "m1", model_version: "v1",
      training_window: {0, 10}, feature_ids: ["base"], excluded_signal_ids: ["anomaly"],
      validation: %{method: :rolling_origin}, uncertainty: %{interval: {0, 1}}}
  end

  test "requires complete forecast lineage" do
    assert {:ok, record} = ForecastProvenance.build(attrs())
    assert record.information_boundary == :forecast_origin_only
    assert {:ok, %{status: :auditable}} = ForecastProvenance.audit(record)
  end

  test "rejects a future-information boundary" do
    {:ok, record} = ForecastProvenance.build(attrs())
    assert {:error, :future_information_boundary_violation} =
      ForecastProvenance.audit(%{record | information_boundary: :future_data_used})
  end
end
