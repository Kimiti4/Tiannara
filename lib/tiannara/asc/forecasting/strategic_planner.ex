defmodule Tiannara.ASC.Forecasting.StrategicPlanner do
  @moduledoc """
  Phase 18: The Grandmaster. Formulates counterfactual interventions, 
  simulates their futures, and executes the strategy that maximizes long-term survival.
  """
  alias Tiannara.ASC.Forecasting.{CounterfactualSimulator, CollapsePredictor, CounterfactualSimulator.Intervention}
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  require Logger

  @simulation_horizon 50 # Epochs to look ahead
  @simulations_per_strategy 20 # Monte Carlo iterations

  def formulate_and_execute(%CivilizationGraph{} = current_graph) do
    Logger.info("♟️ [StrategicPlanner] Formulating counterfactual futures...")
    
    # 1. Generate candidate interventions
    strategies = [
      %{name: "Status Quo", intervention: %Intervention{type: :none}},
      %{name: "Cull Dominant LLM Agent", intervention: %Intervention{type: :cull_capability, target_id: find_dominant_llm_agent(current_graph)}},
      %{name: "Seed Human Baseline", intervention: %Intervention{type: :seed_human_baseline, target_id: nil}}
    ]
    
    # 2. Evaluate each strategy
    evaluations = Enum.map(strategies, fn strategy ->
      evaluate_strategy(current_graph, strategy)
    end)
    
    # 3. Select the optimal strategy (Lowest Risk of Ruin)
    best_strategy = Enum.min_by(evaluations, fn eval -> 
      eval.risks.monoculture_risk + eval.risks.asphyxiation_risk + eval.risks.starvation_risk 
    end)
    
    status_quo = Enum.find(evaluations, & &1.name == "Status Quo")
    status_quo_monoculture = if status_quo, do: status_quo.risks.monoculture_risk * 100, else: 100.0

    Logger.info("""
    🏆 [StrategicPlanner] OPTIMAL STRATEGY SELECTED: #{best_strategy.name}
       Monoculture Risk: #{Float.round(best_strategy.risks.monoculture_risk * 100, 1)}% (Down from #{Float.round(status_quo_monoculture, 1)}% in Status Quo)
       Asphyxiation Risk: #{Float.round(best_strategy.risks.asphyxiation_risk * 100, 1)}%
       Starvation Risk: #{Float.round(best_strategy.risks.starvation_risk * 100, 1)}%
    """)
    
    # 4. Execute the intervention in reality
    if best_strategy.name != "Status Quo" do
      Logger.warning("⚡ [StrategicPlanner] Executing proactive intervention to prevent future collapse.")
      execute_intervention(best_strategy.intervention)
    else
      Logger.info("✅ [StrategicPlanner] Current trajectory is safe. No intervention required.")
    end
  end

  defp evaluate_strategy(graph, strategy) do
    trajectories = Enum.map(1..@simulations_per_strategy, fn _ ->
      CounterfactualSimulator.simulate_future(graph, strategy.intervention, @simulation_horizon)
    end)
    
    risks = CollapsePredictor.calculate_risk_of_ruin(trajectories)
    Map.put(strategy, :risks, risks)
  end

  defp find_dominant_llm_agent(graph) do
    graph.capabilities
    |> Enum.filter(& &1.lineage == :llm_synthesis)
    |> Enum.max_by(& &1.fitness_impact, fn -> nil end)
    |> case do
      nil -> "none"
      cap -> cap.id
    end
  end

  defp execute_intervention(%Intervention{type: :cull_capability, target_id: id}) do
    Logger.warning("   ✂️ [Execution] Proactively culling '#{id}' to prevent future monoculture collapse.")
    # Tiannara.ASC.Ecology.CapabilityRegistry.unregister(id)
  end
  
  defp execute_intervention(%Intervention{type: :seed_human_baseline}) do
    Logger.warning("   🌱 [Execution] Injecting human-seeded baseline to enforce lineage diversity.")
    # Tiannara.ASC.Ecology.CapabilityRegistry.register(...)
  end
end
