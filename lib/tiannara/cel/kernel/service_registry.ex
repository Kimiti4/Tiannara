defmodule Tiannara.CEL.Kernel.ServiceRegistry do
  use GenServer
  require Logger

  @type service_id :: atom()
  @type criticality :: :critical | :high | :medium | :low

  @type service_spec :: %{
          id: service_id(),
          module: module(),
          version: String.t(),
          criticality: criticality(),
          depends_on: [service_id()],
          provides: [atom()],
          requires: [atom()],
          health_check: {module(), atom(), list()},
          constitutional_score_check: {module(), atom(), list()},
          boot_timeout: non_neg_integer(),
          deprecated: boolean()
        }

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def all, do: GenServer.call(__MODULE__, :all)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})
  def register(spec), do: GenServer.call(__MODULE__, {:register, spec})
  def deprecate(id), do: GenServer.call(__MODULE__, {:deprecate, id})
  def replace(old_id, new_spec), do: GenServer.call(__MODULE__, {:replace, old_id, new_spec})
  def boot_order, do: GenServer.call(__MODULE__, :boot_order)
  def discover, do: GenServer.call(__MODULE__, :discover)

  @impl true
  def init(_opts) do
    services = Map.new(canonical_services(), &{&1.id, &1})
    Logger.info("ServiceRegistry: initialized with #{map_size(services)} services")
    {:ok, %{services: services}}
  end

  @impl true
  def handle_call(:all, _from, state), do: {:reply, Map.values(state.services), state}

  @impl true
  def handle_call({:get, id}, _from, state) do
    case Map.fetch(state.services, id) do
      {:ok, spec} -> {:reply, {:ok, spec}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:register, spec}, _from, state) do
    if Map.has_key?(state.services, spec.id) do
      {:reply, {:error, :already_registered}, state}
    else
      Logger.info("ServiceRegistry: registered #{spec.id} v#{spec.version}")
      {:reply, :ok, put_in(state, [:services, spec.id], spec)}
    end
  end

  @impl true
  def handle_call({:deprecate, id}, _from, state) do
    if Map.has_key?(state.services, id) do
      {:reply, :ok, put_in(state, [:services, id, :deprecated], true)}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:replace, old_id, new_spec}, _from, state) do
    state = state
      |> put_in([:services, old_id, :deprecated], true)
      |> put_in([:services, new_spec.id], new_spec)
    Logger.info("ServiceRegistry: replaced #{old_id} with #{new_spec.id}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:boot_order, _from, state) do
    order =
      state.services
      |> Map.values()
      |> Enum.reject(& &1.deprecated)
      |> topological_sort()
    {:reply, order, state}
  end

  @impl true
  def handle_call(:discover, _from, state) do
    active = state.services |> Map.values() |> Enum.reject(& &1.deprecated)
    {:reply, active, state}
  end

  defp canonical_services do
    [
      # --- Tier 0: No dependencies (boot first) ---
      %{id: :executive_memory, module: Tiannara.CEL.Services.ExecutiveMemory, version: "2.0.0",
        criticality: :critical, depends_on: [],
        provides: [:persistent_memory, :decision_history, :institutional_knowledge,
                   :lesson_retrieval, :event_sourcing, :snapshot_recovery], requires: [],
        health_check: {Tiannara.CEL.Services.ExecutiveMemory, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ExecutiveMemory, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :event_store, module: Tiannara.CEL.Services.EventStore, version: "2.0.0",
        criticality: :critical, depends_on: [],
        provides: [:durable_persistence, :replay, :offset_tracking], requires: [],
        health_check: {Tiannara.CEL.Services.EventStore, :healthy?, []},
        constitutional_score_check: {Tiannara.CEL.Services.EventStore, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Tier 1: Depends only on Tier 0 ---
      %{id: :executive_service_bus, module: Tiannara.CEL.Services.EventBus, version: "2.0.0",
        criticality: :critical, depends_on: [:event_store],
        provides: [:event_transport, :command_routing, :observation_broadcast,
                   :durable_delivery, :replay, :dead_letter_handling], requires: [:durable_persistence],
        health_check: {Tiannara.CEL.Services.EventBus, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.EventBus, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :constitutional_score_pipeline, module: Tiannara.CEL.Services.ConstitutionalScorePipeline, version: "1.0.0",
        criticality: :high, depends_on: [:executive_service_bus],
        provides: [:evidence_scoring, :constitutional_analytics], requires: [:event_transport],
        health_check: {Tiannara.CEL.Services.ConstitutionalScorePipeline, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ConstitutionalScorePipeline, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Tier 2: Core executive services ---
      %{id: :capability_graph, module: Tiannara.CEL.Services.CapabilityGraph, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:capability_discovery, :intelligent_delegation, :workload_balancing,
                   :dependency_analysis], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.CEL.Services.CapabilityGraph, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.CapabilityGraph, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :resource_manager, module: Tiannara.CEL.Services.ResourceManager, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory],
        provides: [:resource_allocation, :sustainability_enforcement], requires: [:persistent_memory],
        health_check: {Tiannara.CEL.Services.ResourceManager, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ResourceManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :identity_trust_manager, module: Tiannara.CEL.Services.IdentityTrustManager, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory],
        provides: [:service_identity, :authentication, :authorization, :trust_scoring], requires: [:persistent_memory],
        health_check: {Tiannara.CEL.Services.IdentityTrustManager, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.IdentityTrustManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :priority_engine, module: Tiannara.CEL.Services.PriorityEngine, version: "2.0.0",
        criticality: :critical, depends_on: [:executive_memory],
        provides: [:global_prioritization, :evidence_weighting, :mission_alignment,
                   :adaptive_learning, :uncertainty_quantification], requires: [:persistent_memory],
        health_check: {Tiannara.CEL.Services.PriorityEngine, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.PriorityEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :executive_scheduler, module: Tiannara.CEL.Services.ExecutiveScheduler, version: "1.0.0",
        criticality: :critical, depends_on: [:priority_engine, :resource_manager, :capability_graph],
        provides: [:mission_scheduling, :fairness_enforcement, :preemption,
                   :admission_control, :concurrency_management], requires: [:global_prioritization, :resource_allocation, :capability_discovery],
        health_check: {Tiannara.CEL.Services.ExecutiveScheduler, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ExecutiveScheduler, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :executive_metrics, module: Tiannara.CEL.Services.ExecutiveMetrics, version: "1.0.0",
        criticality: :high, depends_on: [:executive_service_bus, :executive_memory],
        provides: [:kpi_aggregation, :trend_analysis, :constitutional_compliance_tracking],
        requires: [:event_transport, :persistent_memory],
        health_check: {Tiannara.CEL.Services.ExecutiveMetrics, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ExecutiveMetrics, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :runtime_policy_engine, module: Tiannara.CEL.Services.RuntimePolicyEngine, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory],
        provides: [:dynamic_policy_management, :operational_constraint_evaluation], requires: [:persistent_memory],
        health_check: {Tiannara.CEL.Services.RuntimePolicyEngine, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.RuntimePolicyEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Tier 3: World layer (runtime soft-deps to break cycle) ---
      %{id: :unified_reality_graph, module: Tiannara.World.UnifiedRealityGraph, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:entity_management, :relationship_tracking, :causal_reasoning,
                   :temporal_queries, :uncertainty_propagation], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.World.UnifiedRealityGraph, :health, []},
        constitutional_score_check: {Tiannara.World.UnifiedRealityGraph, :constitutional_score, []},
        boot_timeout: 10_000, deprecated: false},

      %{id: :world_mutation_engine, module: Tiannara.World.WorldMutationEngine, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:atomic_mutations, :rollback_support, :constitutional_gating], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.World.WorldMutationEngine, :health, []},
        constitutional_score_check: {Tiannara.World.WorldMutationEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :provenance_engine, module: Tiannara.World.ProvenanceEngine, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:lineage_tracking, :evidence_management, :confidence_propagation], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.World.ProvenanceEngine, :health, []},
        constitutional_score_check: {Tiannara.World.ProvenanceEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :unified_world_model, module: Tiannara.World.UnifiedWorldModel, version: "1.0.0",
        criticality: :critical, depends_on: [:unified_reality_graph, :world_mutation_engine, :provenance_engine],
        provides: [:canonical_world_representation, :typed_entity_management], requires: [:entity_management, :atomic_mutations, :lineage_tracking],
        health_check: {Tiannara.World.UnifiedWorldModel, :health, []},
        constitutional_score_check: {Tiannara.World.UnifiedWorldModel, :constitutional_score, []},
        boot_timeout: 10_000, deprecated: false},

      %{id: :version_manager, module: Tiannara.World.VersionManager, version: "1.0.0",
        criticality: :high, depends_on: [:unified_world_model, :executive_memory],
        provides: [:immutable_versioning, :historical_retrieval, :version_comparison,
                   :branching, :merging, :rollback], requires: [:canonical_world_representation, :persistent_memory],
        health_check: {Tiannara.World.VersionManager, :health, []},
        constitutional_score_check: {Tiannara.World.VersionManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :ontology_manager, module: Tiannara.World.OntologyManager, version: "1.0.0",
        criticality: :high, depends_on: [:unified_world_model, :executive_memory],
        provides: [:concept_definition, :concept_merging, :concept_splitting,
                   :concept_retirement, :cross_domain_mapping], requires: [:canonical_world_representation, :persistent_memory],
        health_check: {Tiannara.World.OntologyManager, :health, []},
        constitutional_score_check: {Tiannara.World.OntologyManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :snapshot_manager, module: Tiannara.World.SnapshotManager, version: "1.0.0",
        criticality: :high, depends_on: [:unified_world_model, :executive_memory],
        provides: [:state_checkpointing, :incremental_snapshots, :state_recovery], requires: [:canonical_world_representation, :persistent_memory],
        health_check: {Tiannara.World.SnapshotManager, :health, []},
        constitutional_score_check: {Tiannara.World.SnapshotManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :replay_engine, module: Tiannara.World.ReplayEngine, version: "1.0.0",
        criticality: :medium, depends_on: [:world_mutation_engine, :snapshot_manager],
        provides: [:deterministic_replay, :sandboxed_execution, :state_recovery], requires: [:atomic_mutations, :state_checkpointing],
        health_check: {Tiannara.World.ReplayEngine, :health, []},
        constitutional_score_check: {Tiannara.World.ReplayEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Tier 4: Knowledge & Conflict (runtime soft-deps break the cycle) ---
      %{id: :conflict_resolution_engine, module: Tiannara.World.ConflictResolutionEngine, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:explicit_disagreement_modeling, :structured_resolution_workflows],
        requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.World.ConflictResolutionEngine, :health, []},
        constitutional_score_check: {Tiannara.World.ConflictResolutionEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :conflict_detector, module: Tiannara.World.ConflictDetector, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:logical_contradiction_detection, :duplicate_detection,
                   :ontology_violation_detection], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.World.ConflictDetector, :health, []},
        constitutional_score_check: {Tiannara.World.ConflictDetector, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :knowledge_coordinator, module: Tiannara.World.KnowledgeCoordinator, version: "1.0.0",
        criticality: :critical, depends_on: [:unified_world_model, :executive_memory, :executive_service_bus],
        provides: [:discovery_ingestion, :evidence_fusion, :knowledge_validation,
                   :principle_extraction, :memory_promotion_orchestration],
        requires: [:canonical_world_representation, :persistent_memory, :event_transport],
        health_check: {Tiannara.World.KnowledgeCoordinator, :health, []},
        constitutional_score_check: {Tiannara.World.KnowledgeCoordinator, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :knowledge_flow_engine, module: Tiannara.World.KnowledgeFlowEngine, version: "1.0.0",
        criticality: :high, depends_on: [:unified_world_model, :executive_service_bus],
        provides: [:cross_domain_propagation, :semantic_translation,
                   :stagnation_prevention], requires: [:canonical_world_representation, :event_transport],
        health_check: {Tiannara.World.KnowledgeFlowEngine, :health, []},
        constitutional_score_check: {Tiannara.World.KnowledgeFlowEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :epistemic_integrity_service, module: Tiannara.World.EpistemicIntegrityService, version: "1.0.0",
        criticality: :high, depends_on: [:unified_world_model, :executive_service_bus],
        provides: [:contradiction_rate_monitoring, :epistemic_drift_detection,
                   :evidence_quality_measurement, :experiment_recommendation],
        requires: [:canonical_world_representation, :event_transport],
        health_check: {Tiannara.World.EpistemicIntegrityService, :health, []},
        constitutional_score_check: {Tiannara.World.EpistemicIntegrityService, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Tier 5: Phase 4 design specs (not yet validated) ---
      %{id: :autonomous_research_engine, module: Tiannara.Phase4.AutonomousResearchEngine, version: "0.1.0",
        criticality: :medium, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:autonomous_hypothesis_generation, :experiment_dispatch],
        requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.Phase4.AutonomousResearchEngine, :health, []},
        constitutional_score_check: {Tiannara.Phase4.AutonomousResearchEngine, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :experiment_orchestrator, module: Tiannara.Phase4.ExperimentOrchestrator, version: "0.1.0",
        criticality: :medium, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:experimental_design_generation, :resource_estimation,
                   :execution_environment_selection], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.Phase4.ExperimentOrchestrator, :health, []},
        constitutional_score_check: {Tiannara.Phase4.ExperimentOrchestrator, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Discovery subsystem (Phase 4.1) ---
      %{id: :discovery_supervisor, module: Tiannara.Discovery.DiscoverySupervisor, version: "1.0.0",
        criticality: :medium, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:discovery_orchestration, :hypothesis_generation, :gap_analysis,
                   :contradiction_analysis, :experiment_planning, :discovery_lineage],
        requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.Discovery.DiscoverySupervisor, :health, []},
        constitutional_score_check: {Tiannara.Discovery.DiscoverySupervisor, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      # --- Existing services (unchanged from original where possible) ---
      %{id: :mission_director, module: Tiannara.CEL.Services.MissionDirector, version: "2.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:scientific_lifecycle_orchestration, :validation_gating, :impact_assessment,
                   :workflow_delegation], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.CEL.Services.MissionDirector, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.MissionDirector, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :workflow_engine, module: Tiannara.CEL.Services.WorkflowEngine, version: "1.0.0",
        criticality: :critical, depends_on: [:executive_memory, :executive_service_bus, :capability_graph,
                                             :resource_manager],
        provides: [:scientific_workflow_orchestration, :saga_compensation,
                   :checkpoint_resumability], requires: [:persistent_memory, :event_transport,
                   :capability_discovery, :resource_allocation],
        health_check: {Tiannara.CEL.Services.WorkflowEngine, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.WorkflowEngine, :constitutional_score, []},
        boot_timeout: 10_000, deprecated: false},

      %{id: :executive_state_manager, module: Tiannara.CEL.Services.ExecutiveStateManager, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory, :executive_service_bus],
        provides: [:state_aggregation, :system_observability], requires: [:persistent_memory, :event_transport],
        health_check: {Tiannara.CEL.Services.ExecutiveStateManager, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ExecutiveStateManager, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :decision_predictor, module: Tiannara.CEL.Services.DecisionPredictor, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory, :capability_graph, :resource_manager],
        provides: [:outcome_forecasting, :bottleneck_prediction, :risk_assessment], requires: [],
        health_check: {Tiannara.CEL.Services.DecisionPredictor, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.DecisionPredictor, :constitutional_score, []},
        boot_timeout: 5_000, deprecated: false},

      %{id: :executive_digital_twin, module: Tiannara.CEL.Services.ExecutiveDigitalTwin, version: "1.0.0",
        criticality: :high, depends_on: [:executive_memory, :capability_graph, :resource_manager, :executive_scheduler],
        provides: [:mission_simulation, :what_if_analysis, :council_advisory], requires: [],
        health_check: {Tiannara.CEL.Services.ExecutiveDigitalTwin, :health, []},
        constitutional_score_check: {Tiannara.CEL.Services.ExecutiveDigitalTwin, :constitutional_score, []},
        boot_timeout: 10_000, deprecated: false}
    ]
  end

  defp topological_sort(specs) do
    ids = Enum.map(specs, & &1.id)
    dep_map = Map.new(specs, &{&1.id, &1.depends_on})
    spec_map = Map.new(specs, &{&1.id, &1})
    do_sort(ids, dep_map, spec_map, [])
  end

  defp do_sort([], _deps, _specs, acc), do: Enum.reverse(acc)
  defp do_sort(remaining, deps, specs, acc) do
    case Enum.find(remaining, fn id -> Map.get(deps, id, []) == [] end) do
      nil ->
        Logger.error("ServiceRegistry: dependency cycle among #{inspect(remaining)}")
        Enum.reverse(acc)
      ready_id ->
        new_remaining = List.delete(remaining, ready_id)
        new_deps = Map.new(deps, fn {k, v} -> {k, List.delete(v, ready_id)} end)
        do_sort(new_remaining, new_deps, specs, [Map.fetch!(specs, ready_id) | acc])
    end
  end
end
