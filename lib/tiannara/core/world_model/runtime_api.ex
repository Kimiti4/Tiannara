defmodule Tiannara.Core.WorldModel.RuntimeAPI do
  @moduledoc """
  Runtime API for World Model operations.
  
  Provides specialized interfaces for runtime systems to interact with
  the World Model while maintaining separation of concerns.
  """

  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API

  @doc "Initialize World Model for runtime operations."
  def initialize_runtime_world_model(core_id, runtime_id) do
    # Create base World Model
    world_model = WorldModel.new()
    
    # Add runtime entity
    runtime_entity = %WorldModel.Entity{
      id: "runtime:#{runtime_id}",
      type: "Runtime",
      name: "Tiannara Runtime Instance",
      attributes: %{core_id: core_id, capabilities: ["execution", "monitoring", "feedback"]},
      confidence: 1.0,
      created_at: DateTime.utc_now(),
      last_updated: DateTime.utc_now()
    }
    
    world_model = %{world_model | 
      entities: Map.put(world_model.entities, runtime_entity.id, runtime_entity)
    }
    
    # Add runtime-specific beliefs
    runtime_belief = %{
      statement: "Runtime system operational",
      confidence: 1.0,
      source: "initialization",
      evidence: ["system_start", "core_connected"],
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }
    
    world_model = %{world_model | 
      beliefs: [runtime_belief | world_model.beliefs]
    }
    
    world_model
  end

  @doc "Process runtime feedback into World Model."
  def process_runtime_feedback(world_model, feedback_data) do
    # Extract feedback components
    %{
      entity_id: entity_id,
      operation: operation,
      success: success,
      confidence: confidence,
      timestamp: timestamp,
      context: context
    } = feedback_data
    
    # Add feedback as a belief
    feedback_belief = %{
      statement: "Runtime operation #{operation} on #{entity_id} was #{if success, do: "successful", else: "failed"}",
      confidence: confidence,
      source: "runtime_feedback",
      evidence: [context],
      created_at: timestamp || DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }
    
    updated_world_model = %{world_model | 
      beliefs: [feedback_belief | world_model.beliefs]
    }
    
    # Update entity confidence based on feedback
    if Map.has_key?(world_model.entities, entity_id) do
      entity = Map.get(world_model.entities, entity_id)
      updated_confidence = update_entity_confidence(entity, success, confidence)
      updated_entities = Map.put(updated_world_model.entities, entity_id, updated_confidence)
      
      %{updated_world_model | entities: updated_entities}
    else
      # Create new entity if it doesn't exist
      new_entity = %WorldModel.Entity{
        id: entity_id,
        type: "RuntimeEntity",
        name: "Entity from runtime",
        attributes: %{last_operation: operation},
        confidence: confidence,
        created_at: timestamp || DateTime.utc_now(),
        last_updated: timestamp || DateTime.utc_now()
      }
      
      updated_entities = Map.put(updated_world_model.entities, entity_id, new_entity)
      %{updated_world_model | entities: updated_entities}
    end
  end

  @doc "Generate runtime intent from World Model state."
  def generate_runtime_intent(world_model) do
    # Analyze World Model state to determine runtime priorities
    active_entities = Map.values(world_model.entities)
    |> Enum.filter(fn entity ->
      entity.confidence > 0.5
    end)
    
    high_confidence_beliefs = Enum.filter(world_model.beliefs, fn belief ->
      belief.confidence > 0.7
    end)
    
    # Generate runtime intent based on analysis
    intent = %{
      priority: calculate_priority(high_confidence_beliefs),
      target_entities: Enum.map(active_entities, & &1.id),
      focus_areas: extract_focus_areas(high_confidence_beliefs),
      confidence: calculate_intent_confidence(high_confidence_beliefs),
      timestamp: DateTime.utc_now(),
      source: "world_model_analysis"
    }
    
    intent
  end

  @doc "Validate runtime operations against World Model constraints."
  def validate_runtime_operation(world_model, operation) do
    %{
      entity_id: entity_id,
      operation_type: operation_type,
      parameters: parameters,
      expected_outcome: expected_outcome
    } = operation
    
    # Check entity exists and is accessible
    entity_exists = Map.has_key?(world_model.entities, entity_id)
    
    unless entity_exists do
      {:error, "Entity #{entity_id} not found in World Model"}
    end
    
    # Check operation is allowed for entity type
    entity = Map.get(world_model.entities, entity_id)
    operation_allowed = is_operation_allowed(entity.type, operation_type)
    
    unless operation_allowed do
      {:error, "Operation #{operation_type} not allowed for entity type #{entity.type}"}
    end
    
    # Check against constraints from beliefs
    constraints = extract_constraints(world_model.beliefs)
    operation_valid = validate_against_constraints(operation, constraints)
    
    unless operation_valid do
      {:error, "Operation violates World Model constraints"}
    end
    
    # Check expected outcome against causal predictions
    outcome_prediction = predict_outcome(world_model, operation)
    outcome_consistent = is_outcome_consistent(expected_outcome, outcome_prediction)
    
    unless outcome_consistent do
      {:warning, "Expected outcome may not align with World Model predictions"}
    end
    
    {:ok, :validated}
  end

  @doc "Update World Model with runtime execution results."
  def update_with_execution_results(world_model, results) do
    %{
      operation_id: operation_id,
      success: success,
      results: results_data,
      confidence: confidence,
      timestamp: timestamp
    } = results
    
    # Add execution result as belief
    result_belief = %{
      statement: "Operation #{operation_id} completed with #{if success, do: "success", else: "failure"}",
      confidence: confidence,
      source: "runtime_execution",
      evidence: [results_data],
      created_at: timestamp || DateTime.utc_now(),
      last_verified: timestamp || DateTime.utc_now()
    }
    
    updated_world_model = %{world_model | 
      beliefs: [result_belief | world_model.beliefs]
    }
    
    # Update entity states based on results
    updated_entities = Enum.reduce(results_data, world_model.entities, fn result, acc_entities ->
      case result do
        %{entity_id: entity_id, new_state: new_state} ->
          if Map.has_key?(acc_entities, entity_id) do
            entity = Map.get(acc_entities, entity_id)
            updated_entity = %{entity | attributes: Map.merge(entity.attributes, new_state)}
            Map.put(acc_entities, entity_id, updated_entity)
          else
            acc_entities
          end
        _ ->
          acc_entities
      end
    end)
    
    %{updated_world_model | entities: updated_entities}
  end

  @doc "Get runtime-specific World Model statistics."
  def get_runtime_stats(world_model) do
    %{
      total_entities: map_size(world_model.entities),
      active_entities: Enum.count(world_model.entities, fn {_id, entity} -> entity.confidence > 0.5 end),
      high_confidence_beliefs: Enum.count(world_model.beliefs, fn belief -> belief.confidence > 0.7 end),
      last_updated: world_model.last_updated,
      version: world_model.version,
      critical_entities: get_critical_entities(world_model),
      operational_state: get_operational_state(world_model)
    }
  end

  # Private helper functions

  defp update_entity_confidence(entity, success, confidence) do
    # Adjust entity confidence based on operation success
    confidence_adjustment = if success, do: 0.1, else: -0.2
    new_confidence = entity.confidence + confidence_adjustment
    
    %{entity | 
      confidence: max(0.0, min(1.0, new_confidence)),
      last_updated: DateTime.utc_now()
    }
  end

  defp calculate_priority(beliefs) do
    if Enum.empty?(beliefs) do
      :low
    else
      avg_confidence = Enum.sum(Enum.map(beliefs, & &1.confidence)) / length(beliefs)
      
      cond do
        avg_confidence >= 0.9 -> :critical
        avg_confidence >= 0.7 -> :high
        avg_confidence >= 0.5 -> :medium
        true -> :low
      end
    end
  end

  defp extract_focus_areas(beliefs) do
    # Extract key focus areas from high-confidence beliefs
    belief_keywords = Enum.flat_map(beliefs, fn belief ->
      String.split(belief.statement)
    end)
    
    # Count keyword frequency
    keyword_counts = Enum.reduce(belief_keywords, %{}, fn keyword, acc ->
      Map.update(acc, keyword, 1, & &1 + 1)
    end)
    
    # Get top keywords
    keyword_counts
    |> Enum.sort_by(fn {_keyword, count} -> -count end)
    |> Enum.take(3)
    |> Enum.map(fn {keyword, _count} -> keyword end)
  end

  defp calculate_intent_confidence(beliefs) do
    if Enum.empty?(beliefs) do
      0.0
    else
      Enum.sum(Enum.map(beliefs, & &1.confidence)) / length(beliefs)
    end
  end

  defp is_operation_allowed(entity_type, operation_type) do
    # Define allowed operations for each entity type
    allowed_operations = %{
      "RuntimeEntity" => ["read", "write", "execute"],
      "Domain" => ["process", "analyze", "predict"],
      "Core" => ["decide", "plan", "monitor"],
      "Goal" => ["track", "update", "achieve"]
    }
    
    allowed_for_type = Map.get(allowed_operations, entity_type, [])
    operation_type in allowed_for_type
  end

  defp extract_constraints(beliefs) do
    # Extract operational constraints from beliefs
    Enum.filter(beliefs, fn belief ->
      String.contains?(belief.statement, "constraint") or 
      String.contains?(belief.statement, "limit") or
      String.contains?(belief.statement, "requirement")
    end)
  end

  defp validate_against_constraints(operation, constraints) do
    # Simplified constraint validation
    Enum.all?(constraints, fn constraint ->
      # Check if operation violates any constraints
      not String.contains?(constraint.statement, "violation")
    end)
  end

  defp predict_outcome(world_model, operation) do
    # Simplified outcome prediction based on causal relationships
    %{
      likelihood: 0.8,  # Base likelihood
      confidence: 0.7,
      factors: ["entity_exists", "operation_allowed"]
    }
  end

  defp is_outcome_consistent(expected, predicted) do
    # Check if expected outcome aligns with predictions
    abs(expected.confidence - predicted.confidence) < 0.3
  end

  defp get_critical_entities(world_model) do
    Enum.filter(world_model.entities, fn {_id, entity} ->
      Map.get(entity.attributes, :critical, false) or entity.confidence >= 0.9
    end)
    |> Enum.map(fn {_id, entity} -> entity.id end)
  end

  defp get_operational_state(world_model) do
    # Determine overall operational state based on World Model
    high_conf_beliefs = Enum.count(world_model.beliefs, fn belief -> belief.confidence > 0.7 end)
    total_beliefs = length(world_model.beliefs)
    
    if total_beliefs == 0 do
      :initializing
    else
      confidence_ratio = high_conf_beliefs / total_beliefs
      cond do
        confidence_ratio >= 0.9 -> :optimal
        confidence_ratio >= 0.7 -> :stable
        confidence_ratio >= 0.5 -> :degraded
        true -> :unstable
      end
    end
  end
end