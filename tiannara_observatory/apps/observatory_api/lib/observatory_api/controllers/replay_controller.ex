defmodule ObservatoryApi.Controllers.ReplayController do
  use ObservatoryApi, :controller

  def replay(conn, %{"timestamp" => timestamp}) do
    result = ReplayStore.Replay.replay_at(timestamp)
    json(conn, %{success: true, data: result, api_version: Shared.Constants.api_version()})
  end

  def replay(conn, _params) do
    json(conn, %{
      success: true,
      data: %{message: "provide ?timestamp parameter"},
      api_version: Shared.Constants.api_version()
    })
  end

  def snapshots(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end

  def timeline(conn, _params) do
    json(conn, %{success: true, data: [], api_version: Shared.Constants.api_version()})
  end
end
