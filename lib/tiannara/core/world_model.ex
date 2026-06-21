defmodule Tiannara.Core.WorldModel do
  @moduledoc """
  Canonical Reality Representation Layer

  The World Model is the single source of truth for all reality representation
  in Tiannara. Every cognitive operation, domain reasoning, and runtime action
  operates on the World Model.

  ## Architecture

  Every domain, lineage, planner, and runtime subsystem reads from and writes
  to the World Model:

  ```
  Domains
    ↓
  World Model
    ↑
  Runtime
  ```

  ## Structure

  - **Entities**: Everything becomes an entity (User, Goal, Lineage, etc.)
  - **Beliefs**: Confidence-weighted statements about reality
  - **Causal Graph**: Cause-effect relationships and interventions
  - **Timeline**: Past, present, future, and counterfactual states
  - **Predictions**: Scenario probabilities and forecasts
  - **Uncertainty**: Ambiguities, contradictions, confidence distribution
  - **Ontology**: Semantic relationships and concept mappings
  - **Metadata**: Last updated, version tracking

  ## Key Principle

  Do NOT let Memory, Ontology, Timeline, Prediction, Entity Registry
  become separate truth stores.

  Everything converges into the World Model as the canonical representation.

  ## Operation Flow

  ```
  User Goal
      ↓
  Core Goal System
      ↓
  Meta-Cognition (consults World Model)
      ↓
  Domain Team (operates on World Model)
      ↓
  World Model Update (revision)
      ↓
  AEO Plan (from World Model state)
      ↓
  OED Challenge (consult World Model)
      ↓
  Runtime Execution (on World Model state)
      ↓
  Feedback (to World Model)
      ↓
  World Model Revision (with confidence updates)
  ```
  """

  defstruct [
    :entities,
    :beliefs,
    :causal_graph,
    :timeline,
    :predictions,
    :ontology,
    :uncertainty,
    :last_updated,
    :version
  ]

  @doc "Create a new World Model."
  def new do
    %__MODULE__{
      entities: %{},
      beliefs: [],
      causal_graph: %{nodes: [], edges: []},
      timeline: %{past: [], present: %{}, future: []},
      predictions: %{},
      ontology: %{},
      uncertainty: %{ambiguities: [], contradictions: []},
      last_updated: DateTime.utc_now(),
      version: 1
    }
  end

  @doc "Update World Model with new information."
  def update(world_model, key, value) do
    %{world_model | key => value, last_updated: DateTime.utc_now(), version: world_model.version + 1}
  end

  @doc "Query World Model for entity by type and attributes."
  def query_entities(world_model, entity_type) do
    world_model.entities
    |> Enum.filter(fn {_id, entity} -> entity.type == entity_type end)
    |> Enum.map(fn {_id, entity} -> entity end)
  end

  @doc "Get all beliefs with confidence > threshold."
  def high_confidence_beliefs(world_model, threshold \\ 0.7) do
    Enum.filter(world_model.beliefs, fn belief ->
      belief.confidence >= threshold
    end)
  end
end
