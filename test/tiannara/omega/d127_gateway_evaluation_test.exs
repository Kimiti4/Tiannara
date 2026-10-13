defmodule Tiannara.Omega.D127GatewayEvaluationTest do
  @moduledoc """
  D127 evaluation — GATEWAY PATH (Wave 3 Step 8).

  Executes the evaluation protocol fixed in the Step-5 artifact, section 6,
  against `DeploymentGateway.deploy/6`: for each of the six D127 properties,
  a constructive attack expecting a NAMED refusal atom, plus negative
  controls proving the legitimately minted path still passes. Results are
  recorded per-property in the Step-8 evaluation artifact — never inferred
  from the existence of countermeasure code.

  D127 definition: operator-supplied, conversation 2026-09-27 (not
  repo-sourced). S01-path evaluation was performed in Step 6; class-D and
  machine-class (council) paths remain unevaluated, so D127 overall stays
  OPEN regardless of this suite's outcome.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.{DeploymentGateway, EffectIdentity, MintRegistry}
  alias Tiannara.Omega.DeploymentGateway.DeploymentRegistry
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity
  alias Tiannara.Omega.Verification.{Baseline, World}

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)

    world = World.create()
    on_exit(fn -> World.discard(world) end)
    baseline = Baseline.establish(world)

    %{world: world, baseline: baseline}
  end

  defp deploy(baseline, opts) do
    DeploymentGateway.deploy(
      Keyword.get(opts, :candidate, baseline.candidate),
      baseline.certification,
      baseline.lineage,
      Keyword.get(opts, :grant, baseline.authorization),
      Keyword.get(opts, :identity, baseline.identity),
      Keyword.get(opts, :registry_path, nil)
    )
  end

  defp audit_entries_for(authorization_id) do
    AuditLog.recent(300)
    |> Enum.filter(fn entry ->
      entry.action == :deployment_committed and
        is_map(entry.payload) and
        Map.get(entry.payload, :authorization_id) == authorization_id
    end)
  end

  # ------------------------------------------------- D127.1 REPLAYED -------

  test "D127.1 REPLAY: a consumed grant cannot redeploy — both registry paths refuse by name",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization
    effect = DeploymentGateway.effect_identity(baseline.candidate)

    assert {:ok, record, _} =
             deploy(baseline, grant: grant, registry_path: world.deployment_registry_path)

    assert record.effect_identity == effect

    # replay through the optional DeploymentRegistry file -> named atom
    assert {:error, :grant_already_used} =
             deploy(baseline, grant: grant, registry_path: world.deployment_registry_path)

    # replay with NO registry file (the pre-M7 bypass path) -> named atom
    assert {:error, :already_consumed} = deploy(baseline, grant: grant, registry_path: nil)

    # exactly one recorded deployment, one audit edge, registry consumed
    assert DeploymentRegistry.deployment_status(grant.authorization_id, effect, world.deployment_registry_path) ==
             :same_effect
    assert length(audit_entries_for(grant.authorization_id)) == 1
    assert MintRegistry.status(grant.authorization_id) == :consumed
  end

  # ---------------------------------------------------- D127.2 COPIED ------

  test "D127.2 COPY: a duplicated grant struct is refused as a second instance",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization

    assert {:ok, _, _} = deploy(baseline, grant: grant, registry_path: world.deployment_registry_path)

    copy = %{grant | lineage: grant.lineage ++ [{:copied, :attack}]}

    assert {:error, :grant_already_used} =
             deploy(baseline, grant: copy, registry_path: world.deployment_registry_path)

    assert {:error, :already_consumed} = deploy(baseline, grant: copy, registry_path: nil)
    assert MintRegistry.status(grant.authorization_id) == :consumed
    assert length(audit_entries_for(grant.authorization_id)) == 1
  end

  test "D127.2 COPY (concurrent, registry path): of 4 presentations exactly 1 deploys",
       %{world: world, baseline: baseline} do
    results =
      1..4
      |> Enum.map(fn _ ->
        Task.async(fn ->
          deploy(baseline, grant: baseline.authorization, registry_path: world.deployment_registry_path)
        end)
      end)
      |> Task.await_many(:timer.seconds(20))

    assert Enum.count(results, &match?({:ok, _, _}, &1)) == 1
    assert Enum.count(results, &(&1 == {:error, :grant_already_used})) == 3
    assert length(audit_entries_for(baseline.authorization.authorization_id)) == 1
    assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
  end

  test "D127.2 COPY (concurrent, nil path): M4 CAS alone gives exactly 1 deploy of 4",
       %{baseline: baseline} do
    results =
      1..4
      |> Enum.map(fn _ ->
        Task.async(fn -> deploy(baseline, grant: baseline.authorization, registry_path: nil) end)
      end)
      |> Task.await_many(:timer.seconds(20))

    assert Enum.count(results, &match?({:ok, _, _}, &1)) == 1
    assert Enum.count(results, &(&1 == {:error, :already_consumed})) == 3
    assert length(audit_entries_for(baseline.authorization.authorization_id)) == 1
    assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
  end

  # ------------------------------------------------ D127.3 DELEGATED -------

  test "D127.3 DELEGATION: the grant cannot deploy under another principal",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization

    {:ok, other_human} =
      AuthenticatedHumanIdentity.authenticate(:human_d127_gw_other, "other-cred", :password)

    # an authenticated human B is still not this grant's principal
    assert {:error, :identity_does_not_match_grant} =
             deploy(baseline, grant: grant, identity: other_human, registry_path: world.deployment_registry_path)

    # a structurally plausible but unauthenticated identity is refused
    forged_identity = %AuthenticatedHumanIdentity{
      identity_id: :ident_d127_gw_forged,
      human_id: grant.human_id,
      authenticated_at: nil,
      method: :forged
    }

    assert {:error, :identity_not_authenticated} =
             deploy(baseline, grant: grant, identity: forged_identity, registry_path: world.deployment_registry_path)

    # neither delegation attempt consumed the grant (negative control inline)
    assert MintRegistry.status(grant.authorization_id) == :granted

    assert {:ok, _, _} =
             deploy(baseline, grant: grant, identity: baseline.identity, registry_path: world.deployment_registry_path)
  end

  # ----------------------------------------------- D127.4 AMPLIFIED ---------

  test "D127.4 AMPLIFICATION: narrowed grant cannot authorize a broader effect",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization

    # (a) broadening the candidate after authorization -> content-hash gate
    mutated = %{baseline.candidate | content: Map.put(baseline.candidate.content, :target, :malicious)}

    assert {:error, :candidate_mutated_after_authorization} =
             deploy(baseline, candidate: mutated, grant: grant, registry_path: world.deployment_registry_path)

    # (b) the canonical identity actually changes under descriptor broadening
    descriptor = DeploymentGateway.effect_descriptor(baseline.candidate)
    broadened = %{descriptor | parameters: Map.put(descriptor.parameters, "scope", "all_candidates")}
    {:ok, broadened_id} = EffectIdentity.effect_id(broadened)
    refute broadened_id == grant.effect_id

    # (c) a grant struct rewritten to the broadened id is refused by recompute
    forged_broad = %{grant | effect_id: broadened_id}

    assert {:error, :effect_id_mismatch} =
             deploy(baseline, grant: forged_broad, registry_path: world.deployment_registry_path)

    # amplification attempts never consumed the grant
    assert MintRegistry.status(grant.authorization_id) == :granted
    assert audit_entries_for(grant.authorization_id) == []
  end

  # ------------------------------- D127.5 REUSED-AGAINST-ANOTHER-EFFECT -----

  test "D127.5 OTHER-EFFECT: the grant cannot authorize an effect it did not name",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization

    # a different candidate = a different effect identity (same content, new id)
    other = %{baseline.candidate | id: :"cand-other-#{System.unique_integer([:monotonic])}"}
    other_effect = DeploymentGateway.effect_identity(other)
    refute other_effect == grant.effect_id

    # attack A: original (narrow) grant against the other effect
    assert {:error, :effect_id_mismatch} =
             deploy(baseline, candidate: other, grant: grant, registry_path: world.deployment_registry_path)

    # attack B: struct rewritten to claim the other effect — registry disagrees
    forged_for_other = %{grant | effect_id: other_effect}

    assert {:error, :registry_binding_mismatch} =
             deploy(baseline, candidate: other, grant: forged_for_other, registry_path: world.deployment_registry_path)

    assert MintRegistry.status(grant.authorization_id) == :granted
    assert audit_entries_for(grant.authorization_id) == []
  end

  test "D127.5 OTHER-EFFECT: binding is one-shot at struct AND registry level",
       %{baseline: baseline} do
    grant = baseline.authorization

    other_descriptor = %{
      DeploymentGateway.effect_descriptor(baseline.candidate)
      | parameters: Map.put(DeploymentGateway.effect_descriptor(baseline.candidate).parameters, "effect", "other")
    }

    # struct-level one-shot
    assert {:error, {:already_bound, _}} = Authorization.bind_effect(grant, other_descriptor)

    # registry-level one-shot
    {:ok, other_id} = EffectIdentity.effect_id(other_descriptor)
    assert {:error, {:already_bound, _}} = MintRegistry.record_bind(grant.authorization_id, other_id)
  end

  # -------------------------- D127.6 RECONSTRUCTED-OUTSIDE-AUTHORITY --------

  test "D127.6 RECONSTRUCTION: a fully plausible forged grant never minted is refused",
       %{world: world, baseline: baseline} do
    identity = baseline.identity

    # everything structurally right: status, principal, expiry, explanation,
    # content hash — even the canonical effect id — but no durable mint record.
    forged = %Authorization{
      authorization_id: :"auth-forged-gw-#{System.unique_integer([:monotonic])}",
      explanation_id: baseline.proposal.id,
      human_id: identity.human_id,
      granted_at: System.system_time(:second),
      ttl: 3600,
      candidate_content_hash: baseline.content_hash,
      effect_id: DeploymentGateway.effect_identity(baseline.candidate),
      decision: :granted,
      lineage: [],
      status: :granted
    }

    assert {:error, :authorization_not_registered} =
             deploy(baseline, grant: forged, registry_path: world.deployment_registry_path)

    assert MintRegistry.status(forged.authorization_id) == :not_registered
    assert audit_entries_for(forged.authorization_id) == []

    # negative control: the legitimately minted grant still deploys
    assert {:ok, _, _} =
             deploy(baseline, grant: baseline.authorization, registry_path: world.deployment_registry_path)
    assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
  end

  # ---------------------------------------------- fail-closed extras --------

  test "fail-closed: an unavailable registry refuses any gateway deploy",
       %{baseline: baseline} do
    registry_pid = Process.whereis(MintRegistry)
    assert is_pid(registry_pid)
    Process.unregister(MintRegistry)

    try do
      assert {:error, :authorization_registry_unavailable} = deploy(baseline, registry_path: nil)
      assert audit_entries_for(baseline.authorization.authorization_id) == []
    after
      Process.register(registry_pid, MintRegistry)
    end
  end

  test "fail-closed: an unavailable audit edge refuses the deployment claim and burns the grant",
       %{baseline: baseline} do
    audit_pid = Process.whereis(AuditLog)
    assert is_pid(audit_pid)
    Process.unregister(AuditLog)

    try do
      assert {:error, {:audit_not_recorded, _reason, detail}} = deploy(baseline, registry_path: nil)
      assert detail.deployed == true
      assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
    after
      Process.register(audit_pid, AuditLog)
    end
  end

  # ---------------------------------------------- negative control -----------

  test "negative control: a legitimately minted, bound grant deploys end-to-end",
       %{world: world, baseline: baseline} do
    grant = baseline.authorization

    assert {:ok, record, deployed} =
             deploy(baseline, grant: grant, registry_path: world.deployment_registry_path)

    assert deployed.status == :deployed
    assert String.starts_with?(record.effect_identity, "effect-v1-")
    assert MintRegistry.status(grant.authorization_id) == :consumed

    assert [entry] = audit_entries_for(grant.authorization_id)
    assert entry.payload.deployment_id == record.deployment_id
  end
end
