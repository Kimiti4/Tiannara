defmodule ObservatoryApi.Controllers.PlanetController do
  use ObservatoryApi, :controller

  def state(conn, _params) do
    json(conn, %{success: true, data: %{}, api_version: Shared.Constants.api_version()})
  end

  def metrics(conn, _params) do
    json(conn, %{success: true, data: %{}, api_version: Shared.Constants.api_version()})
  end
end
