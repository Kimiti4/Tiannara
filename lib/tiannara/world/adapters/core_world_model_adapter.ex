defmodule Tiannara.World.Adapters.CoreWorldModelAdapter do
  @moduledoc """
  Adapter for Tiannara.Core.WorldModel — the legacy canonical world representation.

  Transforms Core.WorldModel entities into the canonical format expected by
  the WorldIntegrationCoordinator.
  """
  @behaviour Tiannara.World.SourceAdapter

  @impl true
  def source_id, do: :core_world_model

  @impl true
  def pull_state(_opts, since_version) do
    case get_legacy_world_state() do
      {:ok, state} ->
        entities = transform_state_to_entities(state)
        version = compute_version(state)

        filtered =
          if since_version do
            Enum.filter(entities, &entity_changed_since?(&1, since_version))
          else
            entities
          end

        {:ok, %{
          entities: filtered,
          version: version,
          changes_only: since_version != nil
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def push_state(_entity, _opts) do
    {:error, :read_only_source}
  end

  @impl true
  def current_version(_opts) do
    case get_legacy_world_state() do
      {:ok, state} -> compute_version(state)
      _ -> "0"
    end
  end

  @impl true
  def metadata do
    %{
      name: "Core.WorldModel",
      description: "Legacy canonical world representation",
      owner: :core,
      read_only: true,
      migration_status: :in_progress
    }
  end

  defp get_legacy_world_state do
    {:ok, %{
      entities: [
        %{id: "entity_1", type: :scientific_entity, subtype: :hypothesis, attributes: %{statement: "H1"}, confidence: 0.7},
        %{id: "entity_2", type: :knowledge_entity, subtype: :fact, attributes: %{content: "F1"}, confidence: 0.9}
      ],
      version_counter: 42
    }}
  end

  defp transform_state_to_entities(state) do
    Enum.map(state.entities, fn e ->
      %{
        id: e.id,
        type: e.type,
        subtype: Map.get(e, :subtype),
        attributes: Map.get(e, :attributes, %{}),
        confidence: Map.get(e, :confidence, 0.5),
        uncertainty: 1.0 - Map.get(e, :confidence, 0.5),
        provenance: %{
          origin: :core_world_model,
          source_id: "entity_#{e.id}",
          migrated_at: DateTime.utc_now()
        },
        relationships: []
      }
    end)
  end

  defp compute_version(state), do: to_string(state.version_counter)

  defp entity_changed_since?(_entity, _since_version), do: true
end
