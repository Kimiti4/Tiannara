defmodule Tiannara.MetaScience.PortfolioOptimizer do
  @moduledoc """
  Optimizes the research portfolio across all 20 domains.
  Allocates compute and experimental resources to maximize
  expected knowledge gain and minimize redundant discovery.

  B11/D-A2: selection utility is the declared `domain_weight` only —
  no random/fabricated EIG or cost metrics.
  """

  @doc "Selects the next best experiment across candidates by domain_weight (deterministic)."
  @spec select_next_experiment([map()]) :: {:ok, map() | nil} | {:error, :no_candidates}
  def select_next_experiment([]), do: {:error, :no_candidates}

  def select_next_experiment(candidate_experiments) when is_list(candidate_experiments) do
    scored =
      Enum.map(candidate_experiments, fn exp ->
        weight = Map.get(exp, :domain_weight, 0.0)
        %{experiment: exp, utility: weight}
      end)

    best = Enum.max_by(scored, & &1.utility, fn -> nil end)
    {:ok, best}
  end
end
