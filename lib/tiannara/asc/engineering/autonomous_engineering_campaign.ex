defmodule Tiannara.ASC.Engineering.AutonomousEngineeringCampaign do
  @moduledoc """
  Phase 8A: The bridge between Research and Engineering.
  Selects the fittest Research Genomes, spawns Autonomous Engineering Projects,
  and feeds the real-world ROI back into the Meta-Science fitness function.
  """
  
  alias Tiannara.ASC.Research.ResearchRegistry
  alias Tiannara.ASC.Engineering.{ProjectSynthesizer, ExecutionPipeline}
  require Logger

  def run do
    Logger.info("🌌 [Phase 8A] Initiating Autonomous Engineering Campaign")
    Logger.info("Translating Meta-Science Genomes into Applied Engineering Reality...\n")
    
    # 1. Retrieve the surviving genomes from the Meta-Science Epoch
    genomes = ResearchRegistry.get_surviving_genomes()
    
    if Enum.empty?(genomes) do
      Logger.warning("No surviving research genomes found. Civilization has stalled.")
      :halt
    else
      # 2. Spawn and Execute Engineering Projects
      results = Enum.map(genomes, fn genome ->
        project = ProjectSynthesizer.synthesize(genome)
        ExecutionPipeline.execute(project)
      end)
      
      # 3. Feed ROI back into the Meta-Science Engine
      update_genome_fitness(results)
      
      # 4. Generate the Engineering Civilization Report
      generate_report(results)
    end
  end

  defp update_genome_fitness(results) do
    Enum.each(results, fn project ->
      if project.deployed do
        # The ultimate test: Does the science actually produce good engineering?
        ResearchRegistry.apply_engineering_roi(project.source_genome_id, project.civilizational_roi)
        Logger.info("  🧬 Fed ROI #{project.civilizational_roi} back to Genome #{project.source_genome_id}")
      end
    end)
  end

  defp generate_report(results) do
    Logger.info("""
    
    ======================================================================
    🏗️ PHASE 8A: AUTONOMOUS ENGINEERING CIVILIZATION REPORT
    ======================================================================
    """)
    
    Enum.each(results, fn proj ->
      status = if proj.deployed, do: "✅ DEPLOYED", else: "❌ ABORTED (QA Failure)"
      
      Logger.info("""
      Project: #{proj.name}
      Status: #{status}
      Architecture: #{inspect(proj.spec.architectural_pattern)}
      Test Coverage: #{Float.round(proj.test_coverage * 100, 1)}%
      
      Production Metrics:
        Fitness: #{Float.round(proj.production_fitness, 1)}
        Compute Cost: #{proj.compute_cost}
        Civilizational ROI: #{proj.civilizational_roi}
      ----------------------------------------------------------------------
      """)
    end)
    
    total_roi = Enum.sum(Enum.map(results, & &1.civilizational_roi))
    Logger.info("Total Civilizational Engineering ROI: #{Float.round(total_roi, 3)}")
    Logger.info("======================================================================")
  end
end
