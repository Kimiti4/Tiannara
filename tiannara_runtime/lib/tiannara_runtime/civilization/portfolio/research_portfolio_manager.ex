defmodule TiannaraRuntime.Civilization.Portfolio.ResearchPortfolioManager do
  def initialize() do
    {:ok, %{portfolios: [], domains: %{}, total_programs: 0, balance: 0.5, diversity: 0.0}}
  end

  def add_portfolio(manager, portfolio) do
    {:ok, %{manager | portfolios: manager.portfolios ++ [portfolio]}}
  end

  def update(manager, domain, metrics) do
    domains = Map.put(manager.domains, domain, metrics)
    total = map_size(domains)
    balance = if total == 0, do: 0.5, else: Enum.reduce(domains, 0.0, fn {_k, m}, acc -> acc + Map.get(m, :weight, 0.0) end) / total
    diversity = if total < 2, do: 0.0, else: Enum.reduce(domains, 0.0, fn {_k, m}, acc -> acc + abs(Map.get(m, :weight, 0.0) - balance) end) / total
    {:ok, %{manager | domains: domains, balance: balance, diversity: diversity}}
  end

  def validate(manager) do
    ids = Enum.map(manager.portfolios, fn p -> Map.get(p, :id) end)
    duplicates = ids -- Enum.uniq(ids)
    if duplicates == [] do
      :ok
    else
      {:error, duplicates}
    end
  end

  def metrics(manager) do
    {:ok, %{portfolio_count: length(manager.portfolios), domains: map_size(manager.domains), balance: manager.balance, diversity: manager.diversity}}
  end
end
