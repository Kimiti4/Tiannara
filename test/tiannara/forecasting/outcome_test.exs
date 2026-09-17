defmodule Tiannara.Forecasting.OutcomeTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Forecast, Outcome}

  defp forecast(created_at) do
    Forecast.new(question: "Q", event: "evt", outcomes: ["yes", "no"],
                 probabilities: [0.7, 0.3], created_at: created_at)
  end

  describe "new/3" do
    test "creates an outcome linked to a forecast id" do
      o = Outcome.new("forecast_1", "yes", observed_at: ~U[2026-09-01 12:00:00Z], source: "event_store")
      assert o.forecast_id == "forecast_1"
      assert o.observed_outcome == "yes"
      assert o.source == "event_store"
      assert is_binary(o.id)
    end

    test "defaults source to event_store" do
      o = Outcome.new("f1", "no")
      assert o.source == "event_store"
    end
  end

  describe "hindsight_clean?/2" do
    test "an observation after forecast creation is clean" do
      f = forecast(~U[2026-01-01 00:00:00Z])
      o = Outcome.new(f.id, "yes", observed_at: ~U[2026-03-01 00:00:00Z])
      assert Outcome.hindsight_clean?(o, f)
    end

    test "an observation before forecast creation is contaminated" do
      f = forecast(~U[2026-06-01 00:00:00Z])
      o = Outcome.new(f.id, "yes", observed_at: ~U[2026-03-01 00:00:00Z])
      refute Outcome.hindsight_clean?(o, f)
    end

    test "an observed_at equal to forecast creation is clean (boundary)" do
      t = ~U[2026-05-05 05:05:05Z]
      f = forecast(t)
      o = Outcome.new(f.id, "yes", observed_at: t)
      assert Outcome.hindsight_clean?(o, f)
    end

    test "nil observation time is treated as clean (cannot prove contamination)" do
      f = forecast(~U[2026-01-01 00:00:00Z])
      o = Outcome.new(f.id, "yes")
      assert Outcome.hindsight_clean?(o, f)
    end
  end

  describe "guard!/2" do
    test "returns {:ok, outcome} for clean linkage" do
      f = forecast(~U[2026-01-01 00:00:00Z])
      o = Outcome.new(f.id, "yes", observed_at: ~U[2026-03-01 00:00:00Z])
      assert {:ok, ^o} = Outcome.guard!(o, f)
    end

    test "rejects hindsight contamination" do
      f = forecast(~U[2026-06-01 00:00:00Z])
      o = Outcome.new(f.id, "yes", observed_at: ~U[2026-03-01 00:00:00Z])
      assert {:error, :hindsight_contamination} = Outcome.guard!(o, f)
    end
  end
end