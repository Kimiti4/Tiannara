defmodule Tiannara.Council.Step13G9R1AuthorizationFollowupsTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{Authorization, MachineAuthorization, RuleEngine}
  alias Tiannara.Omega.HumanDelivery
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.World.WorldMutationEngine

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    :ok
  end

  defp conditional(fields) do
    Map.merge(
      %{
        decision: :conditional,
        evidence: [%{principle: :safety, verdict: :neutral}],
        violated_principles: [],
        constitutional_score: 0.7,
        required_human_review: false,
        conditions: []
      },
      fields
    )
    |> then(&struct(Authorization, &1))
  end

  defp machine_decision(opts \\ []) do
    Authorization.approved(
      Keyword.merge(
        [explanation: "step-13 r1 probe", policy_applied: :rule_engine],
        opts
      )
    )
  end

  describe "G-9 conditions schema on Authorization" do
    test "default conditions are empty and the structural check is unchanged" do
      auth = conditional(%{})
      assert auth.conditions == []
      assert WorldMutationEngine.conditions_met?(auth)

      approved = machine_decision()
      assert approved.conditions == []
      assert WorldMutationEngine.check_decision(approved) == :ok
    end

    test "a satisfied per-concern condition passes the check" do
      auth =
        conditional(%{
          conditions: [%{concern: :safety, evidence_check: :safety}],
          evidence: [%{principle: :safety, verdict: :neutral}]
        })

      assert WorldMutationEngine.conditions_met?(auth)
      assert WorldMutationEngine.check_decision(auth) == :ok
    end

    test "an unsatisfied per-concern condition fails closed with the unmet list in detail" do
      auth =
        conditional(%{
          conditions: [
            %{concern: :safety, evidence_check: :safety},
            %{concern: :data_retention, evidence_check: :data_retention}
          ]
        })

      assert WorldMutationEngine.conditions_met?(auth) == false

      assert {:error, {:conditional_conditions_unmet, detail}} =
               WorldMutationEngine.check_decision(auth)

      assert is_map(detail)
      assert detail.unmet_conditions == [%{concern: :data_retention, evidence_check: :data_retention}]
      assert detail.violated_principles == []
    end

    test "evidence explicitly passed: false does not satisfy a condition" do
      auth =
        conditional(%{
          conditions: [%{concern: :safety, evidence_check: :safety}],
          evidence: [%{check: :safety, passed: false}]
        })

      refute WorldMutationEngine.conditions_met?(auth)
    end

    test "a structurally invalid decision still fails before per-concern detail" do
      auth =
        conditional(%{
          violated_principles: [:coherence],
          conditions: [%{concern: :safety, evidence_check: :safety}],
          evidence: [%{principle: :safety, verdict: :violated}]
        })

      refute WorldMutationEngine.conditions_met?(auth)

      assert {:error, {:conditional_conditions_unmet, detail}} =
               WorldMutationEngine.check_decision(auth)

      assert :coherence in detail.violated_principles
    end

    test "an approved decision carrying an unsatisfied condition is refused" do
      auth =
        machine_decision()
        |> Map.put(:conditions, [%{concern: :backup_integrity, evidence_check: :backup_integrity}])

      assert {:error, {:conditional_conditions_unmet, detail}} =
               WorldMutationEngine.check_decision(auth)

      assert detail.unmet_conditions == [
               %{concern: :backup_integrity, evidence_check: :backup_integrity}
             ]
    end

    test "rule-engine conditional decisions carry conditions their own evidence satisfies" do
      decision = RuleEngine.evaluate(:create_entity, %{id: "g9-e2e", type: :knowledge})

      if decision.decision == :conditional do
        assert is_list(decision.conditions)
        assert decision.conditions != []
        assert Enum.all?(decision.conditions, &match?(%{concern: _, evidence_check: _}, &1))
        assert WorldMutationEngine.conditions_met?(decision)
        assert WorldMutationEngine.check_decision(decision) == :ok
      else
        assert decision.conditions == []
      end
    end
  end

  defp genuine_mint(opts \\ []) do
    scope =
      Keyword.get(opts, :scope, %{
        operation: "world_mutation",
        target: %{id: "step13-g9-r1"},
        effect_id: nil
      })

    mutation_type = Keyword.get(opts, :mutation_type, :world_mutation)

    {:ok, decision, receipt} =
      Council.decide(
        :world_mutation,
        %{
          mutation_type: mutation_type,
          mutation_spec: %{id: "step13-g9-r1"},
          target: scope.target,
          scope: scope,
          context: nil,
          evidence: [%{source: :step13_g9_r1}],
          actor: :step13_g9_r1,
          coherent_with_mission: true,
          degradation_handled: true
        },
        nil
      )

    MachineAuthorization.mint(decision, receipt,
      decision_type: :world_mutation,
      scope: scope,
      ttl: Keyword.get(opts, :ttl, 600)
    )
  end

  describe "R-1 M2 council_decision_ref anchoring" do
    test "a machine mint anchors the decision digest in the registry" do
      {:ok, auth} = genuine_mint()

      assert is_binary(auth.council_decision_ref)
      assert byte_size(auth.council_decision_ref) == 64
      assert MintRegistry.decision_ref(auth.authorization_id) == auth.council_decision_ref
      assert MachineAuthorization.content_hash(auth) == auth.content_hash
    end

    test "content_hash pins council_decision_ref" do
      {:ok, auth} = genuine_mint()

      tampered = %{auth | council_decision_ref: String.duplicate("0", 64)}
      assert MachineAuthorization.content_hash(tampered) != tampered.content_hash
    end

    test "the legacy human bind path refuses a machine record regardless of presented ref" do
      {:ok, auth} = genuine_mint()

      assert {:error, :authorization_provenance_invalid} =
               MintRegistry.record_bind(auth.authorization_id, "effect-v1-c4ref",
                 council_decision_ref: String.duplicate("f", 64)
               )

      assert {:error, :authorization_provenance_invalid} =
               MintRegistry.record_bind(auth.authorization_id, "effect-v1-c4ref",
                 council_decision_ref: nil
               )

      assert MintRegistry.binding(auth.authorization_id) == :not_bound
    end

    test "an unanchored human registration refuses an anchored machine ref at bind" do
      unanchored = :"step13-unanchored-#{System.unique_integer([:positive])}"
      :ok = HumanDelivery.Authorization.record_mint(unanchored)

      {:ok, auth} = genuine_mint()

      assert {:error, :council_decision_mismatch} =
               MintRegistry.record_bind(unanchored, auth.effect_id || "effect-v1-unanchored",
                 council_decision_ref: auth.council_decision_ref
               )
    end

    test "an anchored mint binds cleanly with its own ref" do
      descriptor = %{
        principal: "test.step13",
        authority_scope: "test",
        operation: "probe",
        target: %{id: "r1-target"},
        parameters: %{},
        environment: %{},
        intent: %{},
        semantic_version: "1",
        identity_version: "v1"
      }

      {:ok, auth} =
        genuine_mint(
          scope: %{operation: "probe", target: descriptor.target, effect_id: nil},
          mutation_type: :probe
        )

      {:ok, bound} = MachineAuthorization.bind_effect(auth, descriptor)
      assert is_binary(bound.effect_id)
      assert MintRegistry.status(bound.authorization_id) == :granted
      assert MintRegistry.binding(bound.authorization_id) == {:ok, bound.effect_id}
    end
  end
end
