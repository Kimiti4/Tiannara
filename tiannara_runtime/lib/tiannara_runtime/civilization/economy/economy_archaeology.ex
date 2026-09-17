defmodule TiannaraRuntime.Civilization.Economy.EconomyArchaeology do
  def record(ledger, allocator, origin) do
    archaeology = %{
      transaction_summary: %{
        count: length(ledger.transactions),
        net_flow: Enum.reduce(ledger.transactions, 0, fn tx, acc -> acc + Map.get(tx, :amount) end)
      },
      allocation_lineage: %{
        total_allocated: Enum.reduce(allocator.allocations, 0, fn {_id, amt}, acc -> acc + amt end),
        programs: Map.keys(allocator.allocations),
        remaining: allocator.total
      },
      investment_narrative: %{
        origin: origin,
        total_capital: allocator.total,
        allocation_count: map_size(allocator.allocations)
      }
    }
    {:ok, archaeology}
  end

  def explain(archaeology) do
    tx_summary = Map.get(archaeology, :transaction_summary, %{})
    alloc_lineage = Map.get(archaeology, :allocation_lineage, %{})
    narrative = Map.get(archaeology, :investment_narrative, %{})
    tx_count = Map.get(tx_summary, :count, 0)
    net_flow = Map.get(tx_summary, :net_flow, 0)
    programs = length(Map.get(alloc_lineage, :programs, []))
    origin = Map.get(narrative, :origin, "unknown")
    total = Map.get(narrative, :total_capital, 0)
    result = "Origin: #{origin} | Transactions: #{tx_count} (net: #{net_flow}) | Programs: #{programs} | Capital: #{total}"
    {:ok, result}
  end

  def get_lineage(archaeology) do
    {:ok, Map.get(archaeology, :allocation_lineage, %{})}
  end
end
