defmodule Tiannara.Storage.SoakFootprintGuardTest do
  use ExUnit.Case, async: false

  alias Tiannara.Storage.SoakFootprintGuard
  import ExUnit.Assertions

  @tmp "test_data/soak_footprint_guard"

  setup do
    File.rm_rf!(@tmp)
    File.mkdir_p!(@tmp)
    on_exit(fn -> File.rm_rf!(@tmp) end)
    :ok
  end

  defmodule BreachTracker do
    def start_link do
      Agent.start_link(fn -> %{breached: false, files: nil} end, name: __MODULE__)
    end

    def mark_breached do
      Agent.update(__MODULE__, &Map.put(&1, :breached, true))
    end

    def breached? do
      Agent.get(__MODULE__, & &1.breached)
    end

    def stop do
      Agent.stop(__MODULE__)
    end
  end

  test "does not breach below ceiling and does not abort" do
    BreachTracker.start_link()

    File.write!(Path.join(@tmp, "small.txt"), String.duplicate("x", 100))

    {:ok, _pid} =
      SoakFootprintGuard.start_link(
        dir: @tmp,
        ceiling_bytes: 10_000,
        interval_ms: 200,
        on_breach: fn -> BreachTracker.mark_breached() end
      )

    Process.sleep(500)

    refute BreachTracker.breached?(), "guard must not breach below ceiling"
  after
    stop_guarded()
    BreachTracker.stop()
  end

  test "breaches above ceiling, writes a report, and invokes on_breach" do
    BreachTracker.start_link()

    # 50 KB of live data, ceiling 1 KB -> breach.
    File.write!(Path.join(@tmp, "big.txt"), String.duplicate("x", 50000))

    {:ok, _pid} =
      SoakFootprintGuard.start_link(
        dir: @tmp,
        ceiling_bytes: 1024,
        interval_ms: 100,
        on_breach: fn -> BreachTracker.mark_breached() end
      )

    assert_receive_breached(3_000)

    assert BreachTracker.breached?(), "on_breach must fire on overrun"
  after
    stop_guarded()
    BreachTracker.stop()
  end

  defp assert_receive_breached(timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    unless BreachTracker.breached?() or System.monotonic_time(:millisecond) > deadline do
      Process.sleep(50)
      assert_receive_breached(timeout_ms - 50)
    end
  end

  defp stop_guarded do
    case Process.whereis(SoakFootprintGuard) do
      nil -> :ok
      pid when is_pid(pid) -> GenServer.stop(pid)
    end
  end
end
