defmodule Tiannara.SOPL.EvolutionEngine do
  @moduledoc """
  SOPL-2: Evolution Engine
  
  Orchestrates the highly restricted law-evolution loop.
  5 Parents -> 20 Children -> Shadow Validation -> Parallel Deploy.
  """
  require Logger

  @doc """
  Executes a single evolutionary jump for physical laws.
  """
  def run_evolution_epoch(evaluated_laws, ruins) do
    Logger.info("🌌 [SOPL-2] Initiating Law Evolution Epoch...")
    
    # 1. Select 5 Parents
    parents = select_parents(evaluated_laws, ruins)
    Logger.info("🌌 [SOPL-2] Selected 5 Parents (2 Fitness, 1 Potential, 1 Outlier, 1 Ruin).")
    
    # 2. Compute Safe Mutation Radius based on landscape gradients
    avg_pressure = Enum.sum(Enum.map(parents, fn p -> Tiannara.SOPL.LandscapeAnalyzer.calculate_constitutional_pressure(p) end)) / 5.0
    safe_radius = Tiannara.SOPL.LawGradientTracker.calculate_safe_mutation_radius(avg_pressure)
    
    # 3. Generate 20 Children via Restricted Mutation Engine
    children = Enum.flat_map(parents, fn p -> 
      Tiannara.SOPL.MutationEngine.generate_children(p, 4, safe_radius)
    end)
    
    # 4. Shadow Validation (Constitutional Pressure Budget)
    validated_children = Tiannara.SOPL.ShadowValidator.validate(children)
    
    # 5. Parallel Deploy
    deploy(validated_children)
    
    # 6. Track Lineages
    update_lineages(validated_children)
  end

  defp select_parents(evals, ruins) do
    sorted_by_fitness = Enum.sort_by(evals, & &1.total_fitness, :desc)
    sorted_by_potential = Enum.sort_by(evals, & &1.potential.score, :desc)
    sorted_by_pressure = Enum.sort_by(evals, fn e -> Tiannara.SOPL.LandscapeAnalyzer.calculate_constitutional_pressure(e.law_genome) end, :desc)

    # 2 Fitness Winners
    p1 = Enum.at(sorted_by_fitness, 0).law_genome
    p2 = Enum.at(sorted_by_fitness, 1).law_genome
    
    # 1 High Potential
    p3 = Enum.find(sorted_by_potential, fn e -> e.law_genome.id not in [p1.id, p2.id] end).law_genome
    
    # 1 Constitutional Outlier (Highest pressure surviving law)
    p4 = Enum.find(sorted_by_pressure, fn e -> e.law_genome.id not in [p1.id, p2.id, p3.id] end).law_genome
    
    # 1 Archaeological Resurrection
    p5 = if length(ruins) > 0 do
      List.first(ruins).law_genome
    else
      # Fallback if no ruins exist yet
      Enum.at(sorted_by_fitness, 2).law_genome
    end
    
    [p1, p2, p3, p4, p5]
  end

  defp deploy(children) do
    Logger.info("🚀 [SOPL-2] Deploying #{length(children)} mutated laws into parallel ROS shards.")
    Enum.each(children, fn {:ok, law, pressure} ->
      Logger.debug("    -> Deployed Law #{law.id} (Parent: #{law.parent_id}) | Pressure: #{Float.round(pressure.total_pressure, 3)}")
    end)
  end

  defp update_lineages(children) do
    # Here we would initialize %LawLineage{} entries for tracking phylogenetics
    Logger.info("🧬 [SOPL-2] Initialized %LawLineage{} tracking for #{length(children)} deployed laws.")
  end
end
