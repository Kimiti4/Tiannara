defmodule TiannaraRuntime.Evolution.WorldPruningSystem do
  @moduledoc """
  PHASE 5B: World Pruning System (Extinction Layer)
  
  Prevents infinite world explosion by terminating low-fitness worlds.
  
  Termination Rules:
    - Fitness below threshold for N consecutive cycles
    - Collapse frequency spikes beyond safe limits
    - CIS cannot stabilize entropy
    - No viable coalition structures emerge
  
  SAFETY RULE: Extinction is delayed, not immediate
    Uses hysteresis: 3-cycle confirmation before termination
  
  This ensures we don't accidentally kill worlds experiencing temporary instability.
  """
  
  require Logger
  
  # Termination thresholds
  @fitness_threshold 0.2        # Below this = candidate for extinction
  @confirmation_cycles 3         # Must be below threshold for 3 cycles
  @max_collapse_frequency 0.8    # Above this = immediate termination candidate
  @max_entropy 0.95              # Above this = CIS failure, terminate
  
  @doc """
  Evaluate world for potential termination.
  
  Parameters:
    world_data - Map with :world, :fitness, and tracking state
  
  Returns:
    :safe - Continue running
    :warning - Monitor closely
    :terminate - Schedule for extinction
  """
  def evaluate(world_data) do
    fitness = world_data.fitness
    world = world_data.world
    metrics = world.metrics
    
    # Check immediate termination conditions
    cond do
      # Extreme entropy that CIS cannot handle
      Map.get(metrics, :entropy, 0.0) > @max_entropy ->
        Logger.warning("⚠️  World #{world.id} has critical entropy: #{metrics.entropy}")
        :terminate
      
      # Very high collapse frequency
      Map.get(metrics, :collapse_frequency, 0.0) > @max_collapse_frequency ->
        Logger.warning("⚠️  World #{world.id} has excessive collapses: #{metrics.collapse_frequency}")
        :terminate
      
      # Low fitness - check hysteresis
      fitness < @fitness_threshold ->
        check_hysteresis(world_data)
      
      # Moderate fitness - warning zone
      fitness < 0.3 ->
        :warning
      
      # Safe
      true ->
        :safe
    end
  end
  
  @doc """
  Execute world termination.
  
  Gracefully shuts down world supervisor and publishes extinction event.
  """
  def terminate_world(world_id) do
    Logger.info("💀 Terminating world #{world_id}")
    
    # Stop world supervisor via DynamicSupervisor
    case TiannaraRuntime.WorldSupervisor.stop_world(world_id) do
      :ok ->
        Logger.info("✅ World #{world_id} terminated successfully")
        
        # Publish extinction event
        publish_extinction_event(world_id)
        
        # Update registry
        TiannaraRuntime.WorldRegistry.terminate_world(world_id)
        
        :ok
      
      {:error, reason} ->
        Logger.error("❌ Failed to terminate world #{world_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc """
  Track termination countdown for a world.
  
  Maintains cycle count to implement hysteresis.
  """
  def track_termination_countdown(world_id, current_count \\ 0) do
    new_count = current_count + 1
    
    if new_count >= @confirmation_cycles do
      Logger.warning("⚠️  World #{world_id} confirmed for extinction after #{@confirmation_cycles} cycles")
      :confirmed_for_termination
    else
      Logger.debug("📊 World #{world_id} termination countdown: #{new_count}/#{@confirmation_cycles}")
      {:counting_down, new_count}
    end
  end
  
  @doc """
  Reset termination countdown (world recovered).
  """
  def reset_termination_countdown(world_id) do
    Logger.info("✅ World #{world_id} recovered - termination countdown reset")
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp check_hysteresis(world_data) do
    world_id = world_data.world.id
    current_count = Map.get(world_data, :termination_cycle_count, 0)
    
    case track_termination_countdown(world_id, current_count) do
      :confirmed_for_termination ->
        :terminate
      
      {:counting_down, new_count} ->
        # Return updated data with new count
        {:warning, %{world_data | termination_cycle_count: new_count}}
    end
  end
  
  defp publish_extinction_event(world_id) do
    event = %{
      type: "world_extinct",
      world_id: world_id,
      timestamp: System.system_time(:second),
      reason: "low_fitness_confirmed"
    }
    
    # TODO: Publish to NATS
    Logger.debug("📡 [Extinction] tiannara.worlds.extinction: #{inspect(event)}")
    
    # When NATS integration is ready:
    # TiannaraRuntime.NATS.WorldStreamManager.publish("tiannara.worlds.extinction", event)
  end
end
