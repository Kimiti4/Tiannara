defmodule Tiannara.Forecasting.ForecastRegistryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Forecast, ForecastRegistry}

  setup do
    start_supervised!(ForecastRegistry)
    :ets.delete_all_objects(:efdi_forecast_registry)
    :ok
  end

  defp forecast(question \\ "Q", probs \\ [0.7, 0.3]) do
    Forecast.new(question: question, event: "evt", outcomes: ["yes", "no"],
                 probabilities: probs, horizon: 30, forecast_version: 1)
  end

  describe "register/1" do
    test "registers and retrieves a forecast by id" do
      f = forecast()
      assert {:ok, stored} = ForecastRegistry.register(f)
      assert stored.id == f.id
      assert {:ok, fetched} = ForecastRegistry.get(f.id)
      assert fetched.id == f.id
      assert fetched.forecast_version == 1
    end

    test "registering the same forecast id is a no-op (immutable)" do
      f = forecast()
      assert {:ok, _} = ForecastRegistry.register(f)
      assert {:ok, _} = ForecastRegistry.register(%{f | probabilities: [0.99, 0.01]})
      assert {:ok, fetched} = ForecastRegistry.get(f.id)
      assert fetched.probabilities == [0.7, 0.3]
    end

    test "count/0 reflects registrations" do
      assert ForecastRegistry.count() == 0
      {:ok, _} = ForecastRegistry.register(forecast("q1"))
      {:ok, _} = ForecastRegistry.register(forecast("q2"))
      assert ForecastRegistry.count() == 2
    end

    test "all_ids/0 returns registered forecast ids" do
      {:ok, f1} = ForecastRegistry.register(forecast("a"))
      {:ok, f2} = ForecastRegistry.register(forecast("b"))
      assert Enum.sort(ForecastRegistry.all_ids()) == Enum.sort([f1.id, f2.id])
    end

    test "rejects invalid forecasts (missing question)" do
      bad = Forecast.new(outcomes: ["yes", "no"], probabilities: [0.5, 0.5])
      assert {:error, :missing_question} = ForecastRegistry.register(bad)
    end
  end

  describe "get/1" do
    test "returns :error for unknown id" do
      assert :error = ForecastRegistry.get("nope")
    end
  end

  describe "health/0" do
    test "reports registry health" do
      h = ForecastRegistry.health()
      assert h.ets_available == true
      assert h.eventstore_degraded in [true, false]
    end
  end
end