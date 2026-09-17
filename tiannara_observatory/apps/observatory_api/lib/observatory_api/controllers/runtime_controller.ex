defmodule ObservatoryApi.Controllers.RuntimeController do
  use ObservatoryApi, :controller

  def health(conn, _params) do
    data =
      case ObservatoryState.Runtime.get(:health) do
        {:ok, health} -> health
        _ -> %{status: "unknown"}
      end

    json(conn, %{success: true, data: data, api_version: Shared.Constants.api_version()})
  end

  def metrics(conn, _params) do
    json(conn, %{
      success: true,
      data: %{uptime: 0, discovery_rate: 0, cpu: 0, memory: 0},
      api_version: Shared.Constants.api_version()
    })
  end
end
