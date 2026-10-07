defmodule Tiannara.ASC.Core.BootTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Core.{Coordinator, Supervisor, Worker}

  test "ASC core boots through the production supervision tree" do
    case Process.whereis(Supervisor) do
      nil -> {:ok, _pid} = start_supervised(Supervisor)
      _running -> :ok
    end

    assert is_pid(Process.whereis(Tiannara.ASC.Core.Registry))
    assert is_pid(Process.whereis(Tiannara.ASC.Core.PubSub))
    assert is_pid(Process.whereis(Tiannara.ASC.Core.KnowledgeStore))
    assert is_pid(Process.whereis(Tiannara.ASC.Core.WorkerSupervisor))

    for %{role: role} <- Coordinator.required_workers() do
      assert {:ok, pid} = Worker.whereis(role), "worker #{role} not registered"
      assert Process.alive?(pid)
    end

    assert %{missing: []} = Coordinator.health()

    Process.sleep(150)
    assert Process.whereis(Supervisor) |> Process.alive?()
  end

  test "event bus delivers across the PubSub registry" do
    case Process.whereis(Supervisor) do
      nil -> {:ok, _pid} = start_supervised(Supervisor)
      _running -> :ok
    end

    _test_pid = self()
    Tiannara.ASC.Core.EventBus.subscribe(:core_test_topic)
    Tiannara.ASC.Core.EventBus.publish(:core_test_topic, %{signal: :ping})

    assert_receive {:asc_event, :core_test_topic, %{signal: :ping}}, 1_000
  end
end