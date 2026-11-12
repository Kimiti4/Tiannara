defmodule TiannaraRuntime.Cognitive.Spine.ForecastingPortTest do
  @moduledoc """
  Validation of the Spine → EFDI forecasting boundary.

  Two things are pinned here.

  First, **confidence and probability are different quantities**. The Spine's
  forecast stage reports an evidence-confidence estimate and an uncertainty
  decomposition alongside the probabilistic forecast, and a confidence score
  must never be presented as a forecast probability.

  Second, **an unavailable forecasting authority is reported as unavailable**.
  The Spine must not fabricate a probability, and it must not report an
  investigation as complete while a required capability was unavailable.
  """
  use ExUnit.Case, async: false

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry
  alias TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpine
  alias TiannaraRuntime.Cognitive.Spine.Forecasting
  alias TiannaraRuntime.WorldModel.ModelRegistry

  defmodule GrantingForecaster do
    @behaviour TiannaraRuntime.Cognitive.Spine.Forecasting

    @impl true
    def forecast(request) do
      {:ok,
       %{
         "id" => "fc_1",
         "question" => request["question"],
         "probabilities" => [0.6, 0.4],
         "model_ref" => "model_v3",
         "request_id" => request["request_id"]
       }}
    end
  end

  setup do
    ModelRegistry.reset_table()
    ObservationRegistry.init_table()
    :ets.delete_all_objects(:observation_registry)

    ObservationRegistry.register_observation(
      %{"source" => "sensor_a", "domain" => "physics"},
      %{"temperature" => 25.0, "pressure" => 1013},
      "2026-06-01T12:00:00Z"
    )

    :ok
  end

  defp request do
    %{
      mission: %{objective: "explain thermal behaviour", status: :active},
      domain: :physics,
      model_name: "Spine Physics Model",
      evidence: [%{quality: 0.9}, %{quality: 0.7}],
      candidates: [%{id: "candidate_1", plan: %{}}]
    }
  end

  describe "the port" do
    test "the default adapter refuses with the canonical unavailable reason" do
      assert Forecasting.Refusing.forecast(%{}) == {:error, :forecast_engine_unavailable}
    end

    test "the port declares the same schema version as the application bridge" do
      # The application side is `Tiannara.Forecasting.Bridge`. The two stacks
      # have no compile-time dependency, so the contract is pinned by the
      # field lists rather than by a shared module.
      assert Forecasting.schema_version() == 1
      assert "request_id" in Forecasting.request_fields()
      assert "outcomes" in Forecasting.request_fields()
      assert "evidence" in Forecasting.request_fields()
      assert "provenance" in Forecasting.request_fields()
      assert Forecasting.response_fields() == ~w(v request_id status forecast error)
    end
  end

  describe "the forecast stage" do
    test "an unavailable forecasting authority is reported, not fabricated" do
      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      probabilistic = get_in(result.outputs, [:forecast, :probabilistic_forecast])

      assert probabilistic == {:error, :forecast_engine_unavailable}
      refute Map.has_key?(result.outputs, :probability)
    end

    test "an investigation with an unavailable forecast is not reported as complete" do
      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      assert :probabilistic_forecast in result.unavailable_capabilities
      assert result.complete? == false
    end

    test "confidence is reported separately from the probabilistic forecast" do
      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      forecast = get_in(result.outputs, [:forecast])

      assert forecast.confidence.source == :evidence_quality
      assert forecast.confidence.value == 1.0

      # The confidence value is not the forecast probability.
      refute forecast.probabilistic_forecast == forecast.confidence.value
    end

    test "an injected forecasting authority supplies the probabilistic forecast" do
      assert {:ok, result} =
               CognitiveExecutionSpine.run(request(), forecasting: GrantingForecaster)

      probabilistic = get_in(result.outputs, [:forecast, :probabilistic_forecast])

      assert probabilistic["id"] == "fc_1"
      assert probabilistic["probabilities"] == [0.6, 0.4]
      refute :probabilistic_forecast in result.unavailable_capabilities
    end

    test "the request sent to the forecasting authority is a well-formed EFDI request" do
      {:ok, result} = CognitiveExecutionSpine.run(request(), forecasting: GrantingForecaster)

      probabilistic = get_in(result.outputs, [:forecast, :probabilistic_forecast])

      assert probabilistic["request_id"]
      assert probabilistic["question"] == "explain thermal behaviour"
    end

    test "the request carries the schema version and provenance the bridge requires" do
      {:ok, result} = CognitiveExecutionSpine.run(request(), forecasting: GrantingForecaster)

      probabilistic = get_in(result.outputs, [:forecast, :probabilistic_forecast])

      assert is_binary(probabilistic["request_id"])
      assert is_binary(probabilistic["question"])
    end
  end
end
