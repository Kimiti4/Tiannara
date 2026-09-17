defmodule TiannaraRuntime.Cognitive.Engines.AttentionBudget do
  @moduledoc false

  defstruct [:budgets]

  def new(budgets) do
    state = Map.new(budgets, fn {k, v} -> {k, %{total: v, available: v}} end)
    %__MODULE__{budgets: state}
  end

  def total(budget, resource_type) do
    case Map.fetch(budget.budgets, resource_type) do
      {:ok, %{total: total}} -> {:ok, total}
      :error -> {:error, :unknown_resource}
    end
  end

  def available(budget, resource_type) do
    case Map.fetch(budget.budgets, resource_type) do
      {:ok, %{available: available}} -> {:ok, available}
      :error -> {:error, :unknown_resource}
    end
  end

  def consume(budget, resource_type, amount) do
    case Map.fetch(budget.budgets, resource_type) do
      {:ok, %{total: total, available: available}} when available >= amount ->
        updated = %{budget | budgets: Map.put(budget.budgets, resource_type, %{total: total, available: available - amount})}
        {:ok, updated}
      {:ok, _} ->
        {:error, :insufficient_budget}
      :error ->
        {:error, :unknown_resource}
    end
  end

  def release(budget, resource_type, amount) do
    case Map.fetch(budget.budgets, resource_type) do
      {:ok, %{total: total, available: available}} ->
        new_available = min(total, available + amount)
        updated = %{budget | budgets: Map.put(budget.budgets, resource_type, %{total: total, available: new_available})}
        {:ok, updated}
      :error ->
        {:error, :unknown_resource}
    end
  end

  def rebalance(budget) do
    budgets = Map.new(budget.budgets, fn {k, %{total: total}} -> {k, %{total: total, available: total}} end)
    {:ok, %{budget | budgets: budgets}}
  end
end
