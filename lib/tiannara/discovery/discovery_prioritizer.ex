defmodule Tiannara.Discovery.DiscoveryPrioritizer do
  alias Tiannara.Discovery.{Discovery, DiscoveryScore}

  @max_same_domain 3
  @max_same_causal_model 2

  @spec rank([Discovery.t()]) :: [Discovery.t()]
  def rank(discoveries) when is_list(discoveries) do
    Enum.sort_by(discoveries, fn disc -> DiscoveryScore.composite(disc.score) end, :desc)
  end

  @spec rank_with_diversity([Discovery.t()]) :: [Discovery.t()]
  def rank_with_diversity(discoveries) when is_list(discoveries) do
    discoveries |> rank() |> enforce_diversity()
  end

  @spec select_for_execution([Discovery.t()], non_neg_integer(), map()) :: [Discovery.t()]
  def select_for_execution(discoveries, max_count, resource_budget \\ %{}) do
    discoveries |> rank_with_diversity() |> Enum.take(max_count) |> filter_by_budget(resource_budget)
  end

  @spec systemic_bottleneck([Discovery.t()]) :: {atom(), float()} | nil
  def systemic_bottleneck([]), do: nil
  def systemic_bottleneck(discoveries) when is_list(discoveries) do
    DiscoveryScore.dimensions()
    |> Enum.map(fn dim ->
      avg = discoveries |> Enum.map(fn disc -> Map.fetch!(disc.score, dim) end) |> Enum.sum() |> Kernel./(length(discoveries))
      {dim, avg}
    end)
    |> Enum.min_by(fn {_dim, avg} -> avg end)
  end

  @spec detect_monoculture([Discovery.t()]) :: [map()]
  def detect_monoculture(discoveries) when is_list(discoveries) do
    domain_counts = discoveries |> Enum.group_by(fn disc -> disc.gap.domain end) |> Map.new(fn {d, ds} -> {d, length(ds)} end)
    causal_model_counts = discoveries
      |> Enum.flat_map(fn disc -> disc.hypotheses end)
      |> Enum.group_by(fn hyp -> Map.get(hyp.metadata || %{}, :causal_model, :unknown) end)
      |> Map.new(fn {m, hs} -> {m, length(hs)} end)

    warnings = Enum.reduce(domain_counts, [], fn {domain, count}, acc ->
      if count > @max_same_domain, do: [%{type: :domain_monoculture, domain: domain, count: count, threshold: @max_same_domain} | acc], else: acc
    end)
    Enum.reduce(causal_model_counts, warnings, fn {model, count}, acc ->
      if count > @max_same_causal_model, do: [%{type: :causal_model_monoculture, model: model, count: count, threshold: @max_same_causal_model} | acc], else: acc
    end)
  end

  defp enforce_diversity(ranked_discoveries) do
    {selected, _domains, _models} = Enum.reduce(ranked_discoveries, {[], %{}, %{}}, fn disc, {acc, domains, models} ->
      domain = disc.gap.domain
      disc_models = disc.hypotheses |> Enum.map(fn hyp -> Map.get(hyp.metadata || %{}, :causal_model, :unknown) end) |> Enum.uniq()
      model_over = Enum.any?(disc_models, fn m -> Map.get(models, m, 0) >= @max_same_causal_model end)
      if Map.get(domains, domain, 0) < @max_same_domain and not model_over do
        {[disc | acc], Map.update(domains, domain, 1, &(&1 + 1)), Enum.reduce(disc_models, models, fn m, a -> Map.update(a, m, 1, &(&1 + 1)) end)}
      else
        {acc, domains, models}
      end
    end)
    Enum.reverse(selected)
  end

  defp filter_by_budget(discoveries, resource_budget) when map_size(resource_budget) == 0, do: discoveries
  defp filter_by_budget(discoveries, resource_budget) do
    max_compute = Map.get(resource_budget, :compute, :infinity)
    max_time = Map.get(resource_budget, :time_hours, :infinity)
    {selected, _used} = Enum.reduce(discoveries, {[], %{compute: 0, time_hours: 0}}, fn disc, {acc, used} ->
      exp_cost = disc.experiments |> Enum.reduce(%{compute: 0, time_hours: 0}, fn exp, ca ->
        %{compute: ca.compute + Map.get(exp.estimated_cost || %{}, :compute, 0),
          time_hours: ca.time_hours + Map.get(exp.estimated_cost || %{}, :time_hours, 0)}
      end)
      new_c = used.compute + exp_cost.compute
      new_t = used.time_hours + exp_cost.time_hours
      if new_c <= max_compute and new_t <= max_time,
        do: {[disc | acc], %{compute: new_c, time_hours: new_t}},
        else: {acc, used}
    end)
    Enum.reverse(selected)
  end
end
