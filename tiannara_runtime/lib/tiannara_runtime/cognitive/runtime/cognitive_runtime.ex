defmodule TiannaraRuntime.Cognitive.Runtime.CognitiveRuntime do
  @created_with_phase "18.9"

  def initialize(config) do
    runtime_id = generate_id()
    runtime = %{
      runtime_id: runtime_id,
      status: :initialized,
      missions: [],
      subsystems: %{},
      config: config,
      created_at: :erlang.unique_integer([:positive]),
      created_with_phase: @created_with_phase
    }
    {:ok, runtime}
  end

  def register_subsystem(runtime, name, module) do
    subsystems = Map.get(runtime, :subsystems, %{})
    updated = Map.put(runtime, :subsystems, Map.put(subsystems, name, module))
    {:ok, updated}
  end

  def start_mission(runtime, trajectory_id) do
    config = Map.get(runtime, :config, %{})
    {:ok, mission} = TiannaraRuntime.Cognitive.Runtime.MissionOrchestrator.create_mission(trajectory_id, config)
    mission = Map.put(mission, :status, :active)
    missions = Map.get(runtime, :missions, [])
    updated = Map.put(runtime, :missions, missions ++ [mission])
    {:ok, {updated, mission}}
  end

  def get_mission(runtime, mission_id) do
    missions = Map.get(runtime, :missions, [])
    case Enum.find(missions, fn m -> Map.get(m, :id) == mission_id end) do
      nil -> {:error, :not_found}
      mission -> {:ok, mission}
    end
  end

  def list_missions(runtime) do
    {:ok, Map.get(runtime, :missions, [])}
  end

  def summary(runtime) do
    missions = Map.get(runtime, :missions, [])
    status_counts = missions |> Enum.group_by(fn m -> Map.get(m, :status) end) |> Map.new(fn {k, v} -> {k, length(v)} end)
    {:ok, %{mission_count: length(missions), status_counts: status_counts}}
  end

  defp generate_id do
    base = "cr_#{:erlang.unique_integer([:positive])}"
    :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
  end
end
