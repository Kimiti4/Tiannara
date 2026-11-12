defmodule Tiannara.Council.ConditionalGrantMechanismTest do
  @moduledoc """
  F-GOV-005: a `:conditional` decision must not be a machine grant.

  Before this suite `Authorization.permitted?/1` returned true for
  `:conditional`, so a conditional decision could be minted into a machine
  authorization and could authorise a world mutation without its conditions
  ever being checked. The predicate is now strict (`:approved` only) and the
  conditional path is the explicit, audited mechanism: `conditional_grant?/1`,
  which requires the decision's conditions to be satisfied by its evidence.

  The suite asserts the denial cases first, then the two cases that must keep
  working: a full approval, and a conditional decision whose conditions are
  genuinely satisfied.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{Authorization, MachineAuthorization}
  alias Tiannara.Omega.MintRegistry

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    :ok
  end

  defp decision(fields) do
    struct(Authorization, fields)
  end

  defp conditional(overrides \\ %{}) do
    decision(
      Map.merge(
        %{
          decision: :conditional,
          confidence: 0.7,
          constitutional_score: 0.7,
          violated_principles: [],
          required_human_review: false,
          explanation: "conditional decision under test",
          evidence: [%{principle: :safety, verdict: :neutral}],
          risks: [],
          simulation_results: [],
          recommendation: nil,
          context: nil,
          decided_at: DateTime.utc_now(),
          policy_applied: :rule_engine,
          metadata: %{},
          conditions: [%{concern: :safety, evidence_check: :safety}]
        },
        overrides
      )
    )
  end

  describe "F-GOV-005 — the strict predicate" do
    test "a conditional decision is not a machine grant" do
      refute Authorization.permitted?(conditional())
    end

    test "a full approval is a machine grant" do
      assert Authorization.permitted?(decision(%{decision: :approved, evidence: [%{a: 1}]}))
    end

    test "a decision awaiting human review is not a machine grant" do
      refute Authorization.permitted?(decision(%{decision: :requires_human}))
    end

    test "a rejected decision is not a machine grant" do
      refute Authorization.permitted?(decision(%{decision: :rejected}))
    end
  end

  describe "the conditional-grant mechanism requires satisfied conditions" do
    test "a conditional decision with satisfied conditions grants conditionally" do
      assert Authorization.conditional_grant?(conditional())
    end

    test "a conditional decision with an unmet condition does not grant" do
      auth = conditional(%{evidence: [%{principle: :transparency, verdict: :neutral}]})

      refute Authorization.conditional_grant?(auth)
      assert [%{concern: :safety}] = Authorization.unmet_conditions(auth)
    end

    test "a conditional decision with a violated principle does not grant" do
      auth = conditional(%{violated_principles: [:evidence_based]})

      refute Authorization.conditional_grant?(auth)
    end

    test "a conditional decision that requires human review does not grant" do
      refute Authorization.conditional_grant?(conditional(%{required_human_review: true}))
    end

    test "a conditional decision without evidence does not grant" do
      refute Authorization.conditional_grant?(conditional(%{evidence: []}))
    end

    test "an approved decision is not a conditional grant" do
      refute Authorization.conditional_grant?(decision(%{decision: :approved}))
    end
  end

  describe "machine authorization minting" do
    test "mint/2 fails closed: a decision struct is not proof of Council issuance" do
      assert MachineAuthorization.mint(conditional(),
               decision_type: :world_mutation,
               ttl: 600
             ) == {:error, :council_decision_proof_required}

      approved = decision(%{decision: :approved, evidence: [%{principle: :safety, verdict: :neutral}]})

      assert MachineAuthorization.mint(approved, decision_type: :world_mutation, ttl: 600) ==
               {:error, :council_decision_proof_required}
    end

    test "a signed receipt for a conditional decision with an unmet condition is refused at mint" do
      auth = conditional(%{evidence: [%{principle: :transparency, verdict: :neutral}]})

      scope = %{
        operation: "world_mutation",
        target: %{id: "conditional_grant"},
        effect_id: nil
      }

      receipt = Tiannara.Test.AuthorityFixtures.issue_test_receipt(auth, scope, %{
        decision_type: :world_mutation
      })

      assert MachineAuthorization.mint(auth, receipt,
               decision_type: :world_mutation,
               scope: scope,
               ttl: 600
             ) == {:error, :decision_not_permitted}
    end

    test "a genuine Council decision with satisfied conditions can be minted" do
      scope = %{
        operation: "world_mutation",
        target: %{id: "conditional_grant"},
        effect_id: nil
      }

      {:ok, auth, receipt} =
        Council.decide(
          :world_mutation,
          %{
            mutation_type: :world_mutation,
            mutation_spec: %{id: "conditional_grant"},
            target: scope.target,
            scope: scope,
            evidence: [%{principle: :safety, verdict: :neutral}],
            actor: :conditional_grant_test,
            coherent_with_mission: true,
            degradation_handled: true
          },
          nil
        )

      assert auth.decision in [:approved, :conditional]
      assert Authorization.permitted?(auth) or Authorization.conditional_grant?(auth)

      assert {:ok, minted} =
               MachineAuthorization.mint(auth, receipt,
                 decision_type: :world_mutation,
                 scope: scope,
                 ttl: 600
               )

      assert is_binary(minted.council_decision_ref)
      assert MintRegistry.receipt_status(receipt.receipt_id) == :consumed
    end

    test "a signed receipt for a decision awaiting human review is refused at mint" do
      auth =
        decision(%{
          decision: :requires_human,
          confidence: 0.5,
          constitutional_score: 0.5,
          violated_principles: [],
          required_human_review: true,
          explanation: "parked under test",
          evidence: [%{principle: :safety, verdict: :neutral}],
          decided_at: DateTime.utc_now(),
          policy_applied: :rule_engine
        })

      scope = %{
        operation: "world_mutation",
        target: %{id: "conditional_grant"},
        effect_id: nil
      }

      receipt = Tiannara.Test.AuthorityFixtures.issue_test_receipt(auth, scope, %{
        decision_type: :world_mutation
      })

      assert MachineAuthorization.mint(auth, receipt,
               decision_type: :world_mutation,
               scope: scope,
               ttl: 600
             ) == {:error, :decision_not_permitted}
    end
  end

  describe "the Council decision surface is unchanged" do
    test "a compliant decision is returned as a valid decision atom and is not rejected" do
      auth =
        Council.authorize(
          :r1_batch1_grant_probe,
          %{actor: :r1_batch1, evidence: [%{source: :r1_batch1}]},
          nil
        )

      assert auth.decision in [:approved, :conditional, :requires_human, :rejected]
      refute auth.decision == :rejected
    end
  end
end
