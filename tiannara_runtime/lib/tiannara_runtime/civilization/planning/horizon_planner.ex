defmodule TiannaraRuntime.Civilization.Planning.HorizonPlanner do
  def initialize do
    {:ok, %{horizons: %{1 => [], 5 => [], 10 => [], 25 => [], 50 => [], 100 => []}}}
  end

  def plan(planner, horizon_years, programs) do
    horizons = Map.get(planner, :horizons, %{})
    updated = Map.put(horizons, horizon_years, programs)
    {:ok, %{planner | horizons: updated}}
  end

  def get_horizon(planner, horizon_years) do
    horizons = Map.get(planner, :horizons, %{})
    {:ok, Map.get(horizons, horizon_years, [])}
  end

  def project(planner, horizon_years) do
    programs = Map.get(Map.get(planner, :horizons, %{}), horizon_years, [])
    projected_milestones = Enum.map(programs, fn program ->
      %{
        program: program,
        horizon: horizon_years,
        estimated_completion: :erlang.unique_integer([:positive]),
        confidence: 0.75
      }
    end)
    {:ok, %{horizon: horizon_years, program_count: length(programs), projected_milestones: projected_milestones}}
  end

  def metrics(planner) do
    horizons = Map.get(planner, :horizons, %{})
    counts = Map.new(horizons, fn {h, programs} -> {h, length(programs)} end)
    {:ok, counts}
  end
end
