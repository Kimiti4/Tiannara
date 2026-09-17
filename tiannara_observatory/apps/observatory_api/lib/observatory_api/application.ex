defmodule ObservatoryApi.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ObservatoryApiWeb.Telemetry,
      ObservatoryApi.Repo,
      {DNSCluster, query: Application.get_env(:observatory_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ObservatoryApi.PubSub},
      ObservatoryApiWeb.Hub.EventDispatcher,
      ObservatoryApiWeb.Hub.LiveStreamEngine,
      ObservatoryApiWeb.Hub.SubscriptionRegistry,
      ObservatoryApiWeb.Hub.AlertEngine,
      ObservatoryApiWeb.Hub.MissionBroadcast,
      ObservatoryApiWeb.Hub.COBStreamBridge,
      ObservatoryApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ObservatoryApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ObservatoryApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
