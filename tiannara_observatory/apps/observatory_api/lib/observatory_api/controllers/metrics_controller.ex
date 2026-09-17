defmodule ObservatoryApi.Controllers.MetricsController do
  use ObservatoryApi, :controller

  def index(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end

  def show(conn, %{"name" => name}) do
    json(conn, %{success: true, data: %{name: name}, api_version: Shared.Constants.api_version()})
  end
end
