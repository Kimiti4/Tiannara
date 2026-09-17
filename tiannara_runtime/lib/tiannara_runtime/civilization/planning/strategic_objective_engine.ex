defmodule TiannaraRuntime.Civilization.Planning.StrategicObjectiveEngine do
  def initialize do
    {:ok, %{objectives: %{}, ordered_ids: []}}
  end

  def add_objective(engine, objective) do
    obj = %{
      id: "obj_#{:erlang.unique_integer([:positive])}",
      name: Map.get(objective, :name),
      description: Map.get(objective, :description),
      dependencies: Map.get(objective, :dependencies, []),
      required_institutions: Map.get(objective, :required_institutions, []),
      required_research: Map.get(objective, :required_research, []),
      expected_impact: Map.get(objective, :expected_impact, 0.5),
      status: Map.get(objective, :status, :active)
    }
    updated = %{
      engine
      | objectives: Map.put(Map.get(engine, :objectives, %{}), Map.get(obj, :id), obj),
        ordered_ids: Map.get(engine, :ordered_ids, []) ++ [Map.get(obj, :id)]
    }
    {:ok, updated}
  end

  def update_impact(engine, objective_id, impact) do
    objectives = Map.get(engine, :objectives, %{})
    case Map.get(objectives, objective_id) do
      nil -> {:error, :not_found}
      obj ->
        {:ok, %{engine | objectives: Map.put(objectives, objective_id, Map.put(obj, :expected_impact, impact))}}
    end
  end

  def get_objectives_by_status(engine, status) do
    objectives = Map.get(engine, :objectives, %{})
    filtered = Enum.filter(objectives, fn {_id, obj} -> Map.get(obj, :status) == status end)
    {:ok, Enum.map(filtered, fn {_id, obj} -> obj end)}
  end

  def metrics(engine) do
    objectives = Map.get(engine, :objectives, %{})
    total = map_size(objectives)
    active = Enum.count(objectives, fn {_id, obj} -> Map.get(obj, :status) == :active end)
    completed = Enum.count(objectives, fn {_id, obj} -> Map.get(obj, :status) == :completed end)
    {:ok, %{total: total, active: active, completed: completed}}
  end
end
