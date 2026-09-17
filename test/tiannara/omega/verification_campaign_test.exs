defmodule Tiannara.Omega.VerificationCampaignTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.Verification.{Campaign, Report, Certificate, ScenarioOutcome}

  @moduletag :omega_r_verification_campaign

  test "the full campaign runs all 11 scenarios and produces a certificate" do
    {report, certificate} = Campaign.run()

    assert report.total == 11
    assert report.passed == 11
    assert certificate.scenarios_total == 11
    assert certificate.verdict == :omega_r_verified
  end

  test "every scenario produces structured evidence, not just pass/fail" do
    {report, _} = Campaign.run()

    Enum.each(report.outcomes, fn outcome ->
      assert outcome.scenario != nil
      assert outcome.attack != nil
      assert outcome.invariant != nil
      assert outcome.outcome != nil
      assert is_list(outcome.evidence)
      assert is_boolean(outcome.attempted)
    end)
  end

  test "an inconclusive scenario fails the release gate" do
    inconclusive = %ScenarioOutcome{
      scenario: :test, attack: :test, invariant: :test,
      outcome: :inconclusive, expected: :rejected, attempted: true
    }

    refute ScenarioOutcome.fully_passed?(inconclusive)
  end

  test "a fully-passing scenario requires all criteria, not just outcome" do
    passing = %ScenarioOutcome{
      scenario: :test, attack: :test, invariant: :test,
      outcome: :rejected, expected: :rejected, attempted: true,
      unauthorized_deployment: false
    }

    assert ScenarioOutcome.fully_passed?(passing)

    # Same outcome but with unauthorized deployment -> fails
    bad = %{passing | unauthorized_deployment: true}
    refute ScenarioOutcome.fully_passed?(bad)
  end

  test "certificate carries the epistemic-honesty caveat" do
    {_, certificate} = Campaign.run()
    assert Enum.any?(certificate.caveats, &(&1 =~ "≠ Tiannara universally safe"))
  end
end