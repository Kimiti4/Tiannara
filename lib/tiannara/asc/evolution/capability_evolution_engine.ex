defmodule Tiannara.ASC.Evolution.CapabilityEvolutionEngine do
  @moduledoc """
  Phase 12: Analyzes civilizational friction and evolves the organization.
  If missions fail due to specific bottlenecks, it mutates the Civilization Genome.
  """
  alias Tiannara.ASC.Evolution.{CivilizationGenome, OrganizationalMutator}
  require Logger

  def analyze_and_evolve(%CivilizationGenome{} = genome, audit_logs) do
    Logger.info("🧬 [CapabilityEvolution] Analyzing organizational friction...")
    
    # Identify the primary cause of mission failure/loopbacks
    bottleneck = diagnose_bottleneck(audit_logs)
    
    case bottleneck do
      :context_starvation ->
        Logger.info("💡 [CapabilityEvolution] Diagnosed: Coder lacks historical context. Spawning new role.")
        OrganizationalMutator.speciate_role(genome, :context_injector, before: :coder)
        
      :overzealous_auditing ->
        Logger.info("💡 [CapabilityEvolution] Diagnosed: Auditor is too strict, causing infinite loopbacks.")
        OrganizationalMutator.mutate_governance(genome, :complexity, 0.5) # Relax complexity penalty
        
      :healthy ->
        Logger.info("✅ [CapabilityEvolution] Organization is healthy. Applying minor drift mutations.")
        OrganizationalMutator.drift(genome)
    end
  end

  defp diagnose_bottleneck(audit_logs) do
    # Analyzes the Blackboard history to find where time is being wasted
    loopbacks = Enum.count(audit_logs, fn log -> log.event == :review_failed end)
    context_errors = Enum.count(audit_logs, fn log -> 
      log.event == :rejected and String.contains?(log.details, "context") 
    end)
    
    cond do
      context_errors > 0 -> :context_starvation
      loopbacks > 5 -> :overzealous_auditing
      true -> :healthy
    end
  end
end
