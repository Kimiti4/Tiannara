defmodule TiannaraRuntime.Civilization.Economy.CapitalAllocator do
  def initialize(total_capital) do
    {:ok, %{total: total_capital, allocations: %{}, pending: []}}
  end

  def allocate(allocator, program_id, amount, reason) do
    if allocator.total >= amount do
      allocation = %{program_id: program_id, amount: amount, reason: reason}
      new_allocations = Map.put(allocator.allocations, program_id, amount)
      {:ok, %{allocator | total: allocator.total - amount, allocations: new_allocations}}
    else
      {:error, :insufficient_funds}
    end
  end

  def reallocate(allocator, from_program, to_program, amount) do
    from_amount = Map.get(allocator.allocations, from_program, 0)
    if from_amount >= amount do
      new_from = from_amount - amount
      new_to = Map.get(allocator.allocations, to_program, 0) + amount
      new_allocations = allocator.allocations
      |> Map.put(from_program, new_from)
      |> Map.put(to_program, new_to)
      {:ok, %{allocator | total: allocator.total, allocations: new_allocations}}
    else
      {:error, :insufficient_funds}
    end
  end

  def metrics(allocator) do
    allocated = Enum.reduce(allocator.allocations, 0, fn {_id, amt}, acc -> acc + amt end)
    {:ok, %{
      total: allocator.total + allocated,
      allocated: allocated,
      remaining: allocator.total,
      program_count: map_size(allocator.allocations)
    }}
  end
end
