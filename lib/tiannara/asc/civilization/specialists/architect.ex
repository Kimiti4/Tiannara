defmodule Tiannara.ASC.Civilization.Specialists.Architect do
  alias Tiannara.ASC.Civilization.EngineeringTask
  
  def design(%EngineeringTask{state: :pending} = task, llm_provider) do
    design_doc = llm_provider.generate_design(task.goal, task.assigned_genome)
    
    task
    |> EngineeringTask.log_event(:architect, :design_completed, design_doc)
    |> Map.put(:design_doc, design_doc)
    |> Map.put(:state, :designed)
  end
end
