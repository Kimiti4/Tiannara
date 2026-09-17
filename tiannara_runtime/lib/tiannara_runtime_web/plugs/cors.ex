defmodule TiannaraRuntimeWeb.Plugs.CORS do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization, accept, x-request-id")
    |> put_resp_header("access-control-max-age", "86400")
    |> maybe_handle_preflight()
  end

  defp maybe_handle_preflight(%{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(204, "")
    |> halt()
  end

  defp maybe_handle_preflight(conn), do: conn
end
