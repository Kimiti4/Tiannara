defmodule ObservatoryApi.Controllers.CertificationController do
  use ObservatoryApi, :controller

  def status(conn, _params) do
    json(conn, %{
      success: true,
      data: %{status: "certified"},
      api_version: Shared.Constants.api_version()
    })
  end

  def chain(conn, _params) do
    json(conn, %{success: true, data: %{chain: []}, api_version: Shared.Constants.api_version()})
  end
end
