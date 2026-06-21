defmodule Tiannara.Core do
  @moduledoc """
  Tiannara Core (Mind) - owns identity, cognition, goals and executive intent.

  ## Architecture

  Core represents the cognitive sovereign of Tiannara, responsible for:
  - **Identity**: Self-model, long-term memory, values, preferences
  - **Cognition**: Reasoning, planning, world modeling, meta-cognition
  - **Executive Intent**: Deciding what should happen and why
  - **GRCC Identity Ecology**: Managing identities and lineages (organisms)
  - **Goal System**: Managing executive goals and outcomes
  - **World Model**: Canonical reality representation layer

  ## The World Model Integration

  The World Model is the single source of truth for all reality representation.
  Every cognitive operation, domain reasoning, and runtime action operates on 
  or updates the World Model:

  ```
  Domains → World Model ← Runtime
       ↑        ↑
  Core ← World Model State
  ```

  ## Boundary

  Core decides; it does not execute.

  Execution is delegated to:
  1. **AEO** (Adaptive Execution Orchestrator) - translates intent to execution
  2. **Runtime** - executes with stability, ecology, validation

  ## Data Flow

  ```
  User Goal
      ↓
  Core Goal System (consults World Model)
      ↓
  Meta-Cognition (operates on World Model)
      ↓
  Domain Team (updates World Model)
      ↓
  World Model Revision
      ↓
  AEO Plan (from World Model state)
      ↓
  OED Challenge (consult World Model)
      ↓
  Runtime Execution (on World Model state)
      ↓
  Feedback → World Model → Core
  ```
  """

  alias Tiannara.Identity
  alias Tiannara.Cognition
  alias Tiannara.MetaCognition
  alias Tiannara.DomainCortex
  alias Tiannara.Core.GRCCIdentityEcology
  alias Tiannara.Core.GoalSystem
  alias Tiannara.Core.WorldModel

  @doc "Get a map describing Core components."
  def summary do
    %{
      identity: "Tiannara.Identity",
      cognition: "Tiannara.Cognition",
      meta_cognition: "Tiannara.MetaCognition",
      world_model: "Tiannara.Core.WorldModel (CANONICAL REALITY)",
      goal_system: "Tiannara.Core.GoalSystem",
      grcc_identity_ecology: "Tiannara.Core.GRCCIdentityEcology",
      domain_cortex: "Tiannara.DomainCortex"
    }
  end

  @doc "Create a new Core state with identity, goals, and World Model as canonical reality."
  def new(core_id) do
    world_model = WorldModel.new()
    
    # Add Core as the first entity in the World Model
    core_entity = WorldModel.Entity.new(
      "core:#{core_id}",
      "Core",
      "Tiannara Cognitive Core",
      %{type: "sovereign", capabilities: ["reasoning", "planning", "decision"]}
    )
    
    world_model = WorldModel.update(world_model, :entities, Map.put(world_model.entities, core_entity.id, core_entity))

    %{
      identity: Identity.new(core_id),
      cognition: %Cognition{},
      meta_cognition: %MetaCognition{},
      goal_system: GoalSystem.new(),
      world_model: world_model,
      grcc_ecology: GRCCIdentityEcology.new()
    }
  end

  @doc "Update World Model with new information and propagate to relevant systems."
  def update_world_model(core_state, update_key, update_value) do
    updated_world_model = WorldModel.update(core_state.world_model, update_key, update_value)
    
    # Update MetaCognition based on World Model changes
    updated_meta_cognition = MetaCognition.consult_world_model(core_state.meta_cognition, updated_world_model)
    
    %{core_state | 
      world_model: updated_world_model,
      meta_cognition: updated_meta_cognition
    }
  end

  @doc "Query World Model for entities by type and attributes."
  def query_entities(core_state, entity_type) do
    WorldModel.query_entities(core_state.world_model, entity_type)
  end

  @doc "Get high confidence beliefs from World Model."
  def high_confidence_beliefs(core_state, threshold \\ 0.7) do
    WorldModel.high_confidence_beliefs(core_state.world_model, threshold)
  end

  @doc "Generate executive intent based on World Model state."
  def generate_intent(core_state) do
    # Consult World Model for current state and goals
    current_entities = query_entities(core_state, "Goal")
    high_beliefs = high_confidence_beliefs(core_state)
    
    # Generate intent based on goals and high-confidence beliefs
    intent = %{
      source: "core",
      based_on: Enum.map(high_beliefs, & &1.statement),
      target_goals: Enum.map(current_entities, & &1.name),
      confidence: calculate_intent_confidence(high_beliefs),
      timestamp: DateTime.utc_now()
    }
    
    # Update World Model with new intent
    update_world_model(core_state, :intent, intent)
  end

  defp calculate_intent_confidence(beliefs) do
    if Enum.empty?(beliefs) do
      0.0
    else
      avg_confidence = beliefs 
        |> Enum.map(& &1.confidence)
        |> Enum.sum()
        |> Kernel./(length(beliefs))
      
      # Adjust for goal alignment
      goal_alignment_factor = 0.8
      avg_confidence * goal_alignment_factor
    end
  end
end
