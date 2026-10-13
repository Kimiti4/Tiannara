defmodule Tiannara.World.D127UwmDeleteEvaluationTest do
  @moduledoc """
  D127 evaluation protocol (Step-5 §6) executed against the migrated class-D
  path: `UnifiedWorldModel.delete_entity/2` under the universal G1-G7 sink
  contract (Step-5 §8 row S09).

  Each property runs a constructive attack that MUST be refused with a named
  error atom, plus negative controls. D127 remains OPEN after this path: the
  machine-class (council) minimum path is still unevaluated.
  """

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
    spec = build_entity_spec(:knowledge, :fact, :d127, %{tag: tag}, id: unique_id("d127"))
    {:ok, id} = UnifiedWorldModel.create_entity(spec)
    id
  end

  defp council_decision(mutation_type) do
    Council.authorize(
      :world_mutation,
      %{
        mutation_type: mutation_type,
        mutation_spec: %{id: "d127_target"},
        context: nil,
        evidence: [%{source: :d127_uwm_evaluation}],
        actor: :d127_uwm_evaluation,
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

  defp audit_edge(authorization_id) do
    AuditLog.recent(300)
    |> Enum.find(fn entry ->
      entry.action == :world_entity_deleted and
        is_map(entry.payload) and
        Map.get(entry.payload, :authorization_id) == authorization_id
    end)
  end

  describe "D127 protocol rows against the S09 class-D path" do
    test "D127.1 replay: consumed authorization re-presented -> :already_consumed" do
      id = create_entity("d1")
      auth = mint_for(id)

      assert {:ok, _result} = UnifiedWorldModel.delete_entity(id, auth)

      assert UnifiedWorldModel.delete_entity(id, auth) ==
               {:error, :already_consumed}

      assert MintRegistry.status(auth.authorization_id) == :consumed
      refute_entity_exists(id)
    end

    test "D127.2 copy: duplicated authorization raced -> exactly one execution" do
      id = create_entity("d2")
      auth = mint_for(id)

      tasks =
        for _ <- 1..4 do
          Task.async(fn -> UnifiedWorldModel.delete_entity(id, auth) end)
        end

      results = Task.await_many(tasks, 10_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1
      assert Enum.count(results, &(&1 == {:error, :already_consumed})) == 3
      assert MintRegistry.status(auth.authorization_id) == :consumed
      refute_entity_exists(id)
    end

    test "D127.3 delegation: authorization minted for another operation class -> :decision_type_mismatch" do
      id = create_entity("d3")
      delegated = mint_for(id, mutation_type: :update_entity, decision_type: :update_entity)

      assert UnifiedWorldModel.delete_entity(id, delegated) ==
               {:error, :decision_type_mismatch}

      assert_entity_exists(id)

      control = create_entity("d3c")
      control_auth = mint_for(control)
      assert {:ok, _result} = UnifiedWorldModel.delete_entity(control, control_auth)
    end

    test "D127.4 amplification: widened validity, un-expiry, or rewritten decision -> :decision_tampered" do
      id = create_entity("d4")
      auth = mint_for(id)
      expired = mint_for(id, ttl: -1)

      widened = %MachineAuthorization{auth | ttl: 999_999}

      assert UnifiedWorldModel.delete_entity(id, widened) ==
               {:error, :decision_tampered}

      unexpiring = %MachineAuthorization{expired | granted_at: DateTime.add(expired.granted_at, 7_200)}

      assert UnifiedWorldModel.delete_entity(id, unexpiring) ==
               {:error, :decision_tampered}

      rewritten = %MachineAuthorization{auth | decision: %Authorization{auth.decision | policy_applied: :forged_policy}}

      assert UnifiedWorldModel.delete_entity(id, rewritten) ==
               {:error, :decision_tampered}

      assert UnifiedWorldModel.delete_entity(id, expired) ==
               {:error, :authorization_expired}

      assert_entity_exists(id)
    end

    test "D127.5 other-effect: binding does not transfer to a different target" do
      id_x = create_entity("d5x")
      id_y = create_entity("d5y")
      auth_x = mint_for(id_x)

      assert UnifiedWorldModel.delete_entity(id_y, auth_x) ==
               {:error, :effect_id_mismatch}

      assert {:error, {:already_bound, _existing}} =
               MachineAuthorization.bind_effect(
                 auth_x,
                 UnifiedWorldModel.effect_descriptor(id_y)
               )

      {:ok, effect_y} = EffectIdentity.effect_id(UnifiedWorldModel.effect_descriptor(id_y))
      rewritten = %MachineAuthorization{auth_x | effect_id: effect_y}

      assert UnifiedWorldModel.delete_entity(id_y, rewritten) ==
               {:error, :registry_binding_mismatch}

      assert_entity_exists(id_x)
      assert_entity_exists(id_y)
    end

    test "D127.6 reconstruction: structurally perfect, never-minted authorization -> :authorization_not_registered" do
      id = create_entity("d6")
      real = mint_for(id)

      forged_id = :"mauth-reconstructed-#{System.unique_integer([:monotonic])}"
      forged = %MachineAuthorization{real | authorization_id: forged_id}

      assert UnifiedWorldModel.delete_entity(id, forged) ==
               {:error, :authorization_not_registered}

      assert_entity_exists(id)

      assert {:ok, _result} = UnifiedWorldModel.delete_entity(id, real)
    end
  end

  describe "fail-closed extras" do
    test "registry unavailable -> :authorization_registry_unavailable with no write" do
      id = create_entity("x1")
      auth = mint_for(id)
      pid = Process.whereis(MintRegistry)
      Process.unregister(MintRegistry)

      result =
        try do
          UnifiedWorldModel.delete_entity(id, auth)
        after
          Process.register(pid, MintRegistry)
        end

      assert result == {:error, :authorization_registry_unavailable}
      assert_entity_exists(id)
      assert MintRegistry.status(auth.authorization_id) == :granted
    end

    test "audit append failure fails the claim after the write and burns the authorization (N7)" do
      id = create_entity("x2")
      auth = mint_for(id)
      pid = Process.whereis(AuditLog)
      Process.unregister(AuditLog)

      result =
        try do
          UnifiedWorldModel.delete_entity(id, auth)
        after
          Process.register(pid, AuditLog)
        end

      assert {:error, {:audit_not_recorded, _reason, detail}} = result
      assert detail.deleted == true
      assert detail.authorization_id == auth.authorization_id
      refute_entity_exists(id)
      assert MintRegistry.status(auth.authorization_id) == :consumed
    end
  end

  describe "negative control" do
    test "legitimate governed delete executes with five-way identity equality (I7)" do
      id = create_entity("ctrl")
      auth = mint_for(id)

      assert {:ok, result} = UnifiedWorldModel.delete_entity(id, auth)

      {:ok, recomputed} = EffectIdentity.effect_id(UnifiedWorldModel.effect_descriptor(id))
      assert result.effect_id == recomputed
      assert result.effect_id == auth.effect_id
      assert {:ok, registry_effect} = MintRegistry.binding(auth.authorization_id)
      assert registry_effect == auth.effect_id

      assert MintRegistry.status(auth.authorization_id) == :consumed
      refute_entity_exists(id)

      entry = audit_edge(auth.authorization_id)
      assert entry, "expected a :world_entity_deleted audit edge"
      assert entry.payload.effect_id == auth.effect_id
      assert entry.payload.authorization_id == auth.authorization_id
      assert entry.payload.sink == :unified_world_model
      assert :ok = AuditLog.verify_integrity
    end
  end
end
