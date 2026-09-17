defmodule TiannaraRuntime.Civilization.Economy.InvestmentPlanner do
  def initialize() do
    {:ok, %{schedule: [], expected_returns: %{}, dependencies: %{}}}
  end

  def plan(planner, program_id, amount, horizon, expected_return) do
    entry = %{
      program_id: program_id,
      amount: amount,
      horizon: horizon,
      expected_return: expected_return
    }
    new_returns = Map.put(planner.expected_returns, program_id, expected_return)
    {:ok, %{planner | schedule: [entry | planner.schedule], expected_returns: new_returns}}
  end

  def project(planner, horizon) do
    relevant = Enum.filter(planner.schedule, fn entry ->
      Map.get(entry, :horizon) <= horizon
    end)
    total = Enum.reduce(relevant, 0.0, fn entry, acc ->
      amt = Map.get(entry, :amount, 0)
      ret = Map.get(entry, :expected_return, 0.0)
      acc + amt * ret
    end)
    {:ok, total}
  end

  def metrics(planner) do
    count = length(planner.schedule)
    avg_return = if count == 0 do
      0.0
    else
      Enum.reduce(planner.schedule, 0.0, fn entry, acc ->
        acc + Map.get(entry, :expected_return, 0.0)
      end) / count
    end
    {:ok, %{
      program_count: count,
      average_expected_return: avg_return,
      dependency_count: map_size(planner.dependencies)
    }}
  end
end
