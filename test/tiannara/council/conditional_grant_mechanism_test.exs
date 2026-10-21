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
    test "a conditional decision with an unmet condition cannot be minted" do
      auth = conditional(%{evidence: [%{principle: :transparency, verdict: :neutral}]})

      assert {:error, :decision_not_permitted} =
               MachineAuthorization.mint(auth, decision_type: :world_mutation, ttl: 600)
    end

    test "a conditional decision with satisfied conditions can still be minted" do
      assert {:ok, minted} =
               MachineAuthorization.mint(conditional(),
                 decision_type: :world_mutation,
                 ttl: 600
               )

      assert is_binary(minted.council_decision_ref)
    end

    test "an approved decision can still be minted" do
      auth =
        decision(%{
          decision: :approved,
          confidence: 1.0,
          constitutional_score: 1.0,
          violated_principles: [],
          required_human_review: false,
          explanation: "approved under test",
          evidence: [%{principle: :safety, verdict: :neutral}],
          decided_at: DateTime.utc_now(),
          policy_applied: :rule_engine
        })

      assert {:ok, minted} =
               MachineAuthorization.mint(auth, decision_type: :world_mutation, ttl: 600)

      assert is_binary(minted.council_decision_ref)
    end

    test "a decision awaiting human review cannot be minted" do
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

      assert {:error, :decision_not_permitted} =
               MachineAuthorization.mint(auth, decision_type: :world_mutation, ttl: 600)
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
