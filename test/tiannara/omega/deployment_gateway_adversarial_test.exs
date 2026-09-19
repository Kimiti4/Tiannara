defmodule Tiannara.Omega.DeploymentGatewayAdversarialTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.{DeploymentGateway, ExperimentGenerator, PatchGenerator}
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  @moduletag :deployment_gateway_adversarial

  defp approved_candidate_with_grant do
    # Build a full approved candidate + grant
    proposal = %{
      id: :prop_1,
      hypothesis_id: :hyp_1,
      statement: "test",
      type: :memory,
      falsifier: "f",
      rank: 1,
      status: :proposed
    }

    {:ok, spec} = ExperimentGenerator.design(proposal)
    {:ok, candidate} = PatchGenerator.generate(spec)

    # Walk candidate to :approved
    {:ok, c1} = Candidate.transition(candidate, :sandboxed)
    {:ok, c2} = Candidate.transition(c1, :tested)
    {:ok, c3} = Candidate.transition(c2, :benchmarked)
    {:ok, c4} = Candidate.transition(c3, :certified)
    {:ok, approved} = Candidate.transition(c4, :approved)

    # Authenticate a human and grant authorization
    {:ok, identity} =
      AuthenticatedHumanIdentity.authenticate(:human_1, "secret_credential", :password)

    {:ok, auth} = Authorization.prepare(%{explanation_id: :prop_1})
    {:ok, pending} = Authorization.request(auth)

    content_hash = DeploymentGateway.content_hash(approved)

    {:ok, grant} =
      Authorization.human_grant(pending, :human_1,
        ttl: 3600,
        candidate_content_hash: content_hash,
        effect_descriptor: DeploymentGateway.deployment_effect_descriptor(approved, :human_1)
      )

    {approved, %{verdict: :certified}, [:obs_1, :hyp_1, :prop_1], grant, identity}
  end

  test "LEGITIMATE: full valid chain deploys successfully" do
    {candidate, cert, lineage, grant, identity} = approved_candidate_with_grant()

    assert {:ok, record, deployed} =
             DeploymentGateway.deploy(candidate, cert, lineage, grant, identity)

    assert deployed.status == :deployed
    assert record.granted_by == :human_1
  end

  test "ADVERSARIAL: an unbound grant cannot cross the deployment effect boundary" do
    {candidate, cert, lineage, grant, identity} = approved_candidate_with_grant()
    unbound_grant = %{grant | effect_id: nil}

    assert {:error, :grant_does_not_match_effect} =
             DeploymentGateway.deploy(candidate, cert, lineage, unbound_grant, identity)
  end

  test "ADVERSARIAL: a grant bound to one deployment effect cannot authorize another" do
    {candidate, cert, lineage, grant, identity} = approved_candidate_with_grant()

    altered_descriptor =
      DeploymentGateway.deployment_effect_descriptor(candidate, :human_1)
      |> Map.put(:operation, "rollback")

    {:ok, auth} = Authorization.prepare(%{explanation_id: candidate.proposal_id})
    {:ok, pending} = Authorization.request(auth)

    {:ok, mismatched_grant} =
      Authorization.human_grant(pending, :human_1,
        candidate_content_hash: DeploymentGateway.content_hash(candidate),
        effect_descriptor: altered_descriptor
      )

    assert mismatched_grant.effect_id != grant.effect_id

    assert {:error, :grant_does_not_match_effect} =
             DeploymentGateway.deploy(candidate, cert, lineage, mismatched_grant, identity)
  end

  test "ADVERSARIAL: bypass human authorization — no grant" do
    {candidate, cert, lineage, _grant, identity} = approved_candidate_with_grant()

    assert {:error, :authorization_grant_required} =
             DeploymentGateway.deploy(candidate, cert, lineage, nil, identity)
  end

  test "ADVERSARIAL: reuse an old grant for a different candidate" do
    {candidate, cert, lineage, grant, identity} = approved_candidate_with_grant()

    # Build a DIFFERENT candidate
    proposal = %{
      id: :prop_OTHER,
      hypothesis_id: :hyp_2,
      statement: "other",
      type: :memory,
      falsifier: "f",
      rank: 1,
      status: :proposed
    }

    {:ok, spec} = ExperimentGenerator.design(proposal)
    {:ok, other_candidate} = PatchGenerator.generate(spec)
    {:ok, oc1} = Candidate.transition(other_candidate, :sandboxed)
    {:ok, oc2} = Candidate.transition(oc1, :tested)
    {:ok, oc3} = Candidate.transition(oc2, :benchmarked)
    {:ok, oc4} = Candidate.transition(oc3, :certified)
    {:ok, other_approved} = Candidate.transition(oc4, :approved)

    assert {:error, :grant_does_not_match_candidate} =
             DeploymentGateway.deploy(other_approved, cert, lineage, grant, identity)
  end

  test "ADVERSARIAL: forge a human identity (unauthenticated)" do
    {candidate, cert, lineage, grant, _identity} = approved_candidate_with_grant()

    # Forge an identity without authentication
    forged_identity = %AuthenticatedHumanIdentity{
      identity_id: :forged,
      human_id: :human_1,
      # NOT authenticated
      authenticated_at: nil,
      method: :forged
    }

    assert {:error, :identity_not_authenticated} =
             DeploymentGateway.deploy(candidate, cert, lineage, grant, forged_identity)
  end

  test "ADVERSARIAL: deploy an uncertified candidate" do
    {candidate, _cert, lineage, grant, identity} = approved_candidate_with_grant()

    bad_cert = %{verdict: :not_certified}

    assert {:error, :certification_invalid} =
             DeploymentGateway.deploy(candidate, bad_cert, lineage, grant, identity)
  end

  test "ADVERSARIAL: deploy after grant expiry" do
    {candidate, cert, lineage, _grant, identity} = approved_candidate_with_grant()

    # Create an already-expired grant
    content_hash = DeploymentGateway.content_hash(candidate)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :prop_1})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(pending, :human_1,
        ttl: 1,
        candidate_content_hash: content_hash,
        effect_descriptor: DeploymentGateway.deployment_effect_descriptor(candidate, :human_1)
      )

    # Simulate time passing beyond TTL
    expired_grant = %{grant | granted_at: System.system_time(:second) - 100}

    assert {:error, :grant_expired} =
             DeploymentGateway.deploy(candidate, cert, lineage, expired_grant, identity)
  end

  test "ADVERSARIAL: mutate candidate after authorization" do
    {candidate, cert, lineage, _grant, identity} = approved_candidate_with_grant()

    # Grant was made against the ORIGINAL content hash
    content_hash = DeploymentGateway.content_hash(candidate)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :prop_1})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(pending, :human_1,
        ttl: 3600,
        candidate_content_hash: content_hash,
        effect_descriptor: DeploymentGateway.deployment_effect_descriptor(candidate, :human_1)
      )

    # Mutate the candidate AFTER authorization. The content hash is part of the
    # effect descriptor, so a mutated candidate is a different effect and is
    # rejected at the effect boundary before the deploy transition.
    mutated_candidate = %{candidate | content: %{candidate.content | target: :malicious}}

    assert {:error, :grant_does_not_match_effect} =
             DeploymentGateway.deploy(mutated_candidate, cert, lineage, grant, identity)
  end

  test "ADVERSARIAL: deploy with empty/missing lineage" do
    {candidate, cert, _lineage, grant, identity} = approved_candidate_with_grant()

    assert {:error, :lineage_invalid} =
             DeploymentGateway.deploy(candidate, cert, [], grant, identity)
  end

  test "ADVERSARIAL: deploy a candidate that is not approved" do
    # Build a candidate only up to :certified, not :approved
    proposal = %{
      id: :prop_1,
      hypothesis_id: :hyp_1,
      statement: "test",
      type: :memory,
      falsifier: "f",
      rank: 1,
      status: :proposed
    }

    {:ok, spec} = ExperimentGenerator.design(proposal)
    {:ok, candidate} = PatchGenerator.generate(spec)
    {:ok, c1} = Candidate.transition(candidate, :sandboxed)
    {:ok, c2} = Candidate.transition(c1, :tested)
    {:ok, c3} = Candidate.transition(c2, :benchmarked)
    {:ok, certified_only} = Candidate.transition(c3, :certified)

    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "cred", :password)
    content_hash = DeploymentGateway.content_hash(certified_only)
    {:ok, auth} = Authorization.prepare(%{explanation_id: :prop_1})
    {:ok, pending} = Authorization.request(auth)

    {:ok, grant} =
      Authorization.human_grant(pending, :human_1,
        ttl: 3600,
        candidate_content_hash: content_hash,
        effect_descriptor:
          DeploymentGateway.deployment_effect_descriptor(certified_only, :human_1)
      )

    assert {:error, {:candidate_not_approved, :certified}} =
             DeploymentGateway.deploy(
               certified_only,
               %{verdict: :certified},
               [:obs_1],
               grant,
               identity
             )
  end

  test "ADVERSARIAL: authorization expiry transitions correctly" do
    {:ok, auth} = Authorization.prepare(%{explanation_id: :expl_1})
    {:ok, pending} = Authorization.request(auth)
    {:ok, grant} = Authorization.human_grant(pending, :human_1, ttl: 1)

    # Not yet expired
    refute Authorization.expired?(grant)
    assert {:error, :not_yet_expired} = Authorization.expire(grant)

    # Simulate expiry
    expired_grant = %{grant | granted_at: System.system_time(:second) - 100}
    assert Authorization.expired?(expired_grant)
    assert {:ok, expired} = Authorization.expire(expired_grant)
    assert expired.status == :expired
  end
end
