defmodule Tiannara.Forecasting.BridgeTest do
  @moduledoc """
  Validation of the canonical cross-stack boundary to EFDI.

  The bridge is the only sanctioned way for another stack to ask Tiannara for a
  probabilistic forecast. These tests pin that it refuses malformed or
  under-specified requests with exact reasons, that it never fabricates a
  probability, and that the confidence of a forecast is not confused with its
  probability.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting
  alias Tiannara.Forecasting.Bridge
  alias Tiannara.Forecasting.ForecastRegistry

  setup do
    unless Process.whereis(ForecastRegistry), do: start_supervised!(ForecastRegistry)
    :ok
  end

  # Each test gets its own request id: the bridge is idempotent per request
  # id, so a shared id would replay an earlier forecast instead of producing
  # a new one.
  defp request(overrides \\ %{}) do
    Map.merge(
      %{
        "v" => 1,
        "request_id" => "req_bridge_#{:os.system_time(:microsecond)}_#{System.unique_integer([:positive])}",
        "question" => "Will the thermal model converge within 24h?",
        "event" => "model_converged",
        "outcomes" => ["yes", "no"],
        "horizon" => "24h",
        "evidence" => [
          %{
            "id" => "ev_1",
            "epistemic_status" => "observed",
            "source" => "sensor_a",
            "observed_at" => "2026-06-01T12:00:00Z"
          }
        ],
        "signal_ids" => [],
        "base_rate" => %{
          "reference_class" => "thermal_models_2024",
          "historical_frequency" => 0.62,
          "sample_size" => 40,
          "source" => "forecast_history"
        },
        "model_ref" => "model_v3",
        "assumptions" => ["stationary"],
        "context" => %{},
        "regime" => "stable",
        "provenance" => %{
          "origin" => "cognitive_execution_spine",
          "investigation_id" => "inv_1",
          "requested_by" => "cognitive_execution_spine"
        }
      },
      overrides
    )
  end

  # EFDI may represent a distribution as a list or as an outcome-keyed map.
  # The test asserts the semantics, not the incidental representation.
  defp probability_values(probabilities) when is_map(probabilities),
    do: Map.values(probabilities)

  defp probability_values(probabilities) when is_list(probabilities), do: probabilities

  describe "contract" do
    test "declares a versioned request and response shape" do
      assert Bridge.schema_version() == 1
      assert "request_id" in Bridge.request_fields()
      assert "evidence" in Bridge.request_fields()
      assert "provenance" in Bridge.request_fields()
      assert "forecast" in Bridge.response_fields()
      assert "error" in Bridge.response_fields()
    end

    test "accepts exactly the documented epistemic statuses" do
      assert "observed" in Bridge.epistemic_statuses()
      assert "simulated" in Bridge.epistemic_statuses()
      assert "rejected" in Bridge.epistemic_statuses()
      refute "probably" in Bridge.epistemic_statuses()
    end
  end

  describe "handle_request/1 — refusals" do
    test "refuses a payload that is not a map" do
      response = Bridge.handle_request("not a map")

      assert response["status"] == "error"
      assert response["error"]["reason"] == "invalid_request_payload"
      assert response["forecast"] == nil
    end

    test "refuses a request with no schema version" do
      payload = request() |> Map.delete("v")
      response = Bridge.handle_request(payload)

      assert response["status"] == "error"
      assert response["error"]["reason"] == "missing_schema_version"
    end

    test "refuses a request with an unsupported schema version" do
      response = Bridge.handle_request(request(%{"v" => 99}))

      assert response["status"] == "error"
      assert response["error"]["reason"] == "unsupported_schema_version"
    end

    test "refuses a request with no correlation id" do
      payload = request() |> Map.delete("request_id")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_request_id"
    end

    test "refuses a request with no question" do
      payload = request() |> Map.delete("question")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_question"
    end

    test "refuses a request with no outcome contract" do
      payload = request() |> Map.delete("outcomes")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_outcomes"
    end

    test "refuses a request with no horizon" do
      payload = request() |> Map.delete("horizon")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_horizon"
    end

    test "refuses a request with no evidence" do
      payload = request() |> Map.delete("evidence")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_evidence"
    end

    test "refuses a request with no provenance" do
      payload = request() |> Map.delete("provenance")
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "missing_provenance"
    end

    test "refuses evidence with an unrecognised epistemic status" do
      payload = request(%{"evidence" => [%{"id" => "ev_1", "epistemic_status" => "probably"}]})
      response = Bridge.handle_request(payload)

      assert response["error"]["reason"] == "invalid_epistemic_status"
    end

    test "correlates the refusal with the request id" do
      response = Bridge.handle_request(request(%{"outcomes" => [], "request_id" => "req_correlated"}))

      assert response["request_id"] == "req_correlated"
      assert response["v"] == 1
    end
  end

  describe "handle_request/1 — accepted" do
    test "produces a forecast and registers it" do
      response = Bridge.handle_request(request())

      assert response["status"] == "ok"
      assert response["error"] == nil

      forecast = response["forecast"]
      assert is_binary(forecast["id"])
      assert forecast["question"] == "Will the thermal model converge within 24h?"
      assert forecast["horizon"] == "24h"
      assert forecast["outcomes"] == ["yes", "no"]
      assert forecast["model_ref"] == "model_v3"
      assert forecast["epistemic_status"] == "forecasted"

      # registered, so it is durable and immutable
      assert {:ok, stored} = Forecasting.get_forecast(forecast["id"])
      assert stored.id == forecast["id"]
    end

    test "a base rate produces a probability, and the wire format keeps it" do
      response = Bridge.handle_request(request())

      probabilities = response["forecast"]["probabilities"]
      values = probability_values(probabilities)

      assert is_list(probabilities)
      assert length(values) == 2
      assert Enum.all?(values, &is_number/1)
      assert_in_delta Enum.sum(values), 1.0, 0.0001
    end

    test "the probability distribution is positionally aligned with the declared outcomes" do
      response = Bridge.handle_request(request())

      probabilities = response["forecast"]["probabilities"]
      outcomes = response["forecast"]["outcomes"]

      assert is_list(probabilities)
      assert length(probabilities) == length(outcomes)
    end

    test "a base rate without a reference class is refused, not fabricated" do
      response = Bridge.handle_request(request(%{"base_rate" => %{"historical_frequency" => 0.62}}))

      assert response["status"] == "error"
      assert response["error"]["reason"] == "missing_reference_class"
      assert response["forecast"] == nil
    end

    test "an absent base rate yields an unknown probability, never an invented one" do
      response = Bridge.handle_request(request(%{"base_rate" => nil}))

      assert response["status"] == "ok"

      probabilities = response["forecast"]["probabilities"]

      # `:unknown` is carried as the string "unknown", which is distinct from 0.0
      assert probabilities == "unknown"
      refute probabilities == 0.0
      refute probabilities == 0
    end

    test "a reused request id with different content is refused, not replayed" do
      first = Bridge.handle_request(request(%{"request_id" => "req_conflict_probe"}))

      assert first["status"] == "ok"

      conflicting = request(%{"request_id" => "req_conflict_probe", "question" => "A different question?"})
      second = Bridge.handle_request(conflicting)

      assert second["status"] == "error"
      assert second["error"]["reason"] == "request_id_conflict"
    end

    test "registering the same request twice returns the original forecast" do
      payload = request(%{"request_id" => "req_idempotent"})
      first = Bridge.handle_request(payload)
      second = Bridge.handle_request(payload)

      assert first["forecast"]["id"] == second["forecast"]["id"]
      assert first["status"] == "ok"
      assert second["status"] == "ok"
    end

    test "the bridge does not authorise anything" do
      response = Bridge.handle_request(request())

      refute Map.has_key?(response["forecast"], "authorization")
      refute Map.has_key?(response["forecast"], "decision")
    end
  end
end
