defmodule Tiannara.ProductionCampaign do
  @moduledoc """
  Phase 19/20/21 Demonstration: The Federated Cosmos.
  Launches the MetaGovernor and RealityLedger, inputs a 6-month SaaS directive,
  simulates inter-civilization execution, and reconciles with the external reality.
  """
  alias Tiannara.Council.MetaGovernor
  alias Tiannara.Economics.RealityLedger
  alias Tiannara.Reality.ProductionObservatory
  require Logger

  def run do
    Logger.info("🌌 [Production] Booting Federated Digital Economy...")

    # 1. Start the Global Infrastructure
    {:ok, _pid1} = RealityLedger.start_link([])
    {:ok, _pid2} = MetaGovernor.start_link([])

    # 2. Human directive inputs a major mission
    {:ok, treaty} = MetaGovernor.enact_grand_objective("Build and launch a secure, AI-driven analytics SaaS product")

    Logger.info("\n--- EXECUTING TREATY ACROSS CIVILIZATIONS ---")
    
    # 3. Simulate ASC (Software Engineering) writing code
    Logger.info("   💻 [asc_alpha] Writing core application logic and AI models...")
    RealityLedger.record_cost(:llm_tokens, 1_500_000) # $45.00
    RealityLedger.record_cost(:human_review, 2)       # $30.00
    
    # 4. Simulate SEC (Security) auditing
    Logger.info("   🔒 [sec_gamma] Auditing cryptography and authentication...")
    RealityLedger.record_cost(:llm_tokens, 500_000) # $15.00
    
    # 5. Simulate INFRA (Deployment)
    Logger.info("   ☁️ [infra_omega] Deploying application to production AWS cluster...")
    RealityLedger.record_cost(:llm_tokens, 200_000) # $6.00
    
    # 6. Fulfill the treaty
    MetaGovernor.fulfill_treaty(treaty.id)

    Logger.info("\n--- RUNNING EXTERNAL REALITY RECONCILIATION ---")
    
    # 7. Production Observatory checks external reality
    ProductionObservatory.run_reconciliation_cycle()
    
    # 8. Check net profit
    net_income = RealityLedger.get_net_income()
    Logger.info("\n🏆 [Production] Campaign Complete. Net Treaty Income: $#{Float.round(net_income, 2)}")
  end
end

Tiannara.ProductionCampaign.run()
