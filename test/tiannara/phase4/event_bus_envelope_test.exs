defmodule Tiannara.Phase4.EventBusEnvelopeTest do
  use ExUnit.Case, async: true

  alias Tiannara.Phase4.{AutonomousResearchEngine, ExperimentOrchestrator}

  test "experiment orchestrator ignores current EventBus envelope for unknown workflow" do
    state = %{
      experiments: %{},
      total_experiments: 0,
      completed_experiments: 0,
      failed_experiments: 0,
      cancelled_experiments: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }

    event = %{
      routing_destination: "workflow.failed",
      origin: %{workflow_id: "missing-workflow", reason: :test_failure}
    }

    assert {:noreply, ^state} = ExperimentOrchestrator.handle_info({:event, event}, state)
  end

  test "autonomous research engine ignores current EventBus envelope for unknown workflow" do
    state = %{
      active_programs: %{},
      total_programs_initiated: 0,
      total_hypotheses_generated: 0,
      total_validations_completed: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }

    event = %{
      routing_destination: "workflow.failed",
      origin: %{workflow_id: "missing-workflow", reason: :test_failure}
    }

    assert {:noreply, ^state} = AutonomousResearchEngine.handle_info({:event, event}, state)
  end
end
