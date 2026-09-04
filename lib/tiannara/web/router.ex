defmodule TiannaraWeb.Router do
  @moduledoc """
  Defines web routes for the Interactive REA Research Workbench.
  """
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TiannaraWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api/v1", TiannaraWeb do
    pipe_through(:api)

    get("/health", CRAVChallengeController, :health)
    get("/status", CRAVChallengeController, :status)
    get("/runtime/status", CRAVChallengeController, :runtime_status)
    get("/runtime/boot", CRAVChallengeController, :boot_status)
    get("/runtime/snapshot", CRAVChallengeController, :runtime_snapshot)
    get("/discovery/snapshot", CRAVChallengeController, :discovery_snapshot)
    get("/discovery/pipeline", CRAVChallengeController, :pipeline_snapshot)
    get("/discovery/stall", CRAVChallengeController, :first_stall)
    post("/discovery/seed", CRAVChallengeController, :seed_battery)
    post("/interaction", CRAVChallengeController, :interaction)
    post("/crav/alpha_launch/preflight", CRAVChallengeController, :alpha_preflight)
    get("/civilizational/state", CRAVChallengeController, :civilization_state)
    get("/civilizational/risk", CRAVChallengeController, :civilization_risk)
    get("/civilizational/sustainability", CRAVChallengeController, :civilization_sustainability)
    get("/campaign/telemetry", CRAVChallengeController, :campaign_telemetry)
    get("/reality/physical", CRAVChallengeController, :physical_deployments)
    get("/reality/physical/:id", CRAVChallengeController, :physical_deployment)
    get("/reality/physical/:id/adapter", CRAVChallengeController, :physical_adapter_info)
    post("/reality/physical", CRAVChallengeController, :physical_plan)
    post("/reality/physical/:id/advance", CRAVChallengeController, :physical_advance)
    post("/reality/physical/:id/approve", CRAVChallengeController, :physical_approve)
    post("/reality/physical/:id/abort", CRAVChallengeController, :physical_abort)
  end

  scope "/api", TiannaraWeb do
    pipe_through(:api)

    get("/census", CRAVChallengeController, :census)
    get("/activation", CRAVChallengeController, :activation)
    get("/dead_code", CRAVChallengeController, :dead_code)
    get("/dependency_graph", CRAVChallengeController, :dependency_graph)
    get("/participation", CRAVChallengeController, :participation)
    get("/event_bus", CRAVChallengeController, :event_bus)
    get("/observatory_coverage", CRAVChallengeController, :observatory_coverage)
    get("/discovery_chain", CRAVChallengeController, :discovery_chain)
    get("/communication", CRAVChallengeController, :communication)
    get("/supervisor_integrity", CRAVChallengeController, :supervisor_integrity)
    get("/knowledge_flow", CRAVChallengeController, :knowledge_flow)
    get("/autonomous", CRAVChallengeController, :autonomous)
    get("/compliance", CRAVChallengeController, :compliance)
    get("/heatmap", CRAVChallengeController, :heatmap)
    get("/launch_readiness", CRAVChallengeController, :launch_readiness)
    post("/challenges/run", CRAVChallengeController, :run_challenges)
    get("/observatory/status", CRAVChallengeController, :status)
    get("/observatory/metrics", CRAVChallengeController, :metrics)
    get("/runtime/status", CRAVChallengeController, :runtime_status)
    get("/runtime/boot", CRAVChallengeController, :boot_status)
    get("/health", CRAVChallengeController, :health)
    post("/crav/soak_test/start", CRAVChallengeController, :soak_test_start)
    post("/crav/soak_test/stop", CRAVChallengeController, :soak_test_stop)
    get("/crav/soak_test/status", CRAVChallengeController, :soak_test_status)
    post("/crav/atlas/generate", CRAVChallengeController, :atlas_generate)
    get("/crav/atlas", CRAVChallengeController, :atlas)
    post("/crav/alpha_launch/launch", CRAVChallengeController, :alpha_launch)
    post("/crav/alpha_launch/abort", CRAVChallengeController, :alpha_abort)
    post("/crav/alpha_launch/preflight", CRAVChallengeController, :alpha_preflight)
    get("/crav/alpha_launch/status", CRAVChallengeController, :alpha_status)
    get("/crav/phase_omega/status", CRAVChallengeController, :phase_omega_status)
    post("/crav/campaign/trigger", CRAVChallengeController, :campaign_trigger)
  end

  scope "/", TiannaraWeb do
    pipe_through(:browser)

    # Interactive REA Research Workbench Routes
    live("/", MissionControlLive, :index)
    live("/mission-control", MissionControlLive, :index)
    live("/discoveries", DiscoveriesLive, :index)
    live("/laws", LawsLive, :index)
    live("/theories", TheoriesLive, :index)
    live("/unknowns", UnknownsLive, :index)
    live("/interventions", InterventionsLive, :index)
    live("/portfolio", PortfolioLive, :index)
    live("/worlds", WorldsLive, :index)
    live("/constitutions", ConstitutionsLive, :index)
    live("/programs", ProgramsLive, :index)
    live("/research-map", ResearchMapLive, :index)
    live("/domains", DomainsLive, :index)
    live("/domain/:name", DomainDetailLive, :index)
    live("/civilization-atlas", CivilizationAtlasLive, :index)
    live("/civilization-atlas/knowledge-flow", CivilizationAtlasLive, :knowledge_flow)
    live("/orbit-atlas", OrbitAtlasLive, :index)
    live("/orbit-navigation", OrbitNavigationLive, :index)
    live("/orbit-genesis", OrbitGenesisLive, :index)
    live("/orbit-memory", OrbitMemoryLive, :index)
    live("/orbit-ecology", OrbitEcologyLive, :index)
    live("/orbit-selection", OrbitSelectionLive, :index)
    live("/orbit-meta-memory", MetaMemoryLive, :index)
    live("/orbit-theories", TheoryEcologyLive, :index)
    live("/orbit-theory-selection", TheorySelectionLive, :index)
    live("/orbit-meta-theory", MetaTheoryLive, :index)
    live("/orbit-portfolio-dynamics", PortfolioDynamicsLive, :index)
    live("/orbit-unified-immune", UnifiedImmuneLive, :index)
    live("/orbit-civilization-dynamics", CivilizationDynamicsLive, :index)
  end
end
