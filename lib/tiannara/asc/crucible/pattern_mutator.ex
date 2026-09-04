defmodule Tiannara.ASC.Crucible.PatternMutator do
  @moduledoc """
  Handles the evolutionary mechanics: mutation and crossover of repair patterns.
  """
  def mutate(%{steps: steps} = pattern) do
    new_steps = 
      case :rand.uniform(3) do
        1 -> add_step(steps)
        2 -> modify_step(steps)
        3 -> remove_step(steps)
      end
      
    %{pattern | 
      id: generate_new_id(),
      steps: new_steps,
      lineage: Map.get(pattern, :lineage, []) ++ [pattern.id],
      generation: Map.get(pattern, :generation, 0) + 1
    }
  end
  
  def crossover(%{steps: steps_a} = parent_a, %{steps: steps_b} = parent_b) do
    # Single-point crossover of the step sequences
    split_a = trunc(length(steps_a) / 2)
    {head_a, _} = Enum.split(steps_a, split_a)
    {_, tail_b} = Enum.split(steps_b, split_a)
    
    new_steps = head_a ++ tail_b
    
    %{parent_a |
      id: generate_new_id(),
      steps: new_steps,
      lineage: [parent_a.id, parent_b.id],
      generation: max(Map.get(parent_a, :generation, 0), Map.get(parent_b, :generation, 0)) + 1
    }
  end
  
  defp generate_new_id, do: "pat_#{:erlang.unique_integer([:positive])}_#{:rand.uniform(9999)}"
  
  defp add_step(steps), do: steps ++ [%{action: :analyze, target: :unknown}]
  defp modify_step([]), do: [%{action: :reset, target: :all}]
  defp modify_step(steps) do
    idx = :rand.uniform(length(steps)) - 1
    List.update_at(steps, idx, fn step -> 
      if is_map(step) do
        Map.put(step, :action, :mutate)
      else
        %{action: :mutate, original: step}
      end
    end)
  end
  defp remove_step([]), do: []
  defp remove_step(steps) do
    idx = :rand.uniform(length(steps)) - 1
    List.delete_at(steps, idx)
  end
end
