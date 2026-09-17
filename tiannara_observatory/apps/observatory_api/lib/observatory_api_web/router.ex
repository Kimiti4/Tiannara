defmodule ObservatoryApiWeb.Router do
  use ObservatoryApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", ObservatoryApiWeb do
    pipe_through :api

    # Health / Status
    get "/health", StatusController, :index
    get "/status", StatusController, :index

    # Runtime
    get "/runtime/health", RuntimeController, :health
    get "/runtime/metrics", RuntimeController, :metrics

    # Events
    get "/events", EventsController, :index
    get "/events/:id", EventsController, :show

    # Metrics
    get "/metrics", MetricsController, :counters
    get "/metrics/:name", MetricsController, :show
    get "/metrics/:name/trend", MetricsController, :trend
    get "/metrics/:name/forecast", MetricsController, :forecast
    get "/metrics/query", MetricsController, :query

    # Replay
    get "/replay", ReplayController, :reconstruct
    get "/replay/compare", ReplayController, :compare
    get "/replay/timeline", ReplayController, :timeline
    get "/replay/snapshots", ReplayController, :snapshots
    get "/replay/archaeology", ReplayController, :archaeology
    get "/replay/divergence", ReplayController, :divergence

    # Domain state
    get "/science", ScienceController, :index
    get "/engineering", EngineeringController, :index
    get "/knowledge", KnowledgeController, :index
    get "/planetary", PlanetaryController, :index
    get "/civilization", CivilizationController, :index
    get "/evolution", EvolutionController, :index
    get "/governance", GovernanceController, :index
    get "/certification", CertificationController, :index

    # Constitutional Intelligence Layer (CIL) — M10
    get "/cil/health", CILController, :health
    get "/cil/patterns", CILController, :patterns
    get "/cil/trends", CILController, :trends
    get "/cil/recommendations", CILController, :recommendations
    get "/cil/syntheses", CILController, :syntheses
    get "/cil/risk", CILController, :risk
    get "/cil/causal/:id", CILController, :causal
    get "/cil/report", CILController, :report

    # Constitutional Predictive Observatory (CPO) — M11
    get "/cpo/forecasts", CILController, :forecasts
    get "/cpo/scenarios", CILController, :scenarios
    get "/cpo/risk-projections", CILController, :risk_projections
    get "/cpo/capacity", CILController, :capacity
    get "/cpo/mission-forecasts", CILController, :missions
    get "/cpo/preparedness", CILController, :preparedness

    # Constitutional Epistemic Observatory (CEO) — M12
    get "/epistemic/summary", CILController, :epistemic_summary
    get "/epistemic/confidence", CILController, :epistemic_confidence
    get "/epistemic/evidence", CILController, :evidence_graph
    get "/epistemic/unknowns", CILController, :unknowns
    get "/epistemic/contradictions", CILController, :contradictions
    get "/epistemic/assumptions", CILController, :assumptions
    get "/epistemic/bias", CILController, :bias

    # Scientific Mission Control (CSMC) — M13
    get "/mission/missions", CILController, :mission_list
    get "/mission/scheduler", CILController, :mission_scheduler
    get "/mission/analytics", CILController, :mission_analytics
    get "/mission/portfolio", CILController, :mission_portfolio
    get "/mission/timeline", CILController, :mission_timeline
    get "/mission/health/:id", CILController, :mission_health

    # Strategic Intelligence Center (CSIC) — M14
    get "/strategy/plans", CILController, :strategy_plans
    get "/strategy/plans/:horizon", CILController, :strategy_plan
    get "/strategy/capabilities", CILController, :capabilities
    get "/strategy/capabilities/:id", CILController, :capability
    get "/strategy/capabilities/:id/dependencies", CILController, :capability_dependencies
    get "/strategy/technologies", CILController, :technologies
    get "/strategy/resources", CILController, :resource_allocation
    get "/strategy/resources/optimization", CILController, :resource_optimization
    get "/strategy/bottlenecks", CILController, :bottlenecks
    get "/strategy/opportunities", CILController, :opportunities
    get "/strategy/risks", CILController, :strategic_risks

    # Civilization Observatory (CCO) — M15
    get "/civilization/state", CILController, :civilization_state
    get "/civilization/diffusion", CILController, :technology_diffusion
    get "/civilization/infrastructure", CILController, :infrastructure_state
    get "/civilization/economy", CILController, :knowledge_economy
    get "/civilization/society", CILController, :societal_dynamics
    get "/civilization/resilience", CILController, :resilience_status
    get "/civilization/kardashev", CILController, :kardashev_status

    # Futures Laboratory (CFL) — M16
    get "/futures/list", CILController, :futures_list
    get "/futures/counterfactuals", CILController, :counterfactuals
    get "/futures/tree", CILController, :future_tree
    get "/futures/rankings", CILController, :future_rankings
    get "/futures/compare", CILController, :future_compare
    get "/futures/opportunities", CILController, :future_opportunities
    get "/futures/existential-risks", CILController, :existential_risks
    get "/futures/simulations", CILController, :future_simulations

    # Meta-Governance (CSGOE) — M17
    get "/meta/status", CILController, :meta_status
    get "/meta/blind-spots", CILController, :meta_blind_spots
    get "/meta/instrumentation", CILController, :meta_instrumentation
    get "/meta/architecture", CILController, :meta_architecture
    get "/meta/governance", CILController, :meta_governance
    get "/meta/immune", CILController, :meta_immune
    get "/meta/certification", CILController, :meta_certification
    get "/meta/lineage", CILController, :meta_lineage

    # Autonomous Operations Center (CAOC) — M18
    get "/ops/plans", CILController, :ops_plans
    get "/ops/execution", CILController, :ops_execution
    get "/ops/resources", CILController, :ops_resources
    get "/ops/authorizations", CILController, :ops_authorizations
    get "/ops/safety", CILController, :ops_safety
    get "/ops/recovery", CILController, :ops_recovery
    get "/ops/replay", CILController, :ops_replay

    # Distributed Scientific Civilization Network (CDSCN) — M19
    get "/federation/nodes", CILController, :federation_nodes
    get "/federation/exchanges", CILController, :federation_exchanges
    get "/federation/consensus", CILController, :federation_consensus
    get "/federation/members", CILController, :federation_members
    get "/federation/replay", CILController, :federation_replay
    get "/federation/memory", CILController, :federation_memory
    get "/federation/trust", CILController, :federation_trust

    # COA sidebar sections
    get "/discovery", StatusController, :section_discovery
    get "/worlds", StatusController, :section_worlds
    get "/observatories", StatusController, :section_observatories
    get "/agents", StatusController, :section_agents
    get "/services", StatusController, :section_services
    get "/monitoring", StatusController, :section_monitoring
    get "/logs", StatusController, :section_logs
    get "/security", StatusController, :section_security
    get "/cluster", StatusController, :section_cluster
    get "/storage", StatusController, :section_storage
    get "/performance", StatusController, :section_performance

    # Resources — COA dashboard
    get "/resources", StatusController, :resources
    get "/experiments", StatusController, :experiments


    # Runtime actions — COA dashboard
    get "/runtime/status", RuntimeController, :status
    get "/runtime/boot", RuntimeController, :boot
    post "/runtime/start_all", RuntimeController, :start_all
    post "/runtime/stop_all", RuntimeController, :stop_all
    post "/runtime/restart", RuntimeController, :restart
    post "/runtime/safe_mode", RuntimeController, :safe_mode

    # CRAV operations
    get "/crav/soak_test/status", StatusController, :soak_status
    post "/crav/soak_test/start", StatusController, :soak_start
    post "/crav/soak_test/stop", StatusController, :soak_stop
    post "/crav/alpha_launch/preflight", StatusController, :alpha_preflight
    post "/crav/alpha_launch/launch", StatusController, :alpha_launch
    post "/crav/alpha_launch/abort", StatusController, :alpha_abort
    post "/crav/atlas/generate", StatusController, :atlas_generate

    # Campaign pipeline trigger
    post "/crav/campaign/trigger", StatusController, :campaign_trigger

    # Feedback loop + ASC health
    get "/feedback/loop", StatusController, :feedback_loop
    get "/asc/status", StatusController, :asc_status
    get "/campaign/phases", StatusController, :campaign_phases
    get "/bridge/status", StatusController, :bridge_status

    # Civilizational Intelligence panels — bridge-proxied, not M15
    get "/civilizational/state", StatusController, :civ_state
    get "/civilizational/risk", StatusController, :civ_risk
    get "/civilizational/sustainability", StatusController, :civ_sustainability

    # Campaign Pipeline Telemetry
    get "/campaign/telemetry", StatusController, :campaign_telemetry

    # Constitutional challenges
    post "/challenges/run", StatusController, :challenges_run

    # AI Interaction
    post "/interaction", StatusController, :interaction
  end

  # Backward-compatible CRAV + Challenges routes at /api/...
  scope "/api", ObservatoryApiWeb do
    pipe_through :api
    get "/crav/soak_test/status", StatusController, :soak_status
    post "/crav/soak_test/start", StatusController, :soak_start
    post "/crav/soak_test/stop", StatusController, :soak_stop
    post "/crav/alpha_launch/preflight", StatusController, :alpha_preflight
    post "/crav/alpha_launch/launch", StatusController, :alpha_launch
    post "/crav/alpha_launch/abort", StatusController, :alpha_abort
    post "/crav/atlas/generate", StatusController, :atlas_generate
    post "/challenges/run", StatusController, :challenges_run
  end

  if Application.compile_env(:observatory_api, :dev_routes) do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
