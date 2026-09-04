defmodule Tiannara.ASC.Executive do
  @moduledoc """
  Phase 9.1: The Apex Governor.
  Selects goals, arbitrates priorities, and terminates missions that drift or exhaust budgets.
  """
  alias Tiannara.ASC.Constitution.Goal
  alias Tiannara.ASC.Civilization.{EngineeringTask, GuildOrchestrator}
  require Logger

  def run_mission(%Goal{} = goal, task_generator_fn) do
    Logger.info("🏛️ [Executive] Initiating Mission: #{goal.objective}")
    Logger.info("   Mode: #{goal.mode} | Budget: #{goal.compute_budget} | Target: #{goal.target_value}")
    
    execute_epochs(goal, task_generator_fn, 0, 0)
  end

  defp execute_epochs(goal, task_gen, epoch, compute_spent) do
    cond do
      # --- TERMINATION CONDITIONS ---
      goal.status != :active ->
        Logger.info("🏛️ [Executive] Mission concluded. Status: #{goal.status}")
        Tiannara.ASC.Executive.CivilizationMetrics.record_mission_conclusion(goal.status)
        
      epoch >= goal.deadline_epochs ->
        Logger.warning("🏛️ [Executive] Deadline reached. Aborting mission.")
        new_goal = Map.put(goal, :status, :aborted)
        Tiannara.ASC.Executive.CivilizationMetrics.record_mission_conclusion(new_goal.status)
        
      compute_spent >= goal.compute_budget ->
        Logger.warning("🏛️ [Executive] Compute budget exhausted. Aborting mission.")
        new_goal = Map.put(goal, :status, :aborted)
        Tiannara.ASC.Executive.CivilizationMetrics.record_mission_conclusion(new_goal.status)

      # --- EXECUTION ---
      true ->
        Logger.info("\n📊 [Executive] === EPOCH #{epoch + 1} ===")
        
        # Generate a task aligned to the goal
        task = task_gen.(goal)
        
        # Run the Guild
        final_task = GuildOrchestrator.execute(task, goal)
        
        # Measure outcome against the Goal
        {new_status, compute_used} = evaluate_mission_progress(final_task, goal)
        
        updated_goal = %{goal | status: new_status}
        execute_epochs(updated_goal, task_gen, epoch + 1, compute_spent + compute_used)
    end
  end

  defp evaluate_mission_progress(%EngineeringTask{state: :deployed} = task, goal) do
    # Simulate measuring the real-world metric after deployment
    current_metric = measure_real_world_metric(goal.success_metric)
    
    cost = Map.get(task, :compute_cost, 100)
    if current_metric >= goal.target_value do
      Logger.info("🏆 [Executive] TARGET ACHIEVED! #{goal.success_metric} is now #{current_metric}")
      {:achieved, cost}
    else
      {:active, cost}
    end
  end
  
  defp evaluate_mission_progress(task, _goal) do
    # Simulate the cost. If task rejected quickly, it costs less. If it looped, it costs more.
    # We'll just proxy the compute cost to 50 for failed/rejected tasks.
    cost = Map.get(task, :compute_cost, 50)
    {:active, cost} # Failed tasks still cost compute
  end

  defp measure_real_world_metric("Transfer Success Rate") do
    # In reality, this queries the TransferEcology matrix
    0.26 # Simulate achieving > 0.25 on the second epoch
  end
  
  defp measure_real_world_metric(_), do: 0.0
end
