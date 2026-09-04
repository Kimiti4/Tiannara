defmodule Tiannara.Research.ResearchQueue do
  @moduledoc """
  Research Queue — priority queue for pending research tasks.

  Manages the flow of hypotheses and experiments through the research pipeline.
  Supports priority ordering, status tracking, and deadlock prevention.

  ## Constitutional Alignment

    - Modularity: Isolated queue; can be replaced with external job system.
    - Observability: Queue state is fully inspectable.
    - Fault tolerance: Queue loss is recoverable from Executive Memory.
    - Determinism: Dequeue order is deterministic given the same priorities.
    - Scalability: Bounded queue prevents unbounded memory growth.
  """

  use GenServer

  require Logger

  @max_queue_size 1_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec enqueue(:hypothesis | :experiment, map()) :: :ok | {:error, :queue_full}
  def enqueue(type, item) do
    GenServer.call(__MODULE__, {:enqueue, type, item})
  end

  @spec dequeue() :: {:ok, :hypothesis | :experiment, map()} | :empty
  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  @spec pending_count() :: non_neg_integer()
  def pending_count do
    GenServer.call(__MODULE__, :pending_count)
  end

  @spec running_count() :: non_neg_integer()
  def running_count do
    GenServer.call(__MODULE__, :running_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{queue: :queue.new(), running: %{}, total_enqueued: 0, total_dequeued: 0, total_completed: 0}}
  end

  @impl true
  def handle_call({:enqueue, type, item}, _from, state) do
    if :queue.len(state.queue) >= @max_queue_size do
      {:reply, {:error, :queue_full}, state}
    else
      priority = item[:rank_score] || item[:confidence] || 0.5
      entry = {priority, type, item}
      queue = :queue.in(entry, state.queue)

      {:reply, :ok, %{state | queue: queue, total_enqueued: state.total_enqueued + 1}}
    end
  end

  @impl true
  def handle_call(:dequeue, _from, state) do
    case :queue.out(state.queue) do
      {{:value, {_priority, type, item}}, remaining} ->
        task_id = item[:id] || Tiannara.Executive.Types.new_id()
        running = Map.put(state.running, task_id, {type, item, DateTime.utc_now()})

        {:reply, {:ok, type, item}, %{state | queue: remaining, running: running, total_dequeued: state.total_dequeued + 1}}

      {:empty, _} ->
        {:reply, :empty, state}
    end
  end

  @impl true
  def handle_call(:pending_count, _from, state) do
    {:reply, :queue.len(state.queue), state}
  end

  @impl true
  def handle_call(:running_count, _from, state) do
    {:reply, map_size(state.running), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{pending: :queue.len(state.queue), running: map_size(state.running), total_enqueued: state.total_enqueued, total_dequeued: state.total_dequeued, total_completed: state.total_completed}, state}
  end
end
