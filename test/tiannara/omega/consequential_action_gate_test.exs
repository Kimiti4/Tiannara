defmodule Tiannara.Omega.ConsequentialActionGateTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.ConsequentialActionGate
  alias Tiannara.Omega.DeploymentGateway
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  test "rejects an absent grant" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)

    assert {:error, :authorization_grant_required} =
             ConsequentialActionGate.authorize(:crav_alpha_launch, nil, identity)
  end

  test "requires exact action binding" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :crav_alpha_launch})
    {:ok, pending} = Authorization.request(auth)
    {:ok, grant} = Authorization.human_grant(pending, :human_1, action_id: :crav_alpha_launch)

    assert {:ok, _} =
             ConsequentialActionGate.authorize(:crav_alpha_launch, grant, identity)

    assert {:error, :grant_does_not_match_action} =
             ConsequentialActionGate.authorize(:other_action, grant, identity)
  end

  test "rejects unauthenticated identities" do
    {:ok, auth} = Authorization.prepare(%{explanation_id: :crav_alpha_launch})
    {:ok, pending} = Authorization.request(auth)
    {:ok, grant} = Authorization.human_grant(pending, :human_1, action_id: :crav_alpha_launch)

    forged = %AuthenticatedHumanIdentity{
      identity_id: :forged,
      human_id: :human_1,
      authenticated_at: nil,
      method: :forged
    }

    assert {:error, :identity_not_authenticated} =
             ConsequentialActionGate.authorize(:crav_alpha_launch, grant, forged)
  end

  test "rejects expired grants" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :crav_alpha_launch})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(
        pending,
        :human_1,
        ttl: 1,
        action_id: :crav_alpha_launch
      )

    expired = %{grant | granted_at: System.system_time(:second) - 100}

    assert {:error, :grant_expired} =
             ConsequentialActionGate.authorize(:crav_alpha_launch, expired, identity)
  end

  test "consumption is single-use" do
    path = Path.join(System.tmp_dir!(), "tiannara-action-gate-#{System.unique_integer([:positive])}.jsonl")
    on_exit(fn -> File.rm(path) end)

    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :crav_alpha_launch})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(
        pending,
        :human_1,
        action_id: :crav_alpha_launch
      )

    assert {:ok, receipt} =
             ConsequentialActionGate.consume(
               :crav_alpha_launch,
               grant,
               identity,
               path
             )

    assert receipt.human_id == :human_1

    assert {:error, :authorization_already_consumed} =
             ConsequentialActionGate.consume(
               :crav_alpha_launch,
               grant,
               identity,
               path
             )
  end

  test "legacy map certificates cannot authorize deployment" do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :prop_1})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(
        pending,
        :human_1,
        candidate_content_hash: "not-a-real-candidate-hash",
        action_id: :prop_1
      )

    assert {:error, :canonical_certificate_required} =
             DeploymentGateway.deploy(
               %Tiannara.Omega.PatchGenerator.Candidate{
                 id: :candidate,
                 proposal_id: :prop_1,
                 status: :approved,
                 content: %{target: :safe}
               },
               %{verdict: :certified},
               [:lineage],
               grant,
               identity
             )
  end
end
