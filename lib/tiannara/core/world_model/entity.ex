defmodule Tiannara.Core.WorldModel.Entity do
  @moduledoc """
  Entity representation in the World Model.

  Everything in Tiannara becomes an entity:
  - Users, Agents, Lineages
  - Goals, Projects, Tasks
  - Markets, Files, Tools
  - Ontologies, Concepts
  """

  defstruct [
    :id,
    :type,
    :name,
    :attributes,
    :relationships,
    :confidence,
    :created_at,
    :last_updated
  ]

  @doc "Create a new entity."
  def new(id, type, name, attrs \\ %{}) do
    %__MODULE__{
      id: id,
      type: type,
      name: name,
      attributes: attrs,
      relationships: [],
      confidence: 1.0,
      created_at: DateTime.utc_now(),
      last_updated: DateTime.utc_now()
    }
  end

  @doc "Add a relationship to another entity."
  def add_relationship(entity, target_id, relationship_type) do
    new_rel = {target_id, relationship_type}
    %{entity | relationships: [new_rel | entity.relationships]}
  end

  @doc "Update confidence in this entity."
  def update_confidence(entity, new_confidence) do
    %{entity | confidence: new_confidence, last_updated: DateTime.utc_now()}
  end
end
