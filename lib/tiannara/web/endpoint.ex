defmodule TiannaraWeb.Endpoint do
  @moduledoc """
  Defines the Phoenix Web Endpoint for Tiannara.
  """
  use Phoenix.Endpoint, otp_app: :tiannara

  @session_options [
    store: :cookie,
    key: "_tiannara_key",
    signing_salt: "signing_salt_tiannara"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve static files
  plug Plug.Static,
    at: "/",
    from: :tiannara,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt data)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TiannaraWeb.Router
end
