defmodule ObservatoryApiWeb.Hub.EventDispatcher do
  use GenServer

  @priorities [:constitutional, :scientific, :alert, :metric, :normal, :background]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def dispatch(event, priority \\ :normal) do
    GenServer.cast(__MODULE__, {:dispatch, event, priority})
  end

  def subscribe(topic, pid) do
    GenServer.cast(__MODULE__, {:subscribe, topic, pid})
  end

  def unsubscribe(topic, pid) do
    GenServer.cast(__MODULE__, {:unsubscribe, topic, pid})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    queues = Map.new(@priorities, fn p -> {p, :queue.new()} end)
    {:ok, %{subscribers: %{}, queues: queues, dispatched: 0, queued: 0, topics: %{}}}
  end

  @impl true
  def handle_cast({:dispatch, event, priority}, state) do
    priority = if priority in @priorities, do: priority, else: :normal
    topic = event[:domain] || event.domain || "system"

    case Map.get(state.subscribers, topic) do
      nil ->
        {:noreply, push_queue(state, priority, event)}

      pids when is_list(pids) ->
        Enum.each(pids, fn pid ->
          if Process.alive?(pid) do
            send(pid, {:observatory_event, event, priority, topic})

            :telemetry.execute([:observatory, :dispatcher, :delivered], %{count: 1}, %{
              topic: topic
            })
          end
        end)

        {:noreply, %{state | dispatched: state.dispatched + 1}}
    end
  end

  @impl true
  def handle_cast({:subscribe, topic, pid}, %{subscribers: subs} = state) do
    current = Map.get(subs, topic, [])
    new_subs = if pid in current, do: current, else: [pid | current]

    {:noreply,
     %{
       state
       | subscribers: Map.put(subs, topic, new_subs),
         topics: Map.put(state.topics, pid, [topic | Map.get(state.topics, pid, []) -- [topic]])
     }}
  end

  @impl true
  def handle_cast({:unsubscribe, topic, pid}, %{subscribers: subs} = state) do
    current = Map.get(subs, topic, [])

    {:noreply,
     %{
       state
       | subscribers: Map.put(subs, topic, current -- [pid]),
         topics: Map.put(state.topics, pid, Map.get(state.topics, pid, []) -- [topic])
     }}
  end

  @impl true
  def handle_info(:flush_queues, state) do
    flushed =
      Enum.reduce(@priorities, state, fn p, acc ->
        q = Map.get(acc.queues, p, :queue.new())

        {_drained, remaining} = flush_queue(q, acc.subscribers, p, 100)
        %{acc | queues: Map.put(acc.queues, p, remaining)}
      end)

    schedule_flush()
    {:noreply, %{flushed | dispatched: state.dispatched + 1}}
  end

  defp flush_queue(queue, subscribers, priority, limit, drained \\ 0)
  defp flush_queue(queue, _subscribers, _priority, 0, drained), do: {drained, queue}

  defp flush_queue(queue, subscribers, priority, _limit, drained) do
    case :queue.out(queue) do
      {{:value, event}, rest} ->
        topic = event[:domain] || event.domain || "system"

        case Map.get(subscribers, topic) do
          nil ->
            flush_queue(rest, subscribers, priority, 0, drained + 1)

          pids ->
            Enum.each(pids, fn pid ->
              if Process.alive?(pid) do
                send(pid, {:observatory_event, event, priority, topic})
              end
            end)

            flush_queue(rest, subscribers, priority, 0, drained + 1)
        end

      {:empty, q} ->
        {drained, q}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    queue_sizes = Map.new(state.queues, fn {p, q} -> {p, :queue.len(q)} end)

    {:reply,
     %{
       subscribers: map_size(state.subscribers),
       topics: state.subscribers |> Enum.map(fn {t, pids} -> {t, length(pids)} end) |> Map.new(),
       dispatched: state.dispatched,
       queued: state.queued,
       queue_sizes: queue_sizes,
       priorities: @priorities
     }, state}
  end

  defp push_queue(state, priority, event) do
    q = Map.get(state.queues, priority, :queue.new())

    %{
      state
      | queues: Map.put(state.queues, priority, :queue.in(event, q)),
        queued: state.queued + 1
    }
  end

  defp schedule_flush do
    Process.send_after(self(), :flush_queues, 50)
  end
end
