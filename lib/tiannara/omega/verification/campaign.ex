defmodule Tiannara.Omega.Verification.Campaign do
  @moduledoc """
  The Ω.R release-gating verification campaign. Runs each adversarial scenario
  in an isolated world, captures structured evidence, and issues a release
  certificate.

  Campaign lifecycle per scenario:
      Initialize isolated world → capture baseline → ATTACK → observe →
      verify invariant → persist evidence → discard world → next attack

  Constitutional basis: Verification First ("Adversarial testing"), "No
  feature is complete until it is validated", "Capability must never outpace
  verification."
  """

  alias Tiannara.Omega.Verification.{World, Baseline, Report, Certificate, ScenarioOutcome}

  alias Tiannara.Omega.Verification.Scenarios.{
    AuthorizationBypass, GrantReplay, IdentityForgery, CertificationBypass,
    CandidateMutation, LineageTampering, RestartRecovery, DeploymentRace,
    EvidenceCorruption, LegacyApiBypass, Idempotency
  }

  @scenarios [
    AuthorizationBypass, GrantReplay, IdentityForgery, CertificationBypass,
    CandidateMutation, LineageTampering, RestartRecovery, DeploymentRace,
    EvidenceCorruption, LegacyApiBypass, Idempotency
  ]

  def scenarios, do: @scenarios

  @doc """
  Run the full campaign. Returns {report, certificate}. ALL scenarios must
  fully pass for Ω.R to be verified; any inconclusive result is a failure.
  """
  def run(scenarios \\ @scenarios) do
    outcomes = Enum.map(scenarios, &run_scenario/1)
    report = Report.aggregate(outcomes)
    certificate = Certificate.issue(report)
    {report, certificate}
  end

  defp run_scenario(scenario) do
    world = World.create()

    try do
      baseline = Baseline.establish(world)
      outcome = scenario.attack(world, baseline)
      :ok = persist_evidence(outcome, world)
      outcome
    rescue
      e ->
        %ScenarioOutcome{
          scenario: scenario.name(),
          attack: scenario.attack_type(),
          invariant: scenario.invariant(),
          outcome: :inconclusive,
          expected: :rejected,
          attempted: true,
          passed: false,
          evidence: [{:crash, Exception.message(e)}],
          supervisor_crashed: true
        }
    after
      World.discard(world)
    end
  end

  defp persist_evidence(%ScenarioOutcome{} = outcome, world) do
    entry = Tiannara.Lineage.Entry.new(
      %{scenario: outcome.scenario, attack: outcome.attack, outcome: outcome.outcome},
      :verification_evidence)

    Tiannara.Lineage.Store.persist(entry, world.lineage_path)
  end
end