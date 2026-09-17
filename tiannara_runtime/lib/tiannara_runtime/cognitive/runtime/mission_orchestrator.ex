defmodule TiannaraRuntime.Cognitive.Runtime.MissionOrchestrator do
  def create_mission(trajectory_id, config) do
    id = generate_id(trajectory_id)
    mission = %{
      id: id,
      trajectory_id: trajectory_id,
      status: :created,
      stages: [],
      current_stage: nil,
      plan_id: nil,
      decision_id: nil,
      reflection_id: nil,
      meta_id: nil,
      evidence_chain: [],
      config: config,
      created_at: :erlang.unique_integer([:positive])
    }
    {:ok, mission}
  end

  def execute(mission) do
    updated = mission |> Map.put(:status, :active) |> Map.put(:current_stage, :planning)
    {:ok, updated}
  end

  def complete(mission) do
    updated = Map.put(mission, :status, :completed) |> Map.put(:completed_at, :erlang.unique_integer([:positive]))
    {:ok, updated}
  end

  def abort(mission, reason) do
    updated = Map.put(mission, :status, :aborted) |> Map.put(:abort_reason, reason)
    {:ok, updated}
  end

  def advance_stage(mission, stage) do
    stages = Map.get(mission, :stages, [])
    updated = mission |> Map.put(:stages, stages ++ [stage]) |> Map.put(:current_stage, stage)
    {:ok, updated}
  end

  def link_subsystem(mission, subsystem, id) do
    key =
      case subsystem do
        :plan -> :plan_id
        :decision -> :decision_id
        :reflection -> :reflection_id
        :meta -> :meta_id
        other -> other
      end
    {:ok, Map.put(mission, key, id)}
  end

  defp generate_id(trajectory_id) do
    base = "#{trajectory_id}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "cm_#{hash}"
  end
end
