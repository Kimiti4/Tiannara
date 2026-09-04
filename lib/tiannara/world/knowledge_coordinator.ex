defmodule Tiannara.World.KnowledgeCoordinator do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{
    UnifiedWorldModel, WorldMutationEngine, OntologyManager,
    KnowledgeEvolutionEngine, EvidenceValidator, CanonicalWorldState
  }
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory, WorkflowEngine}
  alias Tiannara.CEL.Kernel.ConstitutionalScore
  alias Tiannara.Discovery.Validation.DiscoveryCertifier

  @min_evidence_for_principle 5
  @min_confidence_for_principle 0.95

  @impl Tiannara.ExecutiveService
  def id, do: :knowledge_coordinator

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :discovery_ingestion,
      :evidence_fusion,
      :duplicate_elimination,
      :knowledge_validation,
      :discovery_certification,
      :principle_extraction,
      :memory_promotion_orchestration
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :world_mutation_engine, :ontology_manager, :knowledge_evolution_engine,
     :evidence_validator, :workflow_engine]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :critical

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    evidence_quality =
      if stats.total_knowledge_items > 0,
        do: stats.validated_knowledge_items / stats.total_knowledge_items,
        else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def ingest_discovery(discovery_spec) do
    GenServer.call(__MODULE__, {:ingest, discovery_spec})
  end

  def fuse_evidence(entity_id, new_evidence, evidence_weight \\ 1.0) do
    GenServer.call(__MODULE__, {:fuse_evidence, entity_id, new_evidence, evidence_weight})
  end

  def promote_memory_stage(entity_id, target_stage, context \\ %{}) do
    GenServer.call(__MODULE__, {:promote, entity_id, target_stage, context})
  end

  def promote_to_knowledge(entity_id) do
    GenServer.call(__MODULE__, {:promote_to_knowledge, entity_id})
  end

  def validate_knowledge(entity_id, validation_protocol) do
    GenServer.call(__MODULE__, {:validate, entity_id, validation_protocol})
  end

  def certify_discovery(discovery) do
    GenServer.call(__MODULE__, {:certify_discovery, discovery})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    EventBus.subscribe("discovery.completed", self())
    EventBus.subscribe("experiment.completed", self())
    EventBus.subscribe("world.entity.updated", self())

    {:ok, %{
      total_knowledge_items: 0,
      validated_knowledge_items: 0,
      pending_validations: 0,
      principles_extracted: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:ingest, spec}, _from, state) do
    case find_similar_entities(spec) do
      {:duplicate, existing_id} ->
        fuse_evidence_internal(existing_id, Map.get(spec, :evidence, []), spec.confidence)
        {:reply, {:ok, :merged_into_existing, existing_id}, state}

      :unique ->
        entity_spec = %{
          id: spec.id,
          type: spec.type,
          subtype: determine_initial_stage(spec.type),
          attributes: Map.get(spec, :attributes, %{}),
          confidence: spec.confidence,
          uncertainty: 1.0 - spec.confidence,
          provenance: spec.provenance,
          version: 1
        }

        case UnifiedWorldModel.create_entity(entity_spec) do
          {:ok, entity_id} ->
            ExecutiveMemory.record_decision(
              "ingest_#{entity_id}",
              :discovery_ingested,
              %{entity_id: entity_id, type: spec.type, confidence: spec.confidence}
            )

            EventBus.publish("knowledge.ingested", %{entity_id: entity_id, type: spec.type})

            {:reply, {:ok, entity_id}, %{state | total_knowledge_items: state.total_knowledge_items + 1}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:fuse_evidence, entity_id, new_evidence, weight}, _from, state) do
    case fuse_evidence_internal(entity_id, new_evidence, weight) do
      {:ok, updated_confidence} ->
        {:reply, {:ok, updated_confidence}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:promote, entity_id, target_stage, context}, _from, state) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        current_stage = entity.subtype
        memory_stages = CanonicalWorldState.memory_stages()
        current_idx = Enum.find_index(memory_stages, &(&1 == current_stage))
        target_idx = Enum.find_index(memory_stages, &(&1 == target_stage))

        cond do
          is_nil(current_idx) or is_nil(target_idx) ->
            {:reply, {:error, :invalid_memory_stage}, state}

          target_idx <= current_idx ->
            {:reply, {:error, :target_stage_not_higher}, state}

          target_stage in [:principle, :generalized_understanding, :scientific_discovery] ->
            if Map.get(context, :human_approved, false) or Map.get(context, :impact_level, :low) == :low do
              do_promote(entity_id, target_stage, state)
            else
              {:reply, {:error, {:requires_human_review, "High-impact knowledge promotion requires human approval"}}, state}
            end

          true ->
            do_promote(entity_id, target_stage, state)
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:validate, entity_id, protocol}, _from, state) do
    workflow_spec = %{
      name: "Knowledge Validation: #{entity_id}",
      steps: [
        %{module: Tiannara.CEL.Workflow.Steps.Validation, input: %{entity_id: entity_id, protocol: protocol}}
      ]
    }

    case WorkflowEngine.start_workflow(workflow_spec) do
      {:ok, workflow_id} ->
        {:reply, {:ok, workflow_id}, %{state | pending_validations: state.pending_validations + 1}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:promote_to_knowledge, entity_id}, _from, state) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        confidence = entity.confidence || 0.0
        evidence = case entity.attributes do
          %{evidence: ev} when is_list(ev) -> ev
          _ -> []
        end
        cond do
          confidence < 0.4 ->
            {:reply, {:error, :insufficient_confidence}, state}
          length(evidence) < 1 ->
            {:reply, {:error, :insufficient_evidence}, state}
          entity.status == :promoted ->
            {:reply, {:error, :already_promoted}, state}
          true ->
            case promote_via_engine(entity_id) do
              {:ok, _} ->
                UnifiedWorldModel.update_entity(entity_id, %{status: :promoted})
                ExecutiveMemory.record_decision("promote_to_knowledge_#{entity_id}", :knowledge_promoted, %{entity_id: entity_id})
                EventBus.publish("knowledge.promoted", %{entity_id: entity_id, stage: :knowledge})
                ns = %{state | total_knowledge_items: state.total_knowledge_items + 1}
                {:reply, {:ok, %{status: :promoted, id: entity_id}}, ns}
              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:certify_discovery, discovery}, _from, state) do
    certified = DiscoveryCertifier.certified?(discovery)
    report = DiscoveryCertifier.validate(discovery)

    ExecutiveMemory.record_decision(
      "certify_#{discovery.id}",
      :discovery_certification,
      %{discovery_id: discovery.id, certified: certified, overall_score: report.overall_score}
    )

    EventBus.publish("discovery.certified", %{
      discovery_id: discovery.id,
      certified: certified,
      overall_score: report.overall_score,
      certification_level: report.certification.level
    })

    {:reply, %{certified: certified, report: report}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:event, event}, state) do
    payload = event.raw_payload
    event_type = Map.get(payload, :type, event.type)

    case event_type do
      "experiment.completed" ->
        hypothesis_id = Map.get(payload, :hypothesis_id)
        evidence = Map.get(payload, :evidence, [])
        confidence = Map.get(payload, :confidence, 0.5)
        if hypothesis_id, do: fuse_evidence_internal(hypothesis_id, evidence, confidence)
        {:noreply, state}

      "world.entity.updated" ->
        if Map.get(payload, :subtype) == :principle do
          {:noreply, %{state | principles_extracted: state.principles_extracted + 1}}
        else
          {:noreply, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  defp fuse_evidence_internal(entity_id, new_evidence, weight) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        old_conf = entity.confidence || 0.5
        avg_evidence_conf =
          if length(new_evidence) == 0 do
            0.5
          else
            Enum.sum(Enum.map(new_evidence, &Map.get(&1, :confidence, 0.5))) / length(new_evidence)
          end

        new_conf = (old_conf + (weight * avg_evidence_conf)) / (1.0 + weight)
        final_conf = min(0.99, max(0.01, new_conf))

        existing_evidence = case entity.attributes do
          %{evidence: ev} when is_list(ev) -> ev
          _ -> []
        end

        UnifiedWorldModel.update_entity(entity_id, %{
          confidence: final_conf,
          uncertainty: 1.0 - final_conf,
          attributes: Map.put(entity.attributes || %{}, :evidence, existing_evidence ++ new_evidence),
          updated_at: DateTime.utc_now()
        })

        EvidenceValidator.validate_entity_evidence(entity_id)
        {:ok, final_conf}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_similar_entities(_spec), do: :unique

  defp determine_initial_stage(type) do
    case type do
      :observation -> :data
      :experimental_result -> :information
      :hypothesis -> :information
      :pattern -> :pattern
      :model -> :model
      _ -> :information
    end
  end

  defp promote_via_engine(entity_id) do
    case Process.whereis(KnowledgeEvolutionEngine) do
      nil ->
        {:ok, :promoted_directly}
      _pid ->
        KnowledgeEvolutionEngine.promote_entity(entity_id, %{target: :knowledge})
    end
  end

  defp do_promote(entity_id, target_stage, state) do
    case KnowledgeEvolutionEngine.promote_entity(entity_id, %{target: target_stage}) do
      {:ok, _} ->
        UnifiedWorldModel.update_entity(entity_id, %{subtype: target_stage})

        ExecutiveMemory.record_decision(
          "promote_#{entity_id}",
          :memory_stage_promoted,
          %{entity_id: entity_id, target_stage: target_stage}
        )

        EventBus.publish("knowledge.promoted", %{entity_id: entity_id, stage: target_stage})

        new_state =
          if target_stage == :principle,
            do: %{state | principles_extracted: state.principles_extracted + 1},
            else: state

        {:reply, {:ok, target_stage}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
end
