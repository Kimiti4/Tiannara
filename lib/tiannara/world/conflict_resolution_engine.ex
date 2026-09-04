defmodule Tiannara.World.ConflictResolutionEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldMutationEngine, WorldQueryEngine}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.Council.HumanApprovalQueue
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @conflict_table :conflict_resolution_engine
  @conflict_file ~c"./conflict_resolution_engine.dets"

  @impl Tiannara.ExecutiveService
  def id, do: :conflict_resolution_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :explicit_disagreement_modeling,
      :contradiction_detection,
      :structured_resolution_workflows,
      :human_escalation,
      :experiment_proposal
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :world_mutation_engine]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :critical

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    active = active_conflicts_list()

    critical_unresolved = Enum.count(active, &(&1.severity == :critical and &1.status == :unresolved))
    health = if critical_unresolved > 0, do: 0.5, else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: health,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record_conflict(conflict_spec) do
    GenServer.call(__MODULE__, {:record_conflict, conflict_spec})
  end

  def resolve(entity_id_a, entity_id_b, opts \\ []) do
    GenServer.call(__MODULE__, {:resolve_entities, entity_id_a, entity_id_b, opts})
  end

  def resolve_conflict(conflict_id, resolution) do
    GenServer.call(__MODULE__, {:resolve_conflict, conflict_id, resolution})
  end

  def detect_conflict(entity_id_a, entity_id_b) do
    GenServer.call(__MODULE__, {:detect_conflict, entity_id_a, entity_id_b})
  end

  def create_entity(entity_spec) do
    UnifiedWorldModel.create_entity(entity_spec)
  end

  def get_entity(entity_id) do
    UnifiedWorldModel.get_entity(entity_id)
  end

  def active_conflicts, do: GenServer.call(__MODULE__, :active_conflicts)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    case :dets.open_file(@conflict_table, type: :set, file: @conflict_file) do
      {:ok, _} ->
        EventBus.subscribe("world.consistency.violation", self())
        Logger.info("ConflictResolutionEngine: initialized")
        {:ok, %{
          total_conflicts: 0,
          resolved_conflicts: 0,
          human_escalations: 0,
          healthy: true,
          started_at: DateTime.utc_now()
        }}

      {:error, reason} ->
        Logger.error("ConflictResolutionEngine: failed to open storage: #{inspect(reason)}")
        {:ok, %{healthy: false, total_conflicts: 0, resolved_conflicts: 0, human_escalations: 0}}
    end
  end

  @impl true
  def handle_call({:detect_conflict, entity_id_a, entity_id_b}, _from, state) do
    if entity_id_a == entity_id_b do
      {:reply, {:ok, %{conflict_type: :no_conflict, entities: [entity_id_a, entity_id_b]}}, state}
    else
      {entity_a, entity_b} = case {UnifiedWorldModel.get_entity(entity_id_a), UnifiedWorldModel.get_entity(entity_id_b)} do
        {{:ok, a}, {:ok, b}} -> {a, b}
        _ -> {:error, :not_found}
      end

      case {entity_a, entity_b} do
        {:error, _} ->
          result = %{conflict_type: :measurement_discrepancy, entities: [entity_id_a, entity_id_b]}
          {:reply, {:ok, result}, state}
        {a, b} ->
          domain_a = Map.get(a, :domain)
          domain_b = Map.get(b, :domain)
          if domain_a != nil and domain_b != nil and domain_a != domain_b do
            {:reply, {:ok, %{conflict_type: :no_conflict, entities: [entity_id_a, entity_id_b]}}, state}
          else
            result = %{conflict_type: :measurement_discrepancy, entities: [entity_id_a, entity_id_b]}
            {:reply, {:ok, result}, state}
          end
      end
    end
  end

  @impl true
  def handle_call({:resolve_entities, entity_id_a, entity_id_b, opts}, _from, state) do
    strategy = Keyword.get(opts, :strategy, :confidence_weighted)
    case strategy do
      :confidence_weighted ->
        case {UnifiedWorldModel.get_entity(entity_id_a), UnifiedWorldModel.get_entity(entity_id_b)} do
          {{:ok, a}, {:ok, b}} ->
            {winner_id, loser_id, winner_conf, loser_conf} =
              if a.confidence >= b.confidence do
                {entity_id_a, entity_id_b, a.confidence, b.confidence}
              else
                {entity_id_b, entity_id_a, b.confidence, a.confidence}
              end
            resolution = %{resolution: :override, winner_id: winner_id, loser_id: loser_id,
              winner_confidence: winner_conf, loser_confidence: loser_conf}
            {:reply, {:ok, resolution}, state}
          _ ->
            {:reply, {:error, :entity_not_found}, state}
        end
      :merge ->
        merged_id = "merged_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
        {conf_a, conf_b} = case {UnifiedWorldModel.get_entity(entity_id_a), UnifiedWorldModel.get_entity(entity_id_b)} do
          {{:ok, a}, {:ok, b}} -> {a.confidence, b.confidence}
          _ -> {0.5, 0.5}
        end
        merged_conf = max(conf_a, conf_b)
        merged_prov = [entity_id_a, entity_id_b]
        {:ok, _} = UnifiedWorldModel.create_entity(%{
          id: merged_id, type: :knowledge_entity, subtype: :merged,
          attributes: %{source_entities: [entity_id_a, entity_id_b]},
          confidence: merged_conf, uncertainty: 1.0 - merged_conf,
          provenance: %{origin: :conflict_merge, source_entities: [entity_id_a, entity_id_b],
            produced_by: :conflict_resolution_engine, produced_at: DateTime.utc_now()}
        })
        resolution = %{resolution: :merge, merged_entity_id: merged_id,
          confidence: merged_conf, provenance: merged_prov}
        {:reply, {:ok, resolution}, state}
    end
  end

  @impl true
  def handle_call({:record_conflict, spec}, _from, state) do
    conflict_id = "conflict_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    conflict_record = %{
      id: conflict_id,
      entity_ids: spec.entity_ids,
      domain: spec.domain,
      description: spec.description,
      severity: Map.get(spec, :severity, :medium),
      evidence: Map.get(spec, :evidence, []),
      requires_human_review: Map.get(spec, :requires_human_review, false),
      status: :unresolved,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      resolution_history: []
    }

    :dets.insert(@conflict_table, {conflict_id, conflict_record})

    contradiction_entity = %{
      id: "contradiction_#{conflict_id}",
      type: :constraint_entity,
      subtype: :contradiction,
      attributes: %{
        description: spec.description,
        severity: spec.severity,
        conflict_id: conflict_id
      },
      confidence: 1.0,
      uncertainty: 0.0,
      provenance: %{
        origin: :conflict_resolution_engine,
        produced_by: :system,
        produced_at: DateTime.utc_now()
      }
    }

    case UnifiedWorldModel.create_entity(contradiction_entity) do
      {:ok, _} ->
        Enum.each(spec.entity_ids, fn entity_id ->
          UnifiedWorldModel.create_relationship(%{
            from_id: "contradiction_#{conflict_id}",
            to_id: entity_id,
            type: :constrained_by,
            confidence: 1.0
          })
        end)

        ExecutiveMemory.record_decision(
          conflict_id,
          :contradiction_recorded,
          conflict_record
        )

        EventBus.publish("world.conflict.recorded", %{
          conflict_id: conflict_id,
          domain: spec.domain,
          severity: spec.severity
        })

        if spec.requires_human_review or spec.severity == :critical do
          escalate_to_human_internal(conflict_id, spec.description)
        end

        {:reply, {:ok, conflict_id}, %{state | total_conflicts: state.total_conflicts + 1}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:resolve_conflict, conflict_id, resolution}, _from, state) do
    case :dets.lookup(@conflict_table, conflict_id) do
      [{^conflict_id, conflict}] when conflict.status == :unresolved ->
        case apply_resolution(conflict, resolution) do
          {:ok, resolution_record} ->
            updated_conflict = %{conflict |
              status: :resolved,
              updated_at: DateTime.utc_now(),
              resolution_history: conflict.resolution_history ++ [resolution_record]
            }

            :dets.insert(@conflict_table, {conflict_id, updated_conflict})

            UnifiedWorldModel.update_entity("contradiction_#{conflict_id}", %{
              status: :resolved,
              attributes: %{
                resolution_type: resolution_record.type,
                resolved_at: DateTime.utc_now()
              }
            })

            ExecutiveMemory.record_decision(
              "resolve_#{conflict_id}",
              :contradiction_resolved,
              %{conflict_id: conflict_id, resolution: resolution_record.type}
            )

            EventBus.publish("world.conflict.resolved", %{
              conflict_id: conflict_id,
              resolution: resolution_record.type
            })

            {:reply, {:ok, updated_conflict}, %{state | resolved_conflicts: state.resolved_conflicts + 1}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      [{^conflict_id, _conflict}] ->
        {:reply, {:error, :already_resolved}, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:active_conflicts, _from, state) do
    {:reply, active_conflicts_list(), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      total_conflicts: state.total_conflicts,
      resolved_conflicts: state.resolved_conflicts,
      human_escalations: state.human_escalations,
      active_conflicts: active_conflicts_list()
    }, state}
  end

  @impl true
  def handle_info({:event, event}, state) do
    payload = event.raw_payload
    event_type = Map.get(payload, :topic, event.type)

    if event_type == "world.consistency.violation" do
      conflict_spec = %{
        entity_ids: Map.get(payload, :entities, []),
        domain: :knowledge,
        description: Map.get(payload, :description, "Consistency violation detected"),
        severity: Map.get(payload, :severity, :medium),
        evidence: [%{type: :validator_alert, details: payload}],
        requires_human_review: Map.get(payload, :severity) == :critical
      }

      handle_call({:record_conflict, conflict_spec}, nil, state)
    end

    {:noreply, state}
  end

  defp apply_resolution(_conflict, {:experiment_to_resolve, experiment_spec}) do
    resolution_record = %{
      type: :experiment_to_resolve,
      experiment_spec: experiment_spec,
      resolved_by: :system,
      resolved_at: DateTime.utc_now(),
      note: "New experiment proposed to gather distinguishing evidence"
    }
    {:ok, resolution_record}
  end

  defp apply_resolution(conflict, {:deprecate_lower_confidence, entity_id_to_deprecate}) do
    case UnifiedWorldModel.get_entity(entity_id_to_deprecate) do
      {:ok, _entity} ->
        UnifiedWorldModel.refute_entity(entity_id_to_deprecate,
          "Deprecated due to conflict resolution: lower confidence"
        )

        resolution_record = %{
          type: :deprecate_lower_confidence,
          deprecated_entity_id: entity_id_to_deprecate,
          resolved_by: :system,
          resolved_at: DateTime.utc_now(),
          note: "Entity deprecated; higher confidence entity retained"
        }
        {:ok, resolution_record}

      {:error, _} ->
        {:error, :entity_to_deprecate_not_found}
    end
  end

  defp apply_resolution(conflict, {:merge_with_uncertainty, new_entity_spec}) do
    merged_spec = Map.put(new_entity_spec, :provenance, %{
      origin: :conflict_merge,
      produced_by: :conflict_resolution_engine,
      produced_at: DateTime.utc_now(),
      source_conflicts: [conflict.id]
    })

    case UnifiedWorldModel.create_entity(merged_spec) do
      {:ok, new_entity_id} ->
        Enum.each(conflict.entity_ids, fn old_id ->
          UnifiedWorldModel.create_relationship(%{
            from_id: old_id,
            to_id: new_entity_id,
            type: :derived_from,
            confidence: 1.0
          })
          UnifiedWorldModel.refute_entity(old_id, "Merged into #{new_entity_id} with expanded uncertainty")
        end)

        resolution_record = %{
          type: :merge_with_uncertainty,
          new_entity_id: new_entity_id,
          resolved_by: :system,
          resolved_at: DateTime.utc_now(),
          note: "Conflicting entities merged into a new entity with expanded uncertainty bounds"
        }
        {:ok, resolution_record}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp apply_resolution(conflict, :request_human_review) do
    escalate_to_human_internal(conflict.id, conflict.description)

    resolution_record = %{
      type: :escalated_to_human,
      resolved_by: :human_pending,
      resolved_at: DateTime.utc_now(),
      note: "Escalated to Constitutional Council / Human Approval Queue"
    }
    {:ok, resolution_record}
  end

  defp apply_resolution(_conflict, _invalid_resolution) do
    {:error, :invalid_resolution_type}
  end

  defp escalate_to_human_internal(conflict_id, description) do
    HumanApprovalQueue.enqueue(
      "conflict_review_#{conflict_id}",
      :contradiction_resolution,
      %{conflict_id: conflict_id, description: description},
      "Critical knowledge contradiction requires human arbitration to determine which claim (if any) is valid."
    )

    ExecutiveMemory.record_decision(
      "escalate_#{conflict_id}",
      :conflict_escalated_to_human,
      %{conflict_id: conflict_id}
    )

    Logger.warning("ConflictResolutionEngine: Conflict #{conflict_id} escalated for human review")
  end

  defp active_conflicts_list do
    :dets.traverse(@conflict_table, fn
      {_id, %{status: :unresolved} = conflict} -> {:continue, conflict}
      _ -> {:continue}
    end)
  end
end
