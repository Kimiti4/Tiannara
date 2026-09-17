defmodule Tiannara.ControlCenterBootTest do
  @moduledoc """
  Regression gate for the ControlCenter boot list: the CEL workflow services
  (ResourceManager, CapabilityGraph, WorkflowEngine) MUST be supervised by
  ControlCenter and alive — the first smoke failure was exactly these three
  being absent from `@subsystems` while WorkflowEngine dispatch assumed them.
  Removing any of them from the boot list fails this test.
  """

  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.{CapabilityGraph, ResourceManager, WorkflowEngine}

  @services [
    {:resource_manager, ResourceManager},
    {:capability_graph, CapabilityGraph},
    {:workflow_engine, WorkflowEngine}
  ]

  test "ControlCenter supervises all three CEL workflow services" do
    assert Process.whereis(Tiannara.ControlCenter) != nil, "ControlCenter is not running"

    status = Tiannara.ControlCenter.status()

    for {id, _module} <- @services do
      entry = Map.fetch!(status.subsystems, id)
      assert entry.alive, "subsystem #{inspect(id)} must be alive under ControlCenter"
      assert Process.whereis(entry.module) != nil
    end
  end

  test "all three respond on their real API" do
    assert ResourceManager.ready?() == true, "ResourceManager must be ready, not alive-but-not_ready"
    assert %{total: _, allocated: _, available: _} = ResourceManager.status()

    assert %{healthy: true} = CapabilityGraph.stats()

    assert %{healthy: true} = WorkflowEngine.stats()
  end

  test "workflow dispatch can resolve a provider end-to-end" do
    # The exact call the engine makes at workflow_engine.ex:522 — must not
    # raise (:noproc) nor return :no_provider for a registered capability.
    assert {:ok, _provider, _score} = CapabilityGraph.find_optimal_provider(:observation_comparison)
    assert {:ok, _provider, _score} = CapabilityGraph.find_optimal_provider(:evidence_validation)
  end
end
