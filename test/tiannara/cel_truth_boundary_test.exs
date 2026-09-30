defmodule Tiannara.CEL.TruthBoundaryTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.{BootSequencer, ConstitutionalScore}

  test "missing constitutional evidence fails closed" do
    score = fn _ -> raise "provider unavailable" end
    assert {:fail, reason} = BootSequencer.send(:check_constitution, score)
    assert reason =~ "unavailable"
  end

  test "default constitutional score is not boot ready" do
    refute ConstitutionalScore.boot_ready?(ConstitutionalScore.default(:missing))
  end

  test "CIS rejects plans without evidence and provenance" do
    assert {:error, {:immune_constraints, reasons}} =
             Tiannara.CISConstraint.validate_plan(%{id: :p, steps: [:x], authority: :operator})
    assert :missing_evidence in reasons
    assert :missing_provenance in reasons
  end
end
