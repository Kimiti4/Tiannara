defmodule Tiannara.Omega.GovernedEffectSinkTest do
  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.EventStore
  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.GovernedEffectSink
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity

  setup do
    unless Process.whereis(EventStore), do: start_supervised!(EventStore)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)

    {:ok, identity} =
      AuthenticatedHumanIdentity.authenticate(:human_wave3, "wave3-credential", :password)

    descriptor =
      GovernedEffectSink.effect_descriptor(
        "human_wave3",
        %{"sink" => "governed_effect_store", "topic" => "governed.effect"},
        %{
          "request" => "wave3_step2",
          "nonce" => "case-#{System.unique_integer([:monotonic, :positive])}"
        }
      )

    %{identity: identity, descriptor: descriptor}
  end

  defp mint_grant(identity, opts \\ []) do
    {:ok, auth} =
      Authorization.prepare(%{explanation_id: "expl-#{System.unique_integer([:monotonic])}"})

    {:ok, pending} = Authorization.request(auth)

    case Authorization.human_grant(pending, identity, opts) do
      {:ok, grant} when is_struct(grant.human_id) ->
        {:ok, %{grant | human_id: identity.human_id}}

      other ->
        other
    end
  end

  defp sink_events_for(authorization_id) do
    GovernedEffectSink.topic()
    |> EventStore.read_topic()
    |> Enum.filter(fn {_o, event, _ts} ->
      is_map(event) and Map.get(event, :authorization_id) == authorization_id
    end)
    |> Enum.map(fn {_o, event, _ts} -> event end)
  end

  defp audit_entries_for(effect_id) do
    AuditLog.recent(300)
    |> Enum.filter(fn entry -> Map.get(entry.payload, :effect_id) == effect_id end)
  end

  test "positive: authorization -> effect -> sink -> observed result -> audit, one identity",
       %{identity: identity, descriptor: descriptor} do
    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)

    {:ok, bound_effect_id} = EffectIdentity.effect_id(descriptor)
    assert bound.effect_id == bound_effect_id
    assert String.starts_with?(bound.effect_id, "effect-v1-")

    {:ok, result} =
      GovernedEffectSink.execute(bound, descriptor,
        identity: identity,
        payload: %{"note" => "wave3 step2 positive"}
      )

    assert result.governed == true
    assert result.authorization_id == bound.authorization_id
    assert result.effect_id == bound.effect_id
    assert is_integer(result.audit.seq)
    assert is_binary(result.audit.hash)

    # executed effect identity: the event as STORED in the sink
    assert [stored_event] = sink_events_for(bound.authorization_id)
    assert stored_event.effect_id == bound.effect_id
    assert result.sink.effect_id == bound.effect_id
    assert result.sink.offset == stored_event.event_store_offset

    # audit/provenance effect identity
    assert [entry] = audit_entries_for(bound.effect_id)
    assert entry.payload.effect_id == bound.effect_id
    assert entry.payload.authorization_id == bound.authorization_id
    assert entry.payload.sink_offset == result.sink.offset
    assert entry.action == :governed_effect_executed
    assert entry.actor == :human_wave3

    # five-way identity cross-check under the canonical representation
    identities = [
      bound.effect_id,
      bound_effect_id,
      stored_event.effect_id,
      result.sink.effect_id,
      entry.payload.effect_id
    ]

    assert Enum.uniq(identities) == [bound.effect_id]
    assert EffectIdentity.verify(descriptor, entry.payload.effect_id) == :ok
  end

  test "N1 missing authorization fails closed and the sink does not execute",
       %{identity: identity, descriptor: descriptor} do
    before = length(EventStore.read_topic(GovernedEffectSink.topic()))

    assert {:error, :authorization_required} =
             GovernedEffectSink.execute(nil, descriptor, identity: identity)

    assert {:error, :authorization_required} =
             GovernedEffectSink.execute(%{status: :granted}, descriptor, identity: identity)

    assert length(EventStore.read_topic(GovernedEffectSink.topic())) == before
  end

  test "N2 authorization bound to effect A cannot execute effect B",
       %{identity: identity, descriptor: descriptor} do
    descriptor_b =
      GovernedEffectSink.effect_descriptor(
        "human_wave3",
        %{"sink" => "governed_effect_store", "topic" => "governed.effect"},
        %{"request" => "wave3_step2", "nonce" => "different-effect"}
      )

    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)

    assert {:error, :effect_id_mismatch} =
             GovernedEffectSink.execute(bound, descriptor_b, identity: identity)

    # the sink never executed: no event and no audit record for this authorization
    assert sink_events_for(bound.authorization_id) == []
    assert audit_entries_for(bound.effect_id) == []
  end

  test "N3 descriptor altered after binding fails closed",
       %{identity: identity, descriptor: descriptor} do
    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)

    altered = %{descriptor | parameters: Map.put(descriptor.parameters, "nonce", "tampered")}
    {:ok, altered_effect_id} = EffectIdentity.effect_id(altered)
    refute altered_effect_id == bound.effect_id

    assert {:error, :effect_id_mismatch} =
             GovernedEffectSink.execute(bound, altered, identity: identity)

    assert sink_events_for(bound.authorization_id) == []
    assert audit_entries_for(bound.effect_id) == []
  end

  test "N4 invalid authorizations fail closed (denied, expired, identity)",
       %{identity: identity, descriptor: descriptor} do
    topic_before = length(EventStore.read_topic(GovernedEffectSink.topic()))

    # denied authorization
    {:ok, auth} =
      Authorization.prepare(%{explanation_id: "expl-#{System.unique_integer([:monotonic])}"})

    {:ok, pending} = Authorization.request(auth)
    {:ok, denied} = Authorization.human_deny(pending, "wave3 negative case")

    assert {:error, :authorization_not_granted} =
             GovernedEffectSink.execute(denied, descriptor, identity: identity)

    # expired authorization (ttl already elapsed)
    {:ok, expired} = mint_grant(identity, ttl: -1)
    assert Authorization.expired?(expired)

    assert {:error, :authorization_expired} =
             GovernedEffectSink.execute(expired, descriptor, identity: identity)

    # bound grant, but the presenting identity is a different human
    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)
    {:ok, other_identity} =
      AuthenticatedHumanIdentity.authenticate(:human_other, "other-credential", :password)

    assert {:error, :identity_human_mismatch} =
             GovernedEffectSink.execute(bound, descriptor, identity: other_identity)

    # missing identity
    assert {:error, :identity_required} = GovernedEffectSink.execute(bound, descriptor)

    # unauthenticated identity (fails the existing validation)
    unauthenticated = %AuthenticatedHumanIdentity{
      identity_id: :ident_fake,
      human_id: :human_wave3,
      authenticated_at: nil,
      method: :forged
    }

    assert {:error, :identity_not_authenticated} =
             GovernedEffectSink.execute(bound, descriptor, identity: unauthenticated)

    assert sink_events_for(bound.authorization_id) == []
    assert audit_entries_for(bound.effect_id) == []
    assert length(EventStore.read_topic(GovernedEffectSink.topic())) == topic_before
  end

  test "N5 authorization without an effect binding fails closed; binding is one-shot",
       %{identity: identity, descriptor: descriptor} do
    {:ok, grant} = mint_grant(identity)
    assert is_nil(grant.effect_id)

    assert {:error, :effect_binding_required} =
             GovernedEffectSink.execute(grant, descriptor, identity: identity)

    {:ok, bound} = Authorization.bind_effect(grant, descriptor)
    assert {:error, {:already_bound, _}} = Authorization.bind_effect(bound, descriptor)
    assert {:error, :authorization_not_granted} =
             Authorization.bind_effect(%{grant | status: :pending_authorization}, descriptor)

    assert sink_events_for(bound.authorization_id) == []
    assert audit_entries_for(bound.effect_id) == []
  end

  test "N6 result identity mismatch cannot produce governed success",
       %{identity: identity, descriptor: descriptor} do
    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)

    wrong_id = "effect-v1-" <> String.duplicate("0", 64)

    wrong_sink = fn _effect_id, _event ->
      {:ok, %{topic: "governed.effect", offset: 1, effect_id: wrong_id, authorization_id: bound.authorization_id}}
    end

    assert {:error, :result_identity_mismatch} =
             GovernedEffectSink.execute(bound, descriptor, identity: identity, sink: wrong_sink)

    # a result that cannot be associated with the authorized effect at all
    unlinkable_sink = fn _effect_id, _event -> {:ok, %{topic: "governed.effect", offset: 2}} end

    assert {:error, :result_identity_mismatch} =
             GovernedEffectSink.execute(bound, descriptor, identity: identity, sink: unlinkable_sink)

    # no audit record was written for either rejected result
    assert audit_entries_for(bound.effect_id) == []
  end

  test "N7 audit/provenance failure does not produce governed success",
       %{identity: identity, descriptor: descriptor} do
    {:ok, grant} = mint_grant(identity)
    {:ok, bound} = Authorization.bind_effect(grant, descriptor)

    failing_audit = fn _payload -> {:error, :storage_degraded} end

    assert {:error, {:audit_not_recorded, :storage_degraded, detail}} =
             GovernedEffectSink.execute(bound, descriptor,
               identity: identity,
               audit: failing_audit
             )

    # the sink event WAS written, but the result is not a governed success
    assert detail.executed == true
    assert detail.governed == false
    assert [stored_event] = sink_events_for(bound.authorization_id)
    assert stored_event.effect_id == bound.effect_id
    assert audit_entries_for(bound.effect_id) == []
  end
end
