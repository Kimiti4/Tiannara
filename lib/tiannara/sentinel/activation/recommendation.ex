defmodule Tiannara.Sentinel.Activation.Recommendation do
  @moduledoc """
  Generates evidence-based responses and intervention proposals.
  Every recommendation includes expected benefit, risk, rollback plan,
  and validation method.
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Generates a list of recommended actions for the given event.
  """
  @spec generate(Event.t()) :: list(map())
  def generate(%Event{} = event) do
    base_recommendations = get_base_recommendations(event.category)

    Enum.map(base_recommendations, fn rec ->
      %{
        action: rec.action,
        expected_gain: rec.expected_gain,
        risk: rec.risk,
        confidence: (event.confidence || 0.5) * rec.base_confidence,
        rollback_plan: rec.rollback_plan,
        validation_method: rec.validation_method
      }
    end)
  end

  defp get_base_recommendations(:scientific) do
    [
      %{
        action: "Run diversity recovery simulation",
        expected_gain: 0.18,
        risk: 0.05,
        base_confidence: 0.8,
        rollback_plan: "Revert to previous simulation state",
        validation_method: "Compare simulation metrics against baseline"
      },
      %{
        action: "Increase mutation rate in REA",
        expected_gain: 0.12,
        risk: 0.15,
        base_confidence: 0.7,
        rollback_plan: "Restore original mutation parameters",
        validation_method: "Monitor genome diversity over 100 cycles"
      }
    ]
  end

  defp get_base_recommendations(:runtime) do
    [
      %{
        action: "Run diagnostic health check",
        expected_gain: 0.25,
        risk: 0.02,
        base_confidence: 0.9,
        rollback_plan: "No state change — diagnostic only",
        validation_method: "Compare telemetry before and after diagnostic"
      },
      %{
        action: "Scale affected subsystem",
        expected_gain: 0.15,
        risk: 0.10,
        base_confidence: 0.75,
        rollback_plan: "Restore previous scaling configuration",
        validation_method: "Monitor latency and throughput for 100 cycles"
      }
    ]
  end

  defp get_base_recommendations(:constitutional) do
    [
      %{
        action: "Run constitutional validation suite",
        expected_gain: 0.30,
        risk: 0.01,
        base_confidence: 0.95,
        rollback_plan: "No state change — validation only",
        validation_method: "Verify all constitutional principles pass"
      }
    ]
  end

  defp get_base_recommendations(:discovery) do
    [
      %{
        action: "Cross-reference with Discovery Genealogy",
        expected_gain: 0.22,
        risk: 0.02,
        base_confidence: 0.85,
        rollback_plan: "No state change — reference only",
        validation_method: "Check for rediscovery patterns in historical records"
      }
    ]
  end

  defp get_base_recommendations(:security) do
    [
      %{
        action: "Isolate and quarantine affected subsystem",
        expected_gain: 0.35,
        risk: 0.08,
        base_confidence: 0.85,
        rollback_plan: "Restore subsystem from last known good state",
        validation_method: "Verify no threat persistence after isolation"
      }
    ]
  end

  defp get_base_recommendations(_) do
    [
      %{
        action: "Record and monitor observation",
        expected_gain: 0.10,
        risk: 0.01,
        base_confidence: 0.90,
        rollback_plan: "No action taken — observation only",
        validation_method: "Continue monitoring for trend confirmation"
      }
    ]
  end
end
