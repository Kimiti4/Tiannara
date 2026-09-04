defmodule Tiannara.Omega.Verification.Baseline do
  @moduledoc """
  Establishes a legitimate, certified, authorized candidate as the attack
  baseline. Every scenario starts from this legitimate state, then attacks.

  Constitutional basis: Verification First, "Maintain audit trails."
  """

  alias Tiannara.Omega.{ExperimentGenerator, PatchGenerator, DeploymentGateway, HumanDelivery}
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  defstruct [:candidate, :certification, :lineage, :explanation, :authorization,
             :identity, :world, :content_hash, :proposal]

  def establish(world) do
    proposal = sample_proposal()
    {:ok, spec} = ExperimentGenerator.design(proposal)
    {:ok, candidate} = PatchGenerator.generate(spec)
    candidate = walk_to_approved(candidate)

    certification = %{verdict: :certified}
    lineage = [:obs_1, :hyp_1, spec.id, candidate.id]

    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    explanation = HumanDelivery.explain(%{explanation_id: proposal.id, detected: "test"})
    {:ok, auth} = HumanDelivery.request_authorization(explanation)
    content_hash = DeploymentGateway.content_hash(candidate)

    {:ok, grant} =
      Authorization.human_grant(auth, :human_1,
        ttl: 3600, candidate_content_hash: content_hash)

    %__MODULE__{
      candidate: candidate,
      certification: certification,
      lineage: lineage,
      explanation: explanation,
      authorization: grant,
      identity: identity,
      world: world,
      content_hash: content_hash,
      proposal: proposal
    }
  end

  defp sample_proposal do
    %{id: :prop_1, hypothesis_id: :hyp_1, statement: "verification baseline",
      type: :memory, falsifier: "f", rank: 1, status: :proposed}
  end

  defp walk_to_approved(candidate) do
    {:ok, c1} = Candidate.transition(candidate, :sandboxed)
    {:ok, c2} = Candidate.transition(c1, :tested)
    {:ok, c3} = Candidate.transition(c2, :benchmarked)
    {:ok, c4} = Candidate.transition(c3, :certified)
    {:ok, approved} = Candidate.transition(c4, :approved)
    approved
  end
end