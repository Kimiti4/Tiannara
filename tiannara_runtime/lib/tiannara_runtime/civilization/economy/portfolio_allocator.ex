defmodule TiannaraRuntime.Civilization.Economy.PortfolioAllocator do
  def initialize(domains) do
    domain_map = Enum.reduce(domains, %{}, fn d, acc ->
      Map.put(acc, d, %{allocation: 0, programs: []})
    end)
    {:ok, %{domains: domain_map, total: 0}}
  end

  def allocate(allocator, domain, amount) do
    current = Map.get(allocator.domains, domain, %{allocation: 0, programs: []})
    updated_domain = %{current | allocation: Map.get(current, :allocation, 0) + amount}
    new_domains = Map.put(allocator.domains, domain, updated_domain)
    {:ok, %{allocator | domains: new_domains, total: allocator.total + amount}}
  end

  def balance(allocator) do
    domain_count = map_size(allocator.domains)
    if domain_count == 0 do
      {:ok, allocator}
    else
      per_domain = div(allocator.total, domain_count)
      balanced = Enum.reduce(allocator.domains, %{}, fn {domain, _config}, acc ->
        Map.put(acc, domain, %{allocation: per_domain, programs: []})
      end)
      {:ok, %{allocator | domains: balanced}}
    end
  end

  def metrics(allocator) do
    domain_list = Enum.map(allocator.domains, fn {domain, config} ->
      %{domain: domain, allocation: Map.get(config, :allocation, 0), program_count: length(Map.get(config, :programs, []))}
    end)
    {:ok, %{domains: domain_list, total: allocator.total}}
  end
end
