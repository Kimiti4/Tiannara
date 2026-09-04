defmodule Tiannara.World.KnowledgeFlowPipeline do
  @moduledoc """
  Knowledge Flow Pipeline — the closed-loop scientific reasoning orchestrator.

  Listens for raw events and automatically triggers the next logical step
  in the scientific method lifecycle, preserving lineage and constitutional context.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldMutationEngine}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory, MissionDirector, WorkflowEngine}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :knowledge_flow_pipeline

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :scientific_method_orchestration,
      :lifecycle_progression,
      :validation_gating,
      :lineage_preservation,
      :stagnation_prevention
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model, :workflow_engine]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    %ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def inject(entity_id, stage), do: GenServer.call(__MODULE__, {:inject, entity_id, stage})

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    EventBus.subscribe("world.entity.created")
    EventBus.subscribe("experiment.completed")
    EventBus.subscribe("validation.completed")
    EventBus.subscribe("discovery.published")

    {:ok, %{
      entities_processed: 0,
      pipeline_promotions: 0,
      pipeline_blocks: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "world.entity.created", payload: payload}}, state) do
    entity_id = payload.entity_id
    entity_type = payload.type
    subtype = payload.subtype

    case {entity_type, subtype} do
      {:scientific_entity, :observation} ->
        trigger_hypothesis_generation(entity_id, payload)
      {:scientific_entity, :hypothesis} ->
        trigger_experiment_design(entity_id, payload)
      _ ->
        :ok
    end

    {:noreply, %{state | entities_processed: state.entities_processed + 1}}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "experiment.completed", payload: payload}}, state) do
    trigger_validation(payload.experiment_id, payload.hypothesis_id, payload)
    {:noreply, %{state | entities_processed: state.entities_processed + 1}}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "validation.completed", payload: payload}}, state) do
    if payload.validated do
      promote_to_discovery(payload.hypothesis_id, payload)
      {:noreply, %{state | pipeline_promotions: state.pipeline_promotions + 1}}
    else
      refute_or_request_new(payload.hypothesis_id, payload)
      {:noreply, %{state | pipeline_blocks: state.pipeline_blocks + 1}}
    end
  end

  @impl true
  def handle_call({:inject, entity_id, stage}, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  # ---------- Private: Pipeline Triggers ----------

  defp trigger_hypothesis_generation(observation_id, payload) do
    Logger.info("KnowledgeFlowPipeline: Triggering hypothesis generation for observation #{observation_id}")

    ExecutiveMemory.record_decision(
      "pipeline_hypothesis_#{observation_id}",
      :hypothesis_generation_triggered,
      %{observation_id: observation_id}
    )
  end

  defp trigger_experiment_design(hypothesis_id, _payload) do
    Logger.info("KnowledgeFlowPipeline: Triggering experiment design for hypothesis #{hypothesis_id}")

    workflow_spec = %{
      name: "Experiment for #{hypothesis_id}",
      steps: [
        %{module: Tiannara.CEL.Workflow.Steps.Experiment, input: %{hypothesis_id: hypothesis_id}}
      ]
    }

    WorkflowEngine.start_workflow(workflow_spec)
  end

  defp trigger_validation(experiment_id, _hypothesis_id, _payload) do
    Logger.info("KnowledgeFlowPipeline: Triggering validation for experiment #{experiment_id}")

    workflow_spec = %{
      name: "Validation for #{experiment_id}",
      steps: [
        %{module: Tiannara.CEL.Workflow.Steps.Validation, input: %{experiment_id: experiment_id}}
      ]
    }

    WorkflowEngine.start_workflow(workflow_spec)
  end

  defp promote_to_discovery(hypothesis_id, validation_payload) do
    Logger.info("KnowledgeFlowPipeline: Promoting hypothesis #{hypothesis_id} to discovery")

    discovery_spec = %{
      id: "discovery_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      type: :scientific_entity,
      subtype: :scientific_discovery,
      attributes: %{
        derived_from: hypothesis_id,
        validation_evidence: validation_payload.evidence
      },
      confidence: validation_payload.confidence,
      provenance: %{
        origin: :knowledge_flow_pipeline,
        validation_id: validation_payload.validation_id
      }
    }

    UnifiedWorldModel.create_entity(discovery_spec)
    UnifiedWorldModel.create_relationship(%{
      from_id: discovery_spec.id,
      to_id: hypothesis_id,
      type: :derived_from,
      confidence: 1.0
    })
  end

  defp refute_or_request_new(hypothesis_id, validation_payload) do
    Logger.info("KnowledgeFlowPipeline: Validation failed for #{hypothesis_id}. Requesting refinement.")

    UnifiedWorldModel.update_entity(hypothesis_id, %{
      confidence: max(0.0, (validation_payload.prior_confidence || 0.5) - 0.2),
      status: :needs_refinement
    })
  end
end
