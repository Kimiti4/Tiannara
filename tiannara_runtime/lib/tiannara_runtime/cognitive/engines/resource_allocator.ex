defmodule TiannaraRuntime.Cognitive.Engines.ResourceAllocator do
  @moduledoc false

  alias TiannaraRuntime.Cognitive.Engines.AttentionBudget

  def allocate(tasks, budgets) do
    budget_state = AttentionBudget.new(budgets)

    {allocations, final_budget} =
      Enum.reduce_while(tasks, {%{}, budget_state}, fn task, {alloc, budget} ->
        cpu = Map.get(task, :cpu, 1)
        mem = Map.get(task, :memory, 1)

        case AttentionBudget.consume(budget, :cpu, cpu) do
          {:ok, b1} ->
            case AttentionBudget.consume(b1, :memory, mem) do
              {:ok, b2} ->
                {:cont, {Map.put(alloc, task, %{cpu: cpu, memory: mem}), b2}}
              {:error, _} ->
                {:cont, {alloc, budget}}
            end
          {:error, _} ->
            {:cont, {alloc, budget}}
        end
      end)

    remaining = Map.new(final_budget.budgets, fn {k, %{available: a}} -> {k, a} end)
    {:ok, %{allocations: allocations, remaining: remaining}}
  end

  def release(allocation, resource_type, amount) do
    current = Map.get(allocation, resource_type, %{used: 0, available: 0})
    new_used = max(0, Map.get(current, :used, 0) - amount)
    new_available = Map.get(current, :available, 0) + amount
    updated = Map.put(allocation, resource_type, %{used: new_used, available: new_available})
    {:ok, updated}
  end
end
