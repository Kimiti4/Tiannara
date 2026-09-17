defmodule TiannaraRuntime.Cognitive.Civilization.PortfolioGovernor do
  def create(civilization_id, programs) do
    portfolio = %{
      id: "rpf_#{:erlang.unique_integer([:positive])}",
      civilization_id: civilization_id,
      programs: programs,
      novelty_score: 0.5,
      uncertainty_score: 0.5,
      maturity_score: 0.0,
      productivity: 0.0,
      expected_impact: 0.5,
      collaboration_density: 0.0
    }
    {:ok, portfolio}
  end

  def add_program(portfolio, program) do
    programs = Map.get(portfolio, :programs) ++ [program]
    {:ok, Map.put(portfolio, :programs, programs)}
  end

  def recompute_scores(portfolio) do
    program_count = length(Map.get(portfolio, :programs))
    updated = portfolio
    |> Map.put(:novelty_score, min(0.5 + program_count * 0.01, 1.0))
    |> Map.put(:uncertainty_score, max(0.5 - program_count * 0.02, 0.0))
    |> Map.put(:maturity_score, min(program_count * 0.05, 1.0))
    |> Map.put(:productivity, min(program_count * 0.03, 1.0))
    |> Map.put(:expected_impact, min(0.5 + program_count * 0.02, 1.0))
    |> Map.put(:collaboration_density, 0.0)
    {:ok, updated}
  end

  def evaluate(portfolio) do
    novelty = Map.get(portfolio, :novelty_score)
    uncertainty = Map.get(portfolio, :uncertainty_score)
    maturity = Map.get(portfolio, :maturity_score)
    productivity = Map.get(portfolio, :productivity)
    expected_impact = Map.get(portfolio, :expected_impact)
    collab_density = Map.get(portfolio, :collaboration_density)
    avg = (novelty + uncertainty + maturity + productivity + expected_impact + collab_density) / 6.0
    recommendation = cond do
      novelty > 0.6 -> :expand
      uncertainty < 0.2 -> :consolidate
      true -> :balanced
    end
    {:ok, %{average_score: avg, recommendation: recommendation}}
  end
end
