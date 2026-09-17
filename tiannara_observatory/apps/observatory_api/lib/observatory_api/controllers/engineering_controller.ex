defmodule ObservatoryApi.Controllers.EngineeringController do
  use ObservatoryApi, :controller

  def designs(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end

  def trl(conn, _params) do
    json(conn, %{success: true, data: %{level: 1}, api_version: Shared.Constants.api_version()})
  end
end
