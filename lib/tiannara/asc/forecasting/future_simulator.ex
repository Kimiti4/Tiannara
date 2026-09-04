defmodule Tiannara.ASC.Forecasting.FutureTimeline do
  @moduledoc "Represents a single projected 100-epoch timeline."
  defstruct [:id, :epochs_simulated, :final_graph, :failure_events]
end

defmodule Tiannara.ASC.Forecasting.FutureSimulator do
  @moduledoc """
  Phase 18: The Timeline Generator.
  Takes the current CivilizationGraph and projects it forward 100 epochs using
  a Monte Carlo stochastic simulation to model extinction events, immune failures, and evolution.
  """
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  alias Tiannara.ASC.Forecasting.FutureTimeline
  require Logger

  @epochs_to_simulate 100
  @num_timelines 100

  def simulate(%CivilizationGraph{} = initial_graph) do
    Logger.info("🔮 [FutureSimulator] Initiating Monte Carlo stochastic simulation...")
    Logger.info("🔮 [FutureSimulator] Simulating #{@epochs_to_simulate} epochs across #{@num_timelines} possible futures...")
    
    1..@num_timelines
    |> Enum.map(fn id -> 
      simulate_timeline(id, initial_graph, @epochs_to_simulate) 
    end)
  end

  defp simulate_timeline(id, graph, epochs) do
    # Run the Monte Carlo simulation for this timeline
    final_state = Enum.reduce(1..epochs, %{graph: graph, failures: []}, fn epoch, state ->
      apply_epoch_physics(epoch, state)
    end)
    
    %FutureTimeline{
      id: "timeline_#{id}",
      epochs_simulated: epochs,
      final_graph: final_state.graph,
      failure_events: final_state.failures
    }
  end

  defp apply_epoch_physics(_epoch, state) do
    graph = state.graph
    
    # 1. Simulate Capability Extinction (Random chance based on lineage and cognitive load)
    {new_caps, extinctions} = simulate_extinctions(graph.capabilities, graph.cognitive_load)
    
    # 2. Simulate Evolutionary Synthesis (Chance to spawn new LLM capabilities)
    new_caps = simulate_synthesis(new_caps, graph.cognitive_load)
    
    # 3. Simulate Pathogen Outbreaks (Chance of memory corruption or reward hacking)
    # 4. Simulate Immune System efficacy (Does the immune system catch it, or does it bypass?)
    {new_failures, _immune_efficacy} = simulate_immune_events(state.failures)
    
    # Re-calculate graph metrics for the next epoch
    new_graph = %{graph | 
      capabilities: new_caps,
      cognitive_load: calculate_cognitive_load(new_caps)
    }

    %{graph: new_graph, failures: state.failures ++ extinctions ++ new_failures}
  end

  defp simulate_extinctions(caps, cognitive_load) do
    # Higher cognitive load increases extinction chance (context window stress)
    base_chance = 0.01 + (cognitive_load * 0.05)
    
    Enum.reduce(caps, {[], []}, fn cap, {survivors, extinctions} ->
      # Human seeded capabilities are much harder to kill
      chance = if cap.lineage == :human_seeded, do: base_chance / 10, else: base_chance
      chance = chance + (Map.get(cap, :betweenness_centrality, 0.0) * 0.02) # Highly loaded nodes break more easily
      
      if :rand.uniform() < chance do
        {survivors, [{:extinction, cap.id} | extinctions]}
      else
        {[cap | survivors], extinctions}
      end
    end)
  end

  defp simulate_synthesis(caps, cognitive_load) do
    # If load is low, evolution is more likely
    chance = if cognitive_load < 0.5, do: 0.1, else: 0.02
    
    if :rand.uniform() < chance do
      new_cap = %{
        id: "cap_llm_synth_#{:rand.uniform(1000)}", 
        status: :active, 
        fitness_impact: :rand.uniform(), 
        lineage: :llm_synthesis, 
        betweenness_centrality: :rand.uniform() * 0.1
      }
      [new_cap | caps]
    else
      caps
    end
  end

  defp simulate_immune_events(_existing_failures) do
    chance = 0.05 # 5% chance of severe pathogen outbreak per epoch
    
    if :rand.uniform() < chance do
      # 10% chance immune system misses it (Immune Failure)
      if :rand.uniform() < 0.10 do
        {[{:immune_failure, "Pathogen bypassed systemic risk scanner"}], 0.0}
      else
        {[], 1.0}
      end
    else
      {[], 1.0}
    end
  end
  
  defp calculate_cognitive_load(caps) do
    active_caps = Enum.count(caps, & &1.status == :active)
    min(1.0, active_caps / 50.0) 
  end
end
