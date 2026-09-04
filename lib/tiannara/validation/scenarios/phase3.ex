defmodule Tiannara.Validation.Scenarios.Phase3 do
  @moduledoc """
  Reusable validation scenarios for Phase 3 components.
  Each function is a self-contained scenario that returns `:ok` or `{:error, reason}`.
  """

  alias Tiannara.World.{
    UnifiedWorldModel, KnowledgeCoordinator, KnowledgeFlowEngine,
    ConflictResolutionEngine
  }

  @doc "Scenario: ingest a discovery and verify it appears in the world model."
  def ingest_discovery do
    discovery_id = "val_test_discovery_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

    spec = %{
      id: discovery_id,
      type: :observation,
      attributes: %{claim: "Test observation for validation"},
      evidence: [%{source: "validation_test", confidence: 0.8}],
      confidence: 0.6,
      provenance: %{origin: :validation_test, produced_by: :validation_scenario, produced_at: DateTime.utc_now()}
    }

    result = KnowledgeCoordinator.ingest_discovery(spec)
    entity = UnifiedWorldModel.get_entity(discovery_id)

    case {result, entity} do
      {{:ok, ^discovery_id}, {:ok, _}} -> :ok
      {{:ok, :merged_into_existing, _}, {:ok, _}} -> :ok
      _ -> {:error, :ingestion_failed}
    end
  end

  @doc "Scenario: fuse evidence into an existing entity and verify confidence changes."
  def fuse_evidence do
    entity_id = "val_test_fuse_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

    initial_spec = %{
      id: entity_id,
      type: :hypothesis,
      attributes: %{statement: "Test hypothesis for evidence fusion"},
      evidence: [%{source: "initial", confidence: 0.5}],
      confidence: 0.5,
      provenance: %{origin: :validation_test, produced_by: :validation_scenario, produced_at: DateTime.utc_now()}
    }

    case KnowledgeCoordinator.ingest_discovery(initial_spec) do
      {:ok, _} ->
        new_evidence = [%{source: "corroborating_experiment", confidence: 0.9}]

        case KnowledgeCoordinator.fuse_evidence(entity_id, new_evidence, 1.0) do
          {:ok, new_confidence} when new_confidence > 0.5 -> :ok
          {:ok, _} -> {:error, :confidence_did_not_increase}
          {:error, reason} -> {:error, reason}
        end

      other ->
        {:error, {:ingestion_failed, other}}
    end
  end

  @doc "Scenario: promote an entity through memory stages."
  def promote_memory do
    entity_id = "val_test_promote_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

    spec = %{
      id: entity_id,
      type: :observation,
      attributes: %{data: "Test promotion data"},
      evidence: [%{source: "promotion_test", confidence: 0.8}],
      confidence: 0.7,
      provenance: %{origin: :validation_test, produced_by: :validation_scenario, produced_at: DateTime.utc_now()}
    }

    with {:ok, _} <- KnowledgeCoordinator.ingest_discovery(spec),
         {:ok, :information} <- KnowledgeCoordinator.promote_memory_stage(entity_id, :information),
         {:ok, :knowledge} <- KnowledgeCoordinator.promote_memory_stage(entity_id, :knowledge) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:promotion_failed, other}}
    end
  end

  @doc "Scenario: force-propagate a knowledge entity through the flow engine."
  def propagate_knowledge do
    entity_id = "val_test_prop_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

    spec = %{
      id: entity_id,
      type: :scientific_entity,
      subtype: :scientific_discovery,
      attributes: %{finding: "Test propagation finding"},
      evidence: [%{source: "propagation_test", confidence: 0.95}],
      confidence: 0.9,
      provenance: %{origin: :validation_test, produced_by: :validation_scenario, produced_at: DateTime.utc_now()}
    }

    case KnowledgeCoordinator.ingest_discovery(spec) do
      {:ok, _} ->
        case KnowledgeFlowEngine.force_propagate(entity_id) do
          {:ok, state} when is_map(state) -> :ok
          {:error, reason} -> {:error, reason}
          other -> {:error, {:propagation_failed, other}}
        end

      other ->
        {:error, {:ingestion_failed, other}}
    end
  end

  @doc "Scenario: record and resolve a conflict."
  def conflict_resolution do
    entity_a = "val_test_conflict_a"
    entity_b = "val_test_conflict_b"

    spec_a = %{
      id: entity_a, type: :hypothesis,
      attributes: %{claim: "The universe is 13.8 billion years old"},
      evidence: [%{source: "telescope_data", confidence: 0.95}],
      confidence: 0.9,
      provenance: %{origin: :validation_test, produced_by: :cosmology_dept, produced_at: DateTime.utc_now()}
    }

    spec_b = %{
      id: entity_b, type: :hypothesis,
      attributes: %{claim: "The universe is 26.7 billion years old"},
      evidence: [%{source: "new_telescope_data", confidence: 0.85}],
      confidence: 0.8,
      provenance: %{origin: :validation_test, produced_by: :alternative_cosmology, produced_at: DateTime.utc_now()}
    }

    with {:ok, _} <- KnowledgeCoordinator.ingest_discovery(spec_a),
         {:ok, _} <- KnowledgeCoordinator.ingest_discovery(spec_b) do
      conflict_spec = %{
        entity_ids: [entity_a, entity_b],
        domain: :cosmology,
        description: "Dispute over universe age",
        severity: :high,
        evidence: [%{type: :direct_contradiction}],
        requires_human_review: false
      }

      case ConflictResolutionEngine.record_conflict(conflict_spec) do
        {:ok, conflict_id} ->
          case ConflictResolutionEngine.resolve_conflict(conflict_id, {:deprecate_lower_confidence, entity_b}) do
            {:ok, _resolved} -> :ok
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:setup_failed, other}}
    end
  end

  @doc "Scenario: run a full campaign covering all Phase 3 scenarios and return a campaign ID."
  def run_full_campaign do
    config = %{
      name: "Phase 3 — Full Validation Campaign",
      description: "Validates all five core Phase 3 scenarios: ingestion, fusion, promotion, propagation, conflict resolution",
      scenarios: [
        %{name: "discovery_ingestion", module: __MODULE__, function: :ingest_discovery, args: []},
        %{name: "evidence_fusion", module: __MODULE__, function: :fuse_evidence, args: []},
        %{name: "memory_promotion", module: __MODULE__, function: :promote_memory, args: []},
        %{name: "knowledge_propagation", module: __MODULE__, function: :propagate_knowledge, args: []},
        %{name: "conflict_resolution", module: __MODULE__, function: :conflict_resolution, args: []}
      ]
    }

    Tiannara.ValidationCampaigns.start_campaign(config)
  end
end
