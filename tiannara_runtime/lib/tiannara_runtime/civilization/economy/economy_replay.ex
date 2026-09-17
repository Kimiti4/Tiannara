defmodule TiannaraRuntime.Civilization.Economy.EconomyReplay do
  def record(ledger, allocator, planner) do
    replay = %{
      transactions: ledger.transactions,
      allocations: allocator.allocations,
      schedule: planner.schedule,
      expected_returns: planner.expected_returns,
      dependencies: planner.dependencies,
      timestamp: :erlang.unique_integer([:positive])
    }
    {:ok, replay}
  end

  def verify(replay, ledger, allocator, planner) do
    replay_txs = Map.get(replay, :transactions, [])
    replay_allocs = Map.get(replay, :allocations, %{})
    replay_schedule = Map.get(replay, :schedule, [])
    replay_returns = Map.get(replay, :expected_returns, %{})
    replay_deps = Map.get(replay, :dependencies, %{})
    txs_match = replay_txs == ledger.transactions
    allocs_match = replay_allocs == allocator.allocations
    sched_match = replay_schedule == planner.schedule
    returns_match = replay_returns == planner.expected_returns
    deps_match = replay_deps == planner.dependencies
    if txs_match and allocs_match and sched_match and returns_match and deps_match do
      {:ok, :verified}
    else
      {:error, :mismatch}
    end
  end
end
