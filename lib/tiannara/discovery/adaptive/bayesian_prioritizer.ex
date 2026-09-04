defmodule Tiannara.Discovery.Adaptive.BayesianPrioritizer do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.DiscoveryScore

  @spec prioritize(Discovery.t(), [Discovery.t()]) :: float()
  def prioritize(%Discovery{} = disc, history) when is_list(history) do
    base_score = DiscoveryScore.composite(disc.score)
    bayesian_factor = compute_bayesian_factor(disc, history)
    opportunity_factor = compute_opportunity_cost(disc, history)
    max(0.0, min(1.0, base_score * bayesian_factor * opportunity_factor))
  end

  @spec rank([Discovery.t()], [Discovery.t()]) :: [{Discovery.t(), float()}]
  def rank(discoveries, history) when is_list(discoveries) do
    discoveries
    |> Enum.map(fn disc -> {disc, prioritize(disc, history)} end)
    |> Enum.sort_by(fn {_disc, priority} -> priority end, :desc)
  end

  @spec learn(map(), Discovery.t(), atom()) :: map()
  def learn(model, %Discovery{} = disc, outcome) do
    domain = if disc.gap, do: disc.gap.domain, else: :unknown
    severity = if disc.gap, do: disc.gap.severity, else: :medium

    domain_stats = Map.get(model, :domain_stats, %{})
    domain_stat = Map.get(domain_stats, domain, %{successes: 0, failures: 0, total: 0})
    domain_stat = %{domain_stat |
      total: domain_stat.total + 1,
      successes: domain_stat.successes + if(outcome == :success, do: 1, else: 0),
      failures: domain_stat.failures + if(outcome == :failure, do: 1, else: 0)
    }

    severity_stats = Map.get(model, :severity_stats, %{})
    severity_stat = Map.get(severity_stats, severity, %{successes: 0, failures: 0, total: 0})
    severity_stat = %{severity_stat |
      total: severity_stat.total + 1,
      successes: severity_stat.successes + if(outcome == :success, do: 1, else: 0),
      failures: severity_stat.failures + if(outcome == :failure, do: 1, else: 0)
    }

    %{model |
      domain_stats: Map.put(domain_stats, domain, domain_stat),
      severity_stats: Map.put(severity_stats, severity, severity_stat),
      total_observations: Map.get(model, :total_observations, 0) + 1,
      last_updated: DateTime.utc_now()
    }
  end

  @spec init_model() :: map()
  def init_model do
    %{
      domain_stats: %{},
      severity_stats: %{},
      total_observations: 0,
      last_updated: DateTime.utc_now()
    }
  end

  @spec calibration_error(map(), [Discovery.t()]) :: float()
  def calibration_error(model, completed_discoveries) do
    if completed_discoveries == [] do
      0.0
    else
      errors =
        Enum.map(completed_discoveries, fn disc ->
          predicted = prioritize(disc, [])
          actual = if disc.status == :completed and disc.confidence > 0.7, do: 1.0, else: 0.0
          abs(predicted - actual)
        end)

      Enum.sum(errors) / length(errors)
    end
  end

  defp compute_bayesian_factor(%Discovery{} = disc, history) do
    if history == [] do
      1.0
    else
      domain = if disc.gap, do: disc.gap.domain, else: :unknown

      domain_discoveries = Enum.filter(history, fn d ->
        d.gap != nil and d.gap.domain == domain
      end)

      if domain_discoveries == [] do
        1.0
      else
        successes = Enum.count(domain_discoveries, fn d ->
          d.status == :completed and d.confidence > 0.7
        end)

        success_rate = successes / length(domain_discoveries)
        max(0.5, min(1.5, 0.5 + success_rate))
      end
    end
  end

  defp compute_opportunity_cost(%Discovery{} = disc, history) do
    if history == [] do
      1.0
    else
      domain = if disc.gap, do: disc.gap.domain, else: :unknown
      domain_count = Enum.count(history, fn d ->
        d.gap != nil and d.gap.domain == domain
      end)
      1.0 / :math.sqrt(domain_count + 1)
    end
  end
end
