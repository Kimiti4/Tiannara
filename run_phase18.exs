defmodule Tiannara.ASC.Forecasting.Phase18Campaign do
  @moduledoc """
  Phase 18 Demonstration: Civilizational Forecasting.
  Builds the Epistemic Mirror, generates counterfactual interventions, 
  simulates their futures, and executes the optimal strategy.
  """
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  alias Tiannara.ASC.Forecasting.StrategicPlanner
  require Logger

  def run do
    Logger.info("🌌 [Phase 18] Initiating Civilizational Forecasting Campaign")
    
    # 1. Start Registries
    Tiannara.ASC.Ecology.CapabilityRegistry.start_link([])
    
    # 2. Build the current state (The Mirror)
    mirror = CivilizationGraph.build_mirror()
    
    # Let's adjust fitnesses: 
    # LLM Agent (cap_technical_debt_archaeologist) gets high fitness (causes monoculture)
    # But human baseline agents get enough fitness so that if LLM is culled, we don't starve (<10.0)
    boosted_caps = Enum.map(mirror.capabilities, fn cap ->
      if cap.lineage == :llm_synthesis do
        %{cap | fitness_impact: 100.0}
      else
        %{cap | fitness_impact: 15.0} # Enough to prevent starvation risk when LLM is culled
      end
    end)
    
    mirror = %{mirror | capabilities: boosted_caps}
    
    # 3. Formulate and Execute the optimal strategy
    StrategicPlanner.formulate_and_execute(mirror)
    
    Logger.info("\n🏆 [Phase 18] Forecasting Campaign Complete. Future trajectories mapped.")
  end
end

Tiannara.ASC.Forecasting.Phase18Campaign.run()
