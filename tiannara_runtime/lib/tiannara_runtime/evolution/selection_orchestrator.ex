defmodule TiannaraRuntime.Evolution.SelectionOrchestrator do
  @moduledoc """
  PHASE 5B: Selection Orchestrator
  
  Applies survival pressure across all worlds through fitness evaluation and classification.
  
  Selection Cycle:
    1. Evaluate all worlds (compute fitness)
    2. Rank by fitness (descending)
    3. Classify into categories:
       - Survivors (top 60%)
       - Unstable (middle 25%)
       - Extinction Risk (bottom 15%)
    4. Trigger adaptive responses (fork/terminate/continue)
  
  This module coordinates the evolutionary selection process without directly
  mutating world state - it only makes recommendations to WorldForkEngine
  and KillSwitch.
  """
  
  alias TiannaraRuntime.Evolution.FitnessEngine
  
  # Classification thresholds (percentages)
  @survivor_threshold 0.60   # Top 60% survive
  @unstable_threshold 0.85   # Next 25% unstable, bottom 15% extinction risk
  
  # Hysteresis: cycles before termination
  @extinction_confirmation_cycles 3
  
  @doc """
  Run selection cycle on all active worlds.
  
  Parameters:
    worlds - List of world maps with :id and :metrics fields
  
  Returns:
    %{
      survivors: [%{world, fitness, rank}],
      unstable: [%{world, fitness, rank}],
      extinction_risk: [%{world, fitness, rank}]
    }
  """
  def run(worlds) do
    # Step 1: Compute fitness for each world
    scored_worlds = Enum.map(worlds, fn world ->
      fitness = FitnessEngine.compute(world.metrics)
      risk = FitnessEngine.calculate_risk(fitness)
      classification = FitnessEngine.classify(fitness)
      
      %{
        world: world,
        fitness: fitness,
        risk: risk,
        classification: classification,
        rank: nil  # Will be set after sorting
      }
    end)
    
    # Step 2: Sort by fitness (descending)
    sorted = Enum.sort_by(scored_worlds, & &1.fitness, :desc)
    
    # Step 3: Assign ranks
    ranked = Enum.with_index(sorted, 1) |> Enum.map(fn {item, rank} ->
      %{item | rank: rank}
    end)
    
    # Step 4: Classify into categories
    classify(ranked)
  end
  
  @doc """
  Determine adaptive response for a world based on fitness and stability.
  
  Returns:
    :continue - Keep running normally
    :fork - Create mutated copy (exploration)
    :terminate - Schedule for extinction
  """
  def adaptive_response(world_data) do
    fitness = world_data.fitness
    stable_structure = stable_structure?(world_data.world)
    
    cond do
      # Low fitness but stable structure → fork for exploration
      fitness < 0.3 and stable_structure ->
        :fork
      
      # Very low fitness → terminate
      fitness < 0.2 ->
        :terminate
      
      # Otherwise continue
      true ->
        :continue
    end
  end
  
  @doc """
  Check if world has stable coalition structure despite low fitness.
  
  Used to decide between fork vs terminate.
  """
  def stable_structure?(world) do
    metrics = world.metrics
    
    # Check for coherent coalition patterns
    coherence = Map.get(metrics, :coherence_stability, 0.0)
    coalition_count = Map.get(metrics, :active_coalitions, 0)
    
    # Stable if coherence is moderate and has active coalitions
    coherence > 0.4 and coalition_count > 0
  end
  
  @doc """
  Publish selection events to NATS streams.
  
  Streams:
    tiannara.worlds.selection.events - All selection decisions
    tiannara.worlds.extinction - Termination events
    tiannara.worlds.fork.events - Fork triggers
  """
  def publish_selection_events(classification_result) do
    # Publish survivor events
    Enum.each(classification_result.survivors, fn item ->
      publish_event("tiannara.worlds.selection.events", %{
        type: "survival_confirmed",
        world_id: item.world.id,
        fitness: item.fitness,
        rank: item.rank
      })
    end)
    
    # Publish extinction warnings
    Enum.each(classification_result.extinction_risk, fn item ->
      publish_event("tiannara.worlds.extinction", %{
        type: "extinction_warning",
        world_id: item.world.id,
        fitness: item.fitness,
        cycles_remaining: @extinction_confirmation_cycles
      })
    end)
    
    # Publish fork triggers
    forks_needed = Enum.filter(classification_result.unstable, fn item ->
      adaptive_response(item) == :fork
    end)
    
    Enum.each(forks_needed, fn item ->
      publish_event("tiannara.worlds.fork.events", %{
        type: "adaptive_fork_triggered",
        parent_world_id: item.world.id,
        reason: "low_fitness_stable_structure",
        fitness: item.fitness
      })
    end)
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp classify(ranked_worlds) do
    total = length(ranked_worlds)
    
    if total == 0 do
      %{survivors: [], unstable: [], extinction_risk: []}
    else
      survivor_count = max(1, round(total * @survivor_threshold))
      unstable_count = max(0, round(total * (@unstable_threshold - @survivor_threshold)))
      
      survivors = Enum.take(ranked_worlds, survivor_count)
      remaining = Enum.drop(ranked_worlds, survivor_count)
      
      unstable = Enum.take(remaining, unstable_count)
      extinction_risk = Enum.drop(remaining, unstable_count)
      
      %{
        survivors: survivors,
        unstable: unstable,
        extinction_risk: extinction_risk
      }
    end
  end
  
  defp publish_event(topic, payload) do
    # TODO: Integrate with NATS.WorldStreamManager
    # For now, just log
    require Logger
    Logger.debug("📡 [Selection] #{topic}: #{inspect(payload)}")
    
    # When NATS integration is ready:
    # TiannaraRuntime.NATS.WorldStreamManager.publish(topic, payload)
  end
end
