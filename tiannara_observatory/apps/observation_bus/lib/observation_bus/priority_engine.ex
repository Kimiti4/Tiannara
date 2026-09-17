defmodule ObservationBus.PriorityEngine do
  @moduledoc """
  Constitutional priority engine — not FIFO, but priority-based.

  Priority levels:
    * 100 — Constitutional (certification failures, integrity violations)
    *  90 — Security (unauthorized access, tampering attempts)
    *  80 — Scientific (discoveries, validations, refutations)
    *  70 — Runtime (health, recovery, checkpoint events)
    *  60 — Engineering (optimization, deployment)
    *  50 — Knowledge (graph updates, new principles)
    *  40 — Planetary (climate, infrastructure, resources)
    *  30 — Evolution (generation changes, regression)
    *  20 — Dashboard (UI refresh, metrics snapshots)
    *  10 — Background (analytics, archival, GC)
  """

  use GenServer

  alias ObservationBus.Event

  @doc """
  Enqueues an event into the priority queue.
  """
  @spec enqueue(Event.t()) :: :ok
  def enqueue(%Event{} = event) do
    GenServer.cast(__MODULE__, {:enqueue, event})
  end

  @doc """
  Dequeues the highest-priority event.
  Returns `{:ok, event}` or `:empty`.
  """
  @spec dequeue() :: {:ok, Event.t()} | :empty
  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  @doc """
  Returns current queue depth per priority level.
  """
  @spec queue_depth() :: map()
  def queue_depth do
    GenServer.call(__MODULE__, :queue_depth)
  end

  @doc """
  Returns total queued event count.
  """
  @spec total_queued() :: non_neg_integer()
  def total_queued do
    GenServer.call(__MODULE__, :total_queued)
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{queues: %{}, size: 0}}
  end

  @impl true
  def handle_cast({:enqueue, %Event{priority: prio} = event}, state) do
    queue = Map.get(state.queues, prio, :queue.new())
    new_queue = :queue.in(event, queue)
    new_queues = Map.put(state.queues, prio, new_queue)
    {:noreply, %{state | queues: new_queues, size: state.size + 1}}
  end

  @impl true
  def handle_call(:dequeue, _from, state) do
    priorities = state.queues |> Map.keys() |> Enum.sort(:desc)

    dequeue_result = Enum.find_value(priorities, :empty, fn prio ->
      queue = Map.get(state.queues, prio)
      case :queue.out(queue) do
        {{:value, event}, rest} ->
          new_queues =
            if :queue.is_empty(rest) do
              Map.delete(state.queues, prio)
            else
              Map.put(state.queues, prio, rest)
            end
          {:ok, %{state | queues: new_queues, size: state.size - 1}, event}
        {:empty, _} ->
          nil
      end
    end)

    case dequeue_result do
      {:ok, new_state, event} -> {:reply, {:ok, event}, new_state}
      :empty -> {:reply, :empty, state}
    end
  end

  @impl true
  def handle_call(:queue_depth, _from, state) do
    depth = state.queues |> Map.new(fn {prio, q} -> {prio, :queue.len(q)} end)
    {:reply, depth, state}
  end

  @impl true
  def handle_call(:total_queued, _from, state) do
    {:reply, state.size, state}
  end
end
