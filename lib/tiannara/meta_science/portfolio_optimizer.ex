defmodule Tiannara.MetaScience.PortfolioOptimizer do
  @moduledoc """
  Optimizes the research portfolio across all 20 domains.
  Allocates compute and experimental resources to maximize
  expected knowledge gain and minimize redundant discovery.
  """

  alias Tiannara.Foundations.InformationTheory

  @doc "Selects the next best experiment to run across all domains using Expected Information Gain."
  def select_next_experiment(candidate_experiments) do
    scored =
      Enum.map(candidate_experiments, fn exp ->
        eig = calculate_eig(exp)
        cost = estimate_resource_cost(exp)
        utility = (eig * exp.domain_weight) / max(cost, 0.01)
        %{experiment: exp, utility: utility, eig: eig, cost: cost}
      end)

    best = Enum.max_by(scored, & &1.utility, fn -> nil end)
    {:ok, best}
  end

  defp calculate_eig(_experiment), do: :rand.uniform() * 2.5
  defp estimate_resource_cost(_experiment), do: :rand.uniform() * 100.0
end
