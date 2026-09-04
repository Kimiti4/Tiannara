defmodule Tiannara.Discovery.Advanced.DiscoveryPortfolioOptimizer do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.DiscoveryScore

  @spec optimize([Discovery.t()], map()) :: map()
  def optimize(discoveries, constraints \\ %{}) when is_list(discoveries) do
    max_active = Map.get(constraints, :max_active, 5)
    budget = Map.get(constraints, :budget, :infinity)
    exploration_weight = Map.get(constraints, :exploration_weight, 0.3)

    scored = Enum.map(discoveries, fn disc ->
      score = if is_struct(disc.score, DiscoveryScore), do: disc.score, else: struct(DiscoveryScore, disc.score || %{})
      value = DiscoveryScore.composite(score)
      novelty = disc.uncertainty
      cost = estimate_cost(disc)
      blended = value * (1.0 - exploration_weight) + novelty * exploration_weight
      %{discovery: disc, value: value, novelty: novelty, cost: cost, blended_score: blended}
    end)

    ranked = Enum.sort_by(scored, & &1.blended_score, :desc)

    {selected, _remaining_budget} = Enum.reduce(ranked, {[], budget}, fn item, {acc, remaining} ->
      if length(acc) < max_active and (remaining == :infinity or item.cost <= remaining) do
        new_remaining = if remaining == :infinity, do: :infinity, else: remaining - item.cost
        {[item | acc], new_remaining}
      else
        {acc, remaining}
      end
    end)

    selected = Enum.reverse(selected)
    total_score = Enum.reduce(selected, 0.0, fn item, acc -> acc + item.blended_score end)

    allocations = Enum.map(selected, fn item ->
      weight = if total_score > 0, do: item.blended_score / total_score, else: 1.0 / max(1, length(selected))
      %{discovery_id: item.discovery.id, weight: weight, value: item.value, novelty: item.novelty, cost: item.cost, blended_score: item.blended_score}
    end)

    diversity = compute_portfolio_diversity(selected)

    %{
      selected: Enum.map(selected, & &1.discovery.id),
      allocations: allocations,
      portfolio_diversity: diversity,
      total_value: Enum.reduce(selected, 0.0, fn item, acc -> acc + item.value end),
      total_cost: Enum.reduce(selected, 0.0, fn item, acc -> acc + item.cost end),
      exploration_exploitation_balance: exploration_weight,
      rejected: Enum.map(ranked -- selected, & &1.discovery.id)
    }
  end

  @spec compute_portfolio_diversity([map()]) :: float()
  def compute_portfolio_diversity(selected) do
    if length(selected) < 2 do
      1.0
    else
      domains = Enum.map(selected, fn item -> item.discovery.gap && item.discovery.gap.domain end)
      unique_domains = Enum.uniq(domains)
      length(unique_domains) / length(domains)
    end
  end

  defp estimate_cost(%Discovery{} = disc) do
    disc.experiments |> Enum.reduce(0, fn exp, acc ->
      acc + Map.get(exp.estimated_cost, :compute, 0) + Map.get(exp.estimated_cost, :time_hours, 0)
    end)
  end
end
