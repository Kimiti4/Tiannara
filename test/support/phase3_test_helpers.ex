defmodule Tiannara.Test.Phase3Helpers do
  import ExUnit.Assertions

  alias Tiannara.World.{
    UnifiedWorldModel, UnifiedRealityGraph, WorldMutationEngine,
    ProvenanceEngine, VersionManager, ConflictResolutionEngine,
    KnowledgeCoordinator, CanonicalWorldState, BeliefState,
    SnapshotManager, OntologyManager
  }

  def unique_id(prefix \\ "test") do
    "#{prefix}_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  def fresh_provenance(origin \\ :test_suite) do
    %{
      origin: origin,
      produced_by: :test_process,
      produced_at: DateTime.utc_now(),
      produced_at_unix: System.system_time(:second)
    }
  end

  def build_entity_spec(domain, type, subtype, attrs \\ %{}, opts \\ []) do
    confidence = Keyword.get(opts, :confidence, 0.5)

    %{
      id: Keyword.get(opts, :id, unique_id("entity")),
      domain: domain,
      type: type,
      subtype: subtype,
      attributes: attrs,
      confidence: confidence,
      uncertainty: 1.0 - confidence,
      provenance: Keyword.get(opts, :provenance, fresh_provenance()),
      owner_subsystem: Keyword.get(opts, :owner, :test_suite),
      version: 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      status: :active
    }
  end

  def assert_entity_exists(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} -> entity
      {:error, reason} -> flunk("Expected entity #{entity_id} to exist, got: #{inspect(reason)}")
    end
  end

  def refute_entity_exists(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:error, _} -> :ok
      {:ok, entity} -> flunk("Expected entity #{entity_id} to not exist, found: #{inspect(entity)}")
    end
  end

  def wait_for_event(topic, timeout_ms \\ 2000) do
    receive do
      {:executive_bus_message, %{topic: ^topic} = msg} -> msg
    after
      timeout_ms -> flunk("Timed out waiting for event on topic #{topic}")
    end
  end
end
