defmodule Tiannara.Meta.Governance.OntologicalSafetyGateTest do
  use ExUnit.Case

  alias Tiannara.Meta.Governance.OntologicalSafetyGate

  test "rejects excessive entropy" do
    result =
      OntologicalSafetyGate.validate(%{
        entropy: 0.95,
        pressure: 50
      })

    assert result == {:reject, :entropy_overflow}
  end
end
