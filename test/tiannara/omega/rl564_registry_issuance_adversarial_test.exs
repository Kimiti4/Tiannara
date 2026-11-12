defmodule Tiannara.Omega.RL564RegistryIssuanceAdversarialTest do
  @moduledoc """
  CP19.18 adversarial regression for RL-564 (registry issuance provenance).

  These tests assert the safe contract, not the current implementation: a
  durable mint record must be backed by an issuance proof that is independent
  of the allowlisted module name on the caller's stack. On the pinned source
  (`de231a78`) the wrapper-assisted path registers a caller-selected ID and the
  downstream consumers accept the resulting struct. The expected red baseline
  is therefore a failure in every non-control case below.

  The controls at the end preserve refusals that already work: a direct
  non-allowlisted mint and one-shot replay/concurrency.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, MachineAuthorization}
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  alias Tiannara.Omega.{
    DeploymentGateway,
    EffectIdentity,
    ExperimentGenerator,
    GovernedEffectSink,
    MintRegistry,
    PatchGenerator
  }

  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Phase4.ExecutionGovernance
  alias Tiannara.World.UnifiedWorldModel
  import Tiannara.Test.Phase3Helpers

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  defp unique, do: System.unique_integer([:positive])

  defp fresh_id(tag), do: :"rl564-#{tag}-#{unique()}"

  defp assert_mint_refused(result) do
    assert result in [
             {:error, :grant_issuance_proof_required},
             {:error, :authorization_provenance_invalid}
           ]
  end

  defp assert_consumer_refused(result) do
    assert result in [
             {:error, :grant_issuance_proof_required},
             {:error, :authorization_provenance_invalid},
             {:error, :authorization_not_registered},
             {:error, :registry_binding_mismatch},
             {:error, :authorization_bind_failed}
           ]
  end

  defp forged_human_grant(tag, opts) do
    human_id = Keyword.get(opts, :human_id, :"rl564-human-#{tag}-#{unique()}")

    %Authorization{
      authorization_id: Keyword.get(opts, :authorization_id, fresh_id(tag)),
      explanation_id: Keyword.get(opts, :explanation_id, "rl564-explanation-#{tag}-#{unique()}"),
      human_id: human_id,
      granted_at: System.system_time(:second),
      ttl: Keyword.get(opts, :ttl, 3600),
      candidate_content_hash: Keyword.get(opts, :candidate_content_hash),
      decision: :granted,
      status: :granted,
      lineage: []
    }
  end

  defp identity_for(human_id) do
    {:ok, identity} =
      AuthenticatedHumanIdentity.authenticate(human_id, "rl564-test-credential", :password)

    identity
  end

  defp council_decision(mutation_type) do
    scope = %{
      operation: Atom.to_string(mutation_type),
      target: %{entity_id: "rl564_target"},
      effect_id: nil
    }

    {:ok, decision, receipt} =
      Council.decide(
        mutation_type,
        %{
          mutation_type: mutation_type,
          mutation_spec: %{id: "rl564_target"},
          target: scope.target,
          scope: scope,
          context: nil,
          evidence: [%{source: :rl564_adversarial}],
          actor: :rl564_adversarial,
          coherent_with_mission: true,
          degradation_handled: true
        },
        nil
      )

    {decision, receipt, scope}
  end

  defp approved_candidate do
    proposal = %{
      id: :"rl564_prop_#{unique()}",
      hypothesis_id: :"rl564_hyp_#{unique()}",
      statement: "RL-564 gateway candidate",
      type: :memory,
      falsifier: "f",
      rank: 1,
      status: :proposed
    }

    {:ok, spec} = ExperimentGenerator.design(proposal)
    {:ok, candidate} = PatchGenerator.generate(spec)

    {:ok, c1} = Candidate.transition(candidate, :sandboxed)
    {:ok, c2} = Candidate.transition(c1, :tested)
    {:ok, c3} = Candidate.transition(c2, :benchmarked)
    {:ok, c4} = Candidate.transition(c3, :certified)
    {:ok, approved} = Candidate.transition(c4, :approved)
    approved
  end

  describe "RL-564 wrapper-assisted registry mint" do
    test "R564-01: an arbitrary ID cannot be self-registered through the human wrapper" do
      id = fresh_id("wrapper")
      assert MintRegistry.status(id) == :not_registered

      assert_mint_refused(Authorization.record_mint(id))
      assert MintRegistry.status(id) == :not_registered
    end

    test "R564-02: a wrapper-registered forged grant cannot enter Phase4 admission" do
      id = fresh_id("phase4")
      grant = forged_human_grant("phase4", authorization_id: id)
      descriptor = UnifiedWorldModel.effect_descriptor(unique_id("rl564-phase4-target"))
      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)

      _mint_result = Authorization.record_mint(id)

      assert_consumer_refused(ExecutionGovernance.begin(grant, descriptor))
      assert MintRegistry.status(id) in [:granted, :not_registered]
      assert MintRegistry.binding(id) == :not_bound
      refute ExecutionGovernance.executed?(effect_id)
    end

    test "R564-03: a forged human grant cannot reach the governed effect sink" do
      id = fresh_id("sink")
      grant = forged_human_grant("sink", authorization_id: id)
      identity = identity_for(grant.human_id)
      descriptor = GovernedEffectSink.effect_descriptor(grant.human_id, %{target: "rl564"}, %{})
      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)
      test_pid = self()

      _mint_result = Authorization.record_mint(id)
      {:ok, bound} = Authorization.bind_effect(grant, descriptor)
      _bind_result = MintRegistry.record_bind(id, effect_id)

      result =
        GovernedEffectSink.execute(bound, descriptor,
          identity: identity,
          sink: fn sink_effect_id, event ->
            send(test_pid, {:sink_called, sink_effect_id})

            {:ok,
             %{
               topic: "rl564-test-topic",
               offset: 1,
               effect_id: sink_effect_id,
               authorization_id: event.authorization_id
             }}
          end,
          audit: fn _payload ->
            send(test_pid, :audit_called)
            {:ok, %{seq: 1, hash: "rl564-test", action: :test}}
          end
        )

      assert_consumer_refused(result)
      refute_received {:sink_called, _}
      refute_received :audit_called
      assert MintRegistry.status(id) in [:granted, :not_registered]
      assert MintRegistry.binding(id) == :not_bound
    end

    test "R564-04: a forged human grant cannot deploy a candidate" do
      candidate = approved_candidate()
      id = fresh_id("gateway")
      human_id = :"rl564-gateway-human-#{unique()}"

      grant =
        forged_human_grant("gateway",
          authorization_id: id,
          human_id: human_id,
          explanation_id: candidate.proposal_id,
          candidate_content_hash: DeploymentGateway.content_hash(candidate)
        )

      identity = identity_for(human_id)
      descriptor = DeploymentGateway.effect_descriptor(candidate)
      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)

      _mint_result = Authorization.record_mint(id)
      {:ok, bound} = Authorization.bind_effect(grant, descriptor)
      _bind_result = MintRegistry.record_bind(id, effect_id)

      assert_consumer_refused(
        DeploymentGateway.deploy(candidate, %{verdict: :certified}, [:rl564], bound, identity)
      )

      assert candidate.status == :approved
      assert MintRegistry.status(id) in [:granted, :not_registered]
      assert MintRegistry.binding(id) == :not_bound

      refute Enum.any?(AuditLog.recent(300), fn entry ->
               entry.action == :deployment_committed and
                 Map.get(entry.payload, :authorization_id) == id
             end)
    end

    test "R564-06 control: direct non-allowlisted mint remains refused" do
      id = fresh_id("direct")

      assert {:error, :minter_not_authorized} = MintRegistry.record_mint(id)
      assert MintRegistry.status(id) == :not_registered
    end

    test "R564-07: a non-issuer cannot bind an existing minted authorization" do
      {decision, receipt, scope} = council_decision(:delete_entity)

      assert {:ok, auth} =
               MachineAuthorization.mint(decision, receipt,
                 decision_type: :delete_entity,
                 scope: scope,
                 ttl: 3600
               )

      descriptor = UnifiedWorldModel.effect_descriptor(unique_id("rl564-bind-target"))
      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)

      assert_mint_refused(
        MintRegistry.record_bind(auth.authorization_id, effect_id,
          council_decision_ref: auth.council_decision_ref
        )
      )

      assert MintRegistry.binding(auth.authorization_id) == :not_bound
    end

    test "R564-08a: a mint cannot be re-subjected to a different human" do
      id = fresh_id("subject")
      original_human = :"rl564-subject-a-#{unique()}"
      substituted_human = :"rl564-subject-b-#{unique()}"
      grant = forged_human_grant("subject", authorization_id: id, human_id: original_human)

      descriptor =
        GovernedEffectSink.effect_descriptor(original_human, %{target: "rl564-subject"}, %{})

      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)
      test_pid = self()

      _mint_result = Authorization.record_mint(id)
      {:ok, bound} = Authorization.bind_effect(grant, descriptor)
      _bind_result = MintRegistry.record_bind(id, effect_id)

      substituted = %{bound | human_id: substituted_human}
      identity = identity_for(substituted_human)

      result =
        GovernedEffectSink.execute(substituted, descriptor,
          identity: identity,
          sink: fn sink_effect_id, event ->
            send(test_pid, {:sink_called, sink_effect_id})

            {:ok,
             %{
               topic: "rl564-test-topic",
               offset: 1,
               effect_id: sink_effect_id,
               authorization_id: event.authorization_id
             }}
          end,
          audit: fn _payload ->
            send(test_pid, :audit_called)
            {:ok, %{seq: 1, hash: "rl564-test", action: :test}}
          end
        )

      assert_consumer_refused(result)
      refute_received {:sink_called, _}
      refute_received :audit_called
    end

    test "R564-08b: a mint cannot be re-pointed to a different explanation digest" do
      id = fresh_id("digest")
      human_id = :"rl564-digest-human-#{unique()}"

      grant =
        forged_human_grant("digest",
          authorization_id: id,
          human_id: human_id,
          explanation_id: "rl564-original-explanation"
        )

      descriptor = GovernedEffectSink.effect_descriptor(human_id, %{target: "rl564-digest"}, %{})
      {:ok, effect_id} = EffectIdentity.effect_id(descriptor)
      test_pid = self()

      _mint_result = Authorization.record_mint(id)
      {:ok, bound} = Authorization.bind_effect(grant, descriptor)
      _bind_result = MintRegistry.record_bind(id, effect_id)

      substituted = %{bound | explanation_id: "rl564-substituted-explanation"}
      identity = identity_for(human_id)

      result =
        GovernedEffectSink.execute(substituted, descriptor,
          identity: identity,
          sink: fn sink_effect_id, event ->
            send(test_pid, {:sink_called, sink_effect_id})

            {:ok,
             %{
               topic: "rl564-test-topic",
               offset: 1,
               effect_id: sink_effect_id,
               authorization_id: event.authorization_id
             }}
          end,
          audit: fn _payload ->
            send(test_pid, :audit_called)
            {:ok, %{seq: 1, hash: "rl564-test", action: :test}}
          end
        )

      assert_consumer_refused(result)
      refute_received {:sink_called, _}
      refute_received :audit_called
    end

    test "R564-09 control: concurrent replay admits exactly one execution" do
      {:ok, auth} = Authorization.prepare(%{explanation_id: "rl564-race-#{unique()}"})
      {:ok, pending} = Authorization.request(auth)

      {:ok, identity} =
        AuthenticatedHumanIdentity.authenticate(
          :rl564_race_human,
          "rl564-race-credential",
          :password
        )

      {:ok, grant} = Authorization.human_grant(pending, identity, ttl: 3600)
      :ok = Authorization.record_mint(grant.authorization_id)
      descriptor = UnifiedWorldModel.effect_descriptor(unique_id("rl564-race-target"))

      results =
        1..4
        |> Enum.map(fn _ ->
          Task.async(fn -> ExecutionGovernance.begin(grant, descriptor) end)
        end)
        |> Task.await_many(10_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 1

      assert Enum.all?(Enum.reject(results, &match?({:ok, _}, &1)), fn
               {:error, reason} -> reason in [:already_consumed, :effect_already_executed]
               _ -> false
             end)

      assert MintRegistry.status(grant.authorization_id) == :consumed
    end
  end
end
