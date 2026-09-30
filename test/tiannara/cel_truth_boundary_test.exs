defmodule Tiannara.CEL.TruthBoundaryTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.ConstitutionalScore

  test "default constitutional score is not boot ready" do
    refute ConstitutionalScore.boot_ready?(ConstitutionalScore.default(:missing))
  end

  test "CIS rejects plans without evidence and provenance" do
    assert {:error, reasons} =
             Tiannara.CIS.validate_plan(%{id: :p, steps: [:x], authority: :operator})
    assert :missing_evidence in reasons
    assert :missing_provenance in reasons
  end
end
