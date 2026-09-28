defmodule Tiannara.ComplexTaskRuntimeTest do
  use ExUnit.Case, async: false

  test "executes independent tasks before dependent tasks" do
    Process.whereis(Tiannara.ExtrusionTaskSupervisor) ||
      start_supervised!({Task.Supervisor, name: Tiannara.ExtrusionTaskSupervisor})

    {:ok, agent} = Agent.start_link(fn -> [] end)

    tasks = [
      %{id: :a, deps: [], run: fn -> Agent.update(agent, &[ :a | &1]); 1 end},
      %{id: :b, deps: [], run: fn -> Agent.update(agent, &[ :b | &1]); 2 end},
      %{id: :c, deps: [:a, :b], run: fn -> Agent.update(agent, &[ :c | &1]); 3 end}
    ]

    assert {:ok, %{status: :completed}} = Tiannara.Agency.ComplexTaskRuntime.execute(tasks)
    assert Agent.get(agent, &Enum.sort/1) == [:a, :b, :c]
  end

  test "rejects cyclic task graphs" do
    tasks = [
      %{id: :a, deps: [:b], run: fn -> :a end},
      %{id: :b, deps: [:a], run: fn -> :b end}
    ]

    assert {:error, :dependency_cycle} = Tiannara.Agency.ComplexTaskRuntime.execute(tasks)
  end
end
