defmodule Tiannara.ASC.Forecasting.CounterfactualSimulator do
  @moduledoc """
  Phase 18: Runs Monte Carlo simulations on the Civilizational Self-Model.
  Projects the evolutionary trajectory of the ecology under hypothetical interventions.
  """
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  require Logger

  defmodule Intervention do
    defstruct [:type, :target_id, :magnitude]
  end

  @doc """
  Simulates `epochs` into the future, returning a list of projected graph states.
  """
  def simulate_future(%CivilizationGraph{} = current_graph, %Intervention{} = intervention, epochs) do
    # 1. Apply the intervention to a clone of the current state
    baseline_graph = apply_intervention(current_graph, intervention)
    
    # 2. Run the evolutionary step function N times
    Enum.reduce(1..epochs, [baseline_graph], fn _epoch, acc ->
      previous_state = List.first(acc)
      next_state = project_evolutionary_step(previous_state)
      [next_state | acc]
    end)
    |> Enum.reverse()
  end

  defp apply_intervention(graph, %Intervention{type: :cull_capability, target_id: id}) do
    %{graph | capabilities: Enum.reject(graph.capabilities, & &1.id == id)}
  end
  
  defp apply_intervention(graph, %Intervention{type: :seed_human_baseline, target_id: _id}) do
    # Injects a low-fitness but highly stable human-seeded capability to break monocultures
    new_cap = %{id: "seeded_baseline", lineage: :human_seeded, fitness_impact: 5.0, status: :active}
    %{graph | capabilities: [new_cap | graph.capabilities]}
  end
  
  defp apply_intervention(graph, _), do: graph

  defp project_evolutionary_step(graph) do
    # Simplified evolutionary physics for simulation:
    # High fitness capabilities grow, low fitness decay, LLM synthesis adds cognitive load.
    
    # Let's add occasional synthesis to allow monoculture risk to grow if no human seeds are present
    synthesis_chance = 0.20
    new_caps = if :rand.uniform() < synthesis_chance do
      [%{id: "llm_synth_#{:rand.uniform(1000)}", lineage: :llm_synthesis, fitness_impact: 10.0, status: :active}]
    else
      []
    end

    updated_caps = Enum.map(graph.capabilities, fn cap ->
      new_fitness = cap.fitness_impact * (1.0 + (:rand.uniform() * 0.2 - 0.1))
      %{cap | fitness_impact: max(0.0, new_fitness)}
    end)
    |> Enum.reject(& &1.fitness_impact < 1.0) # Simulated extinction
    
    final_caps = updated_caps ++ new_caps
    
    %{graph | 
      capabilities: final_caps, 
      cognitive_load: length(final_caps) / 50.0 
    }
  end
end
