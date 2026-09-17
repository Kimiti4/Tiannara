defmodule ObservatoryApi.Controllers.ScienceController do
  use ObservatoryApi, :controller

  def discoveries(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end

  def experiments(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end
end
