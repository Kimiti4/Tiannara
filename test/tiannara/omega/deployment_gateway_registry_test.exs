defmodule Tiannara.Omega.DeploymentGatewayRegistryTest do
  @moduledoc """
  Wave 3 Step 7 — S02 gateway migration: the MintRegistry is mandatory at the
  DeploymentGateway (model M7), consumption is one-shot (M4), binding is
  verified against the durable registry (M1/M7), and the audit edge is
  fail-closed (M8).

  The central assertion: these gates fire even when `registry_path` is nil —
  there is no optional-path bypass of the mint registry.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.{DeploymentGateway, HumanDelivery, MintRegistry}
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.Verification.{Baseline, World}

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  defp establish do
    world = World.create()
    on_exit(fn -> World.discard(world) end)
    {world, Baseline.establish(world)}
  end

  defp deploy(baseline, grant, registry_path \\ nil) do
    DeploymentGateway.deploy(
      baseline.candidate,
      baseline.certification,
      baseline.lineage,
      grant,
      baseline.identity,
      registry_path
    )
  end

  defp fresh_grant(baseline) do
    explanation = HumanDelivery.explain(%{explanation_id: baseline.proposal.id, detected: "test"})
    {:ok, auth} = HumanDelivery.request_authorization(explanation)

    {:ok, grant} =
      Authorization.human_grant(auth, baseline.identity,
        ttl: 3600,
        candidate_content_hash: baseline.content_hash
      )

    grant
  end

  # ------------------------------------------------- M7: mandatory registry --

  test "a grant with no durable mint record is refused (even with nil registry_path)" do
    {_world, baseline} = establish()
    grant = fresh_grant(baseline)

    assert MintRegistry.status(grant.authorization_id) == :not_registered
    assert {:error, :authorization_not_registered} = deploy(baseline, grant, nil)
  end

  test "a structurally valid forged grant that was never minted is refused" do
    {_world, baseline} = establish()

    forged = %Authorization{
      authorization_id: :"auth-forged-gw-#{System.unique_integer([:monotonic])}",
      explanation_id: baseline.proposal.id,
      human_id: baseline.identity.human_id,
      granted_at: System.system_time(:second),
      ttl: 3600,
      candidate_content_hash: baseline.content_hash,
      decision: :granted,
      lineage: [],
      status: :granted
    }

    assert {:error, :authorization_not_registered} = deploy(baseline, forged, nil)
  end

  # ---------------------------------------------- M1/M7: binding at gateway --

  test "a registered but unbound grant cannot deploy" do
    {_world, baseline} = establish()
    grant = fresh_grant(baseline)
    :ok = Authorization.record_mint(grant.authorization_id)

    assert {:error, :effect_binding_required} = deploy(baseline, grant, nil)
  end

  test "a grant bound in the struct but disagreed with by the registry is refused" do
    {_world, baseline} = establish()
    grant = fresh_grant(baseline)

    {:ok, bound} = Authorization.bind_effect(grant, DeploymentGateway.effect_descriptor(baseline.candidate))
    :ok = Authorization.record_mint(bound.authorization_id)

    # registry records a DIFFERENT binding than the struct claims
    :ok = MintRegistry.record_bind(bound.authorization_id, "effect-v1-registry-says-otherwise")

    assert {:error, :registry_binding_mismatch} = deploy(baseline, bound, nil)
  end

  # ------------------------------------------------ M4: one-shot consumption --

  test "a successful deployment consumes the grant; replay is refused with nil registry_path" do
    {_world, baseline} = establish()

    assert {:ok, record, _deployed} = deploy(baseline, baseline.authorization, nil)
    assert String.starts_with?(record.effect_identity, "effect-v1-")
    assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed

    # The nil-path replay bypass is dead: consumption is enforced by the
    # registry itself, not by the optional DeploymentRegistry file.
    assert {:error, :already_consumed} = deploy(baseline, baseline.authorization, nil)
    assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
  end

  # ----------------------------------------------------- M8: audit edge ------

  test "the committed deployment writes a fail-closed audit edge" do
    {_world, baseline} = establish()

    assert {:ok, record, _deployed} = deploy(baseline, baseline.authorization, nil)

    entry =
      AuditLog.recent(200)
      |> Enum.find(fn entry ->
        entry.action == :deployment_committed and
          is_map(entry.payload) and
          Map.get(entry.payload, :deployment_id) == record.deployment_id
      end)

    assert entry, "expected a :deployment_committed audit entry"
    assert entry.payload.authorization_id == baseline.authorization.authorization_id
    assert entry.payload.effect_identity == record.effect_identity
  end

  test "an unavailable audit log refuses the deployment claim (fail-closed)" do
    {_world, baseline} = establish()

    audit_pid = Process.whereis(AuditLog)
    assert is_pid(audit_pid)
    Process.unregister(AuditLog)

    try do
      assert {:error, {:audit_not_recorded, _reason, detail}} =
               deploy(baseline, baseline.authorization, nil)

      assert detail.deployed == true
      assert detail.authorization_id == baseline.authorization.authorization_id

      # the effect side committed at-most-once: the grant is burned, never re-runnable
      assert MintRegistry.status(baseline.authorization.authorization_id) == :consumed
    after
      Process.register(audit_pid, AuditLog)
    end
  end
end
