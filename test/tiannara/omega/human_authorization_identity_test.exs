defmodule Tiannara.Omega.HumanAuthorizationIdentityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.HumanDelivery.{AuthenticatedHumanIdentity, Authorization}

  setup do
    {:ok, prepared} = Authorization.prepare(%{explanation_id: :test_explanation})
    {:ok, pending} = Authorization.request(prepared)
    {:ok, %{pending: pending}}
  end

  test "rejects a bare human identifier", %{pending: pending} do
    assert {:error, :authenticated_identity_required} = Authorization.human_grant(pending, :human_1)
  end

  test "mints a grant only for an authenticated identity", %{pending: pending} do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)

    assert {:ok, grant} = Authorization.human_grant(pending, identity)
    assert grant.human_id == :human_1
    assert grant.status == :granted
  end
end