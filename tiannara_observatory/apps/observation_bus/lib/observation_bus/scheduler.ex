defmodule ObservationBus.Scheduler do
  @moduledoc """
  COB Scheduler — manages different event classes with independent scheduling.

  Event classes:
    * `:real_time` — delivered immediately (constitutional, security)
    * `:background` — queued for batch delivery (analytics, archival)
    * `:replay` — scheduled replay events
    * `:certification` — certification pipeline events
    * `:planetary` — planetary simulation ticks
    * `:analytics` — batch analytics processing
  """

  use GenServer

  alias ObservationBus.Event

  @type event_class :: :real_time | :background | :replay | :certification | :planetary | :analytics

  @doc """
  Schedules an event with the given class.
  """
  @spec schedule(Event.t(), event_class()) :: :ok
  def schedule(%Event{} = event, class \\ :real_time) do
    GenServer.cast(__MODULE__, {:schedule, event, class})
  end

  @doc """
  Returns scheduler state.
  """
  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Triggers a batch flush for the given class.
  """
  @spec flush(event_class()) :: list(Event.t())
  def flush(class) do
    GenServer.call(__MODULE__, {:flush, class})
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{queues: %{}, counters: %{}, flush_timers: %{}}}
  end

  @impl true
  def handle_cast({:schedule, %Event{} = event, class}, state) do
    queue = Map.get(state.queues, class, :queue.new())
    counter = Map.get(state.counters, class, 0)

    {:noreply, %{
      state
      | queues: Map.put(state.queues, class, :queue.in(event, queue)),
        counters: Map.put(state.counters, class, counter + 1)
    }}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = state.queues |> Map.new(fn {class, q} -> {class, %{queued: :queue.len(q), total: Map.get(state.counters, class, 0)}} end)
    {:reply, status, state}
  end

  @impl true
  def handle_call({:flush, class}, _from, state) do
    queue = Map.get(state.queues, class, :queue.new())
    events = :queue.to_list(queue)
    {:reply, events, %{state | queues: Map.put(state.queues, class, :queue.new())}}
  end
end
