defmodule Tiannara.ASC.Research.HorizonScanner do
  @moduledoc """
  Phase 11: Autonomous Domain Generation.
  Scans civilizational telemetry to identify unexplored or failing domains 
  and autonomously spawns new Research Programs to investigate them.
  """
  alias Tiannara.ASC.Research.{ResearchGenome, ResearchRegistry}
  # alias Tiannara.ASC.Crucible.TransferEcology
  require Logger

  def scan_and_spawn do
    Logger.info("🔭 [HorizonScanner] Scanning civilizational boundaries for new research domains...")
    
    # Identify domains with high failure rates but low current research budget
    dark_matter = identify_dark_matter()
    
    Enum.each(dark_matter, fn {domain, failure_rate} ->
      Logger.info("🌌 [HorizonScanner] Discovered unexplored frontier: #{domain} (Failure Rate: #{failure_rate}%)")
      
      # Autonomously generate a new Research Genome to tackle this domain
      new_genome = %ResearchGenome{
        domain: :"#{domain}_frontier_exploration",
        methodology: :hypothesis_generation,
        mutation_rate: 0.20, # High mutation for unexplored territory
        exploration_bias: 0.95,
        exploitation_bias: 0.05,
        compute_allocation: 2000
      }
      
      ResearchRegistry.register_program(new_genome)
    end)
  end

  defp identify_dark_matter do
    # Simulated scan of the Transfer Ecology to find domains we are bad at
    # In reality, this queries the ETS matrix for high-failure target domains
    [
      {:quantum_state_management, 88.5},
      {:distributed_consensus, 74.2}
    ]
    |> Enum.filter(fn {_domain, rate} -> rate > 50.0 end)
  end
end
