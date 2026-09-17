defmodule ObservatoryApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :observatory_api

  socket "/ws", ObservatoryApi.WebSocket,
    websocket: [connect_info: [:peer_data, :x_headers]],
    longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug ObservatoryApi.Router
end
