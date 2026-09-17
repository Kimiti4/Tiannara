defmodule TiannaraRuntime.NATS.WorldEventSerializer do
  @moduledoc """
  PHASE 5A Layer 2: NATS World Event Serializer
  
  Handles serialization and deserialization of world events for NATS streaming.
  
  Supported Event Types:
  - world_state_update
  - cal_decision
  - cis_intervention
  - memory_snapshot
  - world_fork
  - fitness_update
  
  Ensures consistent message format across all worlds.
  """
  
  require Logger
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  @doc """
  Serialize event to JSON string for NATS publishing.
  """
  def serialize(event) do
    case validate_event(event) do
      :ok ->
        encoded = Jason.encode!(event)
        {:ok, encoded}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Deserialize JSON string from NATS subscription.
  """
  def deserialize(json_string) do
    try do
      decoded = Jason.decode!(json_string, keys: :atoms)
      
      case validate_event(decoded) do
        :ok -> {:ok, decoded}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        Logger.error("❌ Failed to deserialize NATS message: #{inspect(e)}")
        {:error, :invalid_json}
    end
  end
  
  @doc """
  Create standardized world state update event.
  """
  def create_state_event(world_id, state_data) do
    %{
      world_id: world_id,
      type: "world_state_update",
      payload: state_data,
      timestamp: System.system_time(:second),
      version: 1
    }
  end
  
  @doc """
  Create standardized CAL decision event.
  """
  def create_cal_event(world_id, coalition_id, decision, metadata \\ %{}) do
    %{
      world_id: world_id,
      type: "cal_decision",
      coalition_id: coalition_id,
      decision: decision,
      metadata: metadata,
      timestamp: System.system_time(:second),
      version: 1
    }
  end
  
  @doc """
  Create standardized CIS intervention event.
  """
  def create_cis_event(world_id, action, intensity, metadata \\ %{}) do
    %{
      world_id: world_id,
      type: "cis_intervention",
      action: action,
      intensity: intensity,
      metadata: metadata,
      timestamp: System.system_time(:second),
      version: 1
    }
  end
  
  @doc """
  Create standardized world fork event.
  """
  def create_fork_event(parent_world_id, child_world_id, mutation \\ %{}) do
    %{
      parent_world: parent_world_id,
      child_world: child_world_id,
      type: "world_fork",
      mutation: mutation,
      timestamp: System.system_time(:second),
      version: 1
    }
  end
  
  @doc """
  Create standardized fitness update event.
  """
  def create_fitness_event(world_id, fitness_score, metrics \\ %{}) do
    %{
      world_id: world_id,
      type: "fitness_update",
      fitness: fitness_score,
      metrics: metrics,
      timestamp: System.system_time(:second),
      version: 1
    }
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp validate_event(event) do
    required_fields = [:world_id, :type, :timestamp]
    
    missing_fields = Enum.filter(required_fields, fn field ->
      not Map.has_key?(event, field) or is_nil(Map.get(event, field))
    end)
    
    if length(missing_fields) > 0 do
      {:error, "Missing required fields: #{inspect(missing_fields)}"}
    else
      :ok
    end
  end
end
