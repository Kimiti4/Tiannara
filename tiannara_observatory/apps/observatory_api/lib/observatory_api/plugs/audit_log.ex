defmodule ObservatoryApi.Plugs.AuditLog do
  @moduledoc """
  Constitutional Audit plug.

  Records every API request in the Immutable Audit Ledger with:
    actor, action, resource, decision, result, latency, request_id, session_id
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    start = System.monotonic_time(:millisecond)

    register_before_send(conn, fn conn ->
      duration = System.monotonic_time(:millisecond) - start

      Rbac.AuditLog.record_with_delta(
        "#{conn.method} #{conn.request_path}",
        conn.assigns[:identity_id] || "anonymous",
        conn.request_path,
        # old_state
        nil,
        # new_state
        %{status: conn.status, duration_ms: duration},
        intent: "api_request",
        evidence: "HTTP request processed",
        decision: if(conn.status < 400, do: "granted", else: "denied"),
        result: if(conn.status < 400, do: "success", else: "error"),
        metadata: %{
          method: conn.method,
          status: conn.status,
          duration_ms: duration,
          request_id: get_req_header(conn, "x-request-id") |> List.first(),
          session_id: conn.assigns[:session_id]
        }
      )

      conn
    end)
  end
end
