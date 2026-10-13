defmodule Tiannara.Omega.D127AuthorizationAttackTest do
  @moduledoc """
  D127 attack suite against the governed sink (Wave 3 Step 6).

  D127 definition is operator-supplied (2026-09-27, conversation-sourced, not
  repo-sourced): can an authorization be replayed, copied, delegated,
  amplified, reused against another effect, or reconstructed outside its
  intended authority?

  Each property gets a constructive attack (expect a NAMED refusal) plus a
  negative control proving the legitimate path still executes. These tests are
  the protocol fixed in the Step-5 artifact, section 6, executed against the
  S01 path only; gateway/migrated-D/council-path evaluations remain open.
  """

  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.EventStore
  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.GovernedEffectSink
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity
  alias Tiannara.Omega.MintRegistry

  setup do
    unless Process.whereis(EventStore), do: start_supervised!(EventStore)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)

    {:ok, identity} =
      AuthenticatedHumanIdentity.authenticate(:human_d127, "d127-credential", :password)

    descriptor =
      GovernedEffectSink.effect_descriptor(
        "human_d127",
        %{"sink" => "governed_effect_store", "topic" => "governed.effect"},
        %{"request" => "d127_attack", "nonce" => "case-#{System.unique_integer([:monotonic, :positive])}"}
      )

    %{identity: identity, descriptor: descriptor}
  end

  defp mint_bound(identity, descriptor) do
    {:ok, auth} =
      Authorization.prepare(%{explanation_id: "expl-d127-#{System.unique_integer([:monotonic])}"})

    {:ok, pending} = Authorization.request(auth)
    {:ok, grant} = Authorization.human_grant(pending, identity, [])
    :ok = Authorization.record_mint(grant.authorization_id)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)
    :ok = MintRegistry.record_bind(bound.authorization_id, bound.effect_id)
    {:ok, bound}
  end

  defp events_for(authorization_id) do
    GovernedEffectSink.topic()
    |> EventStore.read_topic()
    |> Enum.filter(fn {_o, event, _ts} ->
      is_map(event) and Map.get(event, :authorization_id) == authorization_id
    end)
  end

  # ------------------------------------------------- D127.1 REPLAYED -------

  test "D127.1 REPLAY: a consumed authorization cannot re-authorize its effect",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    assert {:ok, result} =
             GovernedEffectSink.execute(bound, descriptor, identity: identity)

    assert result.governed == true

    assert {:error, :already_consumed} =
             GovernedEffectSink.execute(bound, descriptor, identity: identity)

    # exactly one sink event and one audit record for this authorization
    assert length(events_for(bound.authorization_id)) == 1
    assert MintRegistry.status(bound.authorization_id) == :consumed
  end

  # ---------------------------------------------------- D127.2 COPIED ------

  test "D127.2 COPY: a duplicate presentation of a consumed grant is refused",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    assert {:ok, _} = GovernedEffectSink.execute(bound, descriptor, identity: identity)

    copy = %{bound | lineage: bound.lineage ++ [:copied]}
    assert {:error, :already_consumed} =
             GovernedEffectSink.execute(copy, descriptor, identity: identity)

    assert length(events_for(bound.authorization_id)) == 1
  end

  test "D127.2 COPY (concurrent): of N simultaneous presentations exactly one executes",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    results =
      1..4
      |> Enum.map(fn _ ->
        Task.async(fn -> GovernedEffectSink.execute(bound, descriptor, identity: identity) end)
      end)
      |> Task.await_many(:timer.seconds(20))

    successes = Enum.count(results, &match?({:ok, _}, &1))
    refusals = Enum.count(results, &match?({:error, :already_consumed}, &1))

    assert successes == 1, "expected exactly one execution, got #{successes}"
    assert refusals == 3, "expected three refusals, got #{refusals}"
    assert length(events_for(bound.authorization_id)) == 1
  end

  # ----------------------------------------------- D127.3 DELEGATED ---------

  test "D127.3 DELEGATION: a grant minted for human A cannot execute under identity B",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    {:ok, other_identity} =
      AuthenticatedHumanIdentity.authenticate(:human_d127_other, "other-credential", :password)

    assert {:error, :identity_human_mismatch} =
             GovernedEffectSink.execute(bound, descriptor, identity: other_identity)

    # a structurally plausible but unauthenticated identity is also refused
    unauthenticated = %AuthenticatedHumanIdentity{
      identity_id: :ident_d127_forged,
      human_id: identity.human_id,
      authenticated_at: nil,
      method: :forged
    }

    assert {:error, :identity_not_authenticated} =
             GovernedEffectSink.execute(bound, descriptor, identity: unauthenticated)

    # neither refusal consumed the grant: the legitimate holder still executes
    assert MintRegistry.status(bound.authorization_id) == :granted
    assert {:ok, _} = GovernedEffectSink.execute(bound, descriptor, identity: identity)
  end

  # ----------------------------------------------- D127.4 AMPLIFIED ---------

  test "D127.4 AMPLIFICATION: a grant bound to a narrow effect cannot authorize a broader one",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    broadened = %{
      descriptor
      | parameters: Map.put(descriptor.parameters, "scope", "all_sinks")
    }

    {:ok, broadened_id} = EffectIdentity.effect_id(broadened)
    refute broadened_id == bound.effect_id

    assert {:error, :effect_id_mismatch} =
             GovernedEffectSink.execute(bound, broadened, identity: identity)

    # the attempt never consumed the grant and never wrote an event
    assert MintRegistry.status(bound.authorization_id) == :granted
    assert events_for(bound.authorization_id) == []
  end

  # -------------------------------------- D127.5 OTHER-EFFECT REUSE ---------

  test "D127.5 OTHER-EFFECT: a bound grant cannot be rebound or used for effect B",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    descriptor_b =
      GovernedEffectSink.effect_descriptor(
        "human_d127",
        %{"sink" => "governed_effect_store", "topic" => "governed.effect"},
        %{"request" => "d127_attack", "nonce" => "other-effect"}
      )

    # one-shot binding: B can never be named
    assert {:error, {:already_bound, _}} = Authorization.bind_effect(bound, descriptor_b)

    # a struct whose effect_id is rewritten to B still disagrees with the
    # registry-recorded binding and is refused
    {:ok, effect_b} = EffectIdentity.effect_id(descriptor_b)
    forged_for_b = %{bound | effect_id: effect_b}

    assert {:error, :registry_binding_mismatch} =
             GovernedEffectSink.execute(forged_for_b, descriptor_b, identity: identity)

    assert MintRegistry.status(bound.authorization_id) == :granted
    assert events_for(bound.authorization_id) == []
  end

  # ------------------------------- D127.6 RECONSTRUCTED-OUTSIDE-AUTHORITY ---

  test "D127.6 RECONSTRUCTION: a structurally valid grant that was never minted is refused",
       %{identity: identity, descriptor: descriptor} do
    {:ok, effect_id} = EffectIdentity.effect_id(descriptor)

    # A complete, internally consistent grant: correct status, matching human,
    # valid expiry window, correct bound effect — but never registered by any
    # minting path. Struct-shape trust must not admit it.
    forged = %Authorization{
      authorization_id: :"auth-forged-#{System.unique_integer([:monotonic])}",
      explanation_id: "expl-forged",
      human_id: identity.human_id,
      granted_at: System.system_time(:second),
      ttl: 3600,
      effect_id: effect_id,
      decision: :granted,
      lineage: [],
      status: :granted
    }

    assert {:error, :authorization_not_registered} =
             GovernedEffectSink.execute(forged, descriptor, identity: identity)

    assert events_for(forged.authorization_id) == []
    assert MintRegistry.status(forged.authorization_id) == :not_registered
  end

  # ---------------------------------------------- fail-closed registry ------

  test "the registry refuses a second registration of the same authorization_id",
       %{identity: identity} do
    {:ok, auth} =
      Authorization.prepare(%{explanation_id: "expl-dup-#{System.unique_integer([:monotonic])}"})

    {:ok, pending} = Authorization.request(auth)
    {:ok, grant} = Authorization.human_grant(pending, identity, [])

    :ok = Authorization.record_mint(grant.authorization_id)

    assert {:error, {:already_registered, _}} =
             Authorization.record_mint(grant.authorization_id)
  end

  test "registry unavailable refuses governed execution (fail-closed, never permissive)",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    # Works whether the registry was started by the setup block or owned by
    # the application supervisor: temporarily unregister the name so the
    # client sees `:registry_unavailable`, then restore it.
    registry_pid = Process.whereis(MintRegistry)
    assert is_pid(registry_pid)
    Process.unregister(MintRegistry)

    try do
      assert {:error, :authorization_registry_unavailable} =
               GovernedEffectSink.execute(bound, descriptor, identity: identity)

      assert events_for(bound.authorization_id) == []
    after
      Process.register(registry_pid, MintRegistry)
    end
  end

  # ---------------------------------------------- negative control -----------

  test "negative control: the legitimate minted path still executes under the registry",
       %{identity: identity, descriptor: descriptor} do
    {:ok, bound} = mint_bound(identity, descriptor)

    assert {:ok, result} =
             GovernedEffectSink.execute(bound, descriptor, identity: identity)

    assert result.governed == true
    assert result.effect_id == bound.effect_id
    assert MintRegistry.status(bound.authorization_id) == :consumed
    assert length(events_for(bound.authorization_id)) == 1
  end
end
