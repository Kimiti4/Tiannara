defmodule Tiannara.ASC.Civilization.GuildOrchestrator do
  @moduledoc """
  Phase 9: The Event-Driven Blackboard Orchestrator.
  Routes the EngineeringTask through the specialist agents based on state transitions.
  """
  
  alias Tiannara.ASC.Civilization.{EngineeringTask, HeuristicLLM}
  alias Tiannara.ASC.Civilization.Specialists.{Architect, Coder, Auditor, Tester}
  require Logger

  @max_loopbacks 3

  def execute(%EngineeringTask{} = initial_task, active_goal \\ nil) do
    Logger.info("🏛️ [GuildOrchestrator] Initiating Blackboard Workflow for Task: #{initial_task.id}")
    run_loop(initial_task, HeuristicLLM, active_goal, 0)
  end

  defp run_loop(task, llm, goal, loopback_count) do
    Logger.info("  🔄 [Guild] Current State: #{task.state}")
    
    next_task = case task.state do
      :pending      -> Architect.design(task, llm)
      :designed     -> Coder.code(task, llm)
      :coded        -> Auditor.audit(task, goal)
      :review_failed -> 
        if loopback_count >= @max_loopbacks do
          Logger.error("  ❌ [Guild] Max loopbacks reached. Failing task.")
          Map.put(task, :state, :rejected)
        else
          Coder.code(task, llm)
        end
      :approved     -> Tester.test(task)
      :tested_pass  -> handle_deployment(task)
      :tested_fail  -> Map.put(task, :state, :rejected)
      _             -> task # Terminal states (:rejected, :deployed)
    end
    
    if next_task.state in [:deployed, :rejected] do
      finalize(next_task)
    else
      # Recurse to handle the next state transition
      new_loop_count = if task.state == :review_failed, do: loopback_count + 1, else: loopback_count
      run_loop(next_task, llm, goal, new_loop_count)
    end
  end

  defp handle_deployment(task) do
    Logger.info("  🚀 [Deployment] Committing validated patches to mainline...")
    # RealityBridge.commit_and_teardown would be called here
    EngineeringTask.log_event(task, :deployment, :merged, "Branch merged to main")
    |> Map.put(:state, :deployed)
  end

  defp finalize(task) do
    Logger.info("""
    
    ======================================================================
    📜 GUILD AUDIT LOG (Task: #{task.id})
    ======================================================================
    """)
    
    task.history
    |> Enum.reverse()
    |> Enum.each(fn entry ->
      Logger.info("[#{entry.agent}] #{entry.event}: #{inspect(entry.details)}")
    end)
    
    Logger.info("Final State: #{task.state}")
    Logger.info("======================================================================")
    task
  end
end
