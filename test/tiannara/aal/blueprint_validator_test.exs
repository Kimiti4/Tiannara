defmodule Tiannara.AAL.BlueprintValidatorTest do
  use ExUnit.Case, async: true

  alias Tiannara.AAL.BlueprintValidator

  test "accepts a successful structurally valid blueprint" do
    blueprint = %{
      domain: :engineering,
      status: :success,
      schematics: "module safe; endmodule",
      confidence: 0.9
    }

    assert BlueprintValidator.validate([blueprint]) == [blueprint]
  end

  test "rejects failed, malformed, and out-of-range blueprints" do
    failed = %{domain: :engineering, status: :failed, reason: :timeout}
    malformed = %{domain: :engineering, status: :success, schematics: "not verilog", confidence: 0.99}
    invalid_confidence = %{domain: :engineering, status: :success, schematics: "module x; endmodule", confidence: 1.2}

    assert BlueprintValidator.validate([failed, malformed, invalid_confidence]) == []
  end
end
