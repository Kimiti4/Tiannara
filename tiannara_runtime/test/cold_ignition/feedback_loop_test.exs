defmodule ColdIgnition.FeedbackLoopTest do
  @moduledoc """
  PHASE 2: COLD IGNITION - STEP 5
  Verify that perturbation feedback dampens instead of amplifying indefinitely.
  """

  use ExUnit.Case

  import ColdIgnition.Helpers

  alias TiannaraRuntime.Monitoring.ColdIgnitionSupport

  @tag timeout: 60_000
  setup :start_system_minimal_feedback
  setup do
    case TiannaraRuntime.Monitoring.TelemetryPublisher.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  test "feedback loop stabilizes within 500 ticks" do
    {:ok, _} =
      ColdIgnitionSupport.inject_perturbation(%{
        type: :resource_depletion,
        niche_id: "niche_1",
        amount: 80
      })

    Process.sleep(3_000)

    history = TiannaraRuntime.Monitoring.TelemetryPublisher.get_history(:mscl, 500)
    values = Enum.map(history, &Map.get(&1, :value, 0.0))

    assert length(values) > 10, "Not enough feedback telemetry collected"

    amplitudes =
      values
      |> Enum.chunk_every(10)
      |> Enum.map(fn window -> Enum.max(window) - Enum.min(window) end)

    assert Enum.all?(amplitudes, &(&1 <= 1.0)),
           "Feedback amplitude left stable bounds: #{inspect(amplitudes)}"

    assert List.last(values) <= 1.0, "Constraint load escaped bounded range"
  end
end
