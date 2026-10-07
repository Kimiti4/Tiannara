defmodule Tiannara.PhaseOmega.AdversarialValidationTest do
  use ExUnit.Case, async: true

  alias Tiannara.PhaseOmega.AdversarialValidation

  test "no mutation execution evidence is UNKNOWN" do
    result = AdversarialValidation.verify()
    assert result.status == :unknown
    assert result.evidence_class == :not_verified
  end

  test "partial mutation evidence remains UNKNOWN" do
    result = AdversarialValidation.verify(%{evidence: %{injected: true, observed: true}})
    assert result.status == :unknown
    assert :detected in result.missing_steps
  end

  test "complete causal mutation chain can PASS" do
    evidence =
      Enum.into(
        [:injected, :observed, :detected, :classified, :blocked, :restored],
        %{},
        &{&1, true}
      )

    result = AdversarialValidation.verify(%{evidence: evidence})
    assert result.status == :pass
    assert result.evidence_class == :runtime
  end
end
