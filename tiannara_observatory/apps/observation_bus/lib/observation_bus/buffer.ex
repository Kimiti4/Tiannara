defmodule ObservationBus.Buffer do
  @moduledoc """
  Event buffer — holds pending events between intake and processing.

  Provides backpressure-aware buffering with configurable capacity.
  Events are held per-priority-queue and drained by the Router.
  """

  use GenServer

  alias ObservationBus.Event

  @default_capacity 10_000

  @doc """
  Buffers an event for processing.
  """
  @spec push(Event.t()) :: :ok | {:error, :buffer_full}
  def push(%Event{} = event) do
    GenServer.call(__MODULE__, {:push, event}, :infinity)
  end

  @doc """
  Pops the highest-priority event from the buffer.
  """
  @spec pop() :: {:ok, Event.t()} | :empty
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @doc """
  Returns buffer stats.
  """
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Drains all buffered events, returning them in priority order.
  """
  @spec drain() :: list(Event.t())
  def drain do
    GenServer.call(__MODULE__, :drain)
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{queues: %{}, size: 0, capacity: @default_capacity}}
  end

  @impl true
  def handle_call({:push, %Event{priority: prio} = event}, _from, state) do
    if state.size >= state.capacity do
      {:reply, {:error, :buffer_full}, state}
    else
      queue = Map.get(state.queues, prio, :queue.new())
      {:reply, :ok, %{state | queues: Map.put(state.queues, prio, :queue.in(event, queue)), size: state.size + 1}}
    end
  end

  @impl true
  def handle_call(:pop, _from, state) do
    case do_pop(state) do
      {{:ok, _} = result, new_state} -> {:reply, result, new_state}
      {:empty, new_state} -> {:reply, :empty, new_state}
    end
  end

  @impl true
  def handle_call(:drain, _from, state) do
    events = drain_all(state.queues)
    {:reply, events, %{state | queues: %{}, size: 0}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    depth = state.queues |> Map.new(fn {prio, q} -> {prio, :queue.len(q)} end)
    {:reply, %{size: state.size, capacity: state.capacity, per_priority: depth}, state}
  end

  defp do_pop(%{queues: queues, size: size} = state) do
    priorities = queues |> Map.keys() |> Enum.sort(:desc)
    Enum.find_value(priorities, {:empty, state}, fn prio ->
      queue = Map.get(queues, prio)
      case :queue.out(queue) do
        {{:value, event}, rest} ->
          new_queues = if :queue.is_empty(rest), do: Map.delete(queues, prio), else: Map.put(queues, prio, rest)
          {{:ok, event}, %{state | queues: new_queues, size: size - 1}}
        {:empty, _} -> nil
      end
    end)
  end

  defp drain_all(queues) do
    queues
    |> Map.keys()
    |> Enum.sort(:desc)
    |> Enum.flat_map(fn prio ->
      queue = Map.get(queues, prio)
      :queue.to_list(queue)
    end)
  end
end
