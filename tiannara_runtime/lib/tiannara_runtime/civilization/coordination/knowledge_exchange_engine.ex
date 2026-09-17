defmodule TiannaraRuntime.Civilization.Coordination.KnowledgeExchangeEngine do
  def initialize() do
    {:ok, %{exchanges: [], transfer_log: [], domains: %{}}}
  end

  def exchange(engine, from_domain, to_domain, knowledge_item) do
    transfer = %{from: from_domain, to: to_domain, item: knowledge_item, id: :erlang.unique_integer([:positive])}
    domains = engine.domains
    domains = Map.put(domains, from_domain, true)
    domains = Map.put(domains, to_domain, true)
    {:ok, %{engine | exchanges: engine.exchanges ++ [transfer], transfer_log: engine.transfer_log ++ [transfer], domains: domains}}
  end

  def get_transfers(engine, domain) do
    transfers = Enum.filter(engine.transfer_log, fn t -> Map.get(t, :from) == domain or Map.get(t, :to) == domain end)
    {:ok, transfers}
  end

  def metrics(engine) do
    {:ok, %{total_exchanges: length(engine.exchanges), domains_involved: map_size(engine.domains)}}
  end
end
