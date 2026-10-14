defmodule Tiannara.ASC.PipelinePhasesTest do
  use ExUnit.Case, async: true

  alias Tiannara.ASC.Pipeline.Phases

  test "crucible phase has no active handler after archived supervisor stub removal" do
    assert Phases.handler(:crucible) == nil
  end

  test "phase transition contract around crucible is unchanged" do
    assert Phases.valid_transition?(:implementation, :crucible)
    assert Phases.valid_transition?(:crucible, :api_evolution)
    assert Phases.valid_transition?(:crucible, :implementation)
    refute Phases.valid_transition?(:crucible, :deployment)
  end
end
