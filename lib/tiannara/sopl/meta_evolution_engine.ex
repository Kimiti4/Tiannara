defmodule Tiannara.SOPL.MetaEvolutionEngine do
  @moduledoc """
  SOPL-5: Meta-Evolution Engine (The L9 Loop)
  
  Orchestrates the macro-loop that evolves %MetaGenome{} algorithms.
  Its output is the Meta-Evolutionary Periodic Table: a catalog of diverse, 
  viable evolutionary systems rather than a single winner.
  """
  alias Tiannara.SOPL.{MetaEvaluator, MetaRuin}
  require Logger

  @doc """
  Executes a single L9 meta-epoch.
  1. Evaluates concurrent MetaGenomes based on their produced Periodic Tables.
  2. Archives failures as %MetaRuin{} to preserve brilliant but unstable mechanisms.
  3. Generates the Meta-Evolutionary Periodic Table.
  """
  def run_meta_epoch(active_meta_genomes, ecosystem_telemetry) do
    Logger.info("🌌 [SOPL-5] Beginning L9 Meta-Epoch. Active Engines: #{length(active_meta_genomes)}")
    
    # 1. Evaluate Fitness based on their produced multiverses
    evaluations = Enum.map(active_meta_genomes, fn meta ->
      pt = Map.get(ecosystem_telemetry, :periodic_tables, %{}) |> Map.get(meta.id, [])
      innovations = Map.get(ecosystem_telemetry, :innovations, %{}) |> Map.get(meta.id, [])
      downstream = Map.get(ecosystem_telemetry, :downstream_telemetry, %{}) |> Map.get(meta.id, %{})
      
      MetaEvaluator.evaluate_meta_genome(meta, pt, innovations, downstream)
    end)
    
    # 2. Selection for Diversity (Not a single winner)
    # Anyone falling below a critical threshold is archived as a MetaRuin
    {survivors, failures} = Enum.split_with(evaluations, fn eval ->
      eval.total_fitness > 0.4 and eval.diversity_score > 0.2 and eval.cognitive_yield > 0.1
    end)
    
    archive_meta_ruins(failures, active_meta_genomes)
    
    # 3. Generate the Meta-Evolutionary Periodic Table
    meta_table = generate_meta_periodic_table(survivors)
    
    Logger.info("📊 [SOPL-5] L9 Meta-Epoch complete. Discovered #{length(meta_table)} viable evolutionary architectures.")
    
    {:ok, meta_table}
  end

  defp archive_meta_ruins(failed_evals, genomes) do
    Enum.each(failed_evals, fn eval ->
      genome = Enum.find(genomes, & &1.id == eval.meta_genome_id)
      
      failure_vector = cond do
        eval.diversity_score <= 0.2 -> :monoculture
        eval.cognitive_yield <= 0.1 -> :cognitive_stagnation
        true -> :systemic_fragility
      end
      
      _ruin = %MetaRuin{
        id: "mruin_#{genome.id}",
        meta_genome_id: genome.id,
        collapse_epoch: :current,
        failure_vector: failure_vector,
        salvageable_strategies: %{
          # Salvage its pressure strategy for future recombination
          pressure: Map.get(genome, :pressure_strategy, %{})
        }
      }
      
      Logger.debug("📉 [SOPL-5] MetaGenome #{genome.id} collapsed (#{failure_vector}). Archived as MetaRuin.")
    end)
  end

  defp generate_meta_periodic_table(surviving_evals) do
    Enum.map(surviving_evals, fn eval ->
      %{
        meta_system_id: eval.meta_genome_id,
        profile: classify_meta_system(eval),
        diversity: eval.diversity_score,
        resilience: eval.resilience_score,
        innovation: eval.innovation_score,
        cognitive_yield: eval.cognitive_yield
      }
    end)
  end

  defp classify_meta_system(eval) do
    cond do
      eval.innovation_score > 0.7 and eval.diversity_score > 0.6 -> "Exploration Engine"
      eval.resilience_score > 0.7 and eval.cognitive_yield > 0.6 -> "Truth Anchor"
      eval.diversity_score > 0.8 -> "Niche Maximizer"
      true -> "Balanced Evolutionary Engine"
    end
  end
end
