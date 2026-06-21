defmodule Tiannara.SOPL.LawFragment do
  @moduledoc """
  SOPL-3: Law Fragment
  
  A reusable ontological primitive extracted from a successful LawLineage 
  or a failed LawRuin. We no longer recombine whole laws.
  """
  defstruct [
    :id,
    :source_law_id,
    :category,               # :truth, :novelty, :resilience, :diversity, :discovery, :trust, :constraint
    :parameters,             # Map of specific variables
    :fitness_contribution,   # How much this specific trait contributed to success/failure
    :pathology_profile,      # Any diseases the source law carried
    :constitutional_pressure # Invariant strain of the source law
  ]
end

defmodule Tiannara.SOPL.LawFragmentExtractor do
  @moduledoc """
  SOPL-3: Law Fragment Extractor
  
  Mines evolutionary history (Ruins and Lineages) for highly specialized 
  functional sub-components. Treats the forces that prevented collapse 
  (:constraint) as equally valuable to generators of novelty.
  """
  alias Tiannara.SOPL.LawFragment
  require Logger

  @doc "Extracts fragments from an evaluated law or a LawRuin."
  def extract(source, fitness_metrics \\ %{}, pathologies \\ [], pressure \\ 0.0) do
    # source can be %LawGenome{} or %LawRuin{}
    law = if Map.has_key?(source, :law_genome), do: source.law_genome, else: source
    
    fragments = [
      extract_novelty(law, fitness_metrics, pathologies, pressure),
      extract_constraint(law, fitness_metrics, pathologies, pressure),
      extract_truth(law, fitness_metrics, pathologies, pressure),
      extract_resilience(law, fitness_metrics, pathologies, pressure)
    ] |> Enum.reject(&is_nil/1)

    Logger.debug("⛏️ [SOPL-3] Extracted #{length(fragments)} fragments from Law #{law.id}")
    fragments
  end

  defp extract_novelty(law, metrics, pathologies, pressure) do
    # E.g. Shard A failed but had incredible novelty generation.
    novelty_score = get_in(metrics, [:potential, :novelty]) || 0.0
    if novelty_score > 0.6 do
      %LawFragment{
        id: "frag_nov_#{law.id}",
        source_law_id: law.id,
        category: :novelty,
        parameters: %{
          mutation_pressure: law.mutation_pressure,
          novelty_reward: law.novelty_reward
        },
        fitness_contribution: novelty_score,
        pathology_profile: pathologies,
        constitutional_pressure: pressure
      }
    else
      nil
    end
  end

  defp extract_constraint(law, metrics, pathologies, pressure) do
    # Constraint Fragments regulate novelty to prevent collapse.
    stability_score = get_in(metrics, [:health, :stability]) || 0.0
    if stability_score > 0.6 do
      %LawFragment{
        id: "frag_con_#{law.id}",
        source_law_id: law.id,
        category: :constraint,
        parameters: %{
          diversity_floor: law.diversity_floor,
          economic_cap: Map.get(law.fitness_weights, :economic_cap, 5000.0)
        },
        fitness_contribution: stability_score,
        pathology_profile: pathologies,
        constitutional_pressure: pressure
      }
    else
      nil
    end
  end

  defp extract_truth(law, metrics, pathologies, pressure) do
    # Anchors the universe against semantic drift.
    truth_score = get_in(metrics, [:health, :truth_retention]) || 0.0
    if truth_score > 0.6 do
      %LawFragment{
        id: "frag_tru_#{law.id}",
        source_law_id: law.id,
        category: :truth,
        parameters: %{
          identity_persistence_weight: Map.get(law.trust_formula, :identity_persistence_weight, 0.5),
          causal_tolerance: Map.get(law.extinction_model, :causal_tolerance, 0.1)
        },
        fitness_contribution: truth_score,
        pathology_profile: pathologies,
        constitutional_pressure: pressure
      }
    else
      nil
    end
  end

  defp extract_resilience(law, metrics, pathologies, pressure) do
    resilience_score = get_in(metrics, [:health, :resilience]) || 0.0
    if resilience_score > 0.6 do
      %LawFragment{
        id: "frag_res_#{law.id}",
        source_law_id: law.id,
        category: :resilience,
        parameters: %{
          virulence_multiplier: Map.get(law.disease_sensitivity, :virulence_multiplier, 1.0),
          pressure_threshold: Map.get(law.extinction_model, :pressure_threshold, 0.5)
        },
        fitness_contribution: resilience_score,
        pathology_profile: pathologies,
        constitutional_pressure: pressure
      }
    else
      nil
    end
  end
end
