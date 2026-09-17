defmodule Rbac.Token do
  @moduledoc """
  JWT with constitutional payload.

  Every token includes:
    sub — subject (identity ID)
    role — primary role
    capabilities — granted capabilities
    tid — tenant ID
    rtg — runtime generation
    cuv — constitution version
    iat — issued at
    exp — expires
    tid — trace ID (per-request)
    sid — session ID
    gn — generation (token version for rotation)
    sig — issuer signature
  """

  @secret Application.compile_env(:rbac, :jwt_secret, "dev-secret-change-in-production")

  def generate(%Rbac.Identity{} = ident, session_id \\ Ecto.UUID.generate()) do
    now = DateTime.utc_now()

    header = %{alg: "HS256", typ: "JWT"}

    payload = %{
      sub: ident.id,
      rol: List.first(ident.roles),
      cap: ident.capabilities,
      tid: "obs-tenant-1",
      rtg: Application.get_env(:observatory_core, :generation, 1),
      cuv: "1.0.0",
      iat: DateTime.to_unix(now),
      exp: DateTime.to_unix(DateTime.add(now, 15 * 60, :second)),
      sid: session_id,
      gn: 1
    }

    encode_jwt(header, payload)
  end

  def verify(token) when is_binary(token) do
    case String.split(token, ".") do
      [h, p, s] ->
        expected = compute_signature("#{h}.#{p}")

        if s == expected do
          case Jason.decode(Base.url_decode64!(p, padding: false)) do
            {:ok, payload} -> {:ok, payload}
            _ -> :error
          end
        else
          :error
        end

      _ ->
        :error
    end
  end

  def extract_session(token) do
    case verify(token) do
      {:ok, payload} ->
        %{session_id: payload["sid"], identity_id: payload["sub"], role: payload["rol"]}

      :error ->
        nil
    end
  end

  defp encode_jwt(header, payload) do
    h = Jason.encode!(header) |> Base.url_encode64(padding: false)
    p = Jason.encode!(payload) |> Base.url_encode64(padding: false)
    s = compute_signature("#{h}.#{p}")
    "#{h}.#{p}.#{s}"
  end

  defp compute_signature(data) do
    :crypto.mac(:hmac, :sha256, @secret, data) |> Base.url_encode64(padding: false)
  end
end
