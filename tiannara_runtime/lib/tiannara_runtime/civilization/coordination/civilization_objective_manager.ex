defmodule TiannaraRuntime.Civilization.Coordination.CivilizationObjectiveManager do
  def initialize() do
    {:ok, %{objectives: %{}, ordered_ids: []}}
  end

  def add_objective(manager, objective) do
    id = Map.get(objective, :id, "obj_#{:erlang.unique_integer([:positive])}")
    objective = Map.put(objective, :id, id)
    {:ok, %{manager | objectives: Map.put(manager.objectives, id, objective), ordered_ids: manager.ordered_ids ++ [id]}}
  end

  def update_progress(manager, objective_id, progress) do
    case Map.get(manager.objectives, objective_id) do
      nil -> {:ok, manager}
      obj -> {:ok, %{manager | objectives: Map.put(manager.objectives, objective_id, Map.put(obj, :progress, progress))}}
    end
  end

  def get_objectives(manager, status) do
    filtered = Enum.filter(manager.objectives, fn {_id, obj} -> Map.get(obj, :status) == status end)
    {:ok, Enum.map(filtered, fn {_id, obj} -> obj end)}
  end

  def metrics(manager) do
    {:ok, %{total: map_size(manager.objectives), ordered: length(manager.ordered_ids)}}
  end
end
