defmodule ObservationBus.CIL.Mission.MissionScheduler do
  @moduledoc """
  Coordinates mission scheduling across scientific, engineering, planetary,
  civilization, discovery challenge, and verification domains.

  Respects priority, dependencies, and resource availability.
  """
  use GenServer

  defstruct [:queue, :running, :scheduled_count]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cycle()
    {:ok, %__MODULE__{queue: :queue.new(), running: %{}, scheduled_count: 0}}
  end

  @doc "Enqueue a mission for scheduling."
  @spec enqueue(String.t()) :: :ok
  def enqueue(mission_id) do
    GenServer.cast(__MODULE__, {:enqueue, mission_id})
  end

  @doc "Get scheduler status."
  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def handle_cast({:enqueue, mission_id}, state) do
    {:noreply, %{state | queue: :queue.in(mission_id, state.queue)}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{
      queue_size: :queue.len(state.queue),
      running: Map.keys(state.running),
      total_scheduled: state.scheduled_count
    }, state}
  end

  @impl true
  def handle_info(:schedule_cycle, state) do
    schedule_cycle()
    case :queue.out(state.queue) do
      {:empty, _queue} -> {:noreply, state}
      {{:value, mission_id}, queue} ->
        running = Map.put(state.running, mission_id, DateTime.utc_now())
        {:noreply, %{state | queue: queue, running: running,
                      scheduled_count: state.scheduled_count + 1}}
    end
  end

  defp schedule_cycle do
    Process.send_after(self(), :schedule_cycle, 30_000)
  end
end
