defmodule Tiannara.Evolution.MetaLearner do
  @spec select_strategy(map(), map()) :: {String.t(), float()}
  def select_strategy(context, model) do
    strategies = Map.get(model, :strategies, %{})

    if strategies == %{} do
      {"default", 0.5}
    else
      sampled =
        Enum.map(strategies, fn {strategy_id, stats} ->
          alpha = Map.get(stats, :successes, 1) + 1
          beta_param = Map.get(stats, :failures, 1) + 1

          sample = sample_beta(alpha, beta_param)

          context_bonus = compute_context_bonus(context, stats)

          {strategy_id, sample + context_bonus * 0.1}
        end)

      Enum.max_by(sampled, fn {_id, score} -> score end)
    end
  end

  @spec update(map(), String.t(), boolean(), map()) :: map()
  def update(model, strategy_id, success, context) do
    strategies = Map.get(model, :strategies, %{})

    stats = Map.get(strategies, strategy_id, %{
      successes: 0,
      failures: 0,
      total: 0,
      contexts: %{},
      last_updated: nil
    })

    stats = %{stats |
      successes: stats.successes + if(success, do: 1, else: 0),
      failures: stats.failures + if(success, do: 0, else: 1),
      total: stats.total + 1,
      last_updated: DateTime.utc_now()
    }

    context_key = context_key(context)
    context_stats = Map.get(stats.contexts, context_key, %{successes: 0, failures: 0})

    context_stats = %{context_stats |
      successes: context_stats.successes + if(success, do: 1, else: 0),
      failures: context_stats.failures + if(success, do: 0, else: 1)
    }

    stats = %{stats | contexts: Map.put(stats.contexts, context_key, context_stats)}

    %{model |
      strategies: Map.put(strategies, strategy_id, stats),
      total_observations: Map.get(model, :total_observations, 0) + 1,
      last_updated: DateTime.utc_now()
    }
  end

  @spec init_model() :: map()
  def init_model do
    %{
      strategies: %{},
      total_observations: 0,
      last_updated: nil,
      version: 1
    }
  end

  @spec success_rate(map(), String.t(), map()) :: float()
  def success_rate(model, strategy_id, context) do
    strategies = Map.get(model, :strategies, %{})
    stats = Map.get(strategies, strategy_id, %{successes: 0, total: 0, contexts: %{}})

    context_key = context_key(context)
    context_stats = Map.get(stats.contexts, context_key)

    if context_stats && (context_stats.successes + context_stats.failures) >= 3 do
      context_stats.successes / (context_stats.successes + context_stats.failures)
    else
      if stats.total > 0, do: stats.successes / stats.total, else: 0.5
    end
  end

  defp sample_beta(alpha, beta_param) do
    alpha / (alpha + beta_param)
  end

  defp compute_context_bonus(context, stats) do
    context_key = context_key(context)
    context_stats = Map.get(stats.contexts, context_key)

    if context_stats && (context_stats.successes + context_stats.failures) > 0 do
      context_stats.successes / (context_stats.successes + context_stats.failures)
    else
      0.0
    end
  end

  defp context_key(context) do
    domain = Map.get(context, :domain, :unknown)
    severity = Map.get(context, :severity, :medium)
    "#{domain}_#{severity}"
  end
end
