defmodule Tiannara.Omega.Verification.Scenarios do
  @moduledoc """
  The 11 Ω.R adversarial scenarios. Each attacks the interface between
  subsystems and returns structured evidence.
  """

  alias Tiannara.Omega.{DeploymentGateway, ExperimentGenerator, PatchGenerator}
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}
  alias Tiannara.Omega.Verification.{Baseline, ScenarioOutcome}
  alias Tiannara.Omega.DeploymentGateway.DeploymentRegistry

  # --- #1 AuthorizationBypass ---
  defmodule AuthorizationBypass do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :authorization_bypass
    def attack_type, do: :missing_authorization_grant
    def invariant, do: :human_authorization_required
    def boundary, do: :authorization_boundary

    def attack(world, baseline) do
      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          baseline.lineage,
          nil,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_without_grant}],
        baseline.lineage
      )
    end

    defp classify({:error, :authorization_grant_required}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #2 GrantReplay (expired/old grant) ---
  defmodule GrantReplay do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :grant_replay
    def attack_type, do: :expired_grant_reuse
    def invariant, do: :grant_expiry_enforced
    def boundary, do: :authorization_boundary

    def attack(world, baseline) do
      # Expire the grant by backdating granted_at beyond TTL
      expired_grant = %{baseline.authorization | granted_at: System.system_time(:second) - 9999}

      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          baseline.lineage,
          expired_grant,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_with_expired_grant}],
        baseline.lineage
      )
    end

    defp classify({:error, :grant_expired}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #3 IdentityForgery ---
  defmodule IdentityForgery do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :identity_forgery
    def attack_type, do: :forged_human_identity
    def invariant, do: :identity_authentication_required
    def boundary, do: :authorization_boundary

    def attack(world, baseline) do
      forged = %AuthenticatedHumanIdentity{
        identity_id: :forged,
        human_id: :human_1,
        authenticated_at: nil,
        method: :forged
      }

      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          baseline.lineage,
          baseline.authorization,
          forged,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_with_forged_identity}],
        baseline.lineage
      )
    end

    defp classify({:error, :identity_not_authenticated}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #4 CertificationBypass ---
  defmodule CertificationBypass do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :certification_bypass
    def attack_type, do: :deploy_uncertified_candidate
    def invariant, do: :certification_required
    def boundary, do: :certification_boundary

    def attack(world, baseline) do
      bad_cert = %{verdict: :not_certified}

      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          bad_cert,
          baseline.lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_uncertified}],
        baseline.lineage
      )
    end

    defp classify({:error, :certification_invalid}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #5 CandidateMutation ---
  defmodule CandidateMutation do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :candidate_mutation
    def attack_type, do: :mutate_candidate_after_authorization
    def invariant, do: :candidate_immutability_after_authorization
    def boundary, do: :candidate_integrity

    def attack(world, baseline) do
      mutated = %{
        baseline.candidate
        | content: %{baseline.candidate.content | target: :malicious}
      }

      result =
        DeploymentGateway.deploy(
          mutated,
          baseline.certification,
          baseline.lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_mutated_candidate}],
        baseline.lineage
      )
    end

