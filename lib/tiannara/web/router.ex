defmodule TiannaraWeb.Router do
  @moduledoc """
  Defines web routes for the Interactive REA Research Workbench.
  """
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TiannaraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TiannaraWeb do
    pipe_through :browser

    # Interactive REA Research Workbench Routes
    live "/", MissionControlLive, :index
    live "/mission-control", MissionControlLive, :index
    live "/discoveries", DiscoveriesLive, :index
    live "/laws", LawsLive, :index
    live "/theories", TheoriesLive, :index
    live "/unknowns", UnknownsLive, :index
    live "/interventions", InterventionsLive, :index
    live "/portfolio", PortfolioLive, :index
    live "/worlds", WorldsLive, :index
    live "/constitutions", ConstitutionsLive, :index
    live "/programs", ProgramsLive, :index
    live "/research-map", ResearchMapLive, :index
    live "/domains", DomainsLive, :index
    live "/domain/:name", DomainDetailLive, :index
    live "/civilization-atlas", CivilizationAtlasLive, :index
    live "/civilization-atlas/knowledge-flow", CivilizationAtlasLive, :knowledge_flow
    live "/orbit-atlas", OrbitAtlasLive, :index
    live "/orbit-navigation", OrbitNavigationLive, :index
    live "/orbit-genesis", OrbitGenesisLive, :index
    live "/orbit-memory", OrbitMemoryLive, :index
    live "/orbit-ecology", OrbitEcologyLive, :index
    live "/orbit-selection", OrbitSelectionLive, :index
    live "/orbit-meta-memory", MetaMemoryLive, :index
    live "/orbit-theories", TheoryEcologyLive, :index
    live "/orbit-theory-selection", TheorySelectionLive, :index
    live "/orbit-meta-theory", MetaTheoryLive, :index
    live "/orbit-portfolio-dynamics", PortfolioDynamicsLive, :index
    live "/orbit-unified-immune", UnifiedImmuneLive, :index
    live "/orbit-civilization-dynamics", CivilizationDynamicsLive, :index
  end
end
