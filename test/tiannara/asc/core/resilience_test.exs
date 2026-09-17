defmodule Tiannara.ASC.Test.PoisonWorker do
  @moduledoc false
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init(_) do
    Process.send_after(self(), :boom, 0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:boom, _state), do: raise("poison")
end

defmodule Tiannara.ASC.Core.ResilienceTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Core.{Coordinator, Supervisor, Worker}

  setup do
    start_supervised!(Supervisor)
    :ok
  end

  defp await(condition, timeout_ms \\ 3_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    Stream.repeatedly(fn -> :ok end)
    |> Enum.reduce_while(:timeout, fn _, _ ->
      cond do
        condition.() -> {:halt, :ok}
        System.monotonic_time(:millisecond) > deadline -> {:halt, :timeout}
        true -> Process.sleep(25) && {:cont, :timeout}
      end
    end)
  end

  test "worker crash -> supervisor restart -> registry usable -> siblings unaffected" do
    assert {:ok, victim} = Worker.whereis(:research)
    assert {:ok, sibling} = Worker.whereis(:evolution)

    ref = Process.monitor(victim)
    Process.exit(victim, :kill)
    assert_receive {:DOWN, ^ref, :process, ^victim, _}, 1_000

    assert :ok =
             await(fn ->
               case Worker.whereis(:research) do
                 {:ok, pid} when pid != victim -> true
                 _ -> false
               end
             end)

    assert {:ok, _snap} = Worker.call(:research, {:query, "t", "recovery"})
    assert {:ok, ^sibling} = Worker.whereis(:evolution)
    assert Process.alive?(sibling)
  end

  test "repeated failure is CONTAINED: worker subtree dies, core and shared services survive" do
    poison = %{
      id: :poison,
      start: {Tiannara.ASC.Test.PoisonWorker, :start_link, [[]]},
      restart: :permanent
    }

    assert {:ok, _} = DynamicSupervisor.start_child(Tiannara.ASC.Core.WorkerSupervisor, poison)

    ws_ref = Process.monitor(Tiannara.ASC.Core.WorkerSupervisor)
    assert_receive {:DOWN, ^ws_ref, :process, _, _}, 5_000

    sup = Process.whereis(Supervisor)
    assert sup && Process.alive?(sup)
    assert Process.whereis(Tiannara.ASC.Core.Registry)
    assert Process.whereis(Tiannara.ASC.Core.KnowledgeStore)

    assert :ok = await(fn -> Coordinator.health().missing == [] end, 5_000)

    children =
      Tiannara.ASC.Core.WorkerSupervisor
      |> Process.whereis()
      |> DynamicSupervisor.which_children()

    refute Enum.any?(children, fn {id, _, _, _} -> id == :poison end)
  end
end