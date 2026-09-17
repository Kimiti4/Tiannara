defmodule TiannaraRuntime.CCOS.AttentionCoordinator do
  @moduledoc """
  Phase 18.2 Attention Coordinator.

  Produces deterministic attention state by ordering supplied tasks by priority,
  dependency order, submission order, and content hash. It performs no
  optimization.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec allocate(map(), map()) :: {:ok, map()} | {:error, String.t()}
  def allocate(mission_state, context) when is_map(mission_state) and is_map(context) do
    with {:ok, tasks} <- Artifact.require_list(mission_state, :task_graph) do
      ordered =
        tasks
        |> Enum.with_index()
        |> Enum.map(fn {task, index} -> normalize_task(task, index) end)
        |> Enum.sort_by(fn task ->
          {
            -task.priority,
            task.dependency_order,
            task.submission_order,
            task.content_hash
          }
        end)

      state = %{
        mission_id: Map.fetch!(mission_state, :mission_id),
        context_id: Map.fetch!(context, :context_id),
        ordered_tasks: ordered
      }

      {:ok, Map.put(state, :attention_state_id, Artifact.content_id("cckattn", state))}
    end
  end

  def allocate(_mission_state, _context),
    do: {:error, "AttentionCoordinator.allocate requires mission state and context"}

  defp normalize_task(task, submission_order) when is_map(task) do
    priority = Map.get(task, :priority) || Map.get(task, "priority")
    dependency_order = Map.get(task, :dependency_order) || Map.get(task, "dependency_order")

    unless is_number(priority) do
      raise ArgumentError, "task priority is required and must be numeric"
    end

    unless is_integer(dependency_order) do
      raise ArgumentError, "task dependency_order is required and must be an integer"
    end

    content_hash = Artifact.fingerprint(task)

    task
    |> Map.put(:submission_order, submission_order)
    |> Map.put(:content_hash, content_hash)
    |> Map.put(:priority, priority)
    |> Map.put(:dependency_order, dependency_order)
  end
end
