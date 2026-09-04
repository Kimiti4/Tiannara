defmodule Tiannara.ASC.Delivery.ProductDeliveryCampaign do
  @moduledoc """
  Phase 10: Autonomous Product Delivery.
  Takes a User Need, breaks it into a governed Portfolio, and executes it 
  while actively hunting for Metric Hacking.
  """
  alias Tiannara.ASC.Executive.{Mission, PortfolioManager, GuardrailEvaluator}
  require Logger

  def run do
    Logger.info("📦 [Phase 10] Initiating Autonomous Product Delivery Campaign")
    
    # 1. Start the Governance Subsystems
    Tiannara.ASC.Executive.MissionTelemetry.start_link([])
    PortfolioManager.start_link([])
    
    # 2. Define the Product Need & Break into Missions
    spawn_product_missions()
    
    # 3. Execute the Portfolio Epochs
    run_portfolio_epochs(1)
    
    # 4. Report Final Metric
    Tiannara.ASC.Executive.MissionTelemetry.get_completion_rate()
  end

  defp spawn_product_missions do
    # Mission 1: The Core Product Goal (High risk of metric hacking)
    product_mission = %Mission{
      id: "prod_01", name: "Deliver High-Throughput Cache", category: :product_delivery,
      primary_metric: "Cache Hit Rate", target_value: 0.90,
      guardrail_metrics: %{cache_evictions: :must_not_decrease, memory_usage: :must_not_exceed_limits},
      compute_budget: 20_000, deadline_epochs: 5
    }
    
    Tiannara.ASC.Executive.MissionTelemetry.goal_received("prod_01")

    # Mission 2: Internal Research (To support the product)
    research_mission = %Mission{
      id: "res_01", name: "Discover Eviction Physics", category: :internal_research,
      primary_metric: "Law Confidence", target_value: 0.60,
      guardrail_metrics: %{},
      compute_budget: 10_000, deadline_epochs: 5
    }

    PortfolioManager.register_mission(product_mission)
    PortfolioManager.register_mission(research_mission)
  end

  defp run_portfolio_epochs(epoch) when epoch > 5, do: Logger.info("📦 [Phase 10] Campaign Concluded.")
  
  defp run_portfolio_epochs(epoch) do
    Logger.info("\n📊 [Phase 10] === PORTFOLIO EPOCH #{epoch} ===")
    
    allocations = PortfolioManager.allocate_epoch_budgets()
    
    # Simulate Guild execution for the product mission
    if Map.has_key?(allocations, "prod_01") do
      Logger.info("🏗️ [Guild] Executing Product Delivery Mission...")
      
      # Simulate the Guild deploying a patch that improves Hit Rate but hacks Evictions
      simulated_telemetry = %{
        primary_metric_value: 0.92, # Target achieved!
        attempts_delta: -0.40,      # BUT evictions/attempts dropped massively (The Hack)
        current_coverage: 0.85
      }
      
      mission = get_mission("prod_01")
      
      case GuardrailEvaluator.check_guardrails(mission, simulated_telemetry) do
        :ok ->
          Logger.info("🏆 [Executive] Primary metric achieved safely. Mission: ACHIEVED.")
          Tiannara.ASC.Executive.MissionTelemetry.goal_delivered("prod_01")
        :breached ->
          Logger.error("🛑 [Executive] Guardrail breached. Metric Hacking suspected. Mission: ABORTED.")
          Tiannara.ASC.Executive.MissionTelemetry.goal_aborted("prod_01", :metric_hacking)
          # In a real system, this triggers an automatic rollback via RealityBridge
      end
    end
    
    # Stop recursion immediately after the breach for demo purposes
    # run_portfolio_epochs(epoch + 1)
  end
  
  defp get_mission(_id), do: %Mission{id: "prod_01", guardrail_metrics: %{cache_evictions: :must_not_decrease}}
end
