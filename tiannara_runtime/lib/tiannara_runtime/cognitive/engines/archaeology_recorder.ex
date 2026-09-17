defmodule TiannaraRuntime.Cognitive.Engines.ArchaeologyRecorder do
  @moduledoc "Phase 18.2 — Archaeology lineage recording engine"

  alias TiannaraRuntime.Cognitive.ArchaeologyReference

  def record(artifact, mission_state) do
    lineage = build_lineage(mission_state)
    {:ok, ref} = ArchaeologyReference.new(%{
      origin: %{type: artifact.type, mission_id: artifact.mission_id, timestamp: artifact.timestamp},
      purpose: artifact.type,
      dependencies: artifact.dependencies || [],
      lineage: lineage
    })
    {:ok, ref}
  end

  def record_execution(task, exec_result, mission_state) do
    lineage = build_lineage(mission_state) ++ [
      %{type: :task, id: task.id, fingerprint: task.fingerprint},
      %{type: :execution_result, id: exec_result.id, fingerprint: exec_result.fingerprint}
    ]
    {:ok, ref} = ArchaeologyReference.new(%{
      origin: %{type: :task_execution, task_id: task.id, execution_result_id: exec_result.id},
      purpose: :task_execution,
      dependencies: [task.id],
      lineage: lineage
    })
    {:ok, ref}
  end

  def get_lineage(archaeology_ref) do
    {:ok, archaeology_ref.lineage}
  end

  def get_mission_lineage(archaeology_refs, mission_id) do
    filtered = Enum.filter(archaeology_refs, fn ref ->
      Map.get(ref.origin, :mission_id) == mission_id
    end)
    {:ok, filtered}
  end

  defp build_lineage(mission_state) do
    [
      %{type: :mission, id: mission_state.mission.id, fingerprint: mission_state.mission.fingerprint},
      %{type: :context, id: mission_state.context.id, fingerprint: mission_state.context.fingerprint},
      %{type: :attention, id: mission_state.attention.id, fingerprint: mission_state.attention.fingerprint}
    ]
  end
end
