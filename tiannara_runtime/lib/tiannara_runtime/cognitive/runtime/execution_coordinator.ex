defmodule TiannaraRuntime.Cognitive.Runtime.ExecutionCoordinator do
  def initialize(mission) do
    state = %{
      mission_id: Map.get(mission, :id),
      phase: :init,
      step: 0,
      substep: 0,
      status: :ready,
      error: nil,
      error_count: 0
    }
    {:ok, state}
  end

  def execute_step(state, _step) do
    current_step = Map.get(state, :step, 0)
    current_substep = Map.get(state, :substep, 0)
    updated = state |> Map.put(:step, current_step + 1) |> Map.put(:substep, current_substep + 1) |> Map.put(:status, :running)
    {:ok, updated}
  end

  def transition(state, next_phase) do
    updated = state |> Map.put(:phase, next_phase) |> Map.put(:step, 0) |> Map.put(:substep, 0)
    {:ok, updated}
  end

  def fail(state, reason) do
    error_count = Map.get(state, :error_count, 0)
    updated = state |> Map.put(:status, :failed) |> Map.put(:error, reason) |> Map.put(:error_count, error_count + 1)
    {:ok, updated}
  end

  def get_progress(state) do
    {:ok, %{phase: Map.get(state, :phase), step: Map.get(state, :step), substep: Map.get(state, :substep), status: Map.get(state, :status)}}
  end
end
