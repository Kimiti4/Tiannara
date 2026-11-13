defmodule Tiannara.Research.ResearchForecastingIntegrationTest do
  @moduledoc """
  Integration of the Research Director with the canonical forecasting authority.

  These tests drive the **real** Research Director pipeline — the supervisor
  that the application starts — rather than calling the forecasting engine
  directly. A forecast must be produced by the same path a real investigation
  uses.

  The invariants pinned here:

    * a forecastable proposition produces a registered probabilistic forecast;
    * a hypothesis that is not a forecastable proposition is marked as such and
      is **not** given an invented probability;
    * evidence confidence and forecast probability remain separate quantities;
    * the forecast is registered with the canonical EFDI authority and is
      recoverable from it;
    * an unavailable authority fails closed instead of crashing the pipeline.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting
  alias Tiannara.Forecasting.ForecastRegistry
  alias Tiannara.Research.ResearchDirector

  setup do
    unless Process.whereis(ForecastRegistry), do: start_supervised!(ForecastRegistry)
    :ok
  end

  defp forecast_spec do
    %{
      proposition: "The thermal model reaches operational status within 24 hours",
      outcomes: ["operational", "not_operational"],
      horizon: "24h",
      horizon_start: "2026-06-01T00:00:00Z",
      horizon_end: "2026-06-02T00:00:00Z",
      horizon_policy: "closed",
      resolution_criteria: "the model registry records the model with status :operational",
      evidence: [
        %{
          "id" => "ev_signal_1",
          "epistemic_status" => "observed",
          "source" => "sensor_a",
          "observed_at" => "2026-06-01T12:00:00Z"
        }
      ],
      base_rate: %{
        "reference_class" => "thermal_models",
        "historical_frequency" => 0.6,
        "sample_size" => 25,
        "source" => "forecast_history"
      },
      model_ref: "model_v3"
    }
  end

  defp priority(overrides \\ %{}) do
    Map.merge(
      %{
        domain: :physics,
        signal: "signal_thermal_1",
        score: 0.8,
        id: "priority_signal_thermal_1",
        rationale: "EFDI signal prioritized for physics"
      },
      overrides
    )
  end

  defp hypothesis_from(queue_timeout \\ 5_000) do
    # The pipeline enqueues hypotheses; dequeue to inspect the produced record.
    Tiannara.Research.ResearchQueue.dequeue()
    |> case do
      {:ok, :hypothesis, hypothesis} -> hypothesis
      _ -> nil
    end
  end

  describe "a forecastable proposition" do
    test "the real Research Director path produces a registered probabilistic forecast" do
      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      assert hypothesis != nil
      assert hypothesis.forecast_status == :registered
      assert is_binary(hypothesis.forecast_id)
      assert hypothesis.forecast.probabilities != :unknown
      assert hypothesis.forecast.horizon == "24h"
      assert hypothesis.forecast.outcomes == ["operational", "not_operational"]
    end

    test "the forecast is registered with the canonical EFDI authority" do
      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      # The forecast exists in EFDI's own registry, not only on the hypothesis.
      assert {:ok, stored} = Forecasting.get_forecast(hypothesis.forecast_id)
      assert stored.id == hypothesis.forecast_id
      assert stored.horizon == "24h"
    end

    test "the forecast preserves the evidence references and provenance" do
      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      assert hypothesis.forecast.evidence_refs == ["ev_signal_1"]
      assert hypothesis.forecast.question ==
               "The thermal model reaches operational status within 24 hours"
    end

    test "evidence confidence is not replaced by the forecast probability" do
      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      # `confidence` is the evidence-confidence quantity the hypothesis
      # already carried; the forecast probability is a separate value.
      assert is_number(hypothesis.confidence)
      assert hypothesis.forecast.probabilities != hypothesis.confidence
    end

    test "re-ingesting the same priority does not create a second forecast" do
      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])
      first = hypothesis_from()

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])
      second = hypothesis_from()

      assert second.forecast_id == first.forecast_id
    end
  end

  describe "a proposition that is not forecastable" do
    test "a hypothesis without a specification is marked, not invented" do
      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority()])

      hypothesis = hypothesis_from()

      assert hypothesis.forecast_status == :not_forecastable
      assert hypothesis.forecast == nil
      assert hypothesis.forecast_error == :missing_forecast_specification
    end

    test "an underspecified proposition is refused with an exact reason" do
      spec = forecast_spec() |> Map.delete(:outcomes)
      priority = priority(%{forecast_spec: spec})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      assert hypothesis.forecast_status == :unavailable
      assert hypothesis.forecast_error == :missing_outcomes
      assert hypothesis.forecast == nil
    end

    test "evidence with an unrecognised epistemic status is refused" do
      spec =
        forecast_spec()
        |> put_in([:evidence], [%{"id" => "ev_1", "epistemic_status" => "probably"}])

      priority = priority(%{forecast_spec: spec})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      assert hypothesis.forecast_status == :unavailable
      assert hypothesis.forecast_error == :invalid_evidence
    end

    test "a hypothesis with no forecast is not reported as complete" do
      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority()])

      hypothesis = hypothesis_from()

      refute hypothesis.forecast_status == :registered
      assert hypothesis.forecast_id == nil
    end
  end

  describe "an unavailable forecasting authority" do
    test "the pipeline fails closed instead of crashing" do
      # Stop the registry the canonical authority depends on, so the authority
      # is genuinely unavailable rather than merely absent.
      stop_supervised(ForecastRegistry)

      priority = priority(%{forecast_spec: forecast_spec()})

      assert {:ok, 1} = ResearchDirector.ingest_priorities([priority])

      hypothesis = hypothesis_from()

      assert hypothesis.forecast_status == :unavailable
      assert hypothesis.forecast_error in [:forecast_registry_unavailable, :forecast_engine_unavailable]
      assert hypothesis.forecast == nil
    end
  end
end
