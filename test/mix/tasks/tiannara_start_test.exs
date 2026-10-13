defmodule Mix.Tasks.Tiannara.StartTest do
  use ExUnit.Case, async: true

  test "uses only applications owned by the main release" do
    subsystems = Mix.Tasks.Tiannara.Start.runtime_subsystems()

    assert subsystems == [:telemetry, :tiannara]
    refute :tiannara_runtime in subsystems
  end
end