defmodule Tiannara.Core.WorldModel.EntityRegistry do
  @moduledoc """
  Entity Registry for the World Model.

  Manages all entities in the canonical reality representation.
  Provides fast lookup, indexing, and entity lifecycle management.
  """

  use GenServer
  require Logger

  @doc "Start the Entity Registry server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Register a new entity in the World Model."
  def register_entity(entity, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:register_entity, entity})
  end

  @doc "Get an entity by ID."
  def get_entity(entity_id, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:get_entity, entity_id})
  end

  @doc "Get all entities of a specific type."
  def get_entities_by_type(entity_type, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:get_entities_by_type, entity_type})
  end

  @doc "Update an existing entity."
  def update_entity(entity_id, updates, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:update_entity, entity_id, updates})
  end

  @doc "Remove an entity from the registry."
  def remove_entity(entity_id, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:remove_entity, entity_id})
  end

  @doc "Get all entities in the registry."
  def list_entities(shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), :list_entities)
  end

  @doc "Search entities by attributes."
  def search_entities(criteria, shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), {:search_entities, criteria})
  end

  @doc "Get statistics about the entity registry."
  def get_stats(shard_id \\ :world_0) do
    GenServer.call(Tiannara.ROS.Registry.via(__MODULE__, shard_id), :get_stats)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Entity Registry")

    # Initialize state with empty entity map and indexes
    state = %{
      entities: %{},
      type_index: %{},
      name_index: %{},
      confidence_index: %{},
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:register_entity, entity}, _from, state) do
    entity_id = entity.id

    # Check if entity already exists
    if Map.has_key?(state.entities, entity_id) do
      Logger.warning("Entity with ID #{entity_id} already exists")
      {:reply, {:error, :entity_exists}, state}
    else
      # Add entity to registry
      updated_entities = Map.put(state.entities, entity_id, entity)
      
      # Update indexes
      updated_type_index = update_type_index(state.type_index, entity)
      updated_name_index = update_name_index(state.name_index, entity)
      updated_confidence_index = update_confidence_index(state.confidence_index, entity)
      
      new_state = %{state | 
        entities: updated_entities,
        type_index: updated_type_index,
        name_index: updated_name_index,
        confidence_index: updated_confidence_index,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Registered entity: #{entity_id} (type: #{entity.type})")
      {:reply, {:ok, entity_id}, new_state}
    end
  end

  @impl true
  def handle_call({:get_entity, entity_id}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      entity ->
        {:reply, {:ok, entity}, state}
    end
  end

  @impl true
  def handle_call({:get_entities_by_type, entity_type}, _from, state) do
    entity_ids = Map.get(state.type_index, entity_type, [])
    entities = Enum.map(entity_ids, &Map.get(state.entities, &1))
    
    {:reply, {:ok, entities}, state}
  end

  @impl true
  def handle_call({:update_entity, entity_id, updates}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      existing_entity ->
        # Create updated entity
        updated_entity = Map.merge(existing_entity, updates)
        
        # Update entity in registry
        updated_entities = Map.put(state.entities, entity_id, updated_entity)
        
        # Rebuild indexes with new entity data
        updated_type_index = rebuild_type_index(updated_entities, updated_entity.type)
        updated_name_index = rebuild_name_index(updated_entities, updated_entity)
        updated_confidence_index = rebuild_confidence_index(updated_entities, updated_entity)
        
        new_state = %{state |
          entities: updated_entities,
          type_index: updated_type_index,
          name_index: updated_name_index,
          confidence_index: updated_confidence_index,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Updated entity: #{entity_id}")
        {:reply, {:ok, updated_entity}, new_state}
    end
  end

  @impl true
  def handle_call({:remove_entity, entity_id}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      entity_to_remove ->
        # Remove entity from registry
        updated_entities = Map.delete(state.entities, entity_id)
        
        # Remove from all indexes
        updated_type_index = remove_from_type_index(state.type_index, entity_id, entity_to_remove.type)
        updated_name_index = remove_from_name_index(state.name_index, entity_id, entity_to_remove.name)
        updated_confidence_index = remove_from_confidence_index(state.confidence_index, entity_id, entity_to_remove.confidence)
        
        new_state = %{state |
          entities: updated_entities,
          type_index: updated_type_index,
          name_index: updated_name_index,
          confidence_index: updated_confidence_index,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Removed entity: #{entity_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:list_entities, _from, state) do
    entities = Map.values(state.entities)
    {:reply, {:ok, entities}, state}
  end

  @impl true
  def handle_call({:search_entities, criteria}, _from, state) do
    matching_entities = Enum.filter(state.entities, fn {_id, entity} ->
      matches_criteria(entity, criteria)
    end)
    
    {:reply, {:ok, Map.values(matching_entities)}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_entities: map_size(state.entities),
      entity_types: map_size(state.type_index),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      type_distribution: get_type_distribution(state.type_index)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp update_type_index(type_index, entity) do
    entity_ids = Map.get(type_index, entity.type, [])
    updated_ids = [entity.id | entity_ids]
    Map.put(type_index, entity.type, updated_ids)
  end

  defp update_name_index(name_index, entity) do
    entity_ids = Map.get(name_index, entity.name, [])
    updated_ids = [entity.id | entity_ids]
    Map.put(name_index, entity.name, updated_ids)
  end

  defp update_confidence_index(confidence_index, entity) do
    confidence_bucket = get_confidence_bucket(entity.confidence)
    entity_ids = Map.get(confidence_index, confidence_bucket, [])
    updated_ids = [entity.id | entity_ids]
    Map.put(confidence_index, confidence_bucket, updated_ids)
  end

  defp rebuild_type_index(entities, entity_type) do
    entities
    |> Enum.filter(fn {_id, entity} -> entity.type == entity_type end)
    |> Enum.map(fn {id, _entity} -> id end)
    |> then(&Map.put(%{}, entity_type, &1))
  end

  defp rebuild_name_index(entities, entity) do
    entities
    |> Enum.filter(fn {_id, entity} -> entity.name == entity.name end)
    |> Enum.map(fn {id, _entity} -> id end)
    |> then(&Map.put(%{}, entity.name, &1))
  end

  defp rebuild_confidence_index(entities, entity) do
    confidence_bucket = get_confidence_bucket(entity.confidence)
    entities
    |> Enum.filter(fn {_id, entity} -> get_confidence_bucket(entity.confidence) == confidence_bucket end)
    |> Enum.map(fn {id, _entity} -> id end)
    |> then(&Map.put(%{}, confidence_bucket, &1))
  end

  defp remove_from_type_index(type_index, entity_id, entity_type) do
    entity_ids = Map.get(type_index, entity_type, [])
    updated_ids = List.delete(entity_ids, entity_id)
    
    if Enum.empty?(updated_ids) do
      Map.delete(type_index, entity_type)
    else
      Map.put(type_index, entity_type, updated_ids)
    end
  end

  defp remove_from_name_index(name_index, entity_id, entity_name) do
    entity_ids = Map.get(name_index, entity_name, [])
    updated_ids = List.delete(entity_ids, entity_id)
    
    if Enum.empty?(updated_ids) do
      Map.delete(name_index, entity_name)
    else
      Map.put(name_index, entity_name, updated_ids)
    end
  end

  defp remove_from_confidence_index(confidence_index, entity_id, confidence) do
    confidence_bucket = get_confidence_bucket(confidence)
    entity_ids = Map.get(confidence_index, confidence_bucket, [])
    updated_ids = List.delete(entity_ids, entity_id)
    
    if Enum.empty?(updated_ids) do
      Map.delete(confidence_index, confidence_bucket)
    else
      Map.put(confidence_index, confidence_bucket, updated_ids)
    end
  end

  defp matches_criteria(entity, criteria) do
    Enum.all?(criteria, fn {key, value} ->
      case key do
        :type -> entity.type == value
        :name -> entity.name == value
        :confidence_min -> entity.confidence >= value
        :confidence_max -> entity.confidence <= value
        :attributes -> check_attributes(entity.attributes, value)
        _ -> true
      end
    end)
  end

  defp check_attributes(attributes, criteria) when is_list(criteria) do
    Enum.all?(criteria, fn {key, value} ->
      Map.get(attributes, key) == value
    end)
  end

  defp check_attributes(_attributes, _criteria), do: true

  defp get_confidence_bucket(confidence) when confidence >= 0.9, do: :high
  defp get_confidence_bucket(confidence) when confidence >= 0.7, do: :medium_high
  defp get_confidence_bucket(confidence) when confidence >= 0.5, do: :medium
  defp get_confidence_bucket(confidence) when confidence >= 0.3, do: :medium_low
  defp get_confidence_bucket(_confidence), do: :low

  defp get_type_distribution(type_index) do
    type_index
    |> Enum.map(fn {type, entities} -> {type, length(entities)} end)
    |> Enum.into(%{})
  end
end