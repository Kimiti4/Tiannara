defmodule Tiannara.Research.ExperimentRanker do
  @moduledoc """
  Multi-factor experiment ranking for the Ω.2 Research Director. Weighs:
  expected information gain, uncertainty reduction, scientific relevance, cost,
  risk, reproducibility, and feasibility (with dependency availability).
  Constitutional constraints are a HARD gate: a constitutionally-blocked
  experiment scores zero regardless of how attractive it otherwise is.

  Constitutional basis: "Capability must never outpace verification",
  "Security by design", "Evidence Before Confidence."
  """

  @weights %{
    info_gain: 0.25,
    uncertainty_reduction: 0.20,
    relevance: 0.15,
    cost: 0.10,
    risk: 0.10,
    reproducibility: 0.10,
    feasibility: 0.10
  }

  def weights, do: @weights

  @doc "Rank candidates by composite score (deterministic)."
  def rank(candidates) do
    candidates
    |> Enum.map(&score/1)
    |> Enum.sort_by(&(-&1.composite_score))
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, rank} -> Map.put(candidate, :rank, rank) end)
  end

  @doc """
  Score one candidate. Constitutional compliance is a hard gate; unavailable
  dependencies apply a feasibility penalty.
  """
  def score(candidate) do
    if not Map.get(candidate, :constitutional_ok, true) do
      Map.put(candidate, :composite_score, 0.0)
    else
      dependency_factor =
        if Map.get(candidate, :dependencies_available, true), do: 1.0, else: 0.3

      composite =
        @weights.info_gain * norm(candidate.expected_information_gain) +
          @weights.uncertainty_reduction * norm(candidate.uncertainty_reduction) +
          @weights.relevance * norm(candidate.scientific_relevance) +
          @weights.cost * (1.0 - norm(candidate.cost)) +
          @weights.risk * (1.0 - norm(candidate.risk)) +
          @weights.reproducibility * norm(candidate.reproducibility) +
          @weights.feasibility * (norm(candidate.feasibility) * dependency_factor)

      Map.put(candidate, :composite_score, Float.round(composite, 4))
    end
  end

  defp norm(value) when is_number(value), do: max(0.0, min(1.0, value))
  defp norm(_), do: 0.0
end