defmodule Tiannara.ASC.Civilization.Specialists.Coder do
  alias Tiannara.ASC.Civilization.EngineeringTask
  
  def code(%EngineeringTask{state: state} = task, llm_provider) when state in [:designed, :review_failed] do
    patches = llm_provider.generate_patch(task.design_doc, task.assigned_genome, task.review_feedback)
    
    task
    |> EngineeringTask.log_event(:coder, :code_generated, patches)
    |> Map.put(:patches, patches)
    |> Map.put(:state, :coded)
  end
end
