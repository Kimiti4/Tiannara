defmodule ObservatoryApi.Controllers.DiscoveryController do
  use ObservatoryApi, :controller

  def stream(conn, _params) do
    json(conn, %{
      success: true,
      data: %{events: [], active: 0},
      api_version: Shared.Constants.api_version()
    })
  end
end
