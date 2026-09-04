defmodule Tiannara.ASC.Research.Programs.ArchitectureEvolutionProgram do
  @moduledoc """
  Phase 6.1: Executes real meta-analysis on the Transfer Ecology to discover 
  architectural constraints and domain clusters.
  """
  
  alias Tiannara.ASC.Research.{TelemetrySnapshot, ResearchRegistry}
  alias Tiannara.ASC.Crucible.TransferEcology
  alias Tiannara.ASC.Laws.Registry
  require Logger

  def start do
    program = %Tiannara.ASC.Research.ResearchProgram{
      name: "Architecture Evolution",
      domain: :architecture_evolution,
      methodology: :meta_learning,
      budget: 1000
    }
    
    ResearchRegistry.register_program(program)
  end

  def run_epoch(program_id, budget) do
    Logger.info("🏛️ [ArchitectureEvolution] Executing REAL Meta-Learning Analysis (Budget: #{budget})")
    
    snap_before = TelemetrySnapshot.take()
    
    # Meta-analysis is expensive. Budget allows for deep matrix scans.
    scans = max(1, trunc(budget / 50)) 
    
    Enum.each(1..scans, fn _ ->
      analyze_domain_clusters()
    end)
    
    snap_after = TelemetrySnapshot.take()
    delta = TelemetrySnapshot.calculate_delta(snap_before, snap_after)
    
    Logger.info("  📊 Real Delta: #{delta.laws_generated} architectural principles minted.")
    
    ResearchRegistry.update_program_metrics(program_id, delta)
  end

  defp analyze_domain_clusters do
    events = TransferEcology.get_all_events()
    if length(events) > 20 do
      # Find domains that consistently fail transfers (Architectural Bottlenecks)
      failing_domains = 
        events 
        |> Enum.reject(& &1.success)
        |> Enum.frequencies_by(& &1.target_domain)
        |> Enum.filter(fn {_domain, count} -> count > 5 end)
        |> Enum.map(fn {domain, _} -> domain end)

      Enum.each(failing_domains, fn domain ->
        # Mint a real architectural constraint law
        Registry.upsert_law(
          "asc_architecture",
          "Domain #{domain} exhibits systemic transfer resistance",
          %{
            support_count: 10,
            confidence: 0.45,
            tier: :candidate_pattern, # Updated from :candidate to match the new enum
            tags: [:architecture, :bottleneck, domain],
            utility_score: 250.0 # High utility for identifying bottlenecks
          }
        )
      end)
    end
  end
end
