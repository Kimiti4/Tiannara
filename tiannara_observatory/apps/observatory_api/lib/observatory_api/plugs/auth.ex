defmodule ObservatoryApi.Plugs.Auth do
  @moduledoc """
  Constitutional Auth plug.

  Verifies JWT, extracts identity, checks capabilities via RBAC Engine.
  Every auth decision is recorded in the Immutable Audit Ledger.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Dev-mode bypass: if observatory_core env is :dev, skip auth
    if ObservatoryCore.Config.env() == :dev do
      conn
      |> assign(:identity_id, "dev-bypass")
      |> assign(:role, :administrator)
      |> assign(:capabilities, Rbac.Capability.all())
      |> assign(:session_id, "dev-session")
      |> assign(:authenticated, true)
    else
      authenticate_request(conn)
    end
  end

  defp authenticate_request(conn) do
    with [token_str] <- get_req_header(conn, "authorization"),
         "Bearer " <> token <- token_str,
         {:ok, payload} <- Rbac.Token.verify(token) do
      conn
      |> assign(:identity_id, payload["sub"])
      |> assign(:role, payload["rol"])
      |> assign(:capabilities, payload["cap"] || [])
      |> assign(:session_id, payload["sid"])
      |> assign(:authenticated, true)
      |> register_before_send(fn conn ->
        record_auth(conn, :granted)
        conn
      end)
    else
      _ ->
        conn
        |> assign(:authenticated, false)
        |> register_before_send(fn conn ->
          record_auth(conn, :denied)
          conn
        end)
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            success: false,
            errors: [
              %{
                code: "UNAUTHORIZED",
                message: "Missing or invalid token",
                constitutional: "Art. IV.1 — Every operator action is audited"
              }
            ]
          })
        )
        |> halt()
    end
  end

  defp record_auth(conn, decision) do
    Rbac.AuditLog.record(
      "auth_#{decision}",
      conn.assigns[:identity_id] || "anonymous",
      conn.request_path,
      %{
        intent: "authenticate",
        evidence: "JWT verification",
        decision: to_string(decision),
        result: if(decision == :granted, do: "authenticated", else: "rejected"),
        metadata: %{method: conn.method, remote_ip: to_string(conn.remote_ip)}
      }
    )
  end
end
