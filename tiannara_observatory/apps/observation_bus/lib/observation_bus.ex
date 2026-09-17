defmodule ObservationBus do
  @moduledoc """
  The Constitutional Observation Bus (COB) — Tiannara's universal event backbone.

  Every constitutional event flows through COB: observable, replayable, routable,
  certifiable, and evolvable by default.

  ## Key properties

    * **Canonical** — every event conforms to `ObservationBus.Event`
    * **Deterministic** — events are globally ordered and replayable
    * **Traceable** — full lineage preserved for every event
    * **Resilient** — backpressure, buffering, and lifecycle management built-in
    * **Observable** — COB exposes its own telemetry for live monitoring
  """

  alias ObservationBus.Event

  @doc """
  Publishes a constitutional event onto the bus.

  Returns `{:ok, event}` on success or `{:error, reason}` on failure.
  """
  @spec publish(Event.t(), keyword()) :: {:ok, Event.t()} | {:error, term()}
  defdelegate publish(event, opts \\ []), to: ObservationBus.Router

  @doc """
  Subscribes a pid to receive events matching the given topic pattern.

  Topics follow the pattern `constitution.<domain>.<action>`.
  Wildcard `:*:` matches any segment.
  """
  @spec subscribe(pid(), String.t(), keyword()) :: :ok
  defdelegate subscribe(pid, topic_pattern, opts \\ []), to: ObservationBus.SubscriptionRegistry

  @doc """
  Unsubscribes a pid from a topic pattern.
  """
  @spec unsubscribe(pid(), String.t()) :: :ok
  defdelegate unsubscribe(pid, topic_pattern), to: ObservationBus.SubscriptionRegistry

  @doc """
  Returns bus health and diagnostics.
  """
  @spec health() :: map()
  defdelegate health(), to: ObservationBus.Health

  @doc """
  Returns COB metrics snapshot.
  """
  @spec metrics() :: list(map())
  def metrics, do: ObservationBus.Telemetry.Metrics.definitions()

  # ── Constitutional Intelligence Layer (CIL) API ──────────────────────

  @doc """
  Returns current constitutional health state.
  """
  @spec health_state() :: map()
  def health_state, do: ObservationBus.CIL.HealthEngine.current_health()

  @doc """
  Returns current risk matrix.
  """
  @spec risk_matrix() :: map()
  def risk_matrix, do: ObservationBus.CIL.RiskAnalyzer.risk_matrix()

  @doc """
  Returns current recommendations.
  """
  @spec recommendations(keyword()) :: [map()]
  def recommendations(filters \\ []), do: ObservationBus.CIL.RecommendationEngine.list_recommendations(filters)

  @doc """
  Returns detected patterns.
  """
  @spec patterns(keyword()) :: [map()]
  def patterns(filters \\ []), do: ObservationBus.CIL.PatternRegistry.list_patterns(filters)

  @doc """
  Returns knowledge syntheses.
  """
  @spec syntheses() :: [map()]
  def syntheses, do: ObservationBus.CIL.KnowledgeSynthesizer.list_syntheses()

  @doc """
  Returns trend data for all metrics.
  """
  @spec trends() :: map()
  def trends, do: ObservationBus.CIL.TrendEngine.all_trends()

  @doc """
  Returns CIL diagnostics report.
  """
  @spec cil_report() :: map()
  def cil_report, do: ObservationBus.CIL.Diagnostics.report()

  # ── Constitutional Predictive Observatory (CPO) API ──────────────────

  @doc """
  Returns forecasts for all tracked metrics.
  """
  @spec forecasts() :: [map()]
  def forecasts, do: ObservationBus.CIL.Prediction.ForecastEngine.forecast_all()

  @doc """
  Returns scenario simulation results.
  """
  @spec scenarios() :: %{atom() => map()}
  def scenarios, do: ObservationBus.CIL.Prediction.ScenarioSimulator.list_scenarios()

  @doc """
  Returns risk projections.
  """
  @spec risk_projections() :: [map()]
  def risk_projections, do: ObservationBus.CIL.Prediction.RiskProjection.project_all()

  @doc """
  Returns capacity plan.
  """
  @spec capacity_plan() :: map()
  def capacity_plan, do: ObservationBus.CIL.Prediction.CapacityPlanner.plan()

  @doc """
  Returns mission forecast dashboard.
  """
  @spec mission_dashboard() :: map()
  def mission_dashboard, do: ObservationBus.CIL.Prediction.MissionForecast.dashboard()

  @doc """
  Returns preparedness report.
  """
  @spec preparedness_report() :: map()
  def preparedness_report, do: ObservationBus.CIL.Prediction.PreparednessEngine.report()

  # ── Constitutional Epistemic Observatory (CEO) API — M12 ────────────

  @doc """
  Returns epistemic knowledge confidence summary.
  """
  @spec epistemic_summary() :: map()
  def epistemic_summary, do: ObservationBus.CIL.Epistemic.KnowledgeConfidenceEngine.summary()

  @doc """
  Returns all epistemic confidence entries.
  """
  @spec epistemic_confidence() :: [map()]
  def epistemic_confidence, do: ObservationBus.CIL.Epistemic.KnowledgeConfidenceEngine.list_all()

  @doc """
  Returns evidence graph stats.
  """
  @spec evidence_graph_stats() :: map()
  def evidence_graph_stats, do: ObservationBus.CIL.Epistemic.EvidenceGraph.stats()

  @doc """
  Returns unknown registry.
  """
  @spec unknowns(atom()) :: [map()]
  def unknowns(type \\ nil), do: ObservationBus.CIL.Epistemic.UnknownRegistry.list(type)

  @doc """
  Returns unknown counts by type.
  """
  @spec unknown_counts() :: map()
  def unknown_counts, do: ObservationBus.CIL.Epistemic.UnknownRegistry.counts()

  @doc """
  Returns contradictions.
  """
  @spec contradictions(atom()) :: [map()]
  def contradictions(type \\ nil), do: ObservationBus.CIL.Epistemic.ContradictionDetector.list(type)

  @doc """
  Returns assumptions, optionally filtered.
  """
  @spec assumptions(keyword()) :: [map()]
  def assumptions(filters \\ []), do: ObservationBus.CIL.Epistemic.AssumptionRegistry.list(filters)

  @doc """
  Returns bias readings.
  """
  @spec bias_readings() :: [map()]
  def bias_readings, do: ObservationBus.CIL.Epistemic.BiasDetector.readings()

  @doc """
  Returns bias index.
  """
  @spec bias_index() :: float()
  def bias_index, do: ObservationBus.CIL.Epistemic.BiasDetector.bias_index()

  # ── Scientific Mission Control (CSMC) API — M13 ─────────────────────

  @doc """
  Returns all missions.
  """
  @spec missions() :: [map()]
  def missions, do: ObservationBus.CIL.Mission.MissionRegistry.list()

  @doc """
  Returns mission scheduler status.
  """
  @spec scheduler_status() :: map()
  def scheduler_status, do: ObservationBus.CIL.Mission.MissionScheduler.status()

  @doc """
  Returns mission analytics.
  """
  @spec mission_analytics() :: map()
  def mission_analytics, do: ObservationBus.CIL.Mission.MissionAnalytics.compute()

  @doc """
  Returns mission portfolio analysis.
  """
  @spec mission_portfolio() :: map()
  def mission_portfolio, do: ObservationBus.CIL.Mission.MissionPortfolio.analyze()

  @doc """
  Returns mission timeline events.
  """
  @spec mission_timeline() :: [map()]
  def mission_timeline, do: ObservationBus.CIL.Mission.MissionTimeline.all_events()

  @doc """
  Returns mission health assessments.
  """
  @spec mission_health(String.t()) :: map() | nil
  def mission_health(mission_id), do: ObservationBus.CIL.Mission.MissionHealth.get_health(mission_id)

  # ── Strategic Intelligence Center (CSIC) API — M14 ───────────────────

  @doc """
  Returns strategic plan for a given horizon.
  """
  @spec strategic_plan(atom()) :: map()
  def strategic_plan(horizon), do: ObservationBus.CIL.Strategy.StrategicPlanner.get_plan(horizon)

  @doc """
  Returns all strategic plans across horizons.
  """
  @spec strategic_plans() :: map()
  def strategic_plans, do: ObservationBus.CIL.Strategy.StrategicPlanner.list_plans()

  @doc """
  Returns all capabilities in the capability graph.
  """
  @spec capabilities() :: map()
  def capabilities, do: ObservationBus.CIL.Strategy.CapabilityGraph.list_capabilities()

  @doc """
  Returns a single capability by id.
  """
  @spec capability(atom()) :: map() | nil
  def capability(id), do: ObservationBus.CIL.Strategy.CapabilityGraph.get_capability(id)

  @doc """
  Returns dependencies for a capability.
  """
  @spec capability_dependencies(atom()) :: [map()]
  def capability_dependencies(id), do: ObservationBus.CIL.Strategy.CapabilityGraph.get_dependencies(id)

  @doc """
  Returns dependents of a capability.
  """
  @spec capability_dependents(atom()) :: [map()]
  def capability_dependents(id), do: ObservationBus.CIL.Strategy.CapabilityGraph.get_dependents(id)

  @doc """
  Returns all technologies on the roadmap.
  """
  @spec technologies() :: map()
  def technologies, do: ObservationBus.CIL.Strategy.TechnologyRoadmap.list_technologies()

  @doc """
  Returns a single technology by id.
  """
  @spec technology(atom()) :: map() | nil
  def technology(id), do: ObservationBus.CIL.Strategy.TechnologyRoadmap.get_technology(id)

  @doc """
  Returns resource allocation plan.
  """
  @spec resource_allocation() :: map()
  def resource_allocation, do: ObservationBus.CIL.Strategy.ResourcePlanner.get_allocation()

  @doc """
  Returns resource optimization snapshot.
  """
  @spec resource_optimization() :: map()
  def resource_optimization, do: ObservationBus.CIL.Strategy.ResourcePlanner.get_optimization()

  @doc """
  Returns all strategic bottlenecks.
  """
  @spec bottlenecks() :: [map()]
  def bottlenecks, do: ObservationBus.CIL.Strategy.BottleneckEngine.list_bottlenecks()

  @doc """
  Returns ranked bottlenecks by category.
  """
  @spec bottleneck_rankings() :: map()
  def bottleneck_rankings, do: ObservationBus.CIL.Strategy.BottleneckEngine.get_ranked()

  @doc """
  Returns opportunity pipeline.
  """
  @spec opportunities() :: [map()]
  def opportunities, do: ObservationBus.CIL.Strategy.OpportunityEngine.list_opportunities()

  @doc """
  Returns opportunity pipeline status.
  """
  @spec opportunity_pipeline() :: map()
  def opportunity_pipeline, do: ObservationBus.CIL.Strategy.OpportunityEngine.get_pipeline()

  @doc """
  Returns strategic risk assessments.
  """
  @spec strategic_risks() :: [map()]
  def strategic_risks, do: ObservationBus.CIL.Strategy.StrategicRisk.list_risks()

  @doc """
  Returns strategic risk summary.
  """
  @spec strategic_risk_summary() :: map()
  def strategic_risk_summary, do: ObservationBus.CIL.Strategy.StrategicRisk.get_summary()

  # ── Civilization Observatory (CCO) API — M15 ─────────────────────────

  @doc """
  Returns civilization state across all dimensions.
  """
  @spec civilization_state() :: map()
  def civilization_state, do: ObservationBus.CIL.Civilization.CivilizationState.get_state()

  @doc """
  Returns technology diffusion data.
  """
  @spec technology_diffusion() :: map()
  def technology_diffusion, do: ObservationBus.CIL.Civilization.TechnologyDiffusion.list_technologies()

  @doc """
  Returns infrastructure state across all sectors.
  """
  @spec infrastructure_state() :: map()
  def infrastructure_state, do: ObservationBus.CIL.Civilization.InfrastructureEvolution.get_infrastructure()

  @doc """
  Returns knowledge economy metrics.
  """
  @spec knowledge_economy() :: map()
  def knowledge_economy, do: ObservationBus.CIL.Civilization.KnowledgeEconomy.get_metrics()

  @doc """
  Returns societal dynamics.
  """
  @spec societal_dynamics() :: map()
  def societal_dynamics, do: ObservationBus.CIL.Civilization.SocietalDynamics.get_dynamics()

  @doc """
  Returns resilience assessment and threats.
  """
  @spec resilience_status() :: map()
  def resilience_status, do: ObservationBus.CIL.Civilization.ResilienceEngine.get_resilience()

  @doc """
  Returns Kardashev status and projections.
  """
  @spec kardashev_status() :: map()
  def kardashev_status, do: ObservationBus.CIL.Civilization.KardashevEngine.get_status()

  @doc """
  Returns Kardashev projections.
  """
  @spec kardashev_projection() :: map()
  def kardashev_projection, do: ObservationBus.CIL.Civilization.KardashevEngine.get_projection()

  # ── Futures Laboratory (CFL) API — M16 ───────────────────────────────

  @doc """
  Returns all generated futures.
  """
  @spec futures() :: [map()]
  def futures, do: ObservationBus.CIL.Futures.FutureGenerator.list_futures()

  @doc """
  Returns all counterfactuals.
  """
  @spec counterfactuals() :: [map()]
  def counterfactuals, do: ObservationBus.CIL.Futures.CounterfactualEngine.list_counterfactuals()

  @doc """
  Returns the future branch tree.
  """
  @spec future_tree() :: map()
  def future_tree, do: ObservationBus.CIL.Futures.BranchExplorer.get_tree()

  @doc """
  Returns counted branches count.
  """
  @spec future_branch_count() :: non_neg_integer()
  def future_branch_count, do: ObservationBus.CIL.Futures.BranchExplorer.get_tree() |> map_size()

  @doc """
  Returns fitness rankings of futures.
  """
  @spec future_rankings() :: list()
  def future_rankings, do: ObservationBus.CIL.Futures.FitnessEvaluator.rankings()

  @doc """
  Compares two futures by id.
  """
  @spec compare_futures(String.t(), String.t()) :: map()
  def compare_futures(a, b), do: ObservationBus.CIL.Futures.FitnessEvaluator.compare(a, b)

  @doc """
  Returns future opportunities.
  """
  @spec future_opportunities() :: [map()]
  def future_opportunities, do: ObservationBus.CIL.Futures.FutureOpportunityEngine.list_opportunities()

  @doc """
  Returns leverage points.
  """
  @spec leverage_points() :: [map()]
  def leverage_points, do: ObservationBus.CIL.Futures.FutureOpportunityEngine.get_leverage_points()

  @doc """
  Returns catastrophic / existential risk assessments.
  """
  @spec catastrophic_risks() :: [map()]
  def catastrophic_risks, do: ObservationBus.CIL.Futures.CatastrophicRiskEngine.list_risks()

  @doc """
  Returns existential risk summary.
  """
  @spec existential_risk_summary() :: map()
  def existential_risk_summary, do: ObservationBus.CIL.Futures.CatastrophicRiskEngine.existential_summary()

  @doc """
  Returns archived simulations.
  """
  @spec future_simulations() :: [map()]
  def future_simulations, do: ObservationBus.CIL.Futures.FutureArchive.list_simulations()

  # ── Meta-Observatory / Self-Governance (CSGOE) API — M17 ────────────

  @doc """
  Returns meta-observatory status and health.
  """
  @spec meta_status() :: map()
  def meta_status, do: ObservationBus.CIL.Meta.MetaObservatory.get_status()

  @doc """
  Returns blind spots detected by the meta-observatory.
  """
  @spec blind_spots() :: [String.t()]
  def blind_spots, do: ObservationBus.CIL.Meta.MetaObservatory.get_blind_spots()

  @doc """
  Returns instrumentation proposals.
  """
  @spec instrumentation_proposals() :: [map()]
  def instrumentation_proposals, do: ObservationBus.CIL.Meta.InstrumentationEvolution.proposals()

  @doc """
  Returns architecture evolution proposals.
  """
  @spec architecture_proposals() :: [map()]
  def architecture_proposals, do: ObservationBus.CIL.Meta.ArchitectureEvolution.proposals()

  @doc """
  Returns governance proposals.
  """
  @spec governance_proposals() :: [map()]
  def governance_proposals, do: ObservationBus.CIL.Meta.ConstitutionalGovernance.get_proposals()

  @doc """
  Returns governance audit log.
  """
  @spec governance_audit_log() :: [map()]
  def governance_audit_log, do: ObservationBus.CIL.Meta.ConstitutionalGovernance.get_audit_log()

  @doc """
  Returns immune system status.
  """
  @spec immune_status() :: map()
  def immune_status, do: ObservationBus.CIL.Meta.ObservatoryImmuneSystem.get_status()

  @doc """
  Returns self-certification scores per subsystem.
  """
  @spec certification_scores() :: map()
  def certification_scores, do: ObservationBus.CIL.Meta.SelfCertification.get_subsystem_scores()

  @doc """
  Returns observatory lineage / version history.
  """
  @spec observatory_lineage() :: map()
  def observatory_lineage, do: ObservationBus.CIL.Meta.ObservatoryLineage.get_lineage()

  # ── Autonomous Operations Center (CAOC) API — M18 ───────────────────

  @doc """
  Returns operational plans.
  """
  @spec ops_plans() :: [map()]
  def ops_plans, do: ObservationBus.CIL.Ops.OperationsPlanner.list_plans()

  @doc """
  Returns execution orchestrator status.
  """
  @spec ops_execution_status() :: map()
  def ops_execution_status, do: ObservationBus.CIL.Ops.ExecutionOrchestrator.status()

  @doc """
  Returns resource allocation.
  """
  @spec ops_resource_allocation() :: map()
  def ops_resource_allocation, do: ObservationBus.CIL.Ops.ResourceCommander.get_allocation()

  @doc """
  Returns pending authorization requests.
  """
  @spec ops_pending_authorizations() :: [map()]
  def ops_pending_authorizations, do: ObservationBus.CIL.Ops.AuthorizationEngine.get_pending()

  @doc """
  Returns safety supervisor status.
  """
  @spec ops_safety_status() :: map()
  def ops_safety_status, do: ObservationBus.CIL.Ops.SafetySupervisor.status()

  @doc """
  Returns recovery commander status.
  """
  @spec ops_recovery_status() :: map()
  def ops_recovery_status, do: ObservationBus.CIL.Ops.RecoveryCommander.status()

  @doc """
  Returns operational replay events.
  """
  @spec ops_replay_events() :: [map()]
  def ops_replay_events, do: ObservationBus.CIL.Ops.OperationalReplay.list_events()

  # ── Distributed Civilization Network (CDSCN) API — M19 ──────────────

  @doc """
  Returns federated observatory nodes.
  """
  @spec federation_nodes() :: [map()]
  def federation_nodes, do: ObservationBus.CIL.Federation.ObservatoryFederation.list_nodes()

  @doc """
  Returns knowledge exchange records.
  """
  @spec federation_exchanges() :: [map()]
  def federation_exchanges, do: ObservationBus.CIL.Federation.KnowledgeExchange.list_exchanges()

  @doc """
  Returns knowledge exchange statistics.
  """
  @spec federation_exchange_stats() :: map()
  def federation_exchange_stats, do: ObservationBus.CIL.Federation.KnowledgeExchange.get_stats()

  @doc """
  Returns consensus proposals.
  """
  @spec federation_consensus_proposals() :: [map()]
  def federation_consensus_proposals, do: ObservationBus.CIL.Federation.ConsensusEngine.list_proposals()

  @doc """
  Returns scientific federation members.
  """
  @spec federation_members() :: [map()]
  def federation_members, do: ObservationBus.CIL.Federation.ScientificFederation.list_members()

  @doc """
  Returns scientific federation stats.
  """
  @spec federation_stats() :: map()
  def federation_stats, do: ObservationBus.CIL.Federation.ScientificFederation.get_stats()

  @doc """
  Returns distributed replay state.
  """
  @spec federation_replay_state() :: map()
  def federation_replay_state, do: ObservationBus.CIL.Federation.DistributedReplay.get_state()

  @doc """
  Returns civilization memory graph stats.
  """
  @spec federation_memory_stats() :: map()
  def federation_memory_stats, do: ObservationBus.CIL.Federation.CivilizationMemory.get_stats()

  @doc """
  Returns trust scores for all nodes.
  """
  @spec federation_trust_scores() :: map()
  def federation_trust_scores, do: ObservationBus.CIL.Federation.TrustPropagation.list_trust_scores()
end
