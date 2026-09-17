defmodule TiannaraRuntimeWeb.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1" do
    pipe_through :api

    # Health
    get "/health", TiannaraRuntimeWeb.ObservatoryController, :health

    # System status
    get "/system/status", TiannaraRuntimeWeb.ObservatoryController, :system_status

    # Observatory
    get "/observatory/metrics", TiannaraRuntimeWeb.ObservatoryController, :metrics
    get "/observatory/metrics/:category", TiannaraRuntimeWeb.ObservatoryController, :metrics_category
    get "/observatory/screens/:id", TiannaraRuntimeWeb.ObservatoryController, :screen
    get "/observatory/artifacts", TiannaraRuntimeWeb.ObservatoryController, :artifacts
    get "/observatory/timeline", TiannaraRuntimeWeb.ObservatoryController, :timeline
    get "/observatory/status", TiannaraRuntimeWeb.ObservatoryController, :status
    get "/observatory/discoveries", TiannaraRuntimeWeb.ObservatoryController, :discoveries
    get "/observatory/discoveries/:id", TiannaraRuntimeWeb.ObservatoryController, :discovery_detail
    post "/observatory/discoveries/analyze", TiannaraRuntimeWeb.ObservatoryController, :analyze_discovery
    get "/observatory/notifications", TiannaraRuntimeWeb.ObservatoryController, :notifications
    get "/observatory/worlds", TiannaraRuntimeWeb.ObservatoryController, :worlds
    post "/observatory/worlds/:id/intervene", TiannaraRuntimeWeb.ObservatoryController, :intervene_world
    get "/observatory/reports", TiannaraRuntimeWeb.ObservatoryController, :reports
    post "/observatory/reports/generate", TiannaraRuntimeWeb.ObservatoryController, :generate_report

    # Engines
    get "/engines", TiannaraRuntimeWeb.ObservatoryController, :engines
    get "/engines/:name", TiannaraRuntimeWeb.ObservatoryController, :engine_detail
    post "/engines/:id/test", TiannaraRuntimeWeb.ObservatoryController, :test_engine

    # Orchestration
    get "/orchestration/flows", TiannaraRuntimeWeb.ObservatoryController, :flows
    post "/orchestration/flows", TiannaraRuntimeWeb.ObservatoryController, :create_flow
    delete "/orchestration/flows/:id", TiannaraRuntimeWeb.ObservatoryController, :delete_flow
    post "/orchestration/flows/:id/run", TiannaraRuntimeWeb.ObservatoryController, :run_flow

    # Admin
    get "/admin/users", TiannaraRuntimeWeb.ObservatoryController, :admin_users
    get "/admin/api-keys", TiannaraRuntimeWeb.ObservatoryController, :admin_api_keys
    post "/admin/api-keys", TiannaraRuntimeWeb.ObservatoryController, :create_api_key
    delete "/admin/api-keys/:id", TiannaraRuntimeWeb.ObservatoryController, :delete_api_key

    # Moderation
    get "/moderation/health", TiannaraRuntimeWeb.ObservatoryController, :moderation_health

    # Domains
    get "/domains/tests", TiannaraRuntimeWeb.ObservatoryController, :domain_tests

    # Chat
    post "/chat", TiannaraRuntimeWeb.ObservatoryController, :chat

    # CPL
    get "/cpl/stats", TiannaraRuntimeWeb.ObservatoryController, :cpl_stats
    get "/cpl/events", TiannaraRuntimeWeb.ObservatoryController, :cpl_events
    get "/cpl/checkpoints", TiannaraRuntimeWeb.ObservatoryController, :cpl_checkpoints
  end

end
