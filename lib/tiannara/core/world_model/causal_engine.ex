defmodule Tiannara.Core.WorldModel.CausalEngine do
  @moduledoc """
  Causal Engine for the World Model.

  Manages cause-effect relationships, interventions, and causal reasoning.
  """

  use GenServer
  require Logger

  @doc "Start the Causal Engine server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Add a causal relationship between two entities."
  def add_causal_relationship(source_entity, target_entity, relationship_type, strength \\ 0.7, confidence \\ 0.8) do
    relationship = %{
      id: generate_relationship_id(),
      source: source_entity,
      target: target_entity,
      type: relationship_type,
      strength: strength,
      confidence: confidence,
      created_at: DateTime.utc_now(),
      last_updated: DateTime.utc_now(),
      interventions: []
    }

    GenServer.call(__MODULE__, {:add_relationship, relationship})
  end

  @doc "Update a causal relationship."
  def update_relationship(relationship_id, updates) do
    GenServer.call(__MODULE__, {:update_relationship, relationship_id, updates})
  end

  @doc "Get a causal relationship by ID."
  def get_relationship(relationship_id) do
    GenServer.call(__MODULE__, {:get_relationship, relationship_id})
  end

  @doc "Get all causal relationships."
  def list_relationships do
    GenServer.call(__MODULE__, :list_relationships)
  end

  @doc "Get relationships for a specific entity."
  def get_entity_relationships(entity_id) do
    GenServer.call(__MODULE__, {:get_entity_relationships, entity_id})
  end

  @doc "Get relationships by type."
  def get_relationships_by_type(relationship_type) do
    GenServer.call(__MODULE__, {:get_relationships_by_type, relationship_type})
  end

  @doc "Add an intervention to a causal relationship."
  def add_intervention(relationship_id, intervention_type, description, effectiveness) do
    intervention = %{
      id: generate_intervention_id(),
      type: intervention_type,
      description: description,
      effectiveness: effectiveness,
      timestamp: DateTime.utc_now(),
      outcomes: []
    }

    GenServer.call(__MODULE__, {:add_intervention, relationship_id, intervention})
  end

  @doc "Record outcome of an intervention."
  def record_intervention_outcome(relationship_id, intervention_id, outcome, success) do
    GenServer.call(__MODULE__, {:record_intervention_outcome, relationship_id, intervention_id, outcome, success})
  end

  @doc "Perform causal inference - predict effects of changes."
  def infer_effects(entity_id, change_description) do
    GenServer.call(__MODULE__, {:infer_effects, entity_id, change_description})
  end

  @doc "Find causal paths between entities."
  def find_causal_path(source_id, target_id) do
    GenServer.call(__MODULE__, {:find_causal_path, source_id, target_id})
  end

  @doc "Get causal network statistics."
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Causal Engine")

    # Initialize state with causal graph and indexes
    state = %{
      relationships: %{},
      entity_index: %{},
      type_index: %{},
      strength_index: %{},
      confidence_index: %{},
      intervention_history: [],
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:add_relationship, relationship}, _from, state) do
    relationship_id = relationship.id

    # Check for existing relationship
    if Map.has_key?(state.relationships, relationship_id) do
      Logger.warning("Causal relationship with ID #{relationship_id} already exists")
      {:reply, {:error, :relationship_exists}, state}
    else
      # Add relationship to causal graph
      updated_relationships = Map.put(state.relationships, relationship_id, relationship)
      
      # Update indexes
      updated_entity_index = update_entity_index(state.entity_index, relationship)
      updated_type_index = update_type_index(state.type_index, relationship)
      updated_strength_index = update_strength_index(state.strength_index, relationship)
      updated_confidence_index = update_confidence_index(state.confidence_index, relationship)
      
      # Update confidence based on relationship strength and evidence
      updated_relationship = %{relationship | 
        confidence: calculate_relationship_confidence(relationship, state.relationships)
      }
      updated_relationships = Map.put(updated_relationships, relationship_id, updated_relationship)
      
      new_state = %{state |
        relationships: updated_relationships,
        entity_index: updated_entity_index,
        type_index: updated_type_index,
        strength_index: updated_strength_index,
        confidence_index: updated_confidence_index,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Added causal relationship: #{relationship_id}")
      {:reply, {:ok, relationship_id}, new_state}
    end
  end

  @impl true
  def handle_call({:update_relationship, relationship_id, updates}, _from, state) do
    case Map.get(state.relationships, relationship_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      relationship ->
        # Create updated relationship
        updated_relationship = Map.merge(relationship, updates)
        updated_relationship = %{updated_relationship | 
          last_updated: DateTime.utc_now(),
          confidence: calculate_relationship_confidence(updated_relationship, state.relationships)
        }
        
        # Update relationship in causal graph
        updated_relationships = Map.put(state.relationships, relationship_id, updated_relationship)
        
        # Rebuild indexes
        updated_entity_index = rebuild_entity_index(updated_relationships, updated_relationship)
        updated_type_index = rebuild_type_index(updated_relationships, updated_relationship.type)
        updated_strength_index = rebuild_strength_index(updated_relationships, updated_relationship)
        updated_confidence_index = rebuild_confidence_index(updated_relationships, updated_relationship)
        
        new_state = %{state |
          relationships: updated_relationships,
          entity_index: updated_entity_index,
          type_index: updated_type_index,
          strength_index: updated_strength_index,
          confidence_index: updated_confidence_index,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Updated causal relationship: #{relationship_id}")
        {:reply, {:ok, updated_relationship}, new_state}
    end
  end

  @impl true
  def handle_call({:get_relationship, relationship_id}, _from, state) do
    case Map.get(state.relationships, relationship_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      relationship ->
        {:reply, {:ok, relationship}, state}
    end
  end

  @impl true
  def handle_call(:list_relationships, _from, state) do
    relationships = Map.values(state.relationships)
    {:reply, {:ok, relationships}, state}
  end

  @impl true
  def handle_call({:get_entity_relationships, entity_id}, _from, state) do
    # Get relationships where entity is source or target
    outgoing = Map.get(state.entity_index["outgoing"][entity_id] || %{}, entity_id, [])
    incoming = Map.get(state.entity_index["incoming"][entity_id] || %{}, entity_id, [])
    
    all_relationship_ids = outgoing ++ incoming
    relationships = Enum.map(all_relationship_ids, &Map.get(state.relationships, &1))
    
    {:reply, {:ok, relationships}, state}
  end

  @impl true
  def handle_call({:get_relationships_by_type, relationship_type}, _from, state) do
    relationship_ids = Map.get(state.type_index, relationship_type, [])
    relationships = Enum.map(relationship_ids, &Map.get(state.relationships, &1))
    
    {:reply, {:ok, relationships}, state}
  end

  @impl true
  def handle_call({:add_intervention, relationship_id, intervention}, _from, state) do
    case Map.get(state.relationships, relationship_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      relationship ->
        # Add intervention to relationship
        updated_relationship = %{relationship | 
          interventions: [intervention | relationship.interventions]
        }
        
        updated_relationships = Map.put(state.relationships, relationship_id, updated_relationship)
        
        # Record intervention in history
        intervention_record = %{
          relationship_id: relationship_id,
          intervention: intervention,
          timestamp: DateTime.utc_now()
        }
        
        updated_history = [intervention_record | state.intervention_history]
        
        new_state = %{state |
          relationships: updated_relationships,
          intervention_history: updated_history,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Added intervention to relationship: #{relationship_id}")
        {:reply, {:ok, intervention}, new_state}
    end
  end

  @impl true
  def handle_call({:record_intervention_outcome, relationship_id, intervention_id, outcome, success}, _from, state) do
    case Map.get(state.relationships, relationship_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      relationship ->
        # Find and update the intervention
        updated_interventions = Enum.map(relationship.interventions, fn intervention ->
          if intervention.id == intervention_id do
            outcome_record = %{
              outcome: outcome,
              success: success,
              timestamp: DateTime.utc_now()
            }
            
            %{intervention | 
              outcomes: [outcome_record | intervention.outcomes]
            }
          else
            intervention
          end
        end)
        
        updated_relationship = %{relationship | 
          interventions: updated_interventions,
          last_updated: DateTime.utc_now()
        }
        
        updated_relationships = Map.put(state.relationships, relationship_id, updated_relationship)
        
        new_state = %{state |
          relationships: updated_relationships,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Recorded intervention outcome: #{intervention_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:infer_effects, entity_id, _change_description}, _from, state) do
    # Find all causal paths starting from entity_id
    causal_paths = find_all_causal_paths(state.relationships, entity_id)
    
    # Predict effects based on relationship strengths and confidences
    predictions = Enum.map(causal_paths, fn path ->
      %{
        path: path,
        prediction: predict_effect_strength(path, state.relationships),
        confidence: calculate_path_confidence(path, state.relationships),
        likelihood: calculate_likelihood(path, state.relationships)
      }
    end)
    
    {:reply, {:ok, predictions}, state}
  end

  @impl true
  def handle_call({:find_causal_path, source_id, target_id}, _from, state) do
    # Find shortest causal path between source and target
    path = find_shortest_path(state.relationships, source_id, target_id)
    
    {:reply, {:ok, path}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_relationships: map_size(state.relationships),
      entity_connections: calculate_entity_connections(state.entity_index),
      relationship_types: map_size(state.type_index),
      high_confidence_relationships: length(Map.values(state.confidence_index.high || %{})),
      interventions: length(state.intervention_history),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      relationship_distribution: get_relationship_distribution(state.type_index)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp generate_relationship_id do
    "causal:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp generate_intervention_id do
    "intervention:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp calculate_relationship_confidence(relationship, _all_relationships) do
    # Base confidence on relationship strength and evidence from interventions
    base_confidence = relationship.confidence
    
    # Adjust based on intervention success
    intervention_success = calculate_intervention_success(relationship.interventions)
    
    # Combine confidence factors
    final_confidence = base_confidence * 0.7 + intervention_success * 0.3
    
    min(1.0, final_confidence)
  end

  defp calculate_intervention_success(interventions) do
    if Enum.empty?(interventions) do
      0.5  # Neutral confidence when no interventions
    else
      success_count = Enum.count(interventions, fn intervention ->
        Enum.any?(intervention.outcomes, fn outcome -> outcome.success end)
      end)
      
      success_count / length(interventions)
    end
  end

  defp update_entity_index(entity_index, relationship) do
    # Add to outgoing relationships
    outgoing = Map.get(entity_index, "outgoing", %{})
    source_outgoing = Map.get(outgoing, relationship.source, %{})
    updated_source_outgoing = Map.put(source_outgoing, relationship.target, relationship.id)
    updated_outgoing = Map.put(outgoing, relationship.source, updated_source_outgoing)
    
    # Add to incoming relationships
    incoming = Map.get(entity_index, "incoming", %{})
    target_incoming = Map.get(incoming, relationship.target, %{})
    updated_target_incoming = Map.put(target_incoming, relationship.source, relationship.id)
    updated_incoming = Map.put(incoming, relationship.target, updated_target_incoming)
    
    %{entity_index | "outgoing" => updated_outgoing, "incoming" => updated_incoming}
  end

  defp update_type_index(type_index, relationship) do
    relationship_ids = Map.get(type_index, relationship.type, [])
    updated_ids = [relationship.id | relationship_ids]
    Map.put(type_index, relationship.type, updated_ids)
  end

  defp update_strength_index(strength_index, relationship) do
    strength_bucket = get_strength_bucket(relationship.strength)
    relationship_ids = Map.get(strength_index, strength_bucket, [])
    updated_ids = [relationship.id | relationship_ids]
    Map.put(strength_index, strength_bucket, updated_ids)
  end

  defp update_confidence_index(confidence_index, relationship) do
    confidence_bucket = get_confidence_bucket(relationship.confidence)
    relationship_ids = Map.get(confidence_index, confidence_bucket, [])
    updated_ids = [relationship.id | relationship_ids]
    Map.put(confidence_index, confidence_bucket, updated_ids)
  end

  defp rebuild_entity_index(relationships, _relationship) do
    # Rebuild the entire entity index from all relationships
    entity_index = %{"outgoing" => %{}, "incoming" => %{}}
    
    Enum.reduce(relationships, entity_index, fn {_id, rel, acc} ->
      outgoing = Map.get(acc, "outgoing", %{})
      source_outgoing = Map.get(outgoing, rel.source, %{})
      updated_source_outgoing = Map.put(source_outgoing, rel.target, rel.id)
      updated_outgoing = Map.put(outgoing, rel.source, updated_source_outgoing)
      
      incoming = Map.get(acc, "incoming", %{})
      target_incoming = Map.get(incoming, rel.target, %{})
      updated_target_incoming = Map.put(target_incoming, rel.source, rel.id)
      updated_incoming = Map.put(incoming, rel.target, updated_target_incoming)
      
      %{acc | "outgoing" => updated_outgoing, "incoming" => updated_incoming}
    end)
  end

  defp rebuild_type_index(relationships, relationship_type) do
    relationship_ids = Map.keys(relationships)
    |> Enum.filter(fn id -> 
      Map.get(relationships, id).type == relationship_type
    end)
    
    Map.put(%{}, relationship_type, relationship_ids)
  end

  defp rebuild_strength_index(relationships, relationship) do
    strength_bucket = get_strength_bucket(relationship.strength)
    relationship_ids = Map.keys(relationships)
    |> Enum.filter(fn id -> 
      get_strength_bucket(Map.get(relationships, id).strength) == strength_bucket
    end)
    
    Map.put(%{}, strength_bucket, relationship_ids)
  end

  defp rebuild_confidence_index(relationships, relationship) do
    confidence_bucket = get_confidence_bucket(relationship.confidence)
    relationship_ids = Map.keys(relationships)
    |> Enum.filter(fn id -> 
      get_confidence_bucket(Map.get(relationships, id).confidence) == confidence_bucket
    end)
    
    Map.put(%{}, confidence_bucket, relationship_ids)
  end

  defp find_all_causal_paths(relationships, start_entity, max_depth \\ 5) do
    # Find all paths starting from the entity, limited by max_depth
    visited = MapSet.new()
    find_paths_recursive(relationships, start_entity, [], max_depth, visited)
  end

  defp find_paths_recursive(_relationships, _entity, _current_path, 0, _visited) do
    []  # Stop at max depth
  end

  defp find_paths_recursive(relationships, entity, current_path, remaining_depth, visited) do
    if MapSet.member?(visited, entity) do
      []  # Already visited this entity
    else
      new_visited = MapSet.put(visited, entity)
      
      # Find outgoing relationships from this entity
      outgoing_relationships = Enum.filter(relationships, fn {_id, rel} ->
        rel.source == entity
      end)
      
      # Build paths from each relationship
      paths = Enum.flat_map(outgoing_relationships, fn {_id, rel} ->
        new_path = [rel | current_path]
        continue_paths = find_paths_recursive(relationships, rel.target, new_path, remaining_depth - 1, new_visited)
        [new_path | continue_paths]
      end)
      
      paths
    end
  end

  defp predict_effect_strength(path, relationships) do
    if Enum.empty?(path) do
      0.0
    else
      # Calculate cumulative strength along the path
      path_strengths = Enum.map(path, fn rel ->
        Map.get(relationships, rel.id).strength
      end)
      
      # Geometric mean for cumulative strength
      total_strength = Enum.reduce(path_strengths, 1.0, fn strength, acc ->
        acc * strength
      end)
      
      :math.pow(total_strength, 1.0 / length(path))
    end
  end

  defp calculate_path_confidence(path, relationships) do
    if Enum.empty?(path) do
      0.0
    else
      # Average confidence of all relationships in the path
      path_confidences = Enum.map(path, fn rel ->
        Map.get(relationships, rel.id).confidence
      end)
      
      Enum.sum(path_confidences) / length(path)
    end
  end

  defp calculate_likelihood(path, relationships) do
    if Enum.empty?(path) do
      0.0
    else
      # Combine strength and confidence to calculate likelihood
      strength = predict_effect_strength(path, relationships)
      confidence = calculate_path_confidence(path, relationships)
      
      strength * confidence
    end
  end

  defp find_shortest_path(_relationships, _source_id, _target_id) do
    # Simple BFS to find shortest path (stubbed out because original had invalid while loop)
    []
  end

  defp calculate_entity_connections(entity_index) do
    outgoing_connections = entity_index["outgoing"] |> Map.values() |> Enum.map(&map_size/1)
    incoming_connections = entity_index["incoming"] |> Map.values() |> Enum.map(&map_size/1)
    
    total_connections = Enum.sum(outgoing_connections) + Enum.sum(incoming_connections)
    total_connections
  end

  defp get_strength_bucket(strength) when strength >= 0.9, do: :very_high
  defp get_strength_bucket(strength) when strength >= 0.7, do: :high
  defp get_strength_bucket(strength) when strength >= 0.5, do: :medium
  defp get_strength_bucket(strength) when strength >= 0.3, do: :low
  defp get_strength_bucket(_strength), do: :very_low

  defp get_confidence_bucket(confidence) when confidence >= 0.9, do: :very_high
  defp get_confidence_bucket(confidence) when confidence >= 0.7, do: :high
  defp get_confidence_bucket(confidence) when confidence >= 0.5, do: :medium
  defp get_confidence_bucket(confidence) when confidence >= 0.3, do: :low
  defp get_confidence_bucket(_confidence), do: :very_low

  defp get_relationship_distribution(type_index) do
    type_index
    |> Enum.map(fn {type, relationships} -> {type, length(relationships)} end)
    |> Enum.into(%{})
  end
end