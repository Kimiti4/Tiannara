defmodule ObservatoryApi.Controllers.EventsController do
  use ObservatoryApi, :controller

  def index(conn, params) do
    events = EventStore.Reader.list_by_domain(params["domain"] || "runtime/health", limit: 100)
    json(conn, %{success: true, data: events, api_version: Shared.Constants.api_version()})
  end

  def show(conn, %{"id" => id}) do
    event = EventStore.Reader.get(id)
    json(conn, %{success: true, data: event, api_version: Shared.Constants.api_version()})
  end
end
