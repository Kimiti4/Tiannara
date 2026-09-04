defmodule Tiannara.Discovery.Adaptive.OpportunityCostEstimator do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.DiscoveryScore

  @spec estimate(Discovery.t(), [Discovery.t()]) :: float()
  def estimate(%Discovery{} = chosen, alternatives) when is_list(alternatives) do
    chosen_value = DiscoveryScore.composite(chosen.score)

    alternative_values =
      Enum.map(alternatives, fn alt ->
        DiscoveryScore.composite(alt.score)
      end)

    best_alternative = if alternative_values == [], do: 0.0, else: Enum.max(alternative_values)
    max(0.0, best_alternative - chosen_value)
  end

  @spec optimal_choice([Discovery.t()]) :: {Discovery.t(), float()} | nil
  def optimal_choice([]), do: nil
  def optimal_choice(discoveries) when is_list(discoveries) do
    discoveries
    |> Enum.map(fn disc -> {disc, DiscoveryScore.composite(disc.score)} end)
    |> Enum.max_by(fn {_disc, score} -> score end)
  end

  @spec expected_value_of_information(Discovery.t()) :: float()
  def expected_value_of_information(%Discovery{} = disc) do
    uncertainty = disc.uncertainty
    impact = if disc.gap, do: disc.gap.estimated_impact, else: 0.5
    feasibility = DiscoveryScore.composite(disc.score)
    uncertainty * impact * feasibility
  end
end
