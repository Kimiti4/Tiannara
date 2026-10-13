defmodule Tiannara.External.ReadOnlyHTTPTest do
  use ExUnit.Case, async: true

  alias Tiannara.External.ReadOnlyHTTP
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  test "rejects non-allowlisted hosts before network access" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    grant = granted_for("https://example.com/health")

    assert {:error, :host_not_allowlisted} =
             ReadOnlyHTTP.fetch("https://example.com/health", grant, identity, [])
  end

  test "requires the grant to identify the exact read effect" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    grant = granted_for("http://127.0.0.1:4000/expected")

    assert {:error, :grant_does_not_match_effect} =
             ReadOnlyHTTP.fetch("http://127.0.0.1:4000/other", grant, identity, [])
  end

  test "rejects unauthenticated grant callers" do
    grant = granted_for("http://127.0.0.1:4000/expected")

    assert {:error, :authenticated_grant_required} =
             ReadOnlyHTTP.fetch("http://127.0.0.1:4000/expected", grant, :human_1, [])
  end

  defp granted_for(url) do
    {:ok, prepared} = Authorization.prepare(%{explanation_id: {:external_read, url}})
    {:ok, pending} = Authorization.request(prepared)
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, grant} = Authorization.human_grant(pending, identity)
    grant
  end
end