defmodule Tiannara.ASC.Core.SupervisorTopologyTest do
  use ExUnit.Case, async: true

  test "starts the registry, metrics, and telemetry children" do
    pid =
      case Process.whereis(Tiannara.ASC.Core.Supervisor) do
        nil ->
          {:ok, pid} = start_supervised(Tiannara.ASC.Core.Supervisor)
          pid

        pid ->
          pid
      end

    children = Supervisor.which_children(pid)
    child_modules = Enum.map(children, &elem(&1, 0))

    assert Tiannara.ASC.Core.Registry in child_modules
    assert Tiannara.ASC.Core.Metrics in child_modules
    assert Tiannara.ASC.Core.Telemetry in child_modules
  end
end
