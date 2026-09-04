defmodule Tiannara.ASC.Immunity.Phase16Campaign do
  @moduledoc """
  Demonstrates the Epistemic Immune System.
  Seeds corrupted ADRs, echo chamber research programs, and runs the scanner.
  """
  alias Tiannara.ASC.Immunity.ImmuneSystem
  alias Tiannara.ASC.Memory.InstitutionalMemory
  require Logger

  def run do
    Logger.info("🛡️ [Phase 16] Initiating Epistemic Immune System Campaign")
    
    # Start Ecology to allow querying recent syntheses
    Tiannara.ASC.Ecology.CapabilityRegistry.start_link([])

    # Seed an institutional memory corruption (Reality Drift)
    InstitutionalMemory.record_adr(
      "Caching Strategy", 
      "We need fast key-value storage.", 
      "We will use Redis for all internal caching because it provides high throughput.", 
      ["Memcached", "ETS"]
    )

    # Note: ResearchRegistry get_all_programs() is already stubbed to return an echo chamber.

    # Run the immune cycle
    Logger.info("\n--- EXECUTING IMMUNE CYCLE ---")
    ImmuneSystem.run_immune_cycle()
    
    Logger.info("\n🏆 [Phase 16] Epistemic Immune System Campaign Complete.")
  end
end

Tiannara.ASC.Immunity.Phase16Campaign.run()
