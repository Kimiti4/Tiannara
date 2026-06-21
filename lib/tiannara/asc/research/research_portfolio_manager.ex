defmodule Tiannara.ASC.Research.ResearchPortfolioManager do
  @moduledoc """
  Phase 6: Manages the portfolio of competing research programs.
  Allocates resources based on program fitness and runs evolutionary selection.
  """
  
  alias Tiannara.ASC.Research.ResearchRegistry
  alias Tiannara.ASC.Research.Programs.{TransferPhysicsProgram, RepairEcologyProgram, ArchitectureEvolutionProgram}
  require Logger

  @total_civilizational_budget 10000
  @epochs_per_campaign 5

  def run_campaign do
    Logger.info("🏛️ [Phase 6] Initiating Research Civilization Campaign")
    Logger.info("Total Civilizational Budget: #{@total_civilizational_budget} compute cycles")
    Logger.info("Epochs: #{@epochs_per_campaign}")
    
    # 1. Initialize competing research programs
    Logger.info("🔬 [Phase 6] Initializing competing research programs...")
    # Need to start ResearchRegistry if not already started (for testing/script execution)
    if Process.whereis(ResearchRegistry) == nil do
      ResearchRegistry.start_link([])
    end

    transfer_prog_id = TransferPhysicsProgram.start()
    repair_prog_id = RepairEcologyProgram.start()
    arch_prog_id = ArchitectureEvolutionProgram.start()
    
    program_ids = [transfer_prog_id, repair_prog_id, arch_prog_id]
    
    # 2. Run evolutionary epochs
    Enum.each(1..@epochs_per_campaign, fn epoch ->
      Logger.info("\n📊 [Phase 6] === EPOCH #{epoch} ===")
      
      # Allocate resources based on current fitness
      allocations = ResearchRegistry.allocate_resources(@total_civilizational_budget)
      
      Logger.info("💰 [Phase 6] Resource Allocation:")
      Enum.each(allocations, fn {prog_id, budget} ->
        Logger.info("  #{prog_id}: #{budget} compute cycles")
      end)
      
      # Execute each program's epoch
      Enum.each(program_ids, fn prog_id ->
        budget = Map.get(allocations, prog_id, 0)
        execute_program_epoch(prog_id, budget)
      end)
      
      # Report program fitness
      report_program_fitness()
    end)
    
    # 3. Final report
    generate_final_report()
  end

  defp execute_program_epoch(program_id, budget) do
    case program_id do
      id when is_binary(id) ->
        cond do
          String.contains?(id, "transfer_physics") -> 
            TransferPhysicsProgram.run_epoch(id, budget)
          String.contains?(id, "repair_ecology") -> 
            RepairEcologyProgram.run_epoch(id, budget)
          String.contains?(id, "architecture_evolution") -> 
            ArchitectureEvolutionProgram.run_epoch(id, budget)
          true -> 
            Logger.warning("Unknown program: #{program_id}")
        end
      _ -> 
        Logger.warning("Unknown program: #{inspect(program_id)}")
    end
  end

  defp report_program_fitness do
    programs = ResearchRegistry.get_programs_by_fitness()
    
    Logger.info("📈 [Phase 6] Program Fitness Rankings:")
    Enum.with_index(programs, 1) |> Enum.each(fn {program, rank} ->
      Logger.info("  ##{rank} #{program.name}")
      Logger.info("     Fitness: #{Float.round(program.program_fitness, 2)}")
      Logger.info("     Utility: #{Float.round(program.utility_generated, 1)} | Compute: #{program.compute_consumed}")
      Logger.info("     Laws: #{program.laws_generated} (#{program.laws_survived} survived)")
    end)
  end

  defp generate_final_report do
    programs = ResearchRegistry.get_programs_by_fitness()
    
    Logger.info("""
    
    ======================================================================
    🏛️ PHASE 6: RESEARCH CIVILIZATION FINAL REPORT
    ======================================================================
    
    COMPETING RESEARCH PROGRAMS (Ranked by Fitness)
    ----------------------------------------------------------------------
    """)
    
    Enum.with_index(programs, 1) |> Enum.each(fn {program, rank} ->
      Logger.info("""
      ##{rank} #{program.name}
         Domain: #{program.domain}
         Methodology: #{program.methodology}
         
         Performance Metrics:
           Experiments Run: #{program.experiments_run}
           Laws Generated: #{program.laws_generated}
           Laws Survived: #{program.laws_survived} (#{survival_rate(program)}% survival rate)
           
         Resource Efficiency:
           Compute Consumed: #{program.compute_consumed}
           Utility Generated: #{Float.round(program.utility_generated, 1)}
           Utility/Compute: #{Float.round(utility_per_compute(program), 3)}
           
         Evolutionary Fitness: #{Float.round(program.program_fitness, 2)}
      ----------------------------------------------------------------------
      """)
    end)
    
    Logger.info("""
    
    CIVILIZATIONAL INSIGHTS
    ----------------------------------------------------------------------
    """)
    
    # Identify the winning methodology
    winner = List.first(programs)
    Logger.info("🏆 Most Fit Program: #{winner.name}")
    Logger.info("   Methodology: #{winner.methodology}")
    Logger.info("   Domain: #{winner.domain}")
    
    # Calculate total civilizational output
    total_utility = Enum.sum(Enum.map(programs, & &1.utility_generated))
    total_compute = Enum.sum(Enum.map(programs, & &1.compute_consumed))
    total_laws = Enum.sum(Enum.map(programs, & &1.laws_survived))
    
    roi = if total_compute > 0, do: total_utility / total_compute, else: 0.0

    Logger.info("""
    
    Total Civilizational Output:
      Utility Generated: #{Float.round(total_utility, 1)}
      Compute Consumed: #{total_compute}
      Laws Survived: #{total_laws}
      Civilizational ROI: #{Float.round(roi, 3)}
    ======================================================================
    """)
  end

  defp survival_rate(program) do
    if program.laws_generated > 0 do
      Float.round(program.laws_survived / program.laws_generated * 100, 1)
    else
      0.0
    end
  end

  defp utility_per_compute(program) do
    if program.compute_consumed > 0 do
      program.utility_generated / program.compute_consumed
    else
      0.0
    end
  end
end
