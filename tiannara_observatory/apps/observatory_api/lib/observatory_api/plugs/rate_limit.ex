defmodule ObservatoryApi.Plugs.RateLimit do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if ObservatoryCore.Config.env() == :dev do
      conn
    else
      body =
        Jason.encode!(%{
          success: false,
          errors: [%{code: "RATE_LIMITED", message: "Too many requests"}]
        })

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(429, body)
      |> halt()
    end
  end
end
