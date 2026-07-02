defmodule Tiannara.Core.Observer do
  @moduledoc """
  Observer system for Tiannara.

  Manages cognitive observers, their states, and interactions with the system.
  """

  require Logger

  @doc """
  Create a new observer with the given configuration.
  """
  def create_observer(config) when is_map(config) do
    observer_id = generate_observer_id()
    
    observer_state = %{
      id: observer_id,
      type: Map.get(config, :type, :standard),
      tier: Map.get(config, :tier, 1),
      state: :initializing,
      created_at: System.system_time(:millisecond),
      last_update: System.system_time(:millisecond),
      cognitive_load: 0.0,
      observation_count: 0,
      capabilities: Map.get(config, :capabilities, [])
    }

    Logger.info("Created observer #{observer_id} with tier #{observer_state.tier}")
    {:ok, observer_state}
  end

  def create_observer(_config), do: {:error, :invalid_config}

  @doc """
  Upgrade an observer to a higher tier.
  """
  def upgrade_observer(observer, tier) when is_map(observer) and is_integer(tier) and tier > 0 do
    current_tier = Map.get(observer, :tier, 1)
    
    if tier > current_tier do
      upgraded_observer = %{observer | 
        tier: tier,
        state: :upgrading,
        last_update: System.system_time(:millisecond)
      }
      
      Logger.info("Upgrading observer #{observer.id} from tier #{current_tier} to #{tier}")
      
      # Simulate upgrade process
      Process.sleep(100)  # Simulate upgrade time
      
      final_observer = %{upgraded_observer | 
        state: :active,
        last_update: System.system_time(:millisecond)
      }
      
      Logger.info("Observer #{observer.id} upgraded to tier #{tier}")
      {:ok, final_observer}
    else
      Logger.warn("Cannot downgrade observer #{observer.id} from tier #{current_tier} to #{tier}")
      {:error, :downgrade_not_allowed}
    end
  end

  def upgrade_observer(_observer, _tier), do: {:error, :invalid_parameters}

  @doc """
  Query an observer with a specific query.
  """
  def query_observer(observer, query) when is_map(observer) and is_map(query) do
    observer_id = Map.get(observer, :id)
    
    Logger.debug("Querying observer #{observer_id} with: #{inspect(query)}")
    
    # Simulate query processing
    Process.sleep(10)  # Simulate query processing time
    
    result = %{
      observer_id: observer_id,
      query_timestamp: System.system_time(:millisecond),
      response: generate_query_response(observer, query),
      cognitive_impact: calculate_cognitive_impact(query, observer)
    }
    
    # Update observer state
    updated_observer = update_observer_after_query(observer, result)
    
    Logger.debug("Query completed for observer #{observer_id}")
    {:ok, result, updated_observer}
  end

  def query_observer(_observer, _query), do: {:error, :invalid_query}

  # Private helper functions
  defp generate_observer_id do
    "observer_" <> Integer.to_string(System.system_time(:millisecond))
  end

  defp generate_query_response(observer, query) do
    # Simulate different types of responses based on observer tier and query type
    case {observer.tier, Map.get(query, :type)} do
      {1, :basic} -> %{
        status: :success,
        data: "Basic observation data",
        confidence: 0.7
      }
      {2, :advanced} -> %{
        status: :success,
        data: "Advanced analysis results",
        confidence: 0.85
      }
      {3, :comprehensive} -> %{
        status: :success,
        data: "Comprehensive cognitive synthesis",
        confidence: 0.95
      }
      _ -> %{
        status: :partial,
        data: "Limited observation capability",
        confidence: 0.5
      }
    end
  end

  defp calculate_cognitive_impact(query, observer) do
    # Calculate cognitive impact based on query complexity and observer tier
    base_impact = 0.1
    
    complexity_factor = case Map.get(query, :complexity, :medium) do
      :low -> 0.5
      :medium -> 1.0
      :high -> 2.0
    end
    
    tier_factor = observer.tier / 3.0  # Normalize to 0-1 range
    
    min(base_impact * complexity_factor * tier_factor, 1.0)
  end

  defp update_observer_after_query(observer, result) do
    new_cognitive_load = observer.cognitive_load + result.cognitive_impact
    new_observation_count = observer.observation_count + 1
    
    %{observer | 
      cognitive_load: min(new_cognitive_load, 1.0),
      observation_count: new_observation_count,
      last_update: System.system_time(:millisecond)
    }
  end
end