defmodule Tiannara.Sentinel.D2.EpistemicNiche do
  @moduledoc """
  Phase 9.75: Epistemological Niches.
  Species compete contextually within Niches, which favor specific operator patterns.
  """

  defstruct [
    domain: nil,
    preferred_operator_patterns: [],
    fitness_multiplier: 1.0
  ]

  defp niches do
    %{
      science_math_comp: %__MODULE__{
        domain: :engineering,
        preferred_operator_patterns: ["symbolic", "recursive", "formal"],
        fitness_multiplier: 1.5
      },
      engineering_construction_materials: %__MODULE__{
        domain: :engineering,
        preferred_operator_patterns: ["causal", "empirical", "counterfactual"],
        fitness_multiplier: 1.5
      },
      governance_finance_law: %__MODULE__{
        domain: :governance,
        preferred_operator_patterns: ["adversarial", "analogical", "recursive"],
        fitness_multiplier: 1.5
      }
    }
  end

  @doc "Evaluates an operator set's fitness multiplier in a given niche."
  def evaluate_niche_fitness(operators, niche_name) do
    case Map.get(niches(), niche_name) do
      nil -> 1.0
      niche ->
        # Calculate how many preferred patterns match the active operators
        matches = Enum.count(operators, fn op ->
          Enum.any?(niche.preferred_operator_patterns, &String.contains?(op, &1))
        end)
        
        if matches > 0 do
          1.0 + (matches * 0.2) * niche.fitness_multiplier
        else
          0.8 # Penalty for being totally misaligned with the niche
        end
    end
  end
  
  @doc "Returns all defined niches."
  def available_niches, do: Map.keys(niches())
end
