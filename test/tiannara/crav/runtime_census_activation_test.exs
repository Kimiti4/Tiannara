defmodule Tiannara.CRAV.RuntimeCensusActivationTest do
  use ExUnit.Case, async: false

  alias Tiannara.CRAV.RuntimeCensus

  test "reports declared versus loaded module activation" do
    assert {:ok, metrics} = RuntimeCensus.activation_metrics()
    assert metrics.declared_modules > 0
    assert metrics.loaded_modules >= 0
    assert metrics.activation_ratio >= 0.0
    assert metrics.activation_percentage >= 0.0
    assert metrics.status in [:fully_active, :partially_active]
  end
end