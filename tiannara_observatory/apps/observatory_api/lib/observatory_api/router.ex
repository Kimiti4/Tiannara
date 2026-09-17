defmodule ObservatoryApi.Router do
  use ObservatoryApi, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug ObservatoryApi.Plugs.Auth
    plug ObservatoryApi.Plugs.RateLimit
    plug ObservatoryApi.Plugs.AuditLog
  end

  pipeline :public do
    plug :accepts, ["json"]
  end

  scope "/api/v1", ObservatoryApi.Controllers do
    pipe_through :public

    get "/health", StatusController, :health
    get "/status", StatusController, :status
  end

  scope "/api/v1", ObservatoryApi.Controllers do
    pipe_through :api

    get "/runtime/health", RuntimeController, :health
    get "/runtime/metrics", RuntimeController, :metrics

    get "/science/discoveries", ScienceController, :discoveries
    get "/science/experiments", ScienceController, :experiments

    get "/engineering/designs", EngineeringController, :designs
    get "/engineering/trl", EngineeringController, :trl

    get "/discovery/stream", DiscoveryController, :stream

    get "/planet/state", PlanetController, :state
    get "/planet/metrics", PlanetController, :metrics

    get "/civilization/indices", CivilizationController, :indices

    get "/replay", ReplayController, :replay
    get "/replay/snapshots", ReplayController, :snapshots
    get "/replay/timeline", ReplayController, :timeline

    get "/certification/status", CertificationController, :status
    get "/certification/chain", CertificationController, :chain

    # Phase Ω — Runtime Activation Status
    get "/phase-omega/scan", StatusController, :phase_omega
    get "/phase-omega/snapshot", StatusController, :phase_omega_snapshot

    get "/metrics", MetricsController, :index
    get "/metrics/:name", MetricsController, :show

    get "/events", EventsController, :index
    get "/events/:id", EventsController, :show
  end
end
