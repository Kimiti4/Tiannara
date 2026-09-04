defmodule Tiannara.World.Adapters.AgencyRealityGraphAdapter do
  @moduledoc """
  Example GraphAdapter for the Agency's RealityGraph.

  Demonstrates the adapter contract by wrapping a hypothetical
  Tiannara.Agency.RealityGraph module. Replace the internal calls
  with the actual Agency RealityGraph API in production.
  """
  use Tiannara.World.GraphAdapter
  require Logger

  @impl true
  def pull_graph(opts, offset) do
    Logger.info("AgencyRealityGraphAdapter: pulling graph with offset #{inspect(offset)}")

    case fetch_agency_entities(offset) do
      {:ok, entities, new_offset} ->
        transformed = Enum.map(entities, &transform_to_canonical/1)
        {:ok, %{entities: transformed, offset: new_offset}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def push_entity(entity, _opts) do
    Logger.info("AgencyRealityGraphAdapter: pushing entity #{entity.id}")
    push_to_agency(entity)
  end

  @impl true
  def current_offset(_opts) do
    {:ok, get_agency_latest_offset()}
  end

  @impl true
  def metadata do
    %{
      name: "Agency RealityGraph Adapter",
      version: "1.0.0",
      source: :agency_reality_graph,
      bidirectional: false,
      read_only: true
    }
  end

  defp fetch_agency_entities(offset) do
    {:ok, example_entities(), nil}
  end

  defp transform_to_canonical(entity) do
    %{
      id: Map.get(entity, :id, "agency_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"),
      type: Map.get(entity, :type, :knowledge_entity),
      subtype: Map.get(entity, :subtype, :observation),
      attributes: Map.get(entity, :attributes, %{}),
      confidence: Map.get(entity, :confidence, 0.5),
      uncertainty: 1.0 - Map.get(entity, :confidence, 0.5),
      provenance: %{
        origin: :agency_reality_graph,
        source_id: entity.id,
        migrated_at: DateTime.utc_now()
      },
      relationships: Map.get(entity, :relationships, [])
    }
  end

  defp push_to_agency(_entity) do
    {:error, :read_only_source}
  end

  defp get_agency_latest_offset, do: nil

  defp example_entities do
    [
      %{
        id: "agency_obs_001",
        type: :knowledge_entity,
        subtype: :observation,
        attributes: %{content: "Agency detected anomaly X", severity: :high},
        confidence: 0.85,
        relationships: []
      },
      %{
        id: "agency_hyp_001",
        type: :scientific_entity,
        subtype: :hypothesis,
        attributes: %{statement: "Anomaly X is correlated with Y", status: :investigating},
        confidence: 0.6,
        relationships: [
          %{from_id: "agency_hyp_001", to_id: "agency_obs_001", type: :derived_from}
        ]
      }
    ]
  end
end
