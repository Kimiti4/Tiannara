defmodule TiannaraRuntime.Civilization.Planning.DependencyProjectionEngine do
  def initialize do
    {:ok, %{projections: [], dependencies: %{}}}
  end

  def project(engine, source, target, growth_rate) do
    timesteps = Enum.map(1..10, fn t ->
      %{timestep: t, strength: min(growth_rate * (1.1 ** (t - 1)), 1.0)}
    end)
    projection = %{
      id: "proj_#{:erlang.unique_integer([:positive])}",
      source: source,
      target: target,
      growth_rate: growth_rate,
      timesteps: timesteps
    }
    dependencies = Map.get(engine, :dependencies, %{})
    key = "#{source}->#{target}"
    {:ok, %{engine | projections: Map.get(engine, :projections, []) ++ [projection], dependencies: Map.put(dependencies, key, projection)}}
  end

  def forecast(engine, dependency_graph, years) do
    yearly_states = Enum.map(1..years, fn year ->
      evolved = Map.new(dependency_graph, fn {key, strength} ->
        {key, strength * (1.0 + 0.05 * (year - 1))}
      end)
      %{year: year, dependencies: evolved}
    end)
    {:ok, yearly_states}
  end

  def metrics(engine) do
    projections = Map.get(engine, :projections, [])
    total = length(projections)
    max_horizon = if total > 0 do
      Enum.max_by(projections, fn p -> length(Map.get(p, :timesteps, [])) end)
      |> Map.get(:timesteps, [])
      |> length()
    else
      0
    end
    {:ok, %{total_projections: total, max_horizon: max_horizon}}
  end
end
