defmodule TiannaraRuntime.Omega.Heartbeat do
  @moduledoc """
  Continuous heartbeat publisher used by soak validation.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{SafeCPL, SentinelEventBus}

  @default_interval 1_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(opts) do
    state = %{
      interval: Keyword.get(opts, :interval, @default_interval),
      sequence: 0,
      last_heartbeat: nil
    }

    schedule(state.interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, Map.drop(state, [:interval]), state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    heartbeat = %{
      sequence: state.sequence + 1,
      timestamp: System.system_time(:millisecond),
      monotonic_time: System.monotonic_time(:millisecond),
      status: :alive
    }

    SafeCPL.record_event(:heartbeat, heartbeat)
    publish(:heartbeat, heartbeat)
    schedule(state.interval)

    {:noreply, %{state | sequence: heartbeat.sequence, last_heartbeat: heartbeat}}
  end

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp schedule(interval), do: Process.send_after(self(), :heartbeat, interval)
end
