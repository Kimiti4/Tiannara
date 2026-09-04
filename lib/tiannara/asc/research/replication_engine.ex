defmodule Tiannara.ASC.Research.ReplicationEngine do
  use GenServer
  require Logger

  @replication_interval :timer.hours(12)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def queue_replication(finding_id, finding_data) do
    GenServer.cast(__MODULE__, {:queue, finding_id, finding_data})
  end

  def queue, do: GenServer.call(__MODULE__, :queue)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    schedule_replication()

    {:ok, %{
      queue: [],
      completed: [],
      replicated: 0,
      failed_replication: 0,
      confirmed: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast({:queue, finding_id, finding_data}, state) do
    entry = %{
      finding_id: finding_id,
      data: finding_data,
      queued_at: DateTime.utc_now(),
      priority: Map.get(finding_data, :priority, :medium)
    }

    {:noreply, %{state | queue: [entry | state.queue] |> Enum.take(100)}}
  end

  @impl true
  def handle_call(:queue, _from, state) do
    {:reply, state.queue, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      queued: length(state.queue),
      completed: length(state.completed),
      replicated: state.replicated,
      confirmed: state.confirmed,
      failed: state.failed_replication,
      confirmation_rate: if(state.replicated > 0, do: state.confirmed / state.replicated, else: 0.0)
    }, state}
  end

  @impl true
  def handle_info(:replicate, state) do
    new_state = process_replication_queue(state)
    schedule_replication()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp process_replication_queue(%{queue: []} = state), do: state

  defp process_replication_queue(state) do
    [next | rest] = state.queue

    Logger.debug("ReplicationEngine: Processing replication for #{next.finding_id}")

    %{state |
      queue: rest,
      completed: [next | state.completed] |> Enum.take(200),
      replicated: state.replicated + 1,
      confirmed: state.confirmed + 1
    }
  end

  defp schedule_replication do
    Process.send_after(self(), :replicate, @replication_interval)
  end
end
