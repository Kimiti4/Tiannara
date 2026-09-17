defmodule TiannaraRuntime.Civilization.Runtime.InfrastructureRuntime do
  def initialize(sectors) do
    state = Enum.reduce(sectors, %{}, fn {name, config}, acc ->
      Map.put(acc, name, %{
        level: Map.get(config, :level, 0),
        capacity: Map.get(config, :capacity, 0),
        health: Map.get(config, :health, 1.0)
      })
    end)
    {:ok, state}
  end

  def update(state, sector, changes) do
    current = Map.get(state, sector, %{level: 0, capacity: 0, health: 1.0})
    updated = Enum.reduce(changes, current, fn {key, val}, acc ->
      Map.put(acc, key, val)
    end)
    {:ok, Map.put(state, sector, updated)}
  end

  def tick(state) do
    updated = Enum.reduce(state, %{}, fn {sector, config}, acc ->
      new_health = max(0.0, Map.get(config, :health, 1.0) - 0.001)
      Map.put(acc, sector, %{config | health: new_health})
    end)
    {:ok, updated}
  end

  def invest(state, sector, amount) do
    current = Map.get(state, sector, %{level: 0, capacity: 0, health: 1.0})
    new_level = Map.get(current, :level, 0) + amount
    new_capacity = Map.get(current, :capacity, 0) + amount * 10
    updated = %{current | level: new_level, capacity: new_capacity}
    {:ok, Map.put(state, sector, updated)}
  end

  def metrics(state) do
    sectors = Map.to_list(state)
    count = length(sectors)
    avg_health = if count == 0 do
      0.0
    else
      Enum.reduce(sectors, 0.0, fn {_name, config}, acc ->
        acc + Map.get(config, :health, 0.0)
      end) / count
    end
    total_capacity = Enum.reduce(sectors, 0, fn {_name, config}, acc ->
      acc + Map.get(config, :capacity, 0)
    end)
    {:ok, %{sector_count: count, avg_health: avg_health, total_capacity: total_capacity}}
  end
end
