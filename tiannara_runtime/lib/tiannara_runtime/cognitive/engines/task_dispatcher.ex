defmodule TiannaraRuntime.Cognitive.Engines.TaskDispatcher do
  @moduledoc "Phase 18.2 — Task routing to subsystem engines"

  alias TiannaraRuntime.Cognitive.ExecutionRequest

  def dispatch(task, context) do
    task_type = Map.get(task, :task_type)
    case route(task_type, context) do
      {:ok, subsystem} ->
        ExecutionRequest.new(%{
          task_reference: subsystem,
          requested_resources: Map.get(task, :resources, %{}),
          constraints: Map.get(task, :constraints, []),
          deadline: Map.get(task, :deadline)
        })
      {:error, reason} ->
        {:error, reason}
    end
  end

  def route(task_type, _context) do
    case task_type do
      :scientific_discovery -> {:ok, "Phase15.SMCP"}
      :research -> {:ok, "Phase16.REA"}
      :mathematics -> {:ok, "Phase16X"}
      :world_model -> {:ok, "Phase17.WorldModel"}
      :simulation -> {:ok, "Phase17.7.DigitalTwin"}
      :experiment -> {:ok, "Phase17.8.ARPE"}
      _ -> {:error, :unknown_subsystem}
    end
  end
end
