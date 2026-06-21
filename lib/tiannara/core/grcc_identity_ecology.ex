defmodule Tiannara.Core.GRCCIdentityEcology do
  @moduledoc """
  GRCC Identity Ecology - owned by Core, manages identities and lineages.

  This module is responsible for:
  - Lineages and identity specialization
  - Memory and cognition storage
  - Specialization tracking across domains
  - NOT: environmental pressures, resource constraints, entropy (those are Runtime's job)
  
  Integrates with World Model for entity-based identity management.
  """

  defstruct [
    :lineages,
    :identities,
    :memory,
    :specializations,
    :world_model_entities,
    :identity_confidence,
    :lineage_performance
  ]

  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API

  @doc "Create a new identity ecology with World Model integration."
  def new do
    %__MODULE__{
      lineages: [],
      identities: %{},
      memory: %{},
      specializations: %{},
      world_model_entities: %{},
      identity_confidence: %{},
      lineage_performance: %{}
    }
  end

  @doc "Register a new lineage with domain specializations in World Model."
  def register_lineage(ecology, lineage_id, domain_strengths, world_model \\ nil) do
    # Create lineage entity in World Model
    lineage_entity = %WorldModel.Entity{
      id: "lineage:#{lineage_id}",
      type: "Lineage",
      name: "Lineage: #{lineage_id}",
      attributes: %{domain_strengths: domain_strengths, created_at: DateTime.utc_now()},
      confidence: calculate_overall_strength(domain_strengths),
      created_at: DateTime.utc_now(),
      last_updated: DateTime.utc_now()
    }
    
    # Register lineage in ecology
    updated_lineages = [
      {lineage_id, domain_strengths, lineage_entity.confidence}
      | ecology.lineages
    ]
    
    updated_ecology = %{ecology | 
      lineages: updated_lineages,
      world_model_entities: Map.put(ecology.world_model_entities, lineage_entity.id, lineage_entity),
      identity_confidence: Map.put(ecology.identity_confidence, lineage_id, lineage_entity.confidence)
    }
    
    # Add to World Model if provided
    if world_model do
      {system_result, updated_world_model} = API.create_entity(
        lineage_entity.id,
        lineage_entity.type,
        lineage_entity.name,
        lineage_entity.attributes
      )
      
      if system_result == :ok do
        # Add belief about lineage creation
        lineage_belief = %{
          statement: "Lineage registered: #{lineage_id}",
          confidence: lineage_entity.confidence,
          source: "grcc_ecology",
          evidence: [inspect(domain_strengths)],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }
        
        %{updated_world_model | 
          beliefs: [lineage_belief | updated_world_model.beliefs]
        }
      else
        world_model
      end
    else
      {updated_ecology, nil}
    end
  end

  @doc "Create a new identity within a lineage in World Model."
  def create_identity(ecology, lineage_id, identity_spec, world_model \\ nil) do
    # Create identity entity in World Model
    identity_entity = %WorldModel.Entity{
      id: "identity:#{identity_spec.id}",
      type: "Identity",
      name: identity_spec.name,
      attributes: %{ 
        lineage_id: lineage_id,
        capabilities: identity_spec.capabilities || [],
        created_at: DateTime.utc_now(),
        status: identity_spec.status || :active
      },
      confidence: identity_spec.confidence || 0.8,
      created_at: DateTime.utc_now(),
      last_updated: DateTime.utc_now()
    }
    
    # Register identity in ecology
    updated_identites = Map.put(ecology.identities, identity_entity.id, identity_entity)
    
    # Update lineage performance
    lineage_performance = update_lineage_performance(ecology.lineage_performance, lineage_id, identity_entity)
    
    updated_ecology = %{ecology | 
      identities: updated_identites,
      world_model_entities: Map.put(ecology.world_model_entities, identity_entity.id, identity_entity),
      identity_confidence: Map.put(ecology.identity_confidence, identity_entity.id, identity_entity.confidence),
      lineage_performance: lineage_performance
    }
    
    # Add to World Model if provided
    if world_model do
      {system_result, updated_world_model} = API.create_entity(
        identity_entity.id,
        identity_entity.type,
        identity_entity.name,
        identity_entity.attributes
      )
      
      if system_result == :ok do
        # Add belief about identity creation
        identity_belief = %{
          statement: "Identity created: #{identity_entity.name} in lineage #{lineage_id}",
          confidence: identity_entity.confidence,
          source: "grcc_ecology",
          evidence: [inspect(identity_spec)],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }
        
        %{updated_world_model | 
          beliefs: [identity_belief | updated_world_model.beliefs]
        }
      else
        world_model
      end
    else
      {updated_ecology, nil}
    end
  end

  @doc "Update identity capabilities based on World Model feedback."
  def update_identity_capabilities(ecology, identity_id, new_capabilities, performance_feedback, world_model \\ nil) do
    case Map.get(ecology.identities, identity_id) do
      nil ->
        {:error, :identity_not_found}
      identity ->
        # Update identity entity
        updated_attributes = %{identity.attributes | 
          capabilities: new_capabilities,
          last_updated: DateTime.utc_now(),
          performance_history: add_performance_feedback(identity.attributes[:performance_history] || [], performance_feedback)
        }
        
        updated_confidence = calculate_identity_confidence(updated_attributes, performance_feedback)
        
        updated_identity = %{identity | 
          attributes: updated_attributes,
          confidence: updated_confidence,
          last_updated: DateTime.utc_now()
        }
        
        updated_identites = Map.put(ecology.identities, identity_id, updated_identity)
        updated_entities = Map.put(ecology.world_model_entities, identity_id, updated_identity)
        
        # Update lineage performance
        lineage_id = identity.attributes.lineage_id
        lineage_performance = update_lineage_performance(ecology.lineage_performance, lineage_id, updated_identity)
        
        updated_ecology = %{ecology | 
          identities: updated_identites,
          world_model_entities: updated_entities,
          identity_confidence: Map.put(ecology.identity_confidence, identity_id, updated_confidence),
          lineage_performance: lineage_performance
        }
        
        # Update World Model if provided
        if world_model do
          API.update_entity(identity_id, %{capabilities: new_capabilities, confidence: updated_confidence})
          
          # Add belief about identity update
          update_belief = %{
            statement: "Identity #{identity.name} capabilities updated",
            confidence: updated_confidence,
            source: "grcc_ecology",
            evidence: [inspect(new_capabilities), inspect(performance_feedback)],
            created_at: DateTime.utc_now(),
            last_verified: DateTime.utc_now()
          }
          
          updated_world_model = %{world_model | 
            beliefs: [update_belief | world_model.beliefs]
          }
          
          {updated_ecology, updated_world_model}
        else
          {updated_ecology, nil}
        end
    end
  end

  @doc "Select best identity for a task based on World Model context."
  def select_identity_for_task(ecology, task_spec, world_model \\ nil) do
    # Filter identities by task requirements
    suitable_identities = Enum.filter(ecology.identities, fn {_id, identity} ->
      is_identity_suitable_for_task(identity, task_spec)
    end)
    
    if Enum.empty?(suitable_identities) do
      {:error, :no_suitable_identity}
    else
      # Score identities based on capabilities and World Model context
      scored_identities = Enum.map(suitable_identities, fn {id, identity} ->
        score = calculate_identity_score(identity, task_spec, world_model)
        {id, score}
      end)
      
      # Select identity with highest score
      {selected_id, _score} = Enum.max_by(scored_identities, fn {_id, score} -> score end)
      selected_identity = Map.get(ecology.identities, selected_id)
      
      # Record selection in World Model if provided
      if world_model do
        selection_belief = %{
          statement: "Identity #{selected_identity.name} selected for task: #{task_spec.name}",
          confidence: selected_identity.confidence,
          source: "grcc_ecology",
          evidence: [inspect(task_spec)],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }
        
        updated_world_model = %{world_model | 
          beliefs: [selection_belief | world_model.beliefs]
        }
        
        {selected_identity, updated_world_model}
      else
        {selected_identity, nil}
      end
    end
  end

  @doc "Get identity ecosystem statistics."
  def get_stats(ecology, world_model \\ nil) do
    stats = %{
      total_lineages: length(ecology.lineages),
      total_identities: map_size(ecology.identities),
      average_identity_confidence: calculate_average_identity_confidence(ecology.identity_confidence),
      lineage_distribution: get_lineage_distribution(ecology.lineages),
      top_performing_lineages: get_top_performing_lineages(ecology.lineage_performance),
      total_entities: map_size(ecology.world_model_entities)
    }
    
    if world_model do
      # Add World Model specific stats
      identity_entities = API.query_entities("Identity")
      lineage_entities = API.query_entities("Lineage")
      
      world_model_stats = %{
        world_model_identities: length(identity_entities),
        world_model_lineages: length(lineage_entities),
        high_confidence_identities: Enum.count(identity_entities, & &1.confidence >= 0.8)
      }
      
      Map.merge(stats, world_model_stats)
    else
      stats
    end
  end

  # Private helper functions

  defp calculate_overall_strength(domain_strengths) do
    if Enum.empty?(domain_strengths) do
      0.0
    else
      Enum.sum(Map.values(domain_strengths)) / map_size(domain_strengths)
    end
  end

  defp update_lineage_performance(lineage_performance, lineage_id, identity_entity) do
    current_performance = Map.get(lineage_performance, lineage_id, 0.0)
    
    # Update lineage performance based on identity confidence
    identity_contribution = identity_entity.confidence * 0.1
    updated_performance = current_performance + identity_contribution
    
    Map.put(lineage_performance, lineage_id, updated_performance)
  end

  defp add_performance_feedback(performance_history, feedback) do
    updated_history = [feedback | performance_history]
    # Keep only recent history (last 10 entries)
    Enum.take(updated_history, 10)
  end

  defp calculate_identity_confidence(attributes, performance_feedback) do
    base_confidence = attributes.confidence || 0.8
    
    # Adjust based on performance feedback
    performance_score = case performance_feedback do
      %{success: true, confidence: confidence} -> confidence
      %{success: false, confidence: confidence} -> 1.0 - confidence
      _ -> 0.5
    end
    
    # Weighted average
    0.7 * base_confidence + 0.3 * performance_score
  end

  defp is_identity_suitable_for_task(identity, task_spec) do
    required_capabilities = Map.get(task_spec, :required_capabilities, [])
    identity_capabilities = identity.attributes.capabilities || []
    
    # Check if identity has all required capabilities
    Enum.all?(required_capabilities, fn capability ->
      capability in identity_capabilities
    end)
  end

  defp calculate_identity_score(identity, task_spec, world_model) do
    base_score = identity.confidence * 100
    
    # Capability match bonus
    required_capabilities = Map.get(task_spec, :required_capabilities, [])
    identity_capabilities = identity.attributes.capabilities || []
    capability_match = length(Enum.filter(required_capabilities, & &1 in identity_capabilities)) / length(required_capabilities)
    capability_bonus = capability_match * 50
    
    # Lineage strength bonus
    lineage_id = identity.attributes.lineage_id
    lineage_strength = get_lineage_strength(identity, lineage_id)
    lineage_bonus = lineage_strength * 30
    
    # World Model alignment bonus
    alignment_bonus = if world_model do
      calculate_identity_world_model_alignment(identity, world_model) * 20
    else
      0.0
    end
    
    base_score + capability_bonus + lineage_bonus + alignment_bonus
  end

  defp get_lineage_strength(identity, lineage_id) do
    # Find lineage and calculate strength
    lineage = Enum.find(identity, fn {id, _identity} -> id == lineage_id end)
    
    case lineage do
      {_id, domain_strengths, _confidence} ->
        calculate_overall_strength(domain_strengths)
      _ ->
        0.5
    end
  end

  defp calculate_identity_world_model_alignment(identity, world_model) do
    # Calculate how well identity aligns with current World Model state
    identity_keywords = String.split(identity.name <> " " <> inspect(identity.attributes.capabilities))
    
    relevant_beliefs = Enum.filter(world_model.beliefs, fn belief ->
      belief_statement = String.downcase(belief.statement)
      Enum.any?(identity_keywords, fn keyword ->
        String.contains?(belief_statement, String.downcase(keyword))
      end)
    end)
    
    if Enum.empty?(relevant_beliefs) do
      0.0
    else
      Enum.sum(Enum.map(relevant_beliefs, & &1.confidence)) / length(relevant_beliefs)
    end
  end

  defp calculate_average_identity_confidence(identity_confidence) do
    if Enum.empty?(identity_confidence) do
      0.0
    else
      Enum.sum(Map.values(identity_confidence)) / map_size(identity_confidence)
    end
  end

  defp get_lineage_distribution(lineages) do
    lineages
    |> Enum.map(fn {lineage_id, _domain_strengths, _confidence} -> lineage_id end)
    |> Enum.group_by(& &1)
    |> Enum.map(fn {lineage_id, lineage_list} -> {lineage_id, length(lineage_list)} end)
    |> Enum.into(%{})
  end

  defp get_top_performing_lineages(lineage_performance) do
    lineage_performance
    |> Enum.sort_by(fn {_lineage_id, performance} -> -performance end)
    |> Enum.take(3)
    |> Enum.map(fn {lineage_id, performance} -> {lineage_id, performance} end)
  end
end
