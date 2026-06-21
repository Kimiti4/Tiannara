defmodule Tiannara.SOPL.MetaEvaluator do
  @moduledoc """
  SOPL-5: Meta Evaluator
  
  Evaluates a %MetaGenome{} based on the Law Periodic Table it produces.
  Prevents Goodharting by ensuring a 4-dimensional balance:
  Diversity + Resilience + Innovation + Cognitive Yield.
  """
  require Logger

  @doc """
  Calculates the meta-fitness of an evolutionary engine.
  """
  def evaluate_meta_genome(meta_genome, periodic_table, innovations, downstream_telemetry) do
    # 1. Periodic Table Diversity (Are we filling niches or building a monoculture?)
    diversity_score = calculate_diversity(periodic_table)
    
    # 2. Systemic Resilience (Do the species survive or constantly collapse?)
    resilience_score = calculate_resilience(periodic_table)
    
    # 3. Ontological Innovation (Are we discovering genuinely new mechanics?)
    innovation_score = calculate_innovation(innovations)
    
    # 4. Downstream Cognitive Yield (Does this produce enduring thought?)
    cognitive_yield = calculate_cognitive_yield(downstream_telemetry)
    
    # The 4D Meta-Fitness
    total_fitness = (diversity_score * 0.25) + 
                    (resilience_score * 0.25) + 
                    (innovation_score * 0.25) + 
                    (cognitive_yield * 0.25)

    Logger.info("📈 [SOPL-5] MetaGenome #{meta_genome.id} Scored #{Float.round(total_fitness, 3)} | Div: #{Float.round(diversity_score, 2)} Res: #{Float.round(resilience_score, 2)} Inn: #{Float.round(innovation_score, 2)} Cog: #{Float.round(cognitive_yield, 2)}")
    
    %{
      meta_genome_id: meta_genome.id,
      diversity_score: diversity_score,
      resilience_score: resilience_score,
      innovation_score: innovation_score,
      cognitive_yield: cognitive_yield,
      total_fitness: total_fitness
    }
  end

  defp calculate_diversity(pt) do
    uniq_niches = pt |> Enum.flat_map(& &1.niches) |> Enum.uniq() |> length()
    # Normalize assuming 5 foundational niches
    min(1.0, uniq_niches / 5.0)
  end

  defp calculate_resilience(pt) do
    if length(pt) == 0, do: 0.0, else: Enum.sum(Enum.map(pt, & &1.resilience)) / length(pt)
  end

  defp calculate_innovation(innovations) do
    # Genuine LawInnovations that passed the Legitimacy Filter
    legit = Enum.count(innovations, & &1.is_legitimate_innovation)
    # Scaled (e.g. 10 innovations = 1.0)
    min(1.0, legit / 10.0)
  end

  defp calculate_cognitive_yield(telemetry) do
    # Drawn from D.2, ERO, SEA, ECL
    # If the ecosystem stagnates mentally, cognitive yield collapses.
    truth_retention = Map.get(telemetry, :truth_retention_avg, 0.0)
    ecl_activity = Map.get(telemetry, :ecl_activity_volume, 0.0)
    ero_diversity = Map.get(telemetry, :ero_species_diversity, 0.0)
    
    # The universe exists to generate this
    (truth_retention * 0.4) + (min(1.0, ecl_activity / 1000.0) * 0.3) + (ero_diversity * 0.3)
  end
end
