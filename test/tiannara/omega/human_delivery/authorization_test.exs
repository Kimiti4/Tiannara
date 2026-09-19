defmodule Tiannara.Omega.HumanDelivery.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.HumanDelivery.Authorization

  defp descriptor(overrides \\ %{}) do
    base = %{
      principal: "human:alice",
      authority_scope: "candidate:deploy",
      operation: "deploy",
      target: %{type: "candidate", id: "candidate-1"},
      parameters: %{mode: "production"},
      environment: %{region: "ke-1"},
      intent: "deploy the certified candidate",
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }

    Map.merge(base, Map.new(overrides))
  end

  defp pending_auth(explanation_id) do
    {:ok, auth} = Authorization.prepare(%{explanation_id: explanation_id})
    {:ok, pending} = Authorization.request(auth)
    pending
  end

  defp grant_for(effect_descriptor) do
    {:ok, grant} =
      Authorization.human_grant(
        pending_auth(:expl_1),
        :human_alice,
        effect_descriptor: effect_descriptor
      )

    grant
  end

  test "authorization bound to an effect is valid for that exact effect" do
    effect = descriptor()
    {:ok, effect_id} = EffectIdentity.effect_id(effect)
    grant = grant_for(effect)

    assert grant.effect_id == effect_id
    assert Authorization.valid_for_effect?(grant, effect)

    assert Authorization.valid_for_effect?(
             grant,
             descriptor(intent: "deploy the certified candidate")
           )
  end

  test "authorization for one effect is not valid for a different effect" do
    grant = grant_for(descriptor())

    refute Authorization.valid_for_effect?(grant, descriptor(operation: "rollback"))

    refute Authorization.valid_for_effect?(
             grant,
             descriptor(target: %{type: "candidate", id: "candidate-2"})
           )

    refute Authorization.valid_for_effect?(grant, descriptor(environment: %{region: "eu-1"}))
  end

  test "effect mismatch is not rescued by an explanation match" do
    {:ok, grant} =
      Authorization.human_grant(
        pending_auth(:expl_same),
        :human_alice,
        effect_descriptor: descriptor()
      )

    same_explanation_different_effect =
      descriptor(%{intent: "roll back the certified candidate", operation: "rollback"})

    assert Authorization.valid_for?(grant, :expl_same)
    refute Authorization.valid_for_effect?(grant, same_explanation_different_effect)
  end

  test "a grant that names no effect can never authorize a specific effect" do
    {:ok, grant} = Authorization.human_grant(pending_auth(:expl_1), :human_alice)

    refute Authorization.valid_for_effect?(grant, descriptor())
  end

  test "a pending or denied authorization cannot authorize any effect" do
    pending = pending_auth(:expl_1)
    {:ok, denied} = Authorization.human_deny(pending, "insufficient verification")

    refute Authorization.valid_for_effect?(pending, descriptor())
    refute Authorization.valid_for_effect?(denied, descriptor())
  end

  test "an expired grant cannot authorize any effect" do
    {:ok, grant} =
      Authorization.human_grant(
        pending_auth(:expl_1),
        :human_alice,
        ttl: -3600,
        effect_descriptor: descriptor()
      )

    {:ok, expired} = Authorization.expire(grant)
    refute Authorization.valid_for_effect?(expired, descriptor())
  end

  test "a grant cannot be minted for an invalid effect descriptor" do
    assert {:error, {:invalid_effect_descriptor, {:missing_fields, missing}}} =
             Authorization.human_grant(
               pending_auth(:expl_1),
               :human_alice,
               effect_descriptor: %{operation: "deploy"}
             )

    assert "intent" in missing
    assert "principal" in missing
  end

  test "a grant cannot be minted for a malformed effect descriptor" do
    assert {:error, {:invalid_effect_descriptor, :descriptor_must_be_a_map}} =
             Authorization.human_grant(
               pending_auth(:expl_1),
               :human_alice,
               effect_descriptor: "not-a-descriptor"
             )
  end

  test "binding does not break the existing grant contract" do
    effect = descriptor()

    {:ok, unbound} = Authorization.human_grant(pending_auth(:expl_1), :human_alice)

    {:ok, bound} =
      Authorization.human_grant(pending_auth(:expl_1), :human_alice, effect_descriptor: effect)

    assert unbound.status == :granted
    assert unbound.effect_id == nil
    assert bound.status == :granted
    assert is_binary(bound.effect_id)
    assert Authorization.valid_for?(bound, :expl_1)
  end
end
