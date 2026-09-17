defmodule TiannaraRuntime.Civilization.Portfolio.ResourcePlanner do
  def initialize(total_resources) do
    {:ok, %{total: total_resources, planned: %{}, allocated: %{}}}
  end

  def plan(planner, program_id, amount, category) do
    planned_total = Enum.reduce(planner.planned, 0, fn {_k, v}, acc -> acc + Map.get(v, :amount, 0) end)
    allocated_total = Enum.reduce(planner.allocated, 0, fn {_k, v}, acc -> acc + Map.get(v, :amount, 0) end)
    used = planned_total + allocated_total
    if used + amount > planner.total do
      {:error, :insufficient}
    else
      planned = Map.put(planner.planned, program_id, %{amount: amount, category: category})
      {:ok, %{planner | planned: planned}}
    end
  end

  def allocate(planner, program_id) do
    case Map.get(planner.planned, program_id) do
      nil -> {:ok, planner}
      entry ->
        planned = Map.delete(planner.planned, program_id)
        allocated = Map.put(planner.allocated, program_id, entry)
        {:ok, %{planner | planned: planned, allocated: allocated}}
    end
  end

  def metrics(planner) do
    planned_total = Enum.reduce(planner.planned, 0, fn {_k, v}, acc -> acc + Map.get(v, :amount, 0) end)
    allocated_total = Enum.reduce(planner.allocated, 0, fn {_k, v}, acc -> acc + Map.get(v, :amount, 0) end)
    {:ok, %{total: planner.total, planned: planned_total, allocated: allocated_total, remaining: planner.total - planned_total - allocated_total}}
  end
end
