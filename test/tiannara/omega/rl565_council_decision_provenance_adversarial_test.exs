defmodule Tiannara.Omega.RL565CouncilDecisionProvenanceAdversarialTest do
  @moduledoc """
  CP19.18 adversarial regression for RL-565 (Council decision provenance).

  `MachineAuthorization.mint/2` currently treats a caller-constructed
  `Council.Authorization` struct as proof that Council issued the decision.
  `UnifiedWorldModel.delete_entity/2` then accepts the resulting registered,
  effect-bound machine grant. These tests assert the safe contract: a machine
  mint and the delete boundary require a Council-issued decision proof. On the
  pinned source (`de231a78`) the fabricated path succeeds, so the non-control
  cases below are the expected red baseline.

  The controls preserve behavior that already works: wrong operation, other
  target, one-shot replay/concurrency, and genuine Council issuance.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, Authorization, MachineAuthorization}
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.World.UnifiedWorldModel
  import Tiannara.Test.Phase3Helpers

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  defp fabricated_decision do
    Authorization.approved(
      explanation: "RL-565 fabricated approval",
      policy_applied: :fabricated_policy,
      metadata: %{source: :rl565_adversarial}
    )
  end

  defp reconstructed_decision do
    %Authorization{
      decision: :approved,
      confidence: 1.0,
      constitutional_score: 1.0,
      violated_principles: [],
      required_human_review: false,
      explanation: "RL-565 manually reconstructed approval",
      evidence: [],
      risks: [],
      simulation_results: [],
      recommendation: nil,
      context: nil,
      decided_at: DateTime.utc_now(),
      policy_applied: :manual_policy,
      metadata: %{source: :manual_reconstruction},
      conditions: []
    }
  end

  defp genuine_decision(mutation_type) do
    Council.authorize(
      :world_mutation,
      %{
        mutation_type: mutation_type,
        mutation_spec: %{id: "rl565_target"},
        context: nil,
        evidence: [%{source: :rl565_adversarial}],
        actor: :rl565_adversarial,
        coherent_with_mission: true,
        degradation_handled: true
      },
      nil
    )
  end

  defp create_entity(tag) do
    spec = build_entity_spec(:knowledge, :fact, :rl565, %{tag: tag}, id: unique_id("rl565"))
    {:ok, id} = UnifiedWorldModel.create_entity(spec)
    id
  end

  defp assert_proof_required(result) do
    assert result == {:error, :council_decision_proof_required}
  end

  describe "RL-565 fabricated Council decisions" do
    test "R565-01: a public Authorization.approved/1 struct is not Council authority" do
      assert_proof_required(
        MachineAuthorization.mint(fabricated_decision(),
          decision_type: :delete_entity,
          ttl: 3600
        )
      )
    end

    test "R565-02: a manually reconstructed approved decision has no Council provenance" do
      assert_proof_required(
        MachineAuthorization.mint(reconstructed_decision(),
          decision_type: :delete_entity,
          ttl: 3600
        )
      )
    end

    test "R565-03: fabricated mint -> bind -> delete cannot remove a real entity" do
      entity_id = create_entity("chain")

      result =
        case MachineAuthorization.mint(fabricated_decision(),
               decision_type: :delete_entity,
               ttl: 3600
             ) do
          {:error, reason} ->
            {:error, reason}

          {:ok, grant} ->
            {:ok, bound} =
              MachineAuthorization.bind_effect(
                grant,
                UnifiedWorldModel.effect_descriptor(entity_id)
              )

            UnifiedWorldModel.delete_entity(entity_id, bound)
        end

      assert_proof_required(result)
      assert_entity_exists(entity_id)
    end

    test "R565-04: an altered decision cannot reuse genuine Council provenance" do
      genuine = genuine_decision(:delete_entity)
      assert genuine.decision in [:approved, :conditional]

      altered = %{
        genuine
        | policy_applied: :substituted_policy,
          explanation: "RL-565 substituted decision payload"
      }

      assert_proof_required(
        MachineAuthorization.mint(altered, decision_type: :delete_entity, ttl: 3600)
      )
    end

    test "R565-05 control: a delete authorization cannot authorize an update" do
      {:ok, grant} =
        MachineAuthorization.mint(genuine_decision(:update_entity),
          decision_type: :update_entity,
          ttl: 3600
        )

      entity_id = unique_id("rl565-wrong-operation")

      {:ok, bound} =
        MachineAuthorization.bind_effect(grant, UnifiedWorldModel.effect_descriptor(entity_id))

      assert {:error, :decision_type_mismatch} =
               UnifiedWorldModel.delete_entity(entity_id, bound)
    end

    test "R565-06 control: an authorization for entity A cannot delete entity B" do
      id_a = create_entity("other-a")
      id_b = create_entity("other-b")

      {:ok, grant} =
        MachineAuthorization.mint(genuine_decision(:delete_entity),
          decision_type: :delete_entity,
          ttl: 3600
        )

      {:ok, bound} =
        MachineAuthorization.bind_effect(grant, UnifiedWorldModel.effect_descriptor(id_a))

      assert {:error, :effect_id_mismatch} = UnifiedWorldModel.delete_entity(id_b, bound)
      assert_entity_exists(id_a)
      assert_entity_exists(id_b)
    end

    test "R565-07 control: concurrent replay of one genuine grant deletes once" do
      entity_id = create_entity("replay")

      {:ok, grant} =
        MachineAuthorization.mint(genuine_decision(:delete_entity),
          decision_type: :delete_entity,
          ttl: 3600
        )

      {:ok, bound} =
        MachineAuthorization.bind_effect(grant, UnifiedWorldModel.effect_descriptor(entity_id))

      results =
        1..4
        |> Enum.map(fn _ ->
          Task.async(fn -> UnifiedWorldModel.delete_entity(entity_id, bound) end)
        end)
        |> Task.await_many(10_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1

      assert Enum.all?(Enum.reject(results, &match?({:ok, _}, &1)), fn
               {:error, :already_consumed} -> true
               _ -> false
             end)

      refute_entity_exists(entity_id)
      assert MintRegistry.status(bound.authorization_id) == :consumed
    end

    test "R565-08: an active Council emergency blocks new machine minting" do
      :ok = Council.invoke_emergency(:rl565_test, "RL-565 emergency regression")
      on_exit(fn -> Council.lift_emergency(:rl565_test) end)

      result =
        MachineAuthorization.mint(fabricated_decision(),
          decision_type: :delete_entity,
          ttl: 3600
        )

      assert match?({:error, _reason}, result)
    end

    test "control: a genuine Council decision still mints and binds" do
      decision = genuine_decision(:delete_entity)
      assert decision.decision in [:approved, :conditional]

      assert {:ok, grant} =
               MachineAuthorization.mint(decision, decision_type: :delete_entity, ttl: 3600)

      assert is_binary(grant.council_decision_ref)

      entity_id = unique_id("rl565-genuine-control")

      assert {:ok, bound} =
               MachineAuthorization.bind_effect(
                 grant,
                 UnifiedWorldModel.effect_descriptor(entity_id)
               )

      assert is_binary(bound.effect_id)
    end
  end
end