defp classify({:error, reason})
         when reason in [:candidate_mutated_after_authorization, :grant_does_not_match_effect],
         do: :rejected

    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #6 LineageTampering ---
  defmodule LineageTampering do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :lineage_tampering
    def attack_type, do: :alter_persistent_lineage
    def invariant, do: :lineage_integrity
    def boundary, do: :lineage_integrity

    def attack(world, baseline) do
      # empty lineage = broken lineage
      tampered_lineage = []

      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          tampered_lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_with_tampered_lineage}],
        baseline.lineage
      )
    end

    defp classify({:error, :lineage_invalid}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #7 RestartRecovery ---
  defmodule RestartRecovery do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :restart_recovery
    def attack_type, do: :restart_during_authorization
    def invariant, do: :state_and_lineage_recoverable
    def boundary, do: :restart_recovery

    def attack(world, baseline) do
      # Simulate restart by re-reading the lineage store
      case Tiannara.Lineage.Store.reconstruct(world.lineage_path) do
        {:ok, entries} when is_list(entries) ->
          ScenarioOutcome.new(
            name(),
            attack_type(),
            invariant(),
            :recovered,
            :recovered,
            [{:lineage_entries, length(entries)}],
            baseline.lineage
          )

        {:error, reason} ->
          ScenarioOutcome.new(
            name(),
            attack_type(),
            invariant(),
            {:error, reason},
            :recovered,
            [{:reconstruct_failed, reason}],
            baseline.lineage
          )
      end
    end
  end

  # --- #8 DeploymentRace ---
  defmodule DeploymentRace do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :deployment_race
    def attack_type, do: :race_concurrent_deployments
    def invariant, do: :at_most_one_deployment
    def boundary, do: :concurrency_safety

    def attack(world, baseline) do
      # Race two concurrent deployment attempts with the same grant.
      results =
        1..2
        |> Enum.map(fn _ ->
          Task.async(fn ->
            DeploymentGateway.deploy(
              baseline.candidate,
              baseline.certification,
              baseline.lineage,
              baseline.authorization,
              baseline.identity,
              world.deployment_registry_path
            )
          end)
        end)
        |> Enum.map(&Task.await/1)

      deployments = Enum.count(results, &match?({:ok, _, _}, &1))

      outcome =
        cond do
          deployments == 1 -> :exactly_one_deployment
          deployments == 0 -> :no_deployment
          true -> :multiple_deployments
        end

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :exactly_one_deployment,
        [{:deployment_count, deployments}],
        baseline.lineage
      )
    end
  end

  # --- #9 EvidenceCorruption ---
  defmodule EvidenceCorruption do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :evidence_corruption
    def attack_type, do: :corrupt_evidence_chain
    def invariant, do: :evidence_integrity
    def boundary, do: :evidence_integrity

    def attack(world, baseline) do
      # Corrupt the certification (evidence of validation)
      corrupted_cert = %{verdict: :certified, evidence: :corrupted}

      result =
        DeploymentGateway.deploy(
          baseline.candidate,
          corrupted_cert,
          baseline.lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      # A corrupted evidence chain should be detectable. Here we model it as
      # the certification becoming invalid.
      outcome = classify(result)

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_with_corrupted_evidence}],
        baseline.lineage
      )
    end

    defp classify({:error, _}), do: :rejected
    defp classify({:ok, _, _}), do: :accepted
    defp classify(_), do: :inconclusive
  end

  # --- #10 LegacyApiBypass ---
  defmodule LegacyApiBypass do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :legacy_api_bypass
    def attack_type, do: :deploy_through_alternate_api
    def invariant, do: :single_deployment_gateway
    def boundary, do: :legacy_api_containment

    def attack(world, baseline) do
      # Attempt to transition candidate to :deployed directly, bypassing the
      # gateway. The Candidate state machine only allows :approved → :deployed,
      # but there is no alternate public API that should be used.
      # The only legitimate path is DeploymentGateway.deploy.
      result = Candidate.transition(baseline.candidate, :deployed)

      outcome =
        case result do
          # would indicate a bypass exists
          {:ok, _} -> :accepted
          {:error, _} -> :rejected
        end

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :rejected,
        [{:attempted, :deploy_via_direct_transition}],
        baseline.lineage
      )
    end
  end

  # --- #11 Idempotency ---
  defmodule Idempotency do
    @behaviour Tiannara.Omega.Verification.Scenario
    def name, do: :idempotency
    def attack_type, do: :replay_authorization
    def invariant, do: :deployment_idempotent
    def boundary, do: :replay_protection

    def attack(world, baseline) do
      # First deployment succeeds
      first =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          baseline.lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      # Replay the same authorization
      replay =
        DeploymentGateway.deploy(
          baseline.candidate,
          baseline.certification,
          baseline.lineage,
          baseline.authorization,
          baseline.identity,
          world.deployment_registry_path
        )

      outcome =
        case {first, replay} do
          {{:ok, _, _}, {:error, :grant_already_used}} -> :replay_rejected
          {{:ok, _, _}, {:ok, _, _}} -> :replay_deployed_again
          _ -> :inconclusive
        end

      ScenarioOutcome.new(
        name(),
        attack_type(),
        invariant(),
        outcome,
        :replay_rejected,
        [{:first, elem_type(first)}, {:replay, elem_type(replay)}],
        baseline.lineage
      )
    end

    defp elem_type({:ok, _, _}), do: :deployed
    defp elem_type({:error, reason}), do: {:rejected, reason}
  end
end
