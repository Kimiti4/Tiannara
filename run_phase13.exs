defmodule Tiannara.ASC.Ecology.Phase13Campaign do
  @moduledoc """
  Phase 13: Capability Ecology Verification
  """
  alias Tiannara.ASC.Evolution.CapabilitySynthesizer
  alias Tiannara.ASC.Civilization.DynamicGuildOrchestrator
  alias Tiannara.ASC.Civilization.EngineeringTask
  require Logger

  def run do
    # 1. Start Ecology
    Tiannara.ASC.Ecology.CapabilityRegistry.start_link([])

    Logger.info("🧠 [Synthesizer] Analyzing deep systemic friction for unprompted invention...")
    
    # 2. Synthesize Unprompted Capability
    friction_telemetry = %{
      legacy_codebase_failures: 0.8,
      cross_domain_regressions: 0.1
    }
    
    CapabilitySynthesizer.analyze_and_invent(friction_telemetry)
    
    # 3. Dynamic Execution
    task = %EngineeringTask{
      id: "legacy_refactor_01",
      goal: "Refactor legacy module",
      state: :pending
    }
    
    mission_context = %{
      codebase_age: :old,
      touches_multiple_domains: false
    }
    
    DynamicGuildOrchestrator.execute(task, mission_context)
  end
end

Tiannara.ASC.Ecology.Phase13Campaign.run()
