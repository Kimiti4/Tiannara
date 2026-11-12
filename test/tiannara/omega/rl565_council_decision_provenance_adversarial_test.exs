defmodule Tiannara.Omega.RL565CouncilDecisionProvenanceAdversarialTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, Authorization, DecisionReceipt, MachineAuthorization}
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

  defp genuine_decision(mutation_type, entity_id) do
    scope = %{operation: Atom.to_string(mutation_type), target: %{entity_id: entity_id}, effect_id: nil}

    {:ok, decision, receipt} =
      Council.decide(
        mutation_type,
        %{
          mutation_type: mutation_type,
          mutation_spec: %{id: entity_id},
          target: scope.target,
          scope: scope,
          context: nil,
          evidence: [%{source: :rl565_adversarial}],
          actor: :rl565_adversarial,
          coherent_with_mission: true,
          degradation_handled: true
        },
        nil
      )

    {decision, receipt, scope}
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
          {:error, reason} -> {:error, reason}
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
      entity_id = "rl565_alt_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      altered = %{decision | policy_applied: :substituted_policy, explanation: "RL-565 substituted decision payload"}

      assert {:error, :council_decision_digest_mismatch} =
               MachineAuthorization.mint(
                 altered,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert MintRegistry.receipt_status(receipt.receipt_id) == :issued
    end
  end

  describe "RL-565 positive controls" do
    test "R565-05 control: a delete authorization cannot authorize an update" do
      entity_id = "rl565_wrongop_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:update_entity, entity_id)

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :update_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert {:error, :council_scope_mismatch} =
               MachineAuthorization.bind_effect(
                 grant,
                 UnifiedWorldModel.effect_descriptor(unique_id("rl565-wrong-operation"))
               )

      assert MintRegistry.status(grant.authorization_id) == :granted
    end

    test "R565-06 control: an authorization for entity A cannot delete entity B" do
      id_a = create_entity("other-a")
      id_b = create_entity("other-b")

      {decision, receipt, _scope} = genuine_decision(:delete_entity, id_a)
      scope = %{operation: "delete_entity", target: %{entity_id: id_a}, effect_id: nil}

      # re-issue with exact scope/target
      {decision, receipt, scope} = genuine_decision(:delete_entity, id_a)
      scope = %{scope | target: %{entity_id: id_a}}

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      {:ok, bound} =
        MachineAuthorization.bind_effect(
          grant,
          UnifiedWorldModel.effect_descriptor(id_a)
        )

      assert {:error, :effect_id_mismatch} =
               UnifiedWorldModel.delete_entity(id_b, bound)

      assert_entity_exists(id_a)
      assert_entity_exists(id_b)
      assert MintRegistry.status(bound.authorization_id) == :granted
    end

    test "R565-07 control: concurrent replay of one genuine grant deletes once" do
      entity_id = create_entity("replay")

      {decision, receipt, _scope} = genuine_decision(:delete_entity, entity_id)
      scope = %{operation: "delete_entity", target: %{entity_id: entity_id}, effect_id: nil}

      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)
      scope = %{scope | target: %{entity_id: entity_id}}

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      {:ok, bound} =
        MachineAuthorization.bind_effect(
          grant,
          UnifiedWorldModel.effect_descriptor(entity_id)
        )

      results =
        1..4
        |> Enum.map(fn _ -> Task.async(fn -> UnifiedWorldModel.delete_entity(entity_id, bound) end) end)
        |> Task.await_many(10_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1

      assert Enum.all?(Enum.reject(results, &match?({:ok, _}, &1)), fn
               {:error, :already_consumed} -> true
               _ -> false
             end)

      refute_entity_exists(entity_id)
      assert MintRegistry.status(bound.authorization_id) == :consumed
    end

    test "R565-10: one receipt produces at most one machine grant" do
      entity_id = "rl565_once_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      assert {:ok, _grant1} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert {:error, :council_decision_receipt_consumed} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end

    test "control: a genuine Council decision still mints and binds" do
      entity_id = unique_id("rl565-genuine-control")
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      assert decision.decision in [:approved, :conditional]

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert is_binary(grant.council_decision_ref)
      assert MintRegistry.receipt_status(receipt.receipt_id) == :consumed

      assert {:ok, bound} =
               MachineAuthorization.bind_effect(
                 grant,
                 UnifiedWorldModel.effect_descriptor(entity_id)
               )

      assert is_binary(bound.effect_id)
    end
  end

  describe "RL-565 emergency enforcement" do
    test "R565-08d: Council process restart preserves active emergency" do
      :ok = Council.invoke_emergency(:rl565_test, "restart probe")
      on_exit(fn -> Council.lift_emergency(:rl565_test) end)

      # simulate process restart by terminating and restarting the Council child
      sup = Tiannara.Council.Supervisor
      :ok = Supervisor.terminate_child(sup, Tiannara.Council)
      {:ok, _} = Supervisor.restart_child(sup, Tiannara.Council)

      assert Council.emergency_state().active == true
      assert Tiannara.Council.EmergencyState.active?() == true
    end

    test "R565-08a: emergency blocks Council decision issuance" do
      :ok = Council.invoke_emergency(:rl565_test, "RL-565 emergency regression")
      on_exit(fn -> Council.lift_emergency(:rl565_test) end)

      assert {:error, :council_emergency_active} =
               Council.decide(
                 :delete_entity,
                 %{
                   mutation_type: :delete_entity,
                   mutation_spec: %{id: "emergency_target"},
                   target: %{entity_id: "emergency_target"},
                   scope: %{operation: "delete_entity", target: %{entity_id: "emergency_target"}, effect_id: nil},
                   evidence: [%{source: :rl565_adversarial}],
                   actor: :rl565_adversarial,
                   coherent_with_mission: true,
                   degradation_handled: true
                 },
                 nil
               )
    end

    test "R565-08b: emergency blocks machine mint even with a valid receipt" do
      entity_id = "rl565_emint_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      :ok = Council.invoke_emergency(:rl565_test, "RL-565 emergency regression")
      on_exit(fn -> Council.lift_emergency(:rl565_test) end)

      assert {:error, :council_emergency_active} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end

    test "R565-08c: emergency blocks effect execution" do
      entity_id = create_entity("emergency_effect")

      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)
      scope = %{scope | target: %{entity_id: entity_id}}

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      {:ok, bound} =
        MachineAuthorization.bind_effect(
          grant,
          UnifiedWorldModel.effect_descriptor(entity_id)
        )

      :ok = Council.invoke_emergency(:rl565_test, "RL-565 emergency regression")
      on_exit(fn -> Council.lift_emergency(:rl565_test) end)

      assert {:error, :council_emergency_active} =
               UnifiedWorldModel.delete_entity(entity_id, bound)

      assert_entity_exists(entity_id)
    end
  end

  describe "RL-565 receipt and issuer provenance" do
    test "R565-11: a receipt with a wrong issuer is refused" do
      entity_id = "rl565_issuer_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      tampered = %{receipt | issuer: "tiannara.council/v999"}

      # re-sign via test helper is not needed; MAC now invalid too, but issuer check comes first
      assert {:error, :council_receipt_issuer_invalid} =
               DecisionReceipt.verify(tampered)
    end

    test "R565-12: a receipt with a stale policy version is refused at mint" do
      entity_id = "rl565_policy_#{System.unique_integer([:positive])}"
      {decision, _receipt, scope} = genuine_decision(:delete_entity, entity_id)

      receipt = Tiannara.Test.AuthorityFixtures.issue_test_receipt(decision, scope, %{
        policy_version: "stale-policy-version",
        decision_type: :delete_entity
      })

      assert {:error, :council_receipt_policy_mismatch} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end

    test "R565-13: an expired receipt is refused at mint" do
      entity_id = "rl565_expired_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      expired = %{receipt | expires_at: DateTime.add(receipt.issued_at, -10, :second)}
      {:ok, expired_signed} = DecisionReceipt.sign_test(expired)

      assert {:error, :council_decision_receipt_expired} =
               MachineAuthorization.mint(
                 decision,
                 expired_signed,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end

    test "R565-14: a forged MAC receipt is refused" do
      entity_id = "rl565_forgedmac_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      forged = %{receipt | mac: String.duplicate("0", 64)}

      assert {:error, :council_decision_receipt_invalid} =
               MachineAuthorization.mint(
                 decision,
                 forged,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end

    test "R565-15: a receipt consumed by another grant cannot be reused" do
      entity_id = "rl565_reuse_#{System.unique_integer([:positive])}"
      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)

      assert {:ok, _grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert {:error, :council_decision_receipt_consumed} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )
    end
  end

  describe "RL-565 registry provenance and tamper" do
    test "R565-16: machine bind requires registry-anchored grant digest" do
      entity_id = create_entity("tamperbind")

      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)
      scope = %{scope | target: %{entity_id: entity_id}}

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      # tamper the struct's decision ref after mint; bind refuses
      tampered = %{grant | council_decision_ref: String.duplicate("0", 64)}

      assert {:error, :authorization_grant_digest_mismatch} =
               MachineAuthorization.bind_effect(
                 tampered,
                 UnifiedWorldModel.effect_descriptor(entity_id)
               )
    end

    test "R565-17: unbound grant cannot execute at UWM" do
      entity_id = create_entity("unbound")

      {decision, receipt, scope} = genuine_decision(:delete_entity, entity_id)
      scope = %{scope | target: %{entity_id: entity_id}}

      assert {:ok, grant} =
               MachineAuthorization.mint(
                 decision,
                 receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      assert {:error, :effect_binding_required} =
               UnifiedWorldModel.delete_entity(entity_id, grant)

      assert_entity_exists(entity_id)
    end
  end
end
