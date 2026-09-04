defmodule Tiannara.ASC.Civilization.DynamicGuildOrchestrator do
  @moduledoc """
  Phase 13: Replaces the static pipeline.
  Queries the Capability Ecology to dynamically assemble the optimal 
  execution graph for a specific mission.
  """
  alias Tiannara.ASC.Ecology.CapabilityRegistry
  alias Tiannara.ASC.Civilization.EngineeringTask
  require Logger

  def execute(%EngineeringTask{} = task, mission_context) do
    Logger.info("🌊 [DynamicOrchestrator] Assembling fluid pipeline for Mission: #{task.id}")
    
    # 1. Fetch baseline agent roles
    roles = CapabilityRegistry.get_by_type(:agent_role)
    
    # 2. Inject unprompted cognitive tools based on mission context
    tools = CapabilityRegistry.match_triggers(mission_context)
    
    # 3. Assemble the dynamic graph (Tools are injected before relevant roles)
    full_pipeline = inject_tools_into_roles(roles, tools)
    
    Logger.info("   🧬 Assembled Pipeline: #{Enum.map_join(full_pipeline, " -> ", & &1.name)}")
    
    # 4. Execute the dynamic graph
    run_pipeline(task, full_pipeline)
  end
  
  defp inject_tools_into_roles(roles, tools) do
    # Simple heuristic: Cognitive tools run before the Coder
    if Enum.any?(tools) do
      architect = Enum.find(roles, & &1.name == "Architect")
      coder = Enum.find(roles, & &1.name == "Coder")
      auditor = Enum.find(roles, & &1.name == "Auditor")
      
      # We need to make sure we handle nil if any baseline is missing, but typically they are present
      List.flatten([architect, tools, coder, auditor]) |> Enum.reject(&is_nil/1)
    else
      # If no tools, just ensure Architect -> Coder -> Auditor order
      architect = Enum.find(roles, & &1.name == "Architect")
      coder = Enum.find(roles, & &1.name == "Coder")
      auditor = Enum.find(roles, & &1.name == "Auditor")
      List.flatten([architect, coder, auditor]) |> Enum.reject(&is_nil/1)
    end
  end

  defp run_pipeline(task, []), do: task
  defp run_pipeline(task, [capability | rest]) do
    Logger.info("   ⚙️ Executing: #{capability.name} (#{capability.lineage})")
    updated_task = capability.implementation.(task)
    run_pipeline(updated_task, rest)
  end
end
