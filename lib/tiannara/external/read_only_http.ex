defmodule Tiannara.External.ReadOnlyHTTP do
  @moduledoc """
  Bounded, read-only external observation boundary.

  This adapter performs GET requests only. It requires an authenticated human
  grant whose explanation is bound to the exact normalized URL, rejects
  redirects, limits response bytes, and records no external mutation.
  """

  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  @default_timeout 5_000
  @default_max_bytes 1_048_576

  @spec fetch(binary(), Authorization.t(), AuthenticatedHumanIdentity.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def fetch(url, %Authorization{} = grant, %AuthenticatedHumanIdentity{} = identity, opts)
      when is_binary(url) do
    with {:ok, normalized_url} <- normalize_url(url),
         :ok <- validate_identity(identity),
         :ok <- validate_grant(grant, normalized_url),
         {:ok, response} <- request(normalized_url, opts),
         :ok <- enforce_size(response.body, Keyword.get(opts, :max_bytes, @default_max_bytes)) do
      {:ok,
       %{
         url: normalized_url,
         status: response.status,
         headers: response.headers,
         body: response.body,
         observed_by: identity.identity_id,
         authorization_id: grant.authorization_id,
         effect_identity: effect_identity(normalized_url)
       }}
    end
  end

  def fetch(_url, _grant, _identity, _opts), do: {:error, :authenticated_grant_required}

  def effect_identity(url) when is_binary(url) do
    :crypto.hash(:sha256, :erlang.term_to_binary({:read_only_get, url}))
    |> Base.encode16(case: :lower)
  end

  defp normalize_url(url) do
    uri = URI.parse(url)

    cond do
      uri.scheme not in ["http", "https"] -> {:error, :unsupported_scheme}
      is_nil(uri.host) -> {:error, :host_required}
      uri.userinfo != nil -> {:error, :userinfo_not_allowed}
      not allowed_host?(uri.host) -> {:error, :host_not_allowlisted}
      true -> {:ok, URI.to_string(uri)}
    end
  end

  defp allowed_host?(host) do
    allowlist = Application.get_env(:tiannara, :external_read_allowlist, ["127.0.0.1", "localhost", "::1"])
    host in allowlist
  end

  defp validate_identity(identity) do
    if AuthenticatedHumanIdentity.authenticated?(identity), do: :ok, else: {:error, :identity_not_authenticated}
  end

  defp validate_grant(grant, url) do
    cond do
      grant.status != :granted -> {:error, :authorization_grant_denied}
      Authorization.expired?(grant) -> {:error, :grant_expired}
      not Authorization.valid_for?(grant, {:external_read, url}) -> {:error, :grant_does_not_match_effect}
      true -> :ok
    end
  end

  defp request(url, opts) do
    :inets.start()
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    case :httpc.request(:get, {String.to_charlist(url), []}, [autoredirect: false, timeout: timeout],
           body_format: :binary) do
      {:ok, {{_version, status, _reason}, headers, body}} when status in 200..299 ->
        {:ok, %{status: status, headers: headers, body: body}}

      {:ok, {{_version, status, _reason}, _headers, _body}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp enforce_size(body, max_bytes) when is_binary(body) and is_integer(max_bytes) and max_bytes >= 0 do
    if byte_size(body) <= max_bytes, do: :ok, else: {:error, :response_too_large}
  end

  defp enforce_size(_body, _max_bytes), do: {:error, :invalid_max_bytes}
end