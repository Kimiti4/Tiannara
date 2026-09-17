defmodule ObservatoryApi.Controllers.CivilizationController do
  use ObservatoryApi, :controller

  def indices(conn, _params) do
    json(conn, %{success: true, data: %{}, api_version: Shared.Constants.api_version()})
  end
end
