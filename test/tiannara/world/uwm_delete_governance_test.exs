defmodule Tiannara.World.UwmDeleteGovernanceTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, Authorization, MachineAuthorization}
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}
  alias Tiannara.World.UnifiedWorldModel
  import Tiannara.Test.Phase3Helpers

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  defp create_entity(tag) do
    spec = build_entity_spec(:knowledge, :fact, :governance, %{tag: tag}, id: unique_id("gov"))
    {:ok, id} = UnifiedWorldModel.create_entity(spec)
    id
  end

  defp council_decision(mutation_type) do
    Council.authorize(
      :world_mutation,
      %{
        mutation_type: mutation_type,
        mutation_spec: %{id: "governance_target"},
        context: nil,
        evidence: [%{source: :uwm_governance_test}],
        actor: :uwm_governance_test,
        coherent_with_mission: true,
        degradation_handled: true
      },
      nil
    )
  end

  defp mint_for(entity_id, opts \\ []) do
    mutation_type = Keyword.get(opts, :mutation_type, :delete_entity)
    decision_type = Keyword.get(opts, :decision_type, :delete_entity)
    ttl = Keyword.get(opts, :ttl, 3600)

    decision = council_decision(mutation_type)

    {:ok, authorization} =
      MachineAuthorization.mint(decision, decision_type: decision_type, ttl: ttl)

    {:ok, bound} =
      MachineAuthorization.bind_effect(
        authorization,
        UnifiedWorldModel.effect_descriptor(entity_id)
      )

    bound
  end

  describe "G1 authorization present" do
    test "nil authorization is refused before any read or write" do
      id = create_entity("g1")
      assert UnifiedWorldModel.delete_entity(id, nil) == {:error, :authorization_required}
      assert_entity_exists(id)
    end

    test "plain map masquerading as an authorization is refused" do
      id = create_entity("g1b")

      assert UnifiedWorldModel.delete_entity(id, %{authorization_id: :forged, status: :granted}) ==
               {:error, :invalid_authorization}

      assert_entity_exists(id)
    end
  end

  describe "G2 registry-verified status (M7)" do
    test "structurally valid but unminted authorization -> :authorization_not_registered" do
      id = create_entity("g2")
      real = mint_for(id)
      forged_id = :"mauth-forged-#{System.unique_integer([:monotonic])}"
      forged = %MachineAuthorization{real | authorization_id: forged_id}

      assert UnifiedWorldModel.delete_entity(id, forged) ==
               {:error, :authorization_not_registered}

      assert_entity_exists(id)
    end

    test "consumed authorization cannot be replayed" do
      id = create_entity("g2b")
      auth = mint_for(id)
      assert {:ok, _result} = UnifiedWorldModel.delete_entity(id, auth)
      assert UnifiedWorldModel.delete_entity(id, auth) == {:error, :already_consumed}
    end
  end

  describe "G3 sink-side expiry (M4)" do
    test "expired machine decision -> :authorization_expired without consumption" do
      id = create_entity("g3")
      auth = mint_for(id, ttl: -1)
      assert MachineAuthorization.expired?(auth)

      assert UnifiedWorldModel.delete_entity(id, auth) ==
               {:error, :authorization_expired}

      assert MintRegistry.status(auth.authorization_id) == :granted
      assert_entity_exists(id)
    end
  end

  describe "G4 machine authority verification" do
    test "authorization minted for another operation class -> :decision_type_mismatch" do
      id = create_entity("g4")
      auth = mint_for(id, mutation_type: :update_entity, decision_type: :update_entity)

      assert UnifiedWorldModel.delete_entity(id, auth) ==
               {:error, :decision_type_mismatch}

      assert_entity_exists(id)
    end

    test "rewritten decision payload -> :decision_tampered" do
      id = create_entity("g4b")
      auth = mint_for(id)
      tampered = %MachineAuthorization{auth | decision: %Authorization{auth.decision | policy_applied: :forged_policy}}

      assert UnifiedWorldModel.delete_entity(id, tampered) ==
               {:error, :decision_tampered}

      assert_entity_exists(id)
    end

    test "mint refuses a non-permitted council decision" do
      rejected =
        Authorization.rejected(explanation: "test rejection", policy_applied: :test_policy)

      assert MachineAuthorization.mint(rejected, decision_type: :delete_entity) ==
               {:error, :decision_not_permitted}
    end
  end

  describe "G5 one-shot binding (M3)" do
    test "unbound authorization -> :effect_binding_required" do
      id = create_entity("g5")
      {:ok, unbound} = MachineAuthorization.mint(council_decision(:delete_entity), decision_type: :delete_entity)

      assert UnifiedWorldModel.delete_entity(id, unbound) ==
               {:error, :effect_binding_required}

      assert_entity_exists(id)
    end

    test "authorization bound to another entity -> :effect_id_mismatch" do
      id_x = create_entity("g5x")
      id_y = create_entity("g5y")
      auth_x = mint_for(id_x)

      assert UnifiedWorldModel.delete_entity(id_y, auth_x) ==
               {:error, :effect_id_mismatch}

      assert_entity_exists(id_x)
      assert_entity_exists(id_y)
    end

    test "struct effect_id rewritten to the target's identity -> :registry_binding_mismatch" do
      id_x = create_entity("g5r")
      id_y = create_entity("g5w")
      auth_x = mint_for(id_x)
      {:ok, effect_y} = EffectIdentity.effect_id(UnifiedWorldModel.effect_descriptor(id_y))
      rewritten = %MachineAuthorization{auth_x | effect_id: effect_y}

      assert UnifiedWorldModel.delete_entity(id_y, rewritten) ==
               {:error, :registry_binding_mismatch}

      assert_entity_exists(id_y)
    end

    test "rebinding a bound authorization is refused" do
      id_x = create_entity("g5b1")
      id_y = create_entity("g5b2")
      auth_x = mint_for(id_x)

      assert {:error, {:already_bound, _existing}} =
               MachineAuthorization.bind_effect(
                 auth_x,
                 UnifiedWorldModel.effect_descriptor(id_y)
               )
    end
  end

  describe "G6 atomic consumption (M4)" do
    test "missing entity is refused without burning the authorization" do
      ghost = unique_id("ghost")
      auth = mint_for(ghost)

      assert UnifiedWorldModel.delete_entity(ghost, auth) == {:error, :not_found}
      assert MintRegistry.status(auth.authorization_id) == :granted

      spec = build_entity_spec(:knowledge, :fact, :governance, %{ghost: true}, id: ghost)
      assert {:ok, ^ghost} = UnifiedWorldModel.create_entity(spec)
      assert {:ok, _result} = UnifiedWorldModel.delete_entity(ghost, auth)
      assert MintRegistry.status(auth.authorization_id) == :consumed
    end

    test "M6(3): a second distinct authorization for an executed effect is refused" do
      id = create_entity("m63")
      auth_one = mint_for(id)
      assert {:ok, _result} = UnifiedWorldModel.delete_entity(id, auth_one)

      auth_two = mint_for(id)

      assert UnifiedWorldModel.delete_entity(id, auth_two) ==
               {:error, :effect_already_executed}

      assert MintRegistry.status(auth_two.authorization_id) == :granted
    end
  end

  describe "G7 governed success identity (M8)" do
    test "success carries the grant identities and a hash-chained audit edge" do
      id = create_entity("g7")
      auth = mint_for(id)

      assert {:ok, result} = UnifiedWorldModel.delete_entity(id, auth)
      assert result.entity_id == id
      assert result.effect_id == auth.effect_id
      assert result.authorization_id == auth.authorization_id
      assert MintRegistry.status(auth.authorization_id) == :consumed
      refute_entity_exists(id)

      entry =
        AuditLog.recent(100)
        |> Enum.find(fn e ->
          e.action == :world_entity_deleted and
            Map.get(e.payload, :authorization_id) == auth.authorization_id
        end)

      assert entry, "expected a :world_entity_deleted audit edge"
      assert entry.payload.effect_id == auth.effect_id
      assert entry.payload.entity_id == to_string(id)
      assert entry.payload.sink == :unified_world_model
      assert :ok = AuditLog.verify_integrity
    end
  end

  describe "effect descriptor (M1)" do
    test "identity is deterministic and derived from effect semantics only" do
      id = create_entity("m1")
      descriptor = UnifiedWorldModel.effect_descriptor(id)

      assert {:ok, effect_id} = EffectIdentity.effect_id(descriptor)
      assert {:ok, same} = EffectIdentity.effect_id(UnifiedWorldModel.effect_descriptor(id))
      assert effect_id == same
      assert String.starts_with?(effect_id, "effect-v1-")

      assert {:ok, other} =
               EffectIdentity.effect_id(%{descriptor | operation: "update_entity"})

      refute effect_id == other

      assert {:error, _unknown_field} =
               EffectIdentity.effect_id(Map.put(descriptor, :bogus, 1))
    end
  end
end
