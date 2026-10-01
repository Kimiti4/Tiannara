defmodule Tiannara.Forecasting.ForecastIntegrityTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{Forecast, ForecastIntegrity}

  test "valid forecast passes structural integrity" do
    f = Forecast.new(
      question: "Q",
      event: "E",
      outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3],
      uncertainty: :measured,
      assumptions: [],
      created_at: DateTime.utc_now()
    )

    assert {:ok, report} = ForecastIntegrity.audit(f)
    assert report.status == :pass
  end

  test "future data cutoff is rejected" do
    created = DateTime.utc_now()
    f = Forecast.new(
      question: "Q",
      event: "E",
      outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3],
      created_at: created,
      context: %{data_cutoff: DateTime.add(created, 60, :second)}
    )

    assert {:error, :temporal_cutoff_violation} = Forecast.validate(f)
    refute ForecastIntegrity.temporal_consistent?(f)
  end
end
