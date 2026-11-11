defmodule Tiannara.Audits.Checkpoint1910ConstitutionalEvidenceNegativeRegressionTest do
  use ExUnit.Case, async: true

  alias Tiannara.Evolution.ConstitutionalAuditor

  test "an empty evidence map cannot produce constitutional compliance" do
    audit = ConstitutionalAuditor.audit(%{})

    refute audit.status == :compliant,
           "empty evidence was treated as a fully compliant constitutional audit"
  end

  test "partial evidence cannot silently default omitted evidence domains to passing" do
    audit =
      ConstitutionalAuditor.audit(%{
        capabilities_deployed: 20,
        verifications_completed: 20
      })

    refute audit.status == :compliant,
           "omitted constitutional evidence domains were treated as passing"
  end

  test "zero verification denominator is not proof that all capabilities were verified" do
    audit =
      ConstitutionalAuditor.audit(%{
        capabilities_deployed: 0,
        verifications_completed: 0
      })

    verification_check =
      Enum.find(audit.checks, fn check ->
        check.principle == "Capability must never outpace verification"
      end)

    assert verification_check
    refute verification_check.passed,
           "zero capabilities and zero verifications were treated as a passing ratio"
  end

  test "zero evolution denominator is not proof of validation balance" do
    audit =
      ConstitutionalAuditor.audit(%{
        evolutions_deployed: 0,
        evolution_validations: 0
      })

    evolution_check =
      Enum.find(audit.checks, fn check ->
        check.principle ==
          "Evolution without validation creates randomness. Validation without evolution creates stagnation."
      end)

    assert evolution_check
    refute evolution_check.passed,
           "zero evolutions and zero validations were treated as a passing ratio"
  end
end
